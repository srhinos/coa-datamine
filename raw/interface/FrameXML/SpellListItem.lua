SpellListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function SpellListItemMixin:OnLoad()
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self:RegisterForDrag("LeftButton")
    self:SetNormalAtlas("spell-list-button")
    self:GetNormalTexture():SetDrawLayer("BACKGROUND")
    self:SetHighlightAtlas("spell-list-button-highlight")
    self:GetHighlightTexture():SetAlpha(0.7)
    self.Icon:SetOverlayBlendMode("ADD")
    self.Icon:UseQuality(true)
    self.Icon:SetBorderSize(36, 36)
    self.Icon:SetOverlaySize(36, 36)
    self.Icon:EnableDrag()
    self.Icon:SetScript("OnEnter", GenerateClosure(self.OnEnter, self))
    self.Icon.OnClickHandler = GenerateClosure(self.OnClick, self)
    
    self.RarityGemContainer:SetGemSize(16)
    self.RarityGemContainer:SetOrientation({ "BOTTOMRIGHT", "BOTTOMLEFT", 1, 0 })

    self.TalentEssence:SetRounded(true)
    self.TalentEssence:SetIcon("Interface\\Icons\\inv_custom_talentessence")
    self.TalentEssence:SetBorderAtlas("spec-sampleabilityring")
    self.TalentEssence:SetBorderSize(14, 14)
    
    self.AbilityEssence:SetRounded(true)
    self.AbilityEssence:SetIcon("Interface\\Icons\\inv_custom_abilityessence")
    self.AbilityEssence:SetBorderAtlas("spec-sampleabilityring")
    self.AbilityEssence:SetBorderSize(14, 14)

    self.ClassPoints:SetScript("OnEnter", GenerateClosure(self.OnEnterClassPoints, self))

    self.ExpandedContent.Border:SetAtlas("spec-thumbnailborder-off", Const.TextureKit.IgnoreAtlasSize)
    self.ExpandedContent.ClassIcon:SetRounded(true)
    self.ExpandedContent.ClassIcon:SetBorderAtlas("item-border-round-white")
    self.ExpandedContent.ClassIcon:SetBorderSize(28, 28)
    self.LockButton:SetNormalAtlas("spell-list-unlocked")
    self.LockButton:SetHighlightAtlas("spell-list-locked")
end

function SpellListItemMixin:OnShow()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:RegisterEvent("TOKEN_UPDATED")
end

function SpellListItemMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:UnregisterEvent("TOKEN_UPDATED")
end

function SpellListItemMixin:OnLeave()
    GameTooltip:Hide()
    self.Icon:UnlockHighlight()
end

function SpellListItemMixin:Update()
    if BuildCreatorUtil.IsPickingSpells() then
        self.entry = C_BuildEditor.GetFilteredEntryAtIndex(self.index)
        if not self.entry then
            self:SetText("BAD ENTRY "..self.index)
            return
        end
        self.rank = BuildCreatorUtil.GetCurrentTalentRank(self.entry.ID)
        self.maxRank = self.rank and #self.entry.Spells
    else
        self.entry = C_CharacterAdvancement.GetFilteredEntryAtIndex(self.index)
        if not self.entry then
            self:SetText("BAD ENTRY "..self.index)
            return
        end

        if C_CVar.GetBool("previewCharacterAdvancementChanges") then
            self.rank, self.maxRank = C_CharacterAdvancement.GetPendingRankByEntryID(self.entry.ID)
        else
            self.rank, self.maxRank = C_CharacterAdvancement.GetTalentRankByID(self.entry.ID)
        end

        self.rank = C_CharacterAdvancement.IsTalentID(self.entry.ID) and self.rank or nil
    end

    if self:IsSelected() then
        self:LockHighlight()
        self:GetHighlightTexture():SetAtlas("spell-list-button-selected", Const.TextureKit.IgnoreAtlasSize)
    else
        self:UnlockHighlight()
        self:GetHighlightTexture():SetAtlas("spell-list-button-highlight", Const.TextureKit.IgnoreAtlasSize)
    end

    if not self.rank or self.rank < 1 then
        self:SetSpell(self.entry.Spells[1])
    else
        self:SetSpell(self.entry.Spells[self.rank])
    end
    
    if BuildCreatorUtil.IsPickingSpells() then
        self:SetKnown(C_BuildEditor.DoesBuildHaveSpellID(self.spellID))
    else
        local IsPendingEntryID = C_CharacterAdvancement.IsPendingEntryID(self.entry.ID)

        if self.Icon.PendingChange then
            if IsPendingEntryID then
                AutoCastShine_AutoCastStart(self.Icon.PendingChange, 0, 0.7, 1)
            elseif self.Icon.PendingChange:IsVisible() then
                AutoCastShine_AutoCastStop(self.Icon.PendingChange)
            end

            self.Icon.PendingChange:SetShown(IsPendingEntryID)
        end

        self:SetKnown(IsPendingEntryID or C_CharacterAdvancement.IsKnownID(self.entry.ID))
    end

    self:UpdateExpandedContent()
    
    if GameTooltip:IsOwned(self) then
        self:OnEnter()
    end
end

function SpellListItemMixin:OnRightClick()
    CharacterAdvancement:ShowSpellDropDownMenu(self, self:GetNormalTexture())
end

function SpellListItemMixin:OnClick(button)
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)

    CloseDropDownMenus()
    
    if IsModifiedClick("CHATLINK") then
        local spellLink = LinkUtil:GetSpellLink(self.spellID)
        if ChatEdit_InsertLink(spellLink) then
            return
        end
    end

    if not BuildCreatorUtil.IsPickingSpells() then
        if IsShiftKeyDown() then
            CloseDropDownMenus()
            if C_CVar.GetBool("previewCharacterAdvancementChanges") then
                local numRanks = 1
                if C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks) then
                    CharacterAdvancementUtil.MarkForSwap(nil)
                    C_CharacterAdvancement.AddByEntryID(self.entry.ID, numRanks)
                end
            else
                local numRanks = 1
                if C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks) then
                    CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID, true)
                end
            end
            return
        end

        if IsAltKeyDown() then
             if C_CVar.GetBool("previewCharacterAdvancementChanges") then
                if C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID) then
                    CharacterAdvancementUtil.MarkForSwap(nil)
                    C_CharacterAdvancement.RemoveByEntryID(self.entry.ID)
                end
            else
                 if C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID) then
                    CharacterAdvancementUtil.ConfirmOrUnlearnID(self.entry.ID, true)
                end
            end
            return
        end

        if IsControlKeyDown() then
            if self.rank and self.rank ~= self.maxRank then
                local learns = {}
                for i = self.rank + 1, self.maxRank do
                    tinsert(learns, self.entry.ID)
                end
                CharacterAdvancementUtil.ConfirmOrLearnID(learns, true)
                return
            end
        end
    end

    local list = self:GetScrollList()

    if button == "RightButton" then
        local selectedButton = list:GetSelectedButton()
        if selectedButton then
            list:SetSelectedIndex(nil, ScrollListMixin.UpdateType.Always)
            selectedButton:OnDeselected()
        end
        self:OnRightClick()
        return
    end

    local current = list:GetSelectedIndex()
    if current == self.index then
        list:SetSelectedIndex(nil, ScrollListMixin.UpdateType.Always)
        self:OnDeselected()
        return
    end

    list:SetSelectedIndex(self.index, ScrollListMixin.UpdateType.Always)
    self:OnSelected()
end

function SpellListItemMixin:OnDoubleClick(button)
    if button == "LeftButton" then
        local canLearn, reason
        if BuildCreatorUtil.IsPickingSpells() then
            local nextSpellID
            if C_CharacterAdvancement.IsTalentSpellID(self.spellID) then
                nextSpellID = BuildCreatorUtil.GetNextTalentSpellID(self.spellID)
            elseif C_CharacterAdvancement.IsTalentAbilitySpellID(self.spellID) then
                nextSpellID = self.spellID
            elseif not C_Player:IsDefaultClass() then -- default classes cannot pick spells
                nextSpellID = self.spellID
            end

            if not nextSpellID then
                return
            end
            canLearn, reason = C_BuildEditor.CanAddSpell(BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel()))
            reason = reason and reason[1]
        else
            local numRanks = 1
            canLearn, reason = C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks)
        end
        if canLearn then
            self:Learn()
        end
    elseif button == "RightButton" then
        local canUnlearn, reason
        if BuildCreatorUtil.IsPickingSpells() then
            canUnlearn, reason = C_BuildEditor.CanRemoveSpell(BuildCreatorUtil.CreateSpellInfo(self.spellID, BuildCreatorUtil.GetPickLevel()))

            if self.Icon.RankUp then
                self.Icon.RankUp:Hide()
            end
        else
            canUnlearn, reason = C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID)
        end
        if canUnlearn then
            self:Unlearn()
        end
    end
end

function SpellListItemMixin:SetSpell(spellID)
    self.spellID = spellID
    local class, spec = C_CharacterAdvancement.GetClassInfo(spellID)

    self.class = class and class:upper() or "GENERAL"
    self.spec = spec and spec:upper() or "GENERAL"

    self:SetText(self.entry.Name)
    self.Icon:SetCharacterAdvancementEntry(self.entry)
    self:SetEssence()
    self:SetQuality()
    self:SetInvestments()
    self:SetLock()

    if self.rank then
        self.Icon.Rank:SetText(self.rank .. "/" .. self.maxRank)
        local color
        if self.rank > 0 then
            if self.rank == self.maxRank then
                color = NORMAL_FONT_COLOR
            else
                color = GREEN_FONT_COLOR
            end
        else
            color = DISABLED_FONT_COLOR
        end
        self.Icon.Rank:SetTextColor(color:GetRGB())
        self.Icon.Rank:Show()
        self.Icon.Rank:SetPoint("CENTER", self.Icon.RankBorder, "CENTER", 0, 1)
        self.Icon.RankBorder:Show()
    else
        self.Icon.Rank:Hide()
        self.Icon.RankBorder:Hide()
    end
end

function SpellListItemMixin:SetEssence()
    local ae = C_CharacterAdvancement.GetAbilityEssenceCost(self.spellID) or 0
    local te = C_CharacterAdvancement.GetTalentEssenceCost(self.spellID) or 0
    if AccessibilityUtil.IsColorBlind() then
        local text
        if ae and ae > 0 then
            text = (text and text .. " " or "") .. HIGHLIGHT_FONT_COLOR:WrapText(ae) .. " " .. ABILITY_ESSENCE_ABBR
        end

        if te and te > 0 then
            text = (text and text .. " " or "") .. HIGHLIGHT_FONT_COLOR:WrapText(te) .. " " .. TALENT_ESSENCE_ABBR
        end

        self.TalentEssence:Hide()
        self.AbilityEssence:Hide()
        self.EssenceText:SetText(text or "")
        self.EssenceText:Show()
    else
        self.EssenceText:Hide()
        if ae and ae > 0 then
            self.AbilityEssence.Count:SetText(ae)
            self.AbilityEssence:Show()
            self.TalentEssence:SetPoint("TOPRIGHT", self.AbilityEssence, "TOPLEFT", -4, 0)
        else
            self.AbilityEssence:Hide()
            self.TalentEssence:SetPoint("TOPRIGHT", self, "TOPRIGHT", -8, -4)
        end

        if te and te > 0 then
            self.TalentEssence.Count:SetText(te)
            self.TalentEssence:Show()
        else
            self.TalentEssence:Hide()
        end
    end
end 

function SpellListItemMixin:OnEnterClassPoints()
    if self.entry.RequiredClassPoints and self.entry.RequiredClassPoints > 0 then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        local invested = C_CharacterAdvancement.GetClassPointInvestment(self.entry.Class, 0)
        local hasEnough = invested >= self.entry.RequiredClassPoints
        local text = hasEnough and GREEN_FONT_COLOR:WrapText(self.entry.RequiredClassPoints) or RED_FONT_COLOR:WrapText(self.entry.RequiredClassPoints)
        text = text.." "..AccessibilityUtil.GetClassPointsMarkup(self.entry.Class)

        GameTooltip:AddLine(format(CA_GATE_CLASS_POINTS_TEXT, text), 1, 1, 1, true)
        GameTooltip:AddLine(CA_GATE_INFO_CLASS_POINTS_HINT, 1, 0.82, 0, true)
        GameTooltip:Show()
    end
end

function SpellListItemMixin:SetInvestments()
    local hasClassPoints = self:SetClassPoints()
end

function SpellListItemMixin:SetClassPoints()
    self.ClassPoints:Hide()

    if not CA_USE_GATES_DEBUG then
        return
    end

    if self.entry.RequiredClassPoints and self.entry.RequiredClassPoints > 0 then
        self.ClassPoints:SetIcon("Interface\\Icons\\classicon_" .. self.class:lower())
        self.ClassPoints.Count:SetText(self.entry.RequiredClassPoints)
        self.ClassPoints:Show()
        return true
    end
end

function SpellListItemMixin:SetQuality()
    local quality, qualityCost = C_CharacterAdvancement.GetQualityInfo(self.spellID)
    if (quality > Enum.SpellQuality.Common) and C_Config.GetBoolConfig("CONFIG_CHARACTER_ADVANCEMENT_QUALITIES_ENABLED") then
        if AccessibilityUtil.IsColorBlind() then
            self.RarityGemContainer:SetNumGems(0, 0)
            self.RarityGemText:SetFormattedText("%d %s", qualityCost, _G["ITEM_QUALITY" .. quality .. "_DESC"])
            self.RarityGemText:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
            self.RarityGemText:Show()
        else
            self.RarityGemText:Hide()
            self.RarityGemContainer:SetGemQuality(quality)
            self.RarityGemContainer:SetNumGems(qualityCost, qualityCost)
        end
    else
        self.RarityGemContainer:SetNumGems(0, 0)
        self.RarityGemText:Hide()
    end
end

function SpellListItemMixin:SetLock()
    if BuildCreatorUtil.IsPickingSpells() then
        self.LockButton:Hide()
    elseif not C_CharacterAdvancement.IsKnownID(self.entry.ID) then
        self.LockButton:Hide()
    elseif C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        self.LockButton:Show()
        if C_CharacterAdvancement.IsLockedID(self.entry.ID) then
            self.LockButton:SetNormalAtlas("spell-list-locked")
            self.LockButton.tooltipTitle = UNLOCK_SPELL
            self.LockButton.tooltipText = UNLOCK_SPELL_TOOLTIP
            self.LockButton:SetAlpha(1)
        else
            self.LockButton:SetNormalAtlas("spell-list-unlocked")
            self.LockButton.tooltipTitle = LOCK_SPELL
            self.LockButton.tooltipText = LOCK_SPELL_TOOLTIP
            self.LockButton:SetAlpha(0.7)
        end
    else
        self.LockButton:Hide()
    end

    if self.EssenceText:IsShown() then
        self.LockButton:SetPoint("TOPRIGHT", self.EssenceText, "TOPLEFT", -2, 2)
    elseif self.TalentEssence:IsShown() then
        self.LockButton:SetPoint("TOPRIGHT", self.TalentEssence, "TOPLEFT", -2, 2)
    elseif self.AbilityEssence:IsShown() then
        self.LockButton:SetPoint("TOPRIGHT", self.AbilityEssence, "TOPLEFT", -2, 2)
    else
        self.LockButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", -6, -2)
    end
end

function SpellListItemMixin:SetKnown(known)
    self.known = known
    if known then
        self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    else
        self.Text:SetTextColor(GRAY_FONT_COLOR:GetRGB())
    end
    
    self.cannotLearn = nil
    self.cannotUnlearn = nil

    if known then
        local canUnlearn, reason
        if BuildCreatorUtil.IsPickingSpells() then
            canUnlearn, reason = C_BuildEditor.CanRemoveSpell(BuildCreatorUtil.CreateSpellInfo(self.spellID, BuildCreatorUtil.GetPickLevel()))
            
            if self.Icon.RankUp then
                self.Icon.RankUp:Hide()
            end
        else
            canUnlearn, reason = C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID)

            if self.Icon.RankUp and (self.entry.Type == "Ability" or self.entry.Type == "TalentAbility") then
                local maxSpellID = C_Spell.GetMaxLearnableRank(self.spellID, C_Player:GetLevel())
                local canLearn = maxSpellID and not IsSpellKnown(maxSpellID) and not IsSpellIDKnown(maxSpellID)
                canLearn = canLearn and C_Spell.IsTrainerSpell(maxSpellID)
                self.Icon.RankUp:SetShown(maxSpellID and canLearn)
            else
                self.Icon.RankUp:Hide()
            end
        end
        self.Icon:SetIconDesaturated(false)
        self.Icon:SetIconColor(1, 1, 1)
        if not canUnlearn then
            self.cannotUnlearn = _G[reason] or reason
        end
    else
        if self.Icon.RankUp then
            self.Icon.RankUp:Hide()
        end
        local canLearn, reason
        if BuildCreatorUtil.IsPickingSpells() then
            canLearn, reason = C_BuildEditor.CanAddSpell(BuildCreatorUtil.CreateSpellInfo(self.spellID, BuildCreatorUtil.GetPickLevel()))
            reason = reason and reason[1]
        else
            local numRanks = 1
            canLearn, reason = C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks)
        end
        if canLearn then
            self.Icon:SetIconDesaturated(true)
            self.Icon:SetIconColor(1, 1, 1)
        else
            local color, desaturated = CharacterAdvancementUtil.GetSpellErrorColor(reason)
            self.Icon:SetIconDesaturated(desaturated)
            self.Icon:SetIconColor(color:GetRGB())
            if reason ~= Enum.CALearnResult.DisplayEntry then
                self.cannotLearn = _G[reason] or reason
            end
        end
    end
end

function SpellListItemMixin:OnSelected()
    if not self:IsExpanded() then
        self:ToggleExpanded(166)
        HybridScrollFrame_ScrollToIndex(self:GetScrollFrame(), self.index)
    end
end

function SpellListItemMixin:OnDeselected()
    self:Collapse()
end

function SpellListItemMixin:OnEnter()
    if HelpTip:CanShow("SPELL_HINT_LEARN_HOTKEYS1") then
        HelpTip:Show("SPELL_HINT_LEARN_HOTKEYS1", self)
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self.spellID))
    if self.cannotLearn and not self.known then
        GameTooltip:AddLine(CA_CANNOT_LEARN_S:format(self.cannotLearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    elseif self.cannotUnlearn and self.known then
        GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(self.cannotUnlearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    end
    GameTooltip:Show()
    
    self.Icon:LockHighlight()
end

function SpellListItemMixin:UpdateExpandedContent()
    local frame = self.ExpandedContent
    if self:IsExpanded() then
        frame.GMMenu:SetShown(C_AccountInfo.GetGMLevel() > 0)
        frame:Show()
        local atlas = CharacterAdvancementUtil.GetThumbnailAtlas(self.class, self.spec)
        frame.Background:SetAtlas(atlas)
        frame.Background:SetVertexColor(0.22, 0.22, 0.22, 0.8)

        local className = LOCALIZED_CLASS_NAMES_MALE[self.class]
        local specName = LOCALIZED_CLASS_SPEC_NAMES[self.class] and LOCALIZED_CLASS_SPEC_NAMES[self.class][self.spec]
        if className then
            frame.ClassIcon:Show()
            frame.ClassIcon:SetIcon("Interface\\Icons\\classicon_" .. self.class:lower())
            frame.ClassIcon:SetBorderColor(RAID_CLASS_COLORS[self.class]:GetRGB())
            frame.ClassIcon.Text:SetTextColor(RAID_CLASS_COLORS[self.class]:GetRGB())
            if specName then
                frame.ClassIcon.Text:SetText(className .. " - " .. specName)
            else
                frame.ClassIcon.Text:SetText(className)
            end
            frame.LocateButton:Show()
        elseif self.class == "GENERAL" then
            frame.ClassIcon:Show()
            frame.ClassIcon:SetIcon("Interface\\Icons\\classicon_hero")
            frame.ClassIcon:SetBorderColor(RAID_CLASS_COLORS["HERO"]:GetRGB())
            frame.ClassIcon.Text:SetTextColor(RAID_CLASS_COLORS["HERO"]:GetRGB())
            frame.ClassIcon.Text:SetText(CLASSLESS)
            frame.LocateButton:Hide()
        else
            frame.ClassIcon:Hide()
        end
        
        local canLearn, reason
        if BuildCreatorUtil.IsPickingSpells() then
            local nextSpellID
            if C_CharacterAdvancement.IsTalentSpellID(self.spellID) then
                nextSpellID = BuildCreatorUtil.GetNextTalentSpellID(self.spellID)
            elseif C_CharacterAdvancement.IsTalentAbilitySpellID(self.spellID) then
                nextSpellID = self.spellID
            elseif not C_Player:IsDefaultClass() then -- default classes cannot pick spells
                nextSpellID = self.spellID
            end

            if not nextSpellID then
                return
            end
            canLearn, reason = C_BuildEditor.CanAddSpell(BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel()))
            reason = reason and reason[1]
        else
            local numRanks = 1
            canLearn, reason = C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks)
        end
        if canLearn then
            frame.LearnButton.tooltipTitle = nil
            frame.LearnButton.tooltipText = nil
        else
            frame.LearnButton.tooltipTitle = LEARN
            frame.LearnButton.tooltipText = RED_FONT_COLOR:WrapText(CA_CANNOT_LEARN_S:format(_G[reason] or reason))
        end

        frame.LearnButton:SetEnabled(canLearn)
        
        local canUnlearn, reason
        if BuildCreatorUtil.IsPickingSpells() then
            canUnlearn, reason = C_BuildEditor.CanRemoveSpell(self.spellID)
        else
            canUnlearn, reason = C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID)
        end
        local isWildCard = C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)
        local unlearnText = isWildCard and REROLL or UNLEARN
        if canUnlearn then
            frame.UnlearnButton.tooltipTitle = nil
            frame.UnlearnButton.tooltipText = nil
        else
            frame.UnlearnButton.tooltipTitle = unlearnText
            frame.UnlearnButton.tooltipText = RED_FONT_COLOR:WrapText(CA_CANNOT_UNLEARN_S:format(_G[reason] or reason))
        end
        if isWildCard and not BuildCreatorUtil.IsPickingSpells() then
            local available = WildCardUtil.GetAvailableRerolls(self.entry.Type)
            local availableText = (WILDCARD_SOF_REROLLS_AVAILABLE or "WILDCARD_SOF_REROLLS_AVAILABLE"):format(available)
            frame.UnlearnButton.tooltipTitle = frame.UnlearnButton.tooltipTitle or unlearnText
            frame.UnlearnButton.tooltipText = frame.UnlearnButton.tooltipText and (frame.UnlearnButton.tooltipText .. "\n" .. availableText) or availableText
        end
        frame.UnlearnButton:SetEnabled(canUnlearn)
        if BuildCreatorUtil.IsPickingSpells() then
            if self.rank then
                frame.LearnButton:SetText(ADD_RANK)
                frame.UnlearnButton:SetText(REMOVE_RANK)
            else
                frame.LearnButton:SetText(ADD)
                frame.UnlearnButton:SetText(REMOVE)
            end
        elseif self.rank and self.rank > 0 then
            frame.LearnButton:SetText(RANK_UP)
            frame.UnlearnButton:SetText(unlearnText)
        else
            frame.LearnButton:SetText(LEARN)
            frame.UnlearnButton:SetText(unlearnText)
        end
    else
        frame:Hide()
    end
end 

function SpellListItemMixin:ToggleLocked()
    if C_CharacterAdvancement.IsLockedID(self.entry.ID) then
        StaticPopup_Show("UNLOCK_SPELL_CONFIRM", LinkUtil:GetSpellLink(self.spellID), nil, self.entry.ID)
    else
        C_CharacterAdvancement.LockID(self.entry.ID)
    end
end 

function SpellListItemMixin:Learn()
    if BuildCreatorUtil.IsPickingSpells() then
        local nextSpellID
        if C_CharacterAdvancement.IsTalentSpellID(self.spellID) then
            nextSpellID = BuildCreatorUtil.GetNextTalentSpellID(self.spellID)
        elseif C_CharacterAdvancement.IsTalentAbilitySpellID(self.spellID) then
            nextSpellID = self.spellID
        elseif not C_Player:IsDefaultClass() then -- default classes cannot pick spells
            nextSpellID = self.spellID
        end

        if not nextSpellID then
            return
        end

        C_BuildEditor.AddSpell(BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel()))
        BuildCreatorUtil.RefreshFinishPickingPopup()
        BuildCreatorUtil.EditorSpellsChanged(true)
        self:Update()
        return
    end
    CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID, true)
end

function SpellListItemMixin:Unlearn()
    if BuildCreatorUtil.IsPickingSpells() then
        C_BuildEditor.RemoveSpell(self.spellID)
        BuildCreatorUtil.RefreshFinishPickingPopup()
        BuildCreatorUtil.EditorSpellsChanged(true)
        self:Update()
        return
    end

    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) and C_Wildcard.IsRollRequestBlocked() then
        return
    end
    
     if C_CVar.GetBool("previewCharacterAdvancementChanges") then
        if C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID) then
            CharacterAdvancementUtil.MarkForSwap(nil)
            C_CharacterAdvancement.RemoveByEntryID(self.entry.ID)
        end
    else
        if C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID) then
            CharacterAdvancementUtil.ConfirmOrUnlearnID(self.entry.ID, true)
        end
    end
end

function SpellListItemMixin:OnDragStart()
    self.Icon:OnDragStart()
end

function SpellListItemMixin:Search()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    CharacterAdvancement:SetSearch(self.entry.Name)
end

function SpellListItemMixin:Locate()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    CharacterAdvancement:Locate(self.entry)
end

function SpellListItemMixin:CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT(result, internalID)
    if internalID == self.entry.ID then
        self:Update()
    end
end

function SpellListItemMixin:CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT(result, internalID)
    if internalID == self.entry.ID then
        self:Update()
    end
end 

function SpellListItemMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    self:Update()
end

function SpellListItemMixin:TOKEN_UPDATED()
    self:Update()
end
