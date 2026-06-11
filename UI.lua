YunoUI = YunoUI or {}

local UI = YunoUI

UI.Media = UI.Media or {
    Logo = "Interface\\AddOns\\yuno\\Media\\logo.png",
}

UI.Theme = UI.Theme or {
    bg = { 0.012, 0.024, 0.035, 0.98 },
    panel = { 0.025, 0.055, 0.075, 1.00 },
    panelHover = { 0.035, 0.095, 0.130, 1.00 },
    panelActive = { 0.045, 0.145, 0.205, 1.00 },
    header = { 0.015, 0.045, 0.070, 0.96 },
    border = { 0.08, 0.58, 0.92, 0.92 },
    borderMuted = { 0.055, 0.220, 0.320, 1.00 },
    accent = { 0.00, 0.68, 1.00, 1.00 },
    accentSoft = { 0.24, 0.78, 1.00, 0.20 },
    text = { 0.88, 0.97, 1.00, 1.00 },
    textStrong = { 0.68, 0.91, 1.00, 1.00 },
    muted = { 0.56, 0.70, 0.80, 1.00 },
    success = { 0.45, 0.95, 0.82, 1.00 },
    error = { 1.00, 0.38, 0.42, 1.00 },
}

local function Color(target, color)
    target:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function Backdrop(frame, bg, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

function UI.SetTextColor(fontString, kind)
    Color(fontString, UI.Theme[kind or "text"] or UI.Theme.text)
end

function UI.SetStatusColor(fontString, ok)
    Color(fontString, ok and UI.Theme.success or UI.Theme.error)
end

function UI.ApplyPanelBackdrop(frame)
    Backdrop(frame, UI.Theme.bg, UI.Theme.border)
end

function UI.CreateButton(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 30)
    Backdrop(button, UI.Theme.panel, UI.Theme.border)

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    Color(button.label, UI.Theme.textStrong)

    button:SetScript("OnEnter", function(self)
        Backdrop(self, UI.Theme.panelHover, UI.Theme.accent)
        Color(self.label, UI.Theme.text)
    end)
    button:SetScript("OnLeave", function(self)
        Backdrop(self, UI.Theme.panel, UI.Theme.border)
        Color(self.label, UI.Theme.textStrong)
    end)

    return button
end

function UI.CreateCheckbox(parent, text)
    local function Refresh(self)
        local checked = self:GetChecked() == true
        if checked then
            self.checkedFill:Show()
        else
            self.checkedFill:Hide()
        end

        if self.isMouseOver then
            Backdrop(self, UI.Theme.panelHover, UI.Theme.accent)
            Color(self.label, UI.Theme.text)
        elseif checked then
            Backdrop(self, UI.Theme.panelActive, UI.Theme.accent)
            Color(self.label, UI.Theme.textStrong)
        else
            Backdrop(self, UI.Theme.panel, UI.Theme.border)
            Color(self.label, UI.Theme.text)
        end
    end

    local check = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    check:SetSize(20, 20)
    Backdrop(check, UI.Theme.panel, UI.Theme.border)

    check.checkedFill = check:CreateTexture(nil, "BACKGROUND")
    check.checkedFill:SetPoint("TOPLEFT", 3, -3)
    check.checkedFill:SetPoint("BOTTOMRIGHT", -3, 3)
    check.checkedFill:SetColorTexture(UI.Theme.accent[1], UI.Theme.accent[2], UI.Theme.accent[3], 0.22)
    check.checkedFill:Hide()

    check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    local checkedTexture = check:GetCheckedTexture()
    checkedTexture:ClearAllPoints()
    checkedTexture:SetPoint("CENTER", 0, 0)
    checkedTexture:SetSize(22, 22)
    checkedTexture:SetVertexColor(UI.Theme.textStrong[1], UI.Theme.textStrong[2], UI.Theme.textStrong[3], 1)

    check:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    local highlightTexture = check:GetHighlightTexture()
    highlightTexture:ClearAllPoints()
    highlightTexture:SetPoint("TOPLEFT", 1, -1)
    highlightTexture:SetPoint("BOTTOMRIGHT", -1, 1)
    highlightTexture:SetVertexColor(UI.Theme.accent[1], UI.Theme.accent[2], UI.Theme.accent[3], 0.16)

    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    check.label:SetPoint("LEFT", check, "RIGHT", 8, 1)
    check.label:SetText(text)
    Color(check.label, UI.Theme.text)
    check:SetHitRectInsets(0, -260, 0, 0)

    check:SetScript("OnEnter", function(self)
        self.isMouseOver = true
        Refresh(self)
    end)
    check:SetScript("OnLeave", function(self)
        self.isMouseOver = false
        Refresh(self)
    end)
    check:SetScript("OnShow", Refresh)
    check:HookScript("OnClick", Refresh)
    check.RefreshYunoStyle = Refresh

    return check
end

function UI.CreateTab(parent, text, width)
    local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tab:SetSize(width, 28)
    Backdrop(tab, UI.Theme.panel, UI.Theme.borderMuted)

    tab.label = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tab.label:SetPoint("CENTER")
    tab.label:SetText(text)
    Color(tab.label, UI.Theme.muted)

    return tab
end

function UI.StyleTab(tab, selected)
    if selected then
        Backdrop(tab, UI.Theme.panelActive, UI.Theme.accent)
        Color(tab.label, UI.Theme.text)
    else
        Backdrop(tab, UI.Theme.panel, UI.Theme.borderMuted)
        Color(tab.label, UI.Theme.muted)
    end
end

function UI.CreateStatusBox(parent, height)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetHeight(height or 30)
    Backdrop(box, UI.Theme.panel, UI.Theme.borderMuted)

    local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", box, "LEFT", 10, 0)
    text:SetPoint("RIGHT", box, "RIGHT", -10, 0)
    text:SetJustifyH("LEFT")
    Color(text, UI.Theme.muted)

    box:Hide()
    return box, text
end

function UI.CreateWindow(name, parent, width, height, subtitle)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    frame:SetSize(width or 470, height or 470)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    UI.ApplyPanelBackdrop(frame)

    frame.header = frame:CreateTexture(nil, "BACKGROUND")
    frame.header:SetPoint("TOPLEFT", 1, -1)
    frame.header:SetPoint("TOPRIGHT", -1, -1)
    frame.header:SetHeight(82)
    frame.header:SetColorTexture(UI.Theme.header[1], UI.Theme.header[2], UI.Theme.header[3], UI.Theme.header[4])

    frame.logo = frame:CreateTexture(nil, "ARTWORK")
    frame.logo:SetTexture(UI.Media.Logo)
    frame.logo:SetPoint("TOPLEFT", 8, -5)
    frame.logo:SetSize(76, 76)

    frame.accent = frame:CreateTexture(nil, "OVERLAY")
    frame.accent:SetPoint("TOPLEFT", 1, -83)
    frame.accent:SetPoint("TOPRIGHT", -1, -83)
    frame.accent:SetHeight(1)
    frame.accent:SetColorTexture(UI.Theme.accent[1], UI.Theme.accent[2], UI.Theme.accent[3], 1)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOPLEFT", 92, -20)
    frame.title:SetText("yuno")
    Color(frame.title, UI.Theme.text)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    frame.subtitle:SetText(subtitle or "Settings")
    Color(frame.subtitle, UI.Theme.muted)

    frame.closeButton = UI.CreateButton(frame, "x", 24)
    frame.closeButton:SetSize(24, 24)
    frame.closeButton:SetPoint("TOPRIGHT", -12, -12)
    frame.closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    return frame
end
