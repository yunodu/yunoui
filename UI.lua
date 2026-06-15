local ADDON_NAME = ...

local root = _G.yuno or {}
_G.yuno = root

local UI = root.UI or {}
root.UI = UI
_G.YunoUI = UI

UI.Media = UI.Media or {
    Logo = "Interface\\AddOns\\yuno\\Media\\logo.png",
    Font = "Interface\\AddOns\\yuno\\Media\\Gilroy-Regular.ttf",
    FontSemiBold = "Interface\\AddOns\\yuno\\Media\\Gilroy-SemiBold.ttf",
    FontBold = "Interface\\AddOns\\yuno\\Media\\Gilroy-Bold.ttf",
}

UI.Theme = {
    bg = { 0x0A / 255, 0x0A / 255, 0x0C / 255, 0.98 },
    panel = { 0x0D / 255, 0x0D / 255, 0x10 / 255, 1.00 },
    row = { 0x12 / 255, 0x12 / 255, 0x16 / 255, 1.00 },
    rowHover = { 0x18 / 255, 0x18 / 255, 0x1E / 255, 1.00 },
    line = { 0x1E / 255, 0x1E / 255, 0x24 / 255, 1.00 },
    accent = { 0x00 / 255, 0xAD / 255, 0xFF / 255, 1.00 },
    accentDim = { 0x00 / 255, 0xAD / 255, 0xFF / 255, 0.18 },
    accentBarely = { 0x00 / 255, 0xAD / 255, 0xFF / 255, 0.05 },
    text = { 0xED / 255, 0xED / 255, 0xED / 255, 1.00 },
    muted = { 0x8F / 255, 0x92 / 255, 0x9A / 255, 1.00 },
    subtle = { 0x61 / 255, 0x65 / 255, 0x70 / 255, 1.00 },
    success = { 0x60 / 255, 0xE6 / 255, 0xB8 / 255, 1.00 },
    error = { 0xFF / 255, 0x66 / 255, 0x72 / 255, 1.00 },
}

local function Color(target, color)
    target:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function ApplyTexture(frame, key, layer, color)
    local texture = frame[key]
    if not texture then
        texture = frame:CreateTexture(nil, layer or "BACKGROUND")
        texture:SetAllPoints()
        frame[key] = texture
    end
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    return texture
end

local function SetFlatBackground(frame, color)
    return ApplyTexture(frame, "_yunoBg", "BACKGROUND", color)
end

local function FontPath(weight)
    if weight == "bold" then return UI.Media.FontBold end
    if weight == "semibold" then return UI.Media.FontSemiBold end
    return UI.Media.Font
end

local function SetFont(fontString, size, weight)
    local path = FontPath(weight)
    if not fontString:SetFont(path, size or 12, "") then
        fontString:SetFont(STANDARD_TEXT_FONT, size or 12, "")
    end
end

local function CallClick(frame)
    if frame._yunoOnClick then
        frame:_yunoOnClick()
    end
end

function UI:SetFrameColor(frame, color)
    SetFlatBackground(frame, color or self.Theme.row)
end

function UI:SetTextColor(fontString, kind)
    Color(fontString, self.Theme[kind or "text"] or self.Theme.text)
end

function UI:SetStatusColor(fontString, ok)
    Color(fontString, ok and self.Theme.success or self.Theme.error)
end

function UI:CreateText(parent, text, size, kind, weight)
    local fontString = parent:CreateFontString(nil, "OVERLAY")
    SetFont(fontString, size or 12, weight)
    fontString:SetText(text or "")
    fontString:SetJustifyH("LEFT")
    fontString:SetJustifyV("MIDDLE")
    self:SetTextColor(fontString, kind or "text")
    return fontString
end

function UI:CreateWindow(name, parent, width, height)
    local frame = CreateFrame("Frame", name, parent or UIParent)
    frame:SetSize(width or 820, height or 560)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    SetFlatBackground(frame, self.Theme.bg)

    frame.title = self:CreateText(frame, "yunoUI", 18, "text", "bold")
    frame.title:SetPoint("TOPLEFT", 22, -18)

    frame.subtitle = self:CreateText(frame, "configuration", 11, "muted", "semibold")
    frame.subtitle:SetPoint("LEFT", frame.title, "RIGHT", 10, -1)

    frame.closeButton = self:CreateFlatButton(frame, "x")
    frame.closeButton:SetSize(28, 24)
    frame.closeButton:SetPoint("TOPRIGHT", -14, -14)
    frame.closeButton:SetOnClick(function()
        frame:Hide()
    end)

    function frame:RebuildChromeText()
        if self.closeButton and self.closeButton.RebuildLabel then
            self.closeButton:RebuildLabel()
        end
    end

    frame:SetScript("OnShow", function(self)
        self:RebuildChromeText()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if self:IsShown() then self:RebuildChromeText() end
            end)
            C_Timer.After(0.30, function()
                if self:IsShown() then self:RebuildChromeText() end
            end)
        end
    end)

    return frame
end

function UI:CreateSidebarButton(parent, label, pageId)
    local button = CreateFrame("Frame", nil, parent)
    button:SetHeight(34)
    button:SetFrameLevel((parent:GetFrameLevel() or 0) + 2)
    button:EnableMouse(true)
    button.pageId = pageId
    SetFlatBackground(button, self.Theme.bg)

    button.activeLine = button:CreateTexture(nil, "ARTWORK")
    button.activeLine:SetPoint("TOPLEFT")
    button.activeLine:SetPoint("BOTTOMLEFT")
    button.activeLine:SetWidth(2)
    button.activeLine:SetColorTexture(self.Theme.accent[1], self.Theme.accent[2], self.Theme.accent[3], 1)

    button.hover = button:CreateTexture(nil, "BACKGROUND")
    button.hover:SetAllPoints()
    button.hover:SetColorTexture(self.Theme.row[1], self.Theme.row[2], self.Theme.row[3], 0)

    button.labelHost = CreateFrame("Frame", nil, button)
    button.labelHost:SetAllPoints()
    button.labelHost:SetFrameLevel(button:GetFrameLevel() + 2)

    button.label = self:CreateText(button.labelHost, label, 12, "muted", "semibold")
    if button.label.SetDrawLayer then button.label:SetDrawLayer("OVERLAY", 7) end
    button.label:SetText(label or "")

    function button:SetLabelInset(left)
        self.label:ClearAllPoints()
        self.label:SetPoint("TOPLEFT", self.labelHost, "TOPLEFT", left or 14, 0)
        self.label:SetPoint("BOTTOMRIGHT", self.labelHost, "BOTTOMRIGHT", -8, 0)
    end

    button:SetLabelInset(14)

    function button:SetActive(active)
        self._active = active and true or false
        self.activeLine:SetShown(self._active)
        local label = self.overlayLabel or self.label
        if self._active then
            self.hover:SetColorTexture(UI.Theme.accentBarely[1], UI.Theme.accentBarely[2], UI.Theme.accentBarely[3], UI.Theme.accentBarely[4])
            label:SetTextColor(1, 1, 1, 1)
        elseif self._hovered then
            self.hover:SetColorTexture(UI.Theme.rowHover[1], UI.Theme.rowHover[2], UI.Theme.rowHover[3], 1)
            UI:SetTextColor(label, "text")
        else
            self.hover:SetColorTexture(UI.Theme.row[1], UI.Theme.row[2], UI.Theme.row[3], 0)
            UI:SetTextColor(label, "muted")
        end
        if self.overlayLabel and self.label then
            if self._active then
                self.label:SetTextColor(1, 1, 1, 1)
            elseif self._hovered then
                UI:SetTextColor(self.label, "text")
            else
                UI:SetTextColor(self.label, "muted")
            end
        end
    end

    function button:SetOnClick(callback)
        self._yunoOnClick = callback
    end

    button:SetScript("OnEnter", function(self)
        self._hovered = true
        self:SetActive(self._active)
    end)
    button:SetScript("OnLeave", function(self)
        self._hovered = false
        self:SetActive(self._active)
    end)
    button:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton == "LeftButton" then CallClick(self) end
    end)
    button:SetActive(false)

    return button
end

function UI:CreateFlatButton(parent, label, variant)
    local button = CreateFrame("Frame", nil, parent)
    button:SetSize(150, 32)
    button:EnableMouse(true)
    button.variant = variant or "secondary"
    button._labelText = label or ""
    SetFlatBackground(button, self.Theme.row)

    function button:RebuildLabel()
        local text = self._labelText or ""
        if self.label and self.label.GetText then
            text = self.label:GetText() or text
        end

        local r, g, b, a = 1, 1, 1, 1
        if self.label and self.label.GetTextColor then
            r, g, b, a = self.label:GetTextColor()
        end

        if self.labelHost then
            self.labelHost:Hide()
            self.labelHost:SetParent(nil)
        end

        self.labelHost = CreateFrame("Frame", nil, self)
        self.labelHost:SetAllPoints()
        self.labelHost:SetFrameLevel(self:GetFrameLevel() + 2)

        self.label = UI:CreateText(self.labelHost, text, 12, "text", "semibold")
        self.label:SetPoint("CENTER")
        self.label:SetTextColor(r or 1, g or 1, b or 1, a or 1)
    end

    button:RebuildLabel()

    button.activeIndicator = button:CreateTexture(nil, "ARTWORK")
    button.activeIndicator:SetPoint("TOPLEFT")
    button.activeIndicator:SetPoint("BOTTOMLEFT")
    button.activeIndicator:SetWidth(2)
    button.activeIndicator:SetColorTexture(self.Theme.accent[1], self.Theme.accent[2], self.Theme.accent[3], 1)
    button.activeIndicator:SetShown(button.variant == "primary")
    if button.variant == "primary" then
        button.label:SetTextColor(1, 1, 1, 1)
    end

    function button:SetOnClick(callback)
        self._yunoOnClick = callback
    end

    function button:SetLabel(text)
        self._labelText = text or ""
        self.label:SetText(self._labelText)
    end

    function button:SetChoiceActive(active)
        self.choiceActive = active and true or false
        self.activeIndicator:SetShown(self.choiceActive or self.variant == "primary")
        SetFlatBackground(self, UI.Theme.row)
        if self.choiceActive then
            self.label:SetTextColor(1, 1, 1, 1)
        elseif self.variant == "primary" then
            self.label:SetTextColor(1, 1, 1, 1)
        else
            UI:SetTextColor(self.label, "muted")
        end
    end

    function button:SetEnabledState(enabled)
        self._disabled = not enabled
        self:SetAlpha(enabled and 1 or 0.42)
        self:EnableMouse(enabled and true or false)
    end

    button:SetScript("OnEnter", function(self)
        if self._disabled then return end
        SetFlatBackground(self, UI.Theme.rowHover)
        self:SetAlpha(1)
    end)
    button:SetScript("OnLeave", function(self)
        SetFlatBackground(self, UI.Theme.row)
        self:SetAlpha(1)
    end)
    button:SetScript("OnMouseDown", function(self, mouseButton)
        if self._disabled or mouseButton ~= "LeftButton" then return end
        SetFlatBackground(self, UI.Theme.accentDim)
        self:SetAlpha(0.76)
    end)
    button:SetScript("OnMouseUp", function(self, mouseButton)
        if self._disabled then return end
        SetFlatBackground(self, self:IsMouseOver() and UI.Theme.rowHover or UI.Theme.row)
        self:SetAlpha(1)
        if mouseButton == "LeftButton" then CallClick(self) end
    end)

    return button
end

function UI:CreateStatusRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(34)
    SetFlatBackground(row, self.Theme.row)

    row.text = self:CreateText(row, "", 12, "muted", "semibold")
    row.text:SetPoint("LEFT", 12, 0)
    row.text:SetPoint("RIGHT", -12, 0)

    function row:SetStatus(ok, message)
        self.text:SetText(message or "")
        UI:SetStatusColor(self.text, ok)
        self:Show()
    end

    function row:SetMuted(message)
        self.text:SetText(message or "")
        UI:SetTextColor(self.text, "muted")
        self:Show()
    end

    row:Hide()
    return row
end

function UI:CreateToggleRow(parent, labelText)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(38)
    row:EnableMouse(true)
    row.checked = false
    SetFlatBackground(row, self.Theme.row)

    row.label = self:CreateText(row, labelText, 12, "text", "semibold")
    row.label:SetPoint("LEFT", 12, 0)
    row.label:SetPoint("RIGHT", -74, 0)

    row.track = CreateFrame("Frame", nil, row)
    row.track:SetSize(44, 22)
    row.track:SetPoint("RIGHT", -12, 0)
    row.track.bg = row.track:CreateTexture(nil, "BACKGROUND")
    row.track.bg:SetAllPoints()

    row.thumb = row.track:CreateTexture(nil, "ARTWORK")
    row.thumb:SetSize(16, 16)
    row.thumb:SetColorTexture(self.Theme.text[1], self.Theme.text[2], self.Theme.text[3], 1)

    function row:Refresh()
        self.thumb:ClearAllPoints()
        if self.checked then
            self.track.bg:SetColorTexture(UI.Theme.accent[1], UI.Theme.accent[2], UI.Theme.accent[3], 1)
            self.thumb:SetPoint("RIGHT", self.track, "RIGHT", -3, 0)
        else
            self.track.bg:SetColorTexture(UI.Theme.subtle[1], UI.Theme.subtle[2], UI.Theme.subtle[3], 0.55)
            self.thumb:SetPoint("LEFT", self.track, "LEFT", 3, 0)
        end
    end

    function row:SetChecked(value)
        self.checked = value and true or false
        self:Refresh()
    end

    function row:GetChecked()
        return self.checked
    end

    function row:SetOnChanged(callback)
        self._onChanged = callback
    end

    function row:SetOnClick(callback)
        self:SetOnChanged(callback)
    end

    local function Toggle(self)
        self:SetChecked(not self.checked)
        if self._onChanged then self:_onChanged(self.checked) end
    end

    row:SetScript("OnEnter", function(self)
        SetFlatBackground(self, UI.Theme.rowHover)
    end)
    row:SetScript("OnLeave", function(self)
        SetFlatBackground(self, UI.Theme.row)
    end)
    row:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton == "LeftButton" then Toggle(self) end
    end)
    row:Refresh()

    return row
end

function UI:CreateDivider(parent)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetColorTexture(self.Theme.line[1], self.Theme.line[2], self.Theme.line[3], 1)
    return divider
end

function UI:CreateSpacer(parent, height)
    local spacer = CreateFrame("Frame", nil, parent)
    spacer:SetHeight(height or 10)
    return spacer
end

function UI:CreateSection(parentPage, titleText, maxWidth)
    local section = CreateFrame("Frame", nil, parentPage.scrollChild)
    section:SetWidth(maxWidth or parentPage.maxSectionWidth or 550)
    section.cursorY = 0
    section.rows = {}

    local function Advance(self, amount)
        self.cursorY = self.cursorY - amount
        self:SetHeight(math.max(1, math.abs(self.cursorY)))
    end

    if titleText and titleText ~= "" then
        section.title = self:CreateText(section, titleText, 11, "muted", "bold")
        section.title:SetPoint("TOPLEFT", 0, section.cursorY)
        section.title:SetPoint("RIGHT", 0, 0)
        Advance(section, 27)
    end

    function section:AddToggle(label, checked, callback)
        local row = UI:CreateToggleRow(self, label)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        row:SetChecked(checked)
        row:SetOnChanged(callback)
        self.rows[#self.rows + 1] = row
        Advance(self, 42)
        return row
    end

    function section:AddInfoRow(label, value)
        local row = CreateFrame("Frame", nil, self)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        row:SetHeight(34)
        UI:SetFrameColor(row, UI.Theme.row)

        row.label = UI:CreateText(row, label, 12, "muted", "semibold")
        row.label:SetPoint("LEFT", 12, 0)

        row.value = UI:CreateText(row, value, 12, "text", "semibold")
        row.value:SetPoint("RIGHT", -12, 0)

        self.rows[#self.rows + 1] = row
        Advance(self, 40)
        return row
    end

    function section:AddButtonRow(buttons, align)
        local row = CreateFrame("Frame", nil, self)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        row:SetHeight(34)
        row.buttons = {}

        local totalWidth = 0
        for index, data in ipairs(buttons) do
            totalWidth = totalWidth + (data.width or 150)
            if index > 1 then totalWidth = totalWidth + 10 end
        end

        local previous
        for _, data in ipairs(buttons) do
            local button = UI:CreateFlatButton(row, data.label, data.variant)
            button:SetSize(data.width or 150, 34)
            button:SetOnClick(data.onClick)
            row.buttons[#row.buttons + 1] = button
            if previous then
                button:SetPoint("LEFT", previous, "RIGHT", 10, 0)
            elseif align == "right" then
                button:SetPoint("TOPLEFT", row, "TOPRIGHT", -totalWidth, 0)
            else
                button:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
            end
            previous = button
        end

        self.rows[#self.rows + 1] = row
        Advance(self, 44)
        return row
    end

    function section:AddStepperRow(label, value, minValue, maxValue, stepValue, callback)
        local row = CreateFrame("Frame", nil, self)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        row:SetHeight(38)
        UI:SetFrameColor(row, UI.Theme.row)

        row.label = UI:CreateText(row, label, 12, "text", "semibold")
        row.label:SetPoint("LEFT", 12, 0)
        row.label:SetPoint("RIGHT", -170, 0)

        row.value = tonumber(value) or tonumber(minValue) or 0
        row.minValue = tonumber(minValue) or row.value
        row.maxValue = tonumber(maxValue) or row.value
        row.stepValue = tonumber(stepValue) or 1

        row.minus = UI:CreateFlatButton(row, "-")
        row.minus:SetSize(34, 24)
        row.minus:SetPoint("RIGHT", -96, 0)

        row.valueText = UI:CreateText(row, "", 12, "text", "semibold")
        row.valueText:SetPoint("LEFT", row.minus, "RIGHT", 8, 0)
        row.valueText:SetPoint("RIGHT", row.minus, "RIGHT", 58, 0)
        row.valueText:SetJustifyH("CENTER")

        row.plus = UI:CreateFlatButton(row, "+")
        row.plus:SetSize(34, 24)
        row.plus:SetPoint("RIGHT", -12, 0)

        function row:SetValue(nextValue, silent)
            local numeric = tonumber(nextValue) or self.value
            if numeric < self.minValue then numeric = self.minValue end
            if numeric > self.maxValue then numeric = self.maxValue end
            self.value = numeric
            self.valueText:SetText(tostring(numeric))
            if not silent and callback then callback(self, numeric) end
        end

        row.minus:SetOnClick(function()
            row:SetValue(row.value - row.stepValue)
        end)
        row.plus:SetOnClick(function()
            row:SetValue(row.value + row.stepValue)
        end)
        row:SetValue(row.value, true)

        self.rows[#self.rows + 1] = row
        Advance(self, 42)
        return row
    end

    function section:AddText(text, size, kind, height)
        local line = UI:CreateText(self, text, size or 13, kind or "text", "semibold")
        line:SetPoint("TOPLEFT", 0, self.cursorY)
        line:SetPoint("RIGHT", 0, 0)
        line:SetSpacing(4)
        self.rows[#self.rows + 1] = line
        Advance(self, height or 86)
        return line
    end

    function section:AddImage(path, width, height, blockHeight)
        local row = CreateFrame("Frame", nil, self)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        row:SetHeight(blockHeight or height or 128)

        row.image = row:CreateTexture(nil, "ARTWORK")
        row.image:SetTexture(path)
        row.image:SetSize(width or 128, height or 128)
        row.image:SetPoint("CENTER")

        self.rows[#self.rows + 1] = row
        Advance(self, blockHeight or height or 128)
        return row
    end

    function section:AddProgress(label, current, total)
        local row = CreateFrame("Frame", nil, self)
        row:SetPoint("TOPLEFT", 0, self.cursorY)
        row:SetPoint("TOPRIGHT", 0, self.cursorY)
        row:SetHeight(42)
        UI:SetFrameColor(row, UI.Theme.row)

        row.label = UI:CreateText(row, label, 12, "text", "semibold")
        row.label:SetPoint("LEFT", 12, 8)

        row.value = UI:CreateText(row, tostring(current or 0) .. " / " .. tostring(total or 0), 12, "muted", "semibold")
        row.value:SetPoint("RIGHT", -12, 8)

        row.track = CreateFrame("Frame", nil, row)
        row.track:SetPoint("BOTTOMLEFT", 12, 8)
        row.track:SetPoint("BOTTOMRIGHT", -12, 8)
        row.track:SetHeight(4)
        row.track.bg = row.track:CreateTexture(nil, "BACKGROUND")
        row.track.bg:SetAllPoints()
        row.track.bg:SetColorTexture(UI.Theme.subtle[1], UI.Theme.subtle[2], UI.Theme.subtle[3], 0.35)

        row.fill = row.track:CreateTexture(nil, "ARTWORK")
        row.fill:SetPoint("TOPLEFT")
        row.fill:SetPoint("BOTTOMLEFT")
        row.fill:SetColorTexture(UI.Theme.accent[1], UI.Theme.accent[2], UI.Theme.accent[3], 1)

        local ratio = 0
        if type(current) == "number" and type(total) == "number" and total > 0 then
            ratio = current / total
        end
        if ratio < 0 then ratio = 0 end
        if ratio > 1 then ratio = 1 end
        row.fill:SetWidth(math.max(1, (self:GetWidth() - 24) * ratio))

        self.rows[#self.rows + 1] = row
        Advance(self, 48)
        return row
    end

    return section
end

function UI:CreatePage(parent, titleText, descriptionText, maxSectionWidth)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page.maxSectionWidth = maxSectionWidth or 550
    page.sections = {}
    page:Show()

    page.header = self:CreateText(page, titleText, 20, "text", "bold")
    page.header:SetPoint("TOPLEFT", 0, 0)
    page.header:SetPoint("RIGHT", 0, 0)

    page.description = self:CreateText(page, descriptionText or "", 12, "muted", "semibold")
    page.description:SetPoint("TOPLEFT", page.header, "BOTTOMLEFT", 0, -8)
    page.description:SetPoint("RIGHT", 0, 0)
    page.description:SetSpacing(3)

    page.footer = self:CreateStatusRow(page)
    page.footer:SetPoint("BOTTOMLEFT", 0, 0)
    page.footer:SetPoint("BOTTOMRIGHT", 0, 0)
    page.footer:SetHeight(34)
    page.footer:SetMuted("Ready.")

    page.scrollFrame = CreateFrame("ScrollFrame", nil, page)
    page.scrollFrame:SetPoint("TOPLEFT", page.description, "BOTTOMLEFT", 0, -22)
    page.scrollFrame:SetPoint("BOTTOMRIGHT", page.footer, "TOPRIGHT", 0, 16)
    page.scrollFrame:EnableMouseWheel(true)
    page.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local nextScroll = current - (delta * 42)
        if nextScroll < 0 then nextScroll = 0 end
        if nextScroll > maxScroll then nextScroll = maxScroll end
        self:SetVerticalScroll(nextScroll)
    end)

    page.scrollChild = CreateFrame("Frame", nil, page.scrollFrame)
    page.scrollChild:SetSize(page.maxSectionWidth, 1)
    page.scrollFrame:SetScrollChild(page.scrollChild)

    function page:SetStatus(ok, message)
        self.footer:SetStatus(ok, message)
    end

    function page:SetMuted(message)
        self.footer:SetMuted(message or "Ready.")
    end

    function page:AddSection(title, sectionMaxWidth)
        local section = UI:CreateSection(self, title, sectionMaxWidth or self.maxSectionWidth)
        self.sections[#self.sections + 1] = section
        return section
    end

    function page:UpdateLayout()
        local currentY = 0
        local width = self.maxSectionWidth
        for _, section in ipairs(self.sections) do
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, currentY)
            width = math.max(width, section:GetWidth())
            currentY = currentY - section:GetHeight() - 30
        end
        self.scrollChild:SetWidth(width)
        self.scrollChild:SetHeight(math.max(1, math.abs(currentY)))
    end

    return page
end

function UI:ClearFrame(frame)
    if not frame then return end
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        region:Hide()
    end
end
