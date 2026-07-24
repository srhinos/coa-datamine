RapidRollDesiredSpellListItemMixin = CreateFromMixins("RapidRollSpellListItemMixin")

function RapidRollDesiredSpellListItemMixin:OnShow()
    RapidRollSpellListItemMixin.OnShow(self)
    self:RegisterEvent("WILDCARD_RAPID_ROLL_LEARNED")
end

function RapidRollDesiredSpellListItemMixin:OnHide()
    RapidRollSpellListItemMixin.OnHide(self)
    self:UnregisterEvent("WILDCARD_RAPID_ROLL_LEARNED")
end

function RapidRollDesiredSpellListItemMixin:GetEntry()
    return C_Wildcard.GetFilteredDesiredEntryAtIndex(self.index)
end

function RapidRollDesiredSpellListItemMixin:IsActive()
    return C_Wildcard.IsDesiredID(self.entry.ID, self.entry.Type)
end

function RapidRollDesiredSpellListItemMixin:CanSetActive()
    return C_Wildcard.CanAddDesiredID(self.entry.ID, self.entry.Type)
end

function RapidRollDesiredSpellListItemMixin:SetActive()
    WildCardRapidRollingFrame:SaveDesiredEntry(self.entry.ID, self.entry.Type)
end

function RapidRollDesiredSpellListItemMixin:RemoveActive()
    WildCardRapidRollingFrame:RemoveDesiredEntry(self.entry.ID, self.entry.Type)
end

function RapidRollDesiredSpellListItemMixin:UpdateActiveVisual()
    if self:IsActive() then
        self:SetActiveVisual()
    else
        self:SetInactiveVisual()
    end
end

function RapidRollDesiredSpellListItemMixin:SetActiveVisual()
    self:SetAlpha(1)
    self:SetHighlightAtlas("spell-list-button-selected")
    self:LockHighlight()
    self.Icon:SetIconDesaturated(false)
    self.Shine:Show()
    self.Text:SetTextColor(SPELL_LINK_COLOR:GetRGB())
    AutoCastShine_AutoCastStart(self.Shine, 0, 0.7, 1)

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

function RapidRollDesiredSpellListItemMixin:SetInactiveVisual()
    self:SetAlpha(0.5)
    self:SetHighlightAtlas("spell-list-button-highlight")
    self:UnlockHighlight()
    self.Icon:SetIconDesaturated(true)
    self.Shine:Hide()
    self.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
    AutoCastShine_AutoCastStop(self.Shine)

    self.CoreIcon:SetShown(false)
    self.OptimalIcon:SetShown(false)
    self.EmpoweringIcon:SetShown(false)
    self.SynergisticIcon:SetShown(false)    
end

function RapidRollDesiredSpellListItemMixin:OnAnimFinished()
    WildCardRapidRollingFrame:Refresh()
end

function RapidRollDesiredSpellListItemMixin:WILDCARD_RAPID_ROLL_LEARNED(internalID, newRank, preRollRank, reason)
    if self.entry.ID == internalID and reason == "IS_DESIRED" then -- todo: reason names
        self.GlowToast:Show()
        self.GlowToast.AnimIn:Play()
    end
end

