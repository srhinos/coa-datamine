CASpellButtonBaseMixin = {}
CASpellButtonBaseMixin.OnEvent = OnEventToMethod

local BROKEN_SPELL_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function CASpellButtonBaseMixin:OnLoad()
    self.Icon:EnableMouse(false)
    self.Icon:UseQuality(true)
    self.Icon:SetOverlayBlendMode("ADD")
    if self.Icon.LockIcon then
        self.Icon.LockIcon:SetAtlas("spell-list-locked")
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
    self.Icon.LocationIcon:Hide()
    self.entry = entry
    self.spellID = entry.Spells[1]
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
            local rank = C_CharacterAdvancement.GetTalentRankByID(entry.ID)
            if rank and rank > 0 then
                self.spellID = entry.Spells[rank]
            end
        end
    end

    local name = entry.Name
    local level = entry.RequiredLevel
    local isHighEnoughLevel = level <= C_Player:GetLevel()
    if isHighEnoughLevel then
        level = HIGHLIGHT_FONT_COLOR:WrapText(level)
    else
        level = RED_FONT_COLOR:WrapText(level)
    end
    self:SetFormattedText("%s\n%s %s", name, HIGHLIGHT_FONT_COLOR:WrapText(LEVEL), level)
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
                    self.cannotLearn = reason[1] and _G[reason[1]] or reason[1]
                end
            end
        end
    else
        if self.Icon.LockIcon then
            self.Icon.LockIcon:SetShown(C_CharacterAdvancement.IsLockedID(entry.ID))
        end

        if C_CharacterAdvancement.IsKnownID(entry.ID) then
            if self.Icon.KnownGlow then
                self.Icon.KnownGlow:Show()
            end

            self.Icon:SetIconDesaturated(false)
            self.Icon:SetIconColor(1, 1, 1)

            local canUnlearn, reason = C_CharacterAdvancement.CanUnlearnID(entry.ID)

            if not canUnlearn and not CharacterAdvancementUtil.IsReasonRandomMode(reason) then
                self.cannotUnlearn = _G[reason] or reason
            end

            if self.Icon.RankUp and (self.entry.Type == "Ability" or self.entry.Type == "TalentAbility") then
                local maxSpellID = C_Spell.GetMaxLearnableRank(self.spellID, C_Player:GetLevel())
                local canLearn = maxSpellID and not IsSpellKnown(maxSpellID) and not CA_IsSpellKnown(maxSpellID)
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
            local canLearn, reason = C_CharacterAdvancement.CanLearnID(entry.ID)
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
                    self.cannotLearn = _G[reason] or reason
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
    elseif self.cannotUnlearn then
        GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(self.cannotUnlearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    end
    GameTooltip:Show()
    
    self.Icon:LockHighlight()
    self.Icon.LocationIcon:Hide()
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

function CASpellButtonBaseMixin:OnClick()
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

    if not BuildCreatorUtil.IsPickingSpells() then
        if IsShiftKeyDown() then
            CloseDropDownMenus()
            if C_CharacterAdvancement.CanLearnID(self.entry.ID) then
                CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID)
            end
            return
        end

        if IsAltKeyDown() then
            if C_CharacterAdvancement.CanUnlearnID(self.entry.ID) then
                CharacterAdvancementUtil.ConfirmOrUnlearnID(self.entry.ID)
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

    CharacterAdvancement:ShowSpellDropDownMenu(self)
end

function CASpellButtonBaseMixin:OnDoubleClick()
    CloseDropDownMenus()
    if IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() then
        return
    end
    if BuildCreatorUtil.IsPickingSpells() then
        local nextSpellID
        if C_CharacterAdvancement.IsTalentSpellID(self.spellID) then
            nextSpellID = BuildCreatorUtil.GetNextTalentSpellID(self.spellID)
        else
            nextSpellID = self.spellID
        end

        local spellInfo = C_BuildEditor.GetSpellByID(self.spellID) or BuildCreatorUtil.CreateSpellInfo(nextSpellID, BuildCreatorUtil.GetPickLevel())
        spellInfo.Spell = nextSpellID
        spellInfo.Level = BuildCreatorUtil.GetPickLevel()
        C_BuildEditor.AddSpell(spellInfo)
        BuildCreatorUtil.RefreshFinishPickingPopup()
        BuildCreatorUtil.EditorSpellsChanged()
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
    self.Shadow:SetAtlas("spellbook-text-background")

    self.Icon.KnownGlow:SetAtlas("ca_known_glow")
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

function CASpellButtonMixin:OnClick()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    CASpellButtonBaseMixin.OnClick(self)
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
            or not self.gate
            or (self.gate.isMetTree and self.gate.isMetGlobal)

        local rank, maxRank = C_CharacterAdvancement.GetTalentRankByID(entry.ID)

        self:SetRankAndBg(entry, rank, maxRank)

        if entry.RequiredLevel > C_Player:GetLevel() or not(meetsGateCondition) then
            self:SetDisabledVisual()
            self.Icon.RankFrame:Hide()
        end
    end
end

function CATalentButtonMixin:OnClick()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    if not BuildCreatorUtil.IsPickingSpells() then
        if IsControlKeyDown() then
            local currentRank, maxRank = C_CharacterAdvancement.GetTalentRankByID(self.entry.ID)
            if currentRank and currentRank ~= maxRank then
                for i = math.max(currentRank, 1), maxRank do
                    if not C_CharacterAdvancement.CanLearnID(self.entry.ID) then
                        break
                    end
                    if CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID) then
                        break
                    end
                end
                return
            end
        end
    end
    CASpellButtonBaseMixin.OnClick(self)
end

CAPrimaryStatButtonMixin = CreateFromMixins(CASpellButtonBaseMixin)
CAPrimaryStatButtonMixin.OnDoubleClick = nop

function CAPrimaryStatButtonMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)
    self.Icon.KnownGlow:SetAtlas("ca_known_glow")
    self.Icon.KnownGlow:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
end

function CAPrimaryStatButtonMixin:OnClick()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    if C_CharacterAdvancement.CanLearnID(self.entry.ID) then
        CharacterAdvancementUtil.ConfirmOrLearnID(self.entry.ID)
    end
end

function CAPrimaryStatButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    if self:IsBrokenSpell() then
        self:AddBrokenSpellTooltipLines()
        GameTooltip:Show()

        self.Icon:LockHighlight()
        return
    end

    GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self.spellID))
    if self.cannotLearn then
        GameTooltip:AddLine(CA_CANNOT_LEARN_S:format(self.cannotLearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    elseif self.cannotUnlearn then
        GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(self.cannotUnlearn), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
    end
    GameTooltip:Show()

    self.Icon:LockHighlight()
end 
