CASpellButtonBaseMixin = {}
CASpellButtonBaseMixin.OnEvent = OnEventToMethod

local BROKEN_SPELL_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function CASpellButtonBaseMixin:OnLoad()
    self:RegisterForClicks("AnyUp")

    self.Icon:EnableMouse(false)
    self.Icon:UseQuality(true)
    self.Icon:SetOverlayBlendMode("ADD")
    if self.Icon.LockIcon then
        self.Icon.LockIcon:SetAtlas("spell-list-locked", Const.TextureKit.IgnoreAtlasSize)
    end

    if self.Icon.PendingChange then
        self.Icon.PendingChange:SetFrameLevel(self.Icon:GetFrameLevel()+5)
    end

    if self.Icon.ClassPoints then
        if self.Icon.DisabledOverlay then
            self.Icon.ClassPoints:SetFrameLevel(self.Icon.DisabledOverlay:GetFrameLevel()+10)
        else
            self.Icon.ClassPoints:SetFrameLevel(self.Icon:GetFrameLevel()+10)
        end

        self.Icon.ClassPoints:SetBorderSize(22, 22)
        self.Icon.ClassPoints.Count:SetVertexColor(1, 0, 0)
        self.Icon.ClassPoints:SetScript("OnEnter", GenerateClosure(self.OnEnterClassPoints, self))
    end

    if self.Icon.Mastery then
        self.Icon.Mastery:SetScale(0.5)
    end
end

function CASpellButtonBaseMixin:OnShow()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function CASpellButtonBaseMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function CASpellButtonBaseMixin:SetEntry(entry)
    if self.Icon.ClassPoints then
        self.Icon.ClassPoints:Hide()
    end

    self.Icon.LocationIcon:Hide()
    self.entry = entry
    self.spellID = entry.Spells[1]

    self.swapSuggestionData = false

    if self.Icon.Mastery then
        self.Icon.Mastery:Hide()

        local _, masteryID = next(entry.Masteries)

        if masteryID then
            self.Icon.Mastery:Show()
            local mastery = C_CharacterAdvancement.GetEntryByInternalID(masteryID)

            if mastery then
                self.Icon.Mastery:SetEntry(mastery)
            else
                dprint("|cffFF0000[ERROR]: "..entry.Name.." contains broken data reference "..masteryID)
                return
            end
        end
    end

    if CharacterAdvancementUtil.IsSwapping() then
        self.swapSuggestionData = CharacterAdvancementUtil.IsSwapSuggestion(entry.ID)
    end

    if entry.Type == "Talent" or entry.Type == "TalentAbility" then

        if BuildCreatorUtil.IsPickingSpells() then
            for _, spellID in ipairs(entry.Spells) do
                if C_BuildEditor.DoesBuildHaveSpellID(spellID) then
                    self.spellID = spellID
                else
                    break
                end
            end
        else
            local rank, maxRank

            if C_CharacterAdvancement.IsPending() then
                rank, maxRank = C_CharacterAdvancement.GetPendingRankByEntryID(entry.ID)
            elseif CharacterAdvancementUtil.IsSwapping() then
                rank, maxRank = C_CharacterAdvancement.GetPendingRankByEntryID(entry.ID)
                if self.swapSuggestionData then
                    rank = self.swapSuggestionData.NewCARank
                end
            else
                rank, maxRank = C_CharacterAdvancement.GetTalentRankByID(entry.ID)
            end

            rank = math.max(rank, 1)

            self.spellID = entry.Spells[rank]
        end
    end

    local isPendingBuild = C_CharacterAdvancement.IsPending()
    local name = entry.Name
    local level = entry.RequiredLevel
    local isHighEnoughLevel = level <= C_Player:GetLevel()

    if isHighEnoughLevel then
        level = HIGHLIGHT_FONT_COLOR:WrapText(level)
    else
        level = RED_FONT_COLOR:WrapText(level)
    end

    if isHighEnoughLevel and CharacterAdvancementUtil.AreTalentGatesEnabled() and self.entry.RequiredAEInvestment then
        local diff = self.entry.RequiredAEInvestment - C_CharacterAdvancement.GetGlobalAEInvestment()

        level = (diff > 0) and RED_FONT_COLOR:WrapText(entry.RequiredLevel) or HIGHLIGHT_FONT_COLOR:WrapText(entry.RequiredLevel)
    end

    --if bit.contains(entry.Flags, 0x400000) then -- is a trait
        --[[local className = entry.Class and LOCALIZED_CLASS_NAMES_MALE[string.upper(entry.Class)] or ""
        local diff = entry.RequiredClassPoints - C_CharacterAdvancement.GetClassPointInvestment(entry.Class, 0)

        local points = (diff > 0) and RED_FONT_COLOR:WrapText(entry.RequiredClassPoints) or HIGHLIGHT_FONT_COLOR:WrapText(entry.RequiredClassPoints)

        self:SetFormattedText("%s\n%s", name, HIGHLIGHT_FONT_COLOR:WrapText(className.." "..CA_POINTS_GLOBAL_STRING:format(points)))]]--
    if isHighEnoughLevel and C_Player:IsHero() then
        self:SetFormattedText("%s", name)
    else
        self:SetFormattedText("%s\n%s %s", name, HIGHLIGHT_FONT_COLOR:WrapText(LEVEL), level)
    end

    self.Icon:SetCharacterAdvancementEntry(entry)
    self:SetEnabledVisual()
    self.Icon:SetAlpha(1)
    self:EnableMouse(true)

    self.cannotLearn = nil
    self.cannotUnlearn = nil
    self.isBrokenSpell = nil

    if self:IsBrokenSpell() then
        self:SetBrokenSpellVisual()
        return
    end

    if BuildCreatorUtil.IsPickingSpells() then
        if self.Icon.PendingChange then
            self.Icon.PendingChange:Hide()
        end

        if self.Icon.LockIcon then
            self.Icon.LockIcon:Hide()
        end

        if self.Icon.RankUp then
            self.Icon.RankUp:Hide()
            self.Icon.RankUp.tooltipTitle = SPELL_RANK_AVAILABLE
            self.Icon.RankUp.tooltipText = SPELL_RANK_FIND_TRAINER
        end

        if C_BuildEditor.DoesBuildHaveSpellID(self.spellID) then
            if self.Icon.KnownGlow then
                self.Icon.KnownGlow:Show()
            end

            self.Icon:SetIconDesaturated(false)
            self.Icon:SetIconColor(1, 1, 1)
        else
            local canLearn, reason = C_BuildEditor.CanAddSpell(BuildCreatorUtil.CreateSpellInfo(self.spellID, BuildCreatorUtil.GetPickLevel()))
            if canLearn then
                if self.Icon.KnownGlow then
                    self.Icon.KnownGlow:Hide()
                end

                self.Icon:SetIconDesaturated(true)
                self.Icon:SetIconColor(1, 1, 1)
            else
                local color, desaturated = CharacterAdvancementUtil.GetSpellErrorColor(reason[1])
                
                if not(desaturated) then
                    self.Icon:SetIconDesaturated(true)
                    self:SetDisabledVisual()
                end
                if reason[1] ~= Enum.CALearnResult.DisplayEntry then
                    self.cannotLearn = CharacterAdvancementUtil.GetLearnErrorText(reason[1], entry)
                end
            end
        end
    else
        if CharacterAdvancementUtil.IsSwapping() and self.Icon.PendingChange then
            if self.swapSuggestionData then
                AutoCastShine_AutoCastStart(self.Icon.PendingChange, 0, 0.7, 1)

                self.Icon.PendingChange:SetShown(true)
                self.Icon.LockIcon:SetShown(false)

                self.Icon:SetIconDesaturated(false)
                self.Icon:SetIconColor(1, 1, 1)

                self.Icon:SetAlpha(1)
                if self.Icon.KnownGlow then
                    self.Icon.KnownGlow:Show()
                end
            else
                AutoCastShine_AutoCastStop(self.Icon.PendingChange)
                self.Icon.PendingChange:SetShown(false)

                self:SetDisabledVisual()
                self.Icon:SetAlpha(0.75)
                if self.Icon.KnownGlow then
                    self.Icon.KnownGlow:Hide()
                end
            end

            return
        end

        local IsPendingEntryID = C_CharacterAdvancement.IsPendingEntryID(entry.ID)

        if self.Icon.PendingChange then
            if IsPendingEntryID then
                AutoCastShine_AutoCastStart(self.Icon.PendingChange, 0, 0.7, 1)
            elseif self.Icon.PendingChange:IsVisible() then
                AutoCastShine_AutoCastStop(self.Icon.PendingChange)
            end

            self.Icon.PendingChange:SetShown(IsPendingEntryID)
        end

        if self.Icon.LockIcon then
            self.Icon.LockIcon:SetShown(C_CharacterAdvancement.IsLockedID(entry.ID))
        end

        if isPendingBuild and IsPendingEntryID or C_CharacterAdvancement.IsKnownID(entry.ID) then
            if self.Icon.KnownGlow then
                self.Icon.KnownGlow:Show()
            end

            self.Icon:SetIconDesaturated(false)
            self.Icon:SetIconColor(1, 1, 1)

            local canUnlearn, reason
            
            if isPendingBuild then
                canUnlearn, reason = C_CharacterAdvancement.CanRemoveByEntryID(entry.ID)
            else
                canUnlearn, reason = C_CharacterAdvancement.CanUnlearnID(entry.ID)
            end

            if not canUnlearn and not CharacterAdvancementUtil.IsReasonRandomMode(reason)  then
                self.cannotUnlearn = _G[reason] or reason
            end

            if self.Icon.RankUp and (self.entry.Type == "Ability" or self.entry.Type == "TalentAbility") then
                local maxSpellID = C_Spell.GetMaxLearnableRank(self.spellID, C_Player:GetLevel())
                local canLearn = maxSpellID and not IsSpellKnown(maxSpellID) and not IsSpellIDKnown(maxSpellID)
                canLearn = canLearn and C_Spell.IsTrainerSpell(maxSpellID)
                
                self.Icon.RankUp:SetShown(maxSpellID and canLearn)
                self.Icon.RankUp.tooltipTitle = SPELL_RANK_AVAILABLE
                self.Icon.RankUp.tooltipText = SPELL_RANK_FIND_TRAINER
            else
                if self.Icon.RankUp then
                    self.Icon.RankUp:Hide()
                    self.Icon.RankUp.tooltipTitle = SPELL_RANK_AVAILABLE
                    self.Icon.RankUp.tooltipText = SPELL_RANK_FIND_TRAINER
                end
            end
        else
            local canLearn, reason

            if isPendingBuild then
                local numRanks = 1
                canLearn, reason = C_CharacterAdvancement.CanAddByEntryID(entry.ID, numRanks) 
            else
                canLearn, reason = C_CharacterAdvancement.CanLearnID(entry.ID)
            end

            if self.Icon.RankUp then
                if reason == Enum.CALearnResult.DisplayEntry and isHighEnoughLevel then
                    self.Icon.RankUp:Show()
                    self.Icon.RankUp.tooltipTitle = SPELL_AVAILABLE
                    self.Icon.RankUp.tooltipText = SPELL_AVAILABLE_FIND_TRAINER
                else
                    self.Icon.RankUp:Hide()
                    self.Icon.RankUp.tooltipTitle = SPELL_RANK_AVAILABLE
                    self.Icon.RankUp.tooltipText = SPELL_RANK_FIND_TRAINER
                end
            end

            if self.Icon.KnownGlow then
                self.Icon.KnownGlow:Hide()
            end


            if canLearn or CharacterAdvancementUtil.IsReasonRandomMode(reason) then
                self.Icon:SetIconColor(1, 1, 1)
            else
                local color, desaturated = CharacterAdvancementUtil.GetSpellErrorColor(reason)

                if not(desaturated) then
                    self:SetDisabledVisual()
                end
            end

            self.Icon:SetIconDesaturated(true)
            if reason == Enum.CALearnResult.DisplayEntry then
                self.Icon:SetAlpha(0.75)
                self:EnableMouse(false)
            end

            if not(canLearn) then
                if reason ~= Enum.CALearnResult.DisplayEntry then
                    self.cannotLearn = CharacterAdvancementUtil.GetLearnErrorText(reason, entry)
                end
            end
        end
    end
end

function CASpellButtonBaseMixin:Refresh()
    if self.entry then
        self:SetEntry(self.entry)
        if GameTooltip:IsOwned(self) then
            self:OnEnter()
        end
    end
end

function CASpellButtonBaseMixin:ShowLocation()
    self.Icon.LocationIcon:Show()
end

function CASpellButtonBaseMixin:IsBrokenSpell()
    if not self.spellID then
        return true
    end

    local success, name = pcall(GetSpellInfo, self.spellID)
    return not success or not name
end

function CASpellButtonBaseMixin:SetBrokenSpellVisual()
    self.isBrokenSpell = true

    if DEFAULT_CHAT_FRAME and self.reportedBrokenSpellID ~= self.spellID then
        self.reportedBrokenSpellID = self.spellID
        DEFAULT_CHAT_FRAME:AddMessage(format("|cffff0000[NOT_LOCALIZED] [CA ERROR]|r Broken spell entry: entryID=%s spellID=%s name=%s", tostring(self.entry and self.entry.ID), tostring(self.spellID), tostring(self.entry and self.entry.Name)))
    end

    if self.Icon.KnownGlow then
        self.Icon.KnownGlow:Hide()
    end
    if self.Icon.PendingChange then
        AutoCastShine_AutoCastStop(self.Icon.PendingChange)
        self.Icon.PendingChange:Hide()
    end
    if self.Icon.RankUp then
        self.Icon.RankUp:Hide()
    end

    self.Icon:SetIcon(BROKEN_SPELL_ICON)
    self.Icon:SetIconDesaturated(true)
    self.Icon:SetIconColor(1, 0.15, 0.15)
    self.Icon:SetAlpha(1)
    self:EnableMouse(true)
end

function CASpellButtonBaseMixin:AddBrokenSpellTooltipLines()
    GameTooltip:AddLine("[NOT_LOCALIZED] Broken Spell", 1, 0.1, 0.1, true)
    GameTooltip:AddLine("[NOT_LOCALIZED] This Character Advancement entry references a spell that the client cannot resolve.", 1, 0.82, 0, true)
    GameTooltip:AddLine("[NOT_LOCALIZED] Spell ID: "..tostring(self.spellID), 1, 1, 1, true)

    if self.entry then
        GameTooltip:AddLine("[NOT_LOCALIZED] Entry ID: "..tostring(self.entry.ID), 1, 1, 1, true)
        if self.entry.Name then
            GameTooltip:AddLine("[NOT_LOCALIZED] Entry: "..tostring(self.entry.Name), 1, 1, 1, true)
        end
    end
end

function CASpellButtonBaseMixin:OnEnter()
    if HelpTip:CanShow("SPELL_HINT_LEARN_HOTKEYS1") then
        HelpTip:Show("SPELL_HINT_LEARN_HOTKEYS1", self)
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self:IsBrokenSpell() then
        self:AddBrokenSpellTooltipLines()
        GameTooltip:Show()

        self.Icon:LockHighlight()
        self.Icon.LocationIcon:Hide()
        return
    end

    GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self.spellID))
    if self.cannotLearn then
        GameTooltip:AddLine(CA_CANNOT_LEARN_S:format(self.cannotLearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)

        if C_Realm.IsDevelopment() then
            local _, reason = C_CharacterAdvancement.CanUnlearnID(self.entry.ID)
            GameTooltip:AddLine("Error Key: "..tostring(reason), 1, 0, 0, true)
        end
    elseif self.cannotUnlearn then
        GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(self.cannotUnlearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)

        if C_Realm.IsDevelopment() then
            local _, reason = C_CharacterAdvancement.CanUnlearnID(self.entry.ID)
            GameTooltip:AddLine("Error Key: "..tostring(reason), 1, 0, 0, true)
        end
    end
    GameTooltip:Show()
    
    self.Icon:LockHighlight()
    self.Icon.LocationIcon:Hide()
end

function CASpellButtonBaseMixin:OnEnterClassPoints()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if (self.entry.RequiredClassPoints and (self.entry.RequiredClassPoints > 0)) or (self.entry.RequiredAEInvestment and (self.entry.RequiredAEInvestment > 0)) then
        local diff = self.entry.RequiredClassPoints - C_CharacterAdvancement.GetClassPointInvestment(self.entry.Class, 0)
        local diff2 = self.entry.RequiredAEInvestment - C_CharacterAdvancement.GetGlobalAEInvestment()

        GameTooltip:AddLine(self.cannotLearn or "", 1, 0, 0, true)
        
        if (diff > 0) or (diff2 > 0) then
                local class, spec = C_CharacterAdvancement.GetClassInfo(self.spellID)
                class = class and class:upper() or "GENERAL"
                spec = spec and spec:upper() or "GENERAL"

                local className = LOCALIZED_CLASS_NAMES_MALE[class] or "NO CLASS NAME FOR "..self.spellID
                local specName = LOCALIZED_CLASS_SPEC_NAMES[class] and LOCALIZED_CLASS_SPEC_NAMES[class][spec]
                
            if (diff > 0) and (diff2 > 0) then
                GameTooltip:AddLine(CA_GATE_TOOLTIP_FORMAT_CLASS_POINTS:format(diff, className, className, className).."\n", 1, 0.82, 0, true)
                GameTooltip:AddLine(CA_GATE_TOOLTIP_FORMAT_ABILITY_ESSENCE:format(diff2), 1, 0.82, 0, true)
            elseif (diff > 0) then
                GameTooltip:AddLine(CA_GATE_TOOLTIP_FORMAT_CLASS_POINTS:format(diff, className, className, className), 1, 0.82, 0, true)
            elseif (diff2 > 0) then
                GameTooltip:AddLine(CA_GATE_TOOLTIP_FORMAT_ABILITY_ESSENCE:format(diff2), 1, 0.82, 0, true)
            end
        end
    end
    GameTooltip:Show()
end

function CASpellButtonBaseMixin:OnLeave()
    GameTooltip:Hide()
    self.Icon:GetPushedTexture():Hide()
    self.Icon:UnlockHighlight()
end

function CASpellButtonBaseMixin:OnDragStart()
    if not BuildCreatorUtil.IsPickingSpells() then
        C_CharacterAdvancement.PickupSpell(self.entry.ID)
    end
end

function CASpellButtonBaseMixin:OnClick(button)
    CloseDropDownMenus()

    if self:IsBrokenSpell() then
        return
    end

    if IsModifiedClick("CHATLINK") then
        local spellLink = LinkUtil:GetSpellLink(self.spellID)
        if ChatEdit_InsertLink(spellLink) then
            return
        end 
    end

    if button == "RightButton" then
        CharacterAdvancement:ShowSpellDropDownMenu(self)

        --[[if C_CVar.GetBool("previewCharacterAdvancementChanges") then
            if C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID) then
                CharacterAdvancementUtil.MarkForSwap(nil)
                C_CharacterAdvancement.RemoveByEntryID(self.entry.ID)
            end
        end]]--
        
        return
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
                if C_CharacterAdvancement.CanLearnID(self.entry.ID) then
                    CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID)
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
                if C_CharacterAdvancement.CanUnlearnID(self.entry.ID) then
                    CharacterAdvancementUtil.ConfirmOrUnlearnID(self.entry.ID)
                end
            end
            return
        end
    else
        if IsAltKeyDown() then
            if C_BuildEditor.DoesBuildHaveSpellID(self.spellID) then
                C_BuildEditor.RemoveSpell(self.spellID)
                BuildCreatorUtil.RefreshFinishPickingPopup()
                BuildCreatorUtil.EditorSpellsChanged()
            end
            return
        end
    end

    self:Click()
end

function CASpellButtonBaseMixin:Click()
    CloseDropDownMenus()
    if IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() then
        return
    end
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

        local spellInfo = C_BuildEditor.GetSpellByID(self.spellID) or BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel())
        spellInfo.Spell = nextSpellID
        spellInfo.Level = BuildCreatorUtil.GetPickLevel()
        C_BuildEditor.AddSpell(spellInfo)
        BuildCreatorUtil.RefreshFinishPickingPopup()
        BuildCreatorUtil.EditorSpellsChanged()
    elseif C_CVar.GetBool("previewCharacterAdvancementChanges") then
        if CharacterAdvancementUtil.IsSwapping() and self.swapSuggestionData then
            CharacterAdvancementUtil.AttemptSwap(self.entry.ID)
            return
        end

        local numRanks = 1
        if C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks) then
            CharacterAdvancementUtil.MarkForSwap(nil)
            C_CharacterAdvancement.AddByEntryID(self.entry.ID, numRanks)
        end
    elseif C_CharacterAdvancement.CanLearnID(self.entry.ID) then
        CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID)
    end
end

function CASpellButtonBaseMixin:OnMouseDown()
    self.Icon:GetPushedTexture():Show()
end

function CASpellButtonBaseMixin:OnMouseUp()
    self.Icon:GetPushedTexture():Hide()
end

function CASpellButtonBaseMixin:SetDisabledVisual()
    if self.Icon.DisabledOverlay then
        self.Icon.DisabledOverlay:Show()
        self.Icon.DisabledOverlay:SetAlpha(0.35)
    end

    self.Icon.Icon:SetAlpha(0.35)
    self.Icon.IconBorder:SetAlpha(0.35)
    self.Icon.Overlay:SetAlpha(0.35)

    if CharacterAdvancementUtil.AreTalentGatesEnabled() then
        local hasClassPoints = false

        if not self.Icon.ClassPoints then
            return
        end

        if self.entry.RequiredClassPoints and (self.entry.RequiredClassPoints > 0) then
            local diff = self.entry.RequiredClassPoints - C_CharacterAdvancement.GetClassPointInvestment(self.entry.Class, 0)

            if (diff > 0) then
                self.Icon.ClassPoints:Show()
                self.Icon.ClassPoints:SetIcon("Interface\\Icons\\classicon_" .. self.entry.Class:lower())
                self.Icon.ClassPoints.Count:SetText(diff)
                self.Icon.ClassPoints:ClearAndSetPoint("BOTTOMRIGHT", 0, -2)
                hasClassPoints = true
            end
        end

        if not(hasClassPoints) and self.entry.RequiredAEInvestment and (self.entry.RequiredAEInvestment > 0) then
            local diff = self.entry.RequiredAEInvestment - C_CharacterAdvancement.GetGlobalAEInvestment()

            if (diff > 0) then
                self.Icon.ClassPoints:Show()
                self.Icon.ClassPoints:SetIcon("Interface\\Icons\\inv_custom_abilityessence")
                self.Icon.ClassPoints.Count:SetText(diff)
                self.Icon.ClassPoints:ClearAndSetPoint("BOTTOMRIGHT", 0, -2)
            end
        end
    end
end

function CASpellButtonBaseMixin:SetEnabledVisual()
    if self.Icon.DisabledOverlay then
        self.Icon.DisabledOverlay:Hide()
        self.Icon.DisabledOverlay:SetAlpha(1)
    end

    self.Icon.Icon:SetAlpha(1)
    self.Icon.IconBorder:SetAlpha(1)
    self.Icon.Overlay:SetAlpha(1)
end

function CASpellButtonBaseMixin:CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT(result, internalID)
    if internalID == self.entry.ID then
        self:Refresh()
    end
end

function CASpellButtonBaseMixin:CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT(result, internalID)
    if internalID == self.entry.ID then
        self:Refresh()
    end
end

function CASpellButtonBaseMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    if self:IsVisible() then
        self:Refresh()
    end
end

CASpellButtonMixin = CreateFromMixins(CASpellButtonBaseMixin)

function CASpellButtonMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)
    --self.RarityGemContainer:SetGemSize(12)
    --self.RarityGemContainer:SetOrientation({ "BOTTOMLEFT", "BOTTOMRIGHT", -1, 0 })
    self.Shadow:SetAtlas("spellbook-text-background", Const.TextureKit.IgnoreAtlasSize)

    self.Icon.KnownGlow:SetAtlas("ca_known_glow", Const.TextureKit.IgnoreAtlasSize)
    self.Icon.KnownGlow:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())

    self.Icon:SetBackgroundSize(58, 58)
    self.Icon:SetBackgroundTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
    self.Icon:SetBackgroundOffset(9.5, -9.5)
end

function CASpellButtonMixin:SetEntry(entry)
    CASpellButtonBaseMixin.SetEntry(self, entry)

    if not(BuildCreatorUtil.IsPickingSpells()) then
        if entry.RequiredLevel > C_Player:GetLevel() then
            self:SetDisabledVisual()
        end
    end
end

function CASpellButtonMixin:OnClick(button)
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    CASpellButtonBaseMixin.OnClick(self, button)
end

function CASpellButtonMixin:SetDisabledVisual()
    CASpellButtonBaseMixin.SetDisabledVisual(self)
end

CATalentButtonMixin = CreateFromMixins(CASpellButtonBaseMixin)

function CATalentButtonMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)

    self.Icon:SetBackgroundSize(59, 59)
    self.Icon:SetBackgroundTexture("Interface\\Buttons\\UI-EmptySlot")
    self.Icon:SetBackgroundOffset(0, -1)
end

function CATalentButtonMixin:SetRankAndBg(entry, rank, maxRank)
    rank = rank or (C_CharacterAdvancement.IsKnownID(entry.ID) and 1 or 0) 
    maxRank = maxRank or 1

    if maxRank <= 1 and IsHeroClass("player") then
        self.Icon.RankFrame:Hide()
    else
        self.Icon.RankFrame:Show()

        self.Icon.RankFrame:SetRank(rank)
        self.Icon.RankFrame:SetMaxRank(maxRank)
        self.Icon.RankFrame:UpdateVisual()
    end

    if rank == 0 then
        self.Icon.Background:SetDesaturated(true)
    else
        self.Icon.Background:SetDesaturated(false)
        local r, g, b = self.Icon.RankFrame.RankBorder:GetVertexColor()
        self.Icon.Background:SetVertexColor(r, g, b)
    end

end

function CATalentButtonMixin:SetDisabledVisual()
    CASpellButtonBaseMixin.SetDisabledVisual(self)
    self.Icon.RankFrame:Hide()
end

function CATalentButtonMixin:SetEnabledVisual()
    CASpellButtonBaseMixin.SetEnabledVisual(self)
    self.Icon.RankFrame:Show()
end

function CATalentButtonMixin:SetEntry(entry)
    CASpellButtonBaseMixin.SetEntry(self, entry)

    if BuildCreatorUtil.IsPickingSpells() then
        local rank = 0
        for index, spellID in ipairs(entry.Spells) do
            if C_BuildEditor.DoesBuildHaveSpellID(spellID) then
                rank = index
            else
                break
            end
        end

        local maxRank = #entry.Spells

        self:SetRankAndBg(entry, rank, maxRank)
    else
        local meetsGateCondition = not CharacterAdvancementUtil.AreTalentGatesEnabled()
            or C_CharacterAdvancement.IsKnownID(entry.ID)
            or not self.gate
            or (self.gate:IsMetCondition("TAB") and self.gate:IsMetCondition("GLOBAL"))
        local canAdd = C_CharacterAdvancement.KnowsConnectedNodesFor(entry.ID)
        local rank, maxRank


        if C_CharacterAdvancement.IsPending() then
            rank, maxRank = C_CharacterAdvancement.GetPendingRankByEntryID(entry.ID)
        elseif CharacterAdvancementUtil.IsSwapping() then
            rank, maxRank = C_CharacterAdvancement.GetPendingRankByEntryID(entry.ID)
            if self.swapSuggestionData then
                rank = self.swapSuggestionData.NewCARank
            end
        else
            rank, maxRank = C_CharacterAdvancement.GetTalentRankByID(entry.ID)
        end

        self:SetRankAndBg(entry, rank, maxRank)

        if entry.RequiredLevel > C_Player:GetLevel() or not(meetsGateCondition) or not canAdd then
            self:SetDisabledVisual()
        end
    end
end

function CATalentButtonMixin:OnClick(button)
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    if not BuildCreatorUtil.IsPickingSpells() then
        if IsControlKeyDown() then
            if C_CVar.GetBool("previewCharacterAdvancementChanges") then
                local currentRank, maxRank = C_CharacterAdvancement.GetTalentRankByID(self.entry.ID)
                if currentRank and currentRank ~= maxRank then
                    local numRanks = maxRank - currentRank
                    if C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks) then
                        C_CharacterAdvancement.AddByEntryID(self.entry.ID, numRanks)
                        return
                    end
                end

                return
            else
                local currentRank, maxRank = C_CharacterAdvancement.GetTalentRankByID(self.entry.ID)
                if currentRank and currentRank ~= maxRank then
                    local learns = {}
                    for i = currentRank + 1, maxRank do
                        tinsert(learns, self.entry.ID)
                    end
                    CharacterAdvancementUtil.ConfirmOrLearnID(learns)
                    return
                end
            end
        end
    end
    CASpellButtonBaseMixin.OnClick(self, button)
end

CAPrimaryStatButtonMixin = CreateFromMixins(CASpellButtonBaseMixin)
CAPrimaryStatButtonMixin.OnDoubleClick = nop

function CAPrimaryStatButtonMixin:SetEntry(entry)
    self.Icon.KnownGlow.Pulse:Stop()

    CASpellButtonBaseMixin.SetEntry(self, entry)
end

function CAPrimaryStatButtonMixin:SetNoStat()
    self.Icon.KnownGlow:Show()
    self.Icon.KnownGlow.Pulse:Play()
    self.Icon:SetIconAtlas("emptyslot-disabled")
    self.entry = nil
end

function CAPrimaryStatButtonMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)
    self.Icon.KnownGlow:SetAtlas("ca_known_glow", Const.TextureKit.IgnoreAtlasSize)
    self.Icon.KnownGlow:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
end

function CAPrimaryStatButtonMixin:OnClick()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)

    if ForcedPrimaryStatFrame and ForcedPrimaryStatFrame:IsVisible() and self.isControlButton then
        ForcedPrimaryStatFrame:OnPrimaryStatSelected(true)
        return
    end

    if self.isControlButton then
        ShowForcedPrimaryStat(true, true)
        return
    end

    local numRanks = 1
    if C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks) then
        if C_CharacterAdvancement.IsPending() then
            CharacterAdvancementUtil.MarkForSwap(nil)
            C_CharacterAdvancement.AddByEntryID(self.entry.ID, numRanks)
            return
        end

        CharacterAdvancementUtil.MarkForSwap(nil)
        C_CharacterAdvancement.AddByEntryID(self.entry.ID, numRanks)
        C_CharacterAdvancement.ApplyPendingBuild()
    end

    --[[if C_CharacterAdvancement.IsPending() then
        if C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks) then
            CharacterAdvancementUtil.MarkForSwap(nil)
            C_CharacterAdvancement.AddByEntryID(self.entry.ID, numRanks)
        end
    elseif C_CharacterAdvancement.CanLearnID(self.entry.ID) then
        CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID)
    end]]--
end

function CAPrimaryStatButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")

    self.Icon:LockHighlight()

    if not self.entry then
        GameTooltip:AddLine(NO_PRIMARY_STAT, 1, 1, 1, true)
        GameTooltip:AddLine(CHOOSE_A_PRIMARY_STAT)
        GameTooltip:Show()
        return
    end

    if self:IsBrokenSpell() then
        self:AddBrokenSpellTooltipLines()
        GameTooltip:Show()
        return
    end

    GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self.spellID))
    if self.cannotLearn then
        GameTooltip:AddLine(CA_CANNOT_LEARN_S:format(self.cannotLearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    elseif self.cannotUnlearn then
        GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(self.cannotUnlearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    end

    GameTooltip:Show()
end

CACompactSpellButtonMixin = CreateFromMixins("CASpellButtonBaseMixin")

function CACompactSpellButtonMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)
    self.Icon:SetBackgroundSize(58, 58)
    self.Icon:SetBackgroundTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
    self.Icon:SetBackgroundOffset(9.5, -9.5)
end 

CAMasteryButtonMixin = CreateFromMixins("CASpellButtonBaseMixin")

function CAMasteryButtonMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self.Icon.KnownGlow:SetAtlas("ca_known_glow", Const.TextureKit.IgnoreAtlasSize)
    self.Icon.KnownGlow:SetVertexColor(NORMAL_FONT_COLOR:GetRGB()) 
end

function CAMasteryButtonMixin:OnClick(button)
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    CASpellButtonBaseMixin.OnClick(self, button)
end
