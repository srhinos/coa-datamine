local _, addonTable = ...

RapidRollSpellListItemMixin = CreateFromMixins(SpellListItemMixin)
RapidRollSpellListItemMixin.OnEvent = OnEventToMethod
RapidRollSpellListItemMixin.GetEntry = nop
RapidRollSpellListItemMixin.IsActive = nop
RapidRollSpellListItemMixin.CanSetActive = nop
RapidRollSpellListItemMixin.SetActive = nop
RapidRollSpellListItemMixin.RemoveActive = nop
RapidRollSpellListItemMixin.UpdateActiveVisual = nop

function RapidRollSpellListItemMixin:OnShow()
end

function RapidRollSpellListItemMixin:OnHide()
end

function RapidRollSpellListItemMixin:SetTag()
    self.spellID = nil

    self.class = "GENERAL"
    self.spec = "GENERAL"

    self:SetText(self.entry.Name)
    self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    self.Icon:SetIcon(self.entry.Icon)
    self.Icon:SetQuality(Enum.ItemQuality.Common)
    self.Icon:SetIconColor(1, 1, 1)
    
    -- SetEssence
    self.TalentEssence:Hide()
    self.AbilityEssence:Hide()
    self.EssenceText:Hide()
    
    -- SetQuality
    self.RarityGemText:Hide()
    self.RarityGemContainer:SetNumGems(0, 0)
    
    -- SetLock
    self.LockButton:Hide()

    self.Icon.Rank:Hide()
    self.Icon.RankBorder:Hide()
    self.Icon.RankUp:Hide()
end

function RapidRollSpellListItemMixin:Update()
    self.entry = self:GetEntry()

    if not self.entry then
        self:SetText("BAD ENTRY "..self.index)
        return
    end

    if self.entry.Type == "Tag" or self.entry.Type == "Suggestion" then
        self:SetTag(self.entry)
    else -- talent/ability
        self.rank, self.maxRank = C_CharacterAdvancement.GetTalentRankByID(self.entry.ID)
        self.rank = C_CharacterAdvancement.IsTalentID(self.entry.ID) and self.rank or nil

        if not self.rank or self.rank < 1 then
            self:SetSpell(self.entry.Spells[1])
        else
            self:SetSpell(self.entry.Spells[self.rank])
        end

        self:SetKnown(C_CharacterAdvancement.IsKnownID(self.entry.ID))
        self:UpdateExpandedContent()
    end

    self:UpdateActiveVisual()

    if GameTooltip:IsOwned(self) then
        self:OnEnter()
    end
end

function RapidRollSpellListItemMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.spellID then
        GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self.spellID))
    elseif self.entry.Type == "Tag" or self.entry.Type == "Suggestion" then
        GameTooltip:SetText(self.entry.Name, 1, 1, 1)
        GameTooltip:AddLine(format(SPELL_TAG_TOOLTIP, HIGHLIGHT_FONT_COLOR:WrapText(self.entry.Name)), 1, 0.82, 0, true)
    end
    GameTooltip:Show()

    self.Icon:LockHighlight()
end

function RapidRollSpellListItemMixin:OnClick()
    if self:IsActive() then
        self:RemoveActive()
    elseif self:CanSetActive() then
        self:SetActive()
    end
end 