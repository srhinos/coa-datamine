RapidRollUndesiredSpellListItemMixin = CreateFromMixins("RapidRollSpellListItemMixin")

function RapidRollUndesiredSpellListItemMixin:OnLoad()
    RapidRollSpellListItemMixin.OnLoad(self)
end

function RapidRollUndesiredSpellListItemMixin:OnShow()
    RapidRollSpellListItemMixin.OnShow(self)
    self:RegisterEvent("WILDCARD_RAPID_ROLL_UNLEARNED")
end

function RapidRollUndesiredSpellListItemMixin:OnHide()
    RapidRollSpellListItemMixin.OnHide(self)
    self:UnregisterEvent("WILDCARD_RAPID_ROLL_UNLEARNED")
end

function RapidRollUndesiredSpellListItemMixin:GetEntry()
    return C_Wildcard.GetFilteredUndesiredEntryAtIndex(self.index)
end

function RapidRollUndesiredSpellListItemMixin:IsActive()
    return C_Wildcard.IsUndesiredID(self.entry.ID, self.entry.Type)
end

function RapidRollUndesiredSpellListItemMixin:CanSetActive()
    return C_Wildcard.CanAddUndesiredID(self.entry.ID, self.entry.Type)
end

function RapidRollUndesiredSpellListItemMixin:SetActive()
    WildCardRapidRollingFrame:SaveUndesiredEntry(self.entry.ID, self.entry.Type)
end

function RapidRollUndesiredSpellListItemMixin:RemoveActive()
    WildCardRapidRollingFrame:RemoveUndesiredEntry(self.entry.ID, self.entry.Type)
end

function RapidRollUndesiredSpellListItemMixin:UpdateActiveVisual()
    if self:IsActive() then
        self:SetActiveVisual()
    else
        self:SetInactiveVisual()
    end

    self.CoreIcon:Hide()
    self.OptimalIcon:Hide()
    self.EmpoweringIcon:Hide()
    self.SynergisticIcon:Hide()

    if WildCardRapidRollingFrame.savedBuild and self.spellID then
        local spell = C_BuildCreator.GetSpell(WildCardRapidRollingFrame.savedBuild.ID, self.spellID) 

        if spell then
            self.CoreIcon:SetShown(spell.IsCoreAbility)
            self.OptimalIcon:SetShown(spell.IsOptimalAbility)
            self.EmpoweringIcon:SetShown(spell.IsEmpoweringAbility)
            self.SynergisticIcon:SetShown(spell.IsSynergisticAbility)
        end
    end
end

function RapidRollUndesiredSpellListItemMixin:SetActiveVisual()
    self.Icon:SetIconColor(1, 0, 0, 1)
    self:GetHighlightTexture():SetVertexColor(1, 0, 0, 1)
    self:LockHighlight()
    self.Text:SetTextColor(RED_FONT_COLOR:GetRGB())
    self.LockButton:Hide()

    if C_Wildcard.GetNextUnlearnedID() == self.entry.ID then
        self.Shine:Show()
        AutoCastShine_AutoCastStart(self.Shine, 1, 0, 0)
    else
        self.Shine:Hide()
        AutoCastShine_AutoCastStop(self.Shine)
    end
end

function RapidRollUndesiredSpellListItemMixin:SetInactiveVisual()
    self.Icon:SetIconColor(1, 1, 1, 1)
    self:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
    self:UnlockHighlight()
    self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    self.LockButton:Show()
    self.Shine:Hide()
    AutoCastShine_AutoCastStop(self.Shine)
end

function RapidRollUndesiredSpellListItemMixin:OnAnimFinished()
    WildCardRapidRollingFrame:Refresh()
end

function RapidRollUndesiredSpellListItemMixin:WILDCARD_RAPID_ROLL_UNLEARNED(internalID)
    if self.entry.ID == internalID then
        self.GlowToast:Show()
        self.GlowToast.AnimIn:Play()
        PlaySound(SOUNDKIT.UI_SHIPYARD_SHIP_DESTROYED_FLAME_01)
    end
end
