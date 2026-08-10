
if UIParent and not AscensionRealmHotSwapOverlay then
    local f = CreateFrame("Frame", "AscensionRealmHotSwapOverlay", UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetAllPoints(UIParent)
    f:EnableMouse(true)
    f:Hide()

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(f)
    f.bg:SetTexture(0, 0, 0, 1)

    f.bar_bg = f:CreateTexture(nil, "ARTWORK")
    f.bar_bg:SetPoint("CENTER", f, "CENTER", 0, -70)
    f.bar_bg:SetWidth(360)
    f.bar_bg:SetHeight(18)
    f.bar_bg:SetTexture(0.08, 0.08, 0.08, 1)

    f.bar = f:CreateTexture(nil, "OVERLAY")
    f.bar:SetPoint("LEFT", f.bar_bg, "LEFT", 0, 0)
    f.bar:SetHeight(18)
    f.bar:SetWidth(1)
    f.bar:SetTexture(0.85, 0.78, 0.45, 1)

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.text:SetPoint("BOTTOM", f.bar_bg, "TOP", 0, 14)

    f.percent = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.percent:SetPoint("TOP", f.bar_bg, "BOTTOM", 0, -10)
end
