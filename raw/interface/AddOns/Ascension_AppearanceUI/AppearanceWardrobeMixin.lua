AppearanceWardrobeMixin = {}

function AppearanceWardrobeMixin:OnLoad()
    PortraitFrame_SetIcon(self, "Interface\\Icons\\inv_arcane_orb")
    PortraitFrame_SetTitle(self, APPEARANCE_WARDROBE)

    self.CloseButton:SetScript("OnClick", function()
        HideUIPanel(Collections)
    end)
end 

function AppearanceWardrobeMixin:OnShow()
     local canSeeItemTransmog, canSeeSpellTransmog = C_Appearance.CanSeeAppearances()
    self.DisableTransmogButton:SetText(canSeeItemTransmog and DISABLE_TRANSMOG or ENABLE_TRANSMOG)
    self.DisableTransmogButton.tooltipTitle = canSeeItemTransmog and DISABLE_TRANSMOG or ENABLE_TRANSMOG
    self.DisableTransmogButton.tooltipText = canSeeItemTransmog and DISABLE_TRANSMOG_TOOLTIP or ENABLE_TRANSMOG_TOOLTIP

    self.DisableSpellVisualsButton:SetText(canSeeSpellTransmog and DISABLE_SPELLVISUAL_TRANSMOG or ENABLE_SPELLVISUAL_TRANSMOG)
    self.DisableSpellVisualsButton.tooltipTitle = canSeeItemTransmog and DISABLE_SPELLVISUAL_TRANSMOG or ENABLE_SPELLVISUAL_TRANSMOG
    self.DisableSpellVisualsButton.tooltipText = canSeeItemTransmog and DISABLE_SPELLVISUAL_TRANSMOG_TOOLTIP or ENABLE_SPELLVISUAL_TRANSMOG_TOOLTIP
    
    HelpTip:Show("WARDROBE_CHANGE_TRANSMOG")
end

function AppearanceWardrobeMixin:ToggleSpellVisuals()
    local canSeeItemTransmog, canSeeSpellTransmog = C_Appearance.CanSeeAppearances()
    canSeeSpellTransmog = not canSeeSpellTransmog
    C_Appearance.SetCanSeeAppearances(canSeeItemTransmog, canSeeSpellTransmog)
    self.DisableSpellVisualsButton:SetText(canSeeSpellTransmog and DISABLE_SPELLVISUAL_TRANSMOG or ENABLE_SPELLVISUAL_TRANSMOG)
    self.DisableSpellVisualsButton.tooltipTitle = canSeeSpellTransmog and DISABLE_SPELLVISUAL_TRANSMOG or ENABLE_SPELLVISUAL_TRANSMOG
    self.DisableSpellVisualsButton.tooltipText = canSeeSpellTransmog and DISABLE_SPELLVISUAL_TRANSMOG_TOOLTIP or ENABLE_SPELLVISUAL_TRANSMOG_TOOLTIP

    if GameTooltip:IsOwned(self.DisableSpellVisualsButton) then
        self.DisableSpellVisualsButton:CallScript("OnEnter")
    end
end 

function AppearanceWardrobeMixin:ToggleItemTransmog()
    local canSeeItemTransmog, canSeeSpellTransmog = C_Appearance.CanSeeAppearances()
    canSeeItemTransmog = not canSeeItemTransmog
    C_Appearance.SetCanSeeAppearances(canSeeItemTransmog, canSeeSpellTransmog)
    self.DisableTransmogButton:SetText(canSeeItemTransmog and DISABLE_TRANSMOG or ENABLE_TRANSMOG)
    self.DisableTransmogButton.tooltipTitle = canSeeItemTransmog and DISABLE_TRANSMOG or ENABLE_TRANSMOG
    self.DisableTransmogButton.tooltipText = canSeeItemTransmog and DISABLE_TRANSMOG_TOOLTIP or ENABLE_TRANSMOG_TOOLTIP

    if GameTooltip:IsOwned(self.DisableTransmogButton) then
        self.DisableTransmogButton:CallScript("OnEnter")
    end
end 