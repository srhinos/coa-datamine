--
-- Talent Base
--
CATalentBaseMixin = CreateFromMixins("CATalentArtMixin")

function CATalentBaseMixin:OnLoad()
    CATalentArtMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self.selectSound = SOUNDKIT.UI_CLASS_TALENT_NODE_SPEND
    self.deselectSound = SOUNDKIT.UI_CLASS_TALENT_NODE_REFUND
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self.showSingleRanks = true
     self.showZeroMultiRanks = false
    self.Icon:EnableMouse(false)
    self.connectionBranches = {}
end

function CATalentBaseMixin:SetShowSingleRanks(showSingleRanks)
    self.showSingleRanks = showSingleRanks
    self:UpdateRank()
end

function CATalentBaseMixin:SetShowZeroMultiRanks(showZeroMultiRanks)
    self.showZeroMultiRanks = showZeroMultiRanks
    self:UpdateRank()
end

function CATalentBaseMixin:SetEntry(entry)
    self.entry = entry
end

function CATalentBaseMixin:UpdateRank()
    if not self.entry then
        self.RankFrame:Hide()
        return
    end

    if not (self.showSingleRanks or self.maxRank > 1) then
        self.RankFrame:Hide()
        return
    end

    if not self.canLearn and self.rank == 0 and not (self.showZeroMultiRanks and self.maxRank > 1) then
        self.RankFrame:Hide()
        return
    end

    self.RankFrame:Show()
    if self.artSet.spendFont then
        self.RankFrame.Rank:SetFontObject(self.artSet.spendFont)
    end
    self.RankFrame:SetRank(self.rank)
    self.RankFrame:SetMaxRank(self.maxRank)
    self.RankFrame:UpdateVisual()
end

function CATalentBaseMixin:UpdateIcon()
    if self.Icon:GetSpellID() ~= self.spellID or self.Icon.iconMask ~= self.artSet.iconMask then
        self.Icon:SetIconMask(self.artSet.iconMask, TextureUtil.MaskSize.Small)
        self.Icon:SetSpell(self.spellID)
    end
    self.Icon:SetBackgroundAtlas(self.artSet.shadow)
end

function CATalentBaseMixin:UpdateDisplay()
    if not self.entry then
        return
    end
    local numRanks = 1
    self.canLearn, self.cantLearnReason = C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks)
    self.rank, self.maxRank = C_CharacterAdvancement.GetPendingRankByEntryID(self.entry.ID)
    self.isGated = not C_CharacterAdvancement.MeetsInvestmentForAddByEntryID(self.entry.ID, numRanks)

    self.spellID = self.entry.Spells[math.max(self.rank, 1)]
    
    self:UpdateIcon()
    self:UpdateRank()
    self.visualState = self:CalculateVisualState()
    self:UpdateConnectionVisual(self.visualState)
    self:ApplyVisualState(self.visualState)
    if GameTooltip:IsOwned(self) then
        self:OnEnter()
    end
end

function CATalentBaseMixin:ApplyVisualState(state)
    if state == TalentButtonUtil.BaseVisualState.Invisible then
        self:Hide()
    else
        self:Show()
    end

    local color = TalentButtonUtil.GetColorForBaseVisualState(state)
    local r, g, b, a = color:GetRGBA()

    if self.RankFrame then
        self.RankFrame.Rank:SetTextColor(r, g, b, a)
    end

    local isGated = state == TalentButtonUtil.BaseVisualState.Gated
    local isDisabled = isGated or
            (state == TalentButtonUtil.BaseVisualState.Locked) or
            (state == TalentButtonUtil.BaseVisualState.Disabled)
    self.Icon:SetIconDesaturated(isDisabled)
    if state == TalentButtonUtil.BaseVisualState.Invalid then
        self.Icon:SetIconColor(RED_FONT_COLOR:GetRGBA())
    else
        self.Icon:SetIconColor(1, 1, 1, 1)
    end
    self.Icon:SetBorderAlpha(isDisabled and 1 or isGated and 0.7 or 0.25)
    self:UpdateStateBorder(state)
end

function CATalentBaseMixin:SetBorderAtlas(atlas, state)
    self.Icon:SetOverlayAtlas(atlas)
    self.Icon:SetHighlightAtlas(atlas)
    self.Icon:SetHighlightAlpha(TalentButtonUtil.GetHoverAlphaForVisualStyle(state))
end

function CATalentBaseMixin:UpdateStateBorder(state)
    local isDisabled = (state == TalentButtonUtil.BaseVisualState.Gated)
            or (state == TalentButtonUtil.BaseVisualState.Locked)
            or (state == TalentButtonUtil.BaseVisualState.Disabled)

    if state == TalentButtonUtil.BaseVisualState.Invalid then
        self:SetBorderAtlas(self.artSet.refundInvalid, state)
    elseif state == TalentButtonUtil.BaseVisualState.Gated then
        self:SetBorderAtlas(self.artSet.locked, state)
    elseif state == TalentButtonUtil.BaseVisualState.Selectable then
        self:SetBorderAtlas(self.artSet.selectable, state)
    elseif state == TalentButtonUtil.BaseVisualState.Maxed then
        self:SetBorderAtlas(self.artSet.maxed, state)
    elseif not isDisabled then
        self:SetBorderAtlas(self.artSet.normal, state)
    else
        self:SetBorderAtlas(self.artSet.disabled, state)
    end
end

function CATalentBaseMixin:CalculateVisualState()
    if not self:ShouldBeVisible() then
        return TalentButtonUtil.BaseVisualState.Invalid
    end

    if self:IsInvalid() then
        return TalentButtonUtil.BaseVisualState.Invalid
    end

    if self:IsMaxed() then
        return TalentButtonUtil.BaseVisualState.Maxed
    end

    if self:IsSelectable() then
        return TalentButtonUtil.BaseVisualState.Selectable
    end

    if self:HasProgress() then
        return TalentButtonUtil.BaseVisualState.Normal
    end

    if self:IsGated() then
        return TalentButtonUtil.BaseVisualState.Gated
    end

    if self:IsLocked() then
        return TalentButtonUtil.BaseVisualState.Locked
    end
end

function CATalentBaseMixin:ShouldBeVisible()
    return self.entry ~= nil
end

function CATalentBaseMixin:IsMaxed()
    return self.entry and self.rank and self.rank == self.maxRank
end

function CATalentBaseMixin:IsSelectable()
    return self.canLearn
end

function CATalentBaseMixin:HasProgress()
    return self.entry and self.rank and self.rank > 0 and self.rank < self.maxRank
end

function CATalentBaseMixin:IsGated()
    return self.isGated
end

function CATalentBaseMixin:IsLocked()
    return not self.canLearn
end

function CATalentBaseMixin:IsInvalid()
    return self.entry and self.rank and self.rank > 0 and self.isGated
end

function CATalentBaseMixin:AddConnection(targetNode, pool)
    if not targetNode then
        return
    end

    if self.connectionBranches[targetNode] then
        return
    end

    local connection = pool:Acquire()
    connection:SetStartNode(self)
    connection:SetEndNode(targetNode)
    self.connectionBranches[targetNode] = connection
    self:UpdateConnectionVisual(self.visualState)
end

function CATalentBaseMixin:CanConnect(otherEntryID)
    return C_CharacterAdvancement.IsConnectionAllowed(otherEntryID, self.entry.ID)
end

function CATalentBaseMixin:UpdateConnectionVisual(visualState)
    local connectionState
    local isGated = visualState == TalentButtonUtil.BaseVisualState.Gated
    local isInvalid = visualState == TalentButtonUtil.BaseVisualState.Invalid
    for targetNode, connection in pairs(self.connectionBranches) do
        if isGated then
            connectionState = TalentButtonUtil.ConnectionState.Gated
        elseif targetNode.entry and self:CanConnect(targetNode.entry.ID) then
            if isInvalid then
                connectionState = TalentButtonUtil.ConnectionState.Invalid
            else
                connectionState = TalentButtonUtil.ConnectionState.Connected
            end
        else
            connectionState = TalentButtonUtil.ConnectionState.NoConnection
        end
        connection:UpdateConnectionState(connectionState)
    end
end

function CATalentBaseMixin:IsSubNode()
    return self.subNode
end

function CATalentBaseMixin:SetIsSubNode(isSubNode)
    self.subNode = isSubNode
end

function CATalentBaseMixin:UpdateSearchMarker()
    self.Icon.LocationIcon:SetShown(C_CharacterAdvancement.IsFiltered(self.entry.ID))
end

function CATalentBaseMixin:GetTooltipSpellID()
    if not self.entry or not self.entry.Spells then
        return nil
    end

    local rankIndex
    if self.canLearn and self.rank and self.maxRank and self.rank < self.maxRank then
        rankIndex = self.rank + 1
    else
        rankIndex = math.max(self.rank or 0, 1)
    end

    return self.entry.Spells[rankIndex] or self.entry.Spells[1]
end

function CATalentBaseMixin:OnClick(button)
    CloseDropDownMenus()
    if not self.entry then
        return
    end

    if IsModifiedClick("CHATLINK") then
        local spellLink = LinkUtil:GetSpellLink(self.spellID)
        if ChatEdit_InsertLink(spellLink) then
            return
        end
    end

    if button == "RightButton" then
        if BuildCreatorUtil.IsPickingSpells() then
            C_BuildEditor.RemoveSpell(self.spellID)
            BuildCreatorUtil.RefreshFinishPickingPopup()
            BuildCreatorUtil.EditorSpellsChanged()
            if self.deselectSound then
                PlaySound(self.deselectSound)
            end
        end
        if C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID) then
            C_CharacterAdvancement.RemoveByEntryID(self.entry.ID)
            if self.deselectSound then
                PlaySound(self.deselectSound)
            end
        end
        return
    end

    if BuildCreatorUtil.IsPickingSpells() then
        -- TODO:not implemented
        if self.selectSound then
            PlaySound(self.selectSound)
        end
    else
        local numRanks = 1
        if C_CharacterAdvancement.CanAddByEntryID(self.entry.ID, numRanks) then
            CharacterAdvancementUtil.MarkForSwap(nil)
            C_CharacterAdvancement.AddByEntryID(self.entry.ID, numRanks)
            if self.selectSound then
                PlaySound(self.selectSound)
            end
        end
    end
end

function CATalentBaseMixin:OnEnter()
    local tooltipSpellID = self:GetTooltipSpellID()
    if tooltipSpellID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(tooltipSpellID)
        GameTooltip:AddLine(TOOLTIP_TALENT_RANK:format(self.rank, self.maxRank), HIGHLIGHT_FONT_COLOR:GetRGB())
        local addedSpace = false
        if self.canLearn then
            if not addedSpace then
                GameTooltip_AddSpacer(GameTooltip)
                addedSpace = true
            end
            GameTooltip:AddLine(TOOLTIP_TALENT_LEARN, GREEN_FONT_COLOR:GetRGB())
        end
        if C_CharacterAdvancement.CanRemoveByEntryID(self.entry.ID) then
            if not addedSpace then
                GameTooltip_AddSpacer(GameTooltip)
                addedSpace = true
            end
            GameTooltip:AddLine(TOOLTIP_TALENT_UNLEARN, DISABLED_FONT_COLOR:GetRGB())
        end
        if self:IsGated() then
            if not addedSpace then
                GameTooltip_AddSpacer(GameTooltip)
                addedSpace = true
            end
            local r, g, b = RED_FONT_COLOR:GetRGB()
            GameTooltip:AddLine(TALENT_SPEND_MORE_POINTS, r, g, b, true)
        end
        GameTooltip:Show()
    else
        GameTooltip_GenericTooltip(self)
    end
end


function CATalentBaseMixin:OnLeave()
    GameTooltip:Hide()
end

function CATalentBaseMixin:OnDragStart()
    if self.entry then
        if not IsPassiveSpellID(self.spellID) and C_CharacterAdvancement.IsKnownID(self.entry.ID) then
            C_CharacterAdvancement.PickupSpell(self.entry.ID)
        end
    end
end

function CATalentBaseMixin:Reset()
    wipe(self.connectionBranches)
    self:SetIsSubNode(false)
end

function CATalentBaseMixin:IsChoiceNode()
    return false
end
