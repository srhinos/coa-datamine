--
-- Level Scroll Item
--
SpecListPresetItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function SpecListPresetItemMixin:Update()
    local name, icon = self:GetScrollList().GetSetInfo(self.index)
    self:SetText(name)
    self.Icon:SetTexture(icon)
end

function SpecListPresetItemMixin:OnSelected()
    self:GetScrollList().SetPreset(self.index)
end

--
-- Old style spec list item
--
OldSpecializationButtonMixin = CreateFromMixins(ScrollListItemBaseMixin)

function OldSpecializationButtonMixin:OnLoad()
    self:Layout()
end

function OldSpecializationButtonMixin:SetActive()
    self.Text:SetFontObject(GameFontHighlight)
    self.Text_Add:SetText(ACTIVE)
    self.SpecIcon.KnownBorder:Show()
    self.Selected:Show()
    self.isActive = true
end

function OldSpecializationButtonMixin:SetEnabled()
    self:Enable()
    self.Text:SetFontObject(GameFontNormal)
    self.Text_Add:SetText("|cff00FF00"..AVAILABLE.."|r")
    self.SpecIcon.KnownBorder:Hide()
    self.Selected:Hide()
    self.isActive = false
end

function OldSpecializationButtonMixin:OnMouseDown()
    if self:IsEnabled() ~= 1 then return end
    local point, relativeTo, relativePoint, x, y = self.Text:GetPoint()
    self.Text:SetPoint(point, relativeTo, relativePoint, x+1, y-2)
end

function OldSpecializationButtonMixin:OnMouseUp()
    if self:IsEnabled() ~= 1 then return end
    local point, relativeTo, relativePoint, x, y = self.Text:GetPoint()
    self.Text:SetPoint(point, relativeTo, relativePoint, x-1, y+2)
end

function OldSpecializationButtonMixin:SetText(...)
    self.Text:SetText(...)
end

function OldSpecializationButtonMixin:GetText()
   return self.Text:GetText()
end

function OldSpecializationButtonMixin:Layout()
    self.Border:SetAtlas("pvpqueue-button-casual-up", Const.TextureKit.IgnoreAtlasSize)
    self.H:SetAtlas("pvpqueue-button-casual-highlight", Const.TextureKit.IgnoreAtlasSize)
    self.Selected:SetAtlas("pvpqueue-button-casual-selected", Const.TextureKit.IgnoreAtlasSize)
    self:SetHighlightTexture(self.H)
    self.Text:SetPoint("LEFT", self.SpecIcon, "RIGHT", 10, 8)
end

--
-- spec list item mixin
--
SpecListItemMixin = CreateFromMixins(OldSpecializationButtonMixin)
SpecListItemMixin.OnEvent = OnEventToMethod

function SpecListItemMixin:OnLoad()
    self:Layout()

    self.SpecIcon:SetScript("OnEnter", GenerateClosure(self.OnEnter, self))

    self.ExpandedContent.EnchantPreset.tooltipText = CLICK_TO_LINK_ENCHANT_PRESET_HINT
    self.ExpandedContent.EquipmentSet.tooltipText = CLICK_TO_LINK_EQUIPMENT_SET_HINT

    self.SpecIcon.Settings:SetScript("OnClick", GenerateClosure(self.ToggleEditMode, self))
end

function SpecListItemMixin:Update()
    local name, icon, equipmentSet, enchantPreset, isPrestigeLocked = SpecializationUtil.GetSpecializationInfo(self.index)
    self:SetText(name or SPECIALIZATION_LABEL.." "..self.index)
    self.SpecIcon.Icon:SetTexture(icon)
    
    self:SetEquipmentSet(equipmentSet)
    self:SetEnchantPreset(enchantPreset)
    
    self.ExpandedContent:SetShown(self:IsExpanded())
    self:HideEditMode()

    if self:IsSelected() then
        self:LockHighlight()
        self.Border:SetAtlas("characterAdvancement-SpecTab-Extend-up", Const.TextureKit.IgnoreAtlasSize)
        self.H:SetAtlas("characterAdvancement-SpecTab-Extend-Highlight", Const.TextureKit.IgnoreAtlasSize)
        self.Selected:SetAtlas("characterAdvancement-SpecTab-Extend-Selected", Const.TextureKit.IgnoreAtlasSize)
    else
        self:UnlockHighlight()
        self.Border:SetAtlas("pvpqueue-button-casual-up", Const.TextureKit.IgnoreAtlasSize)
        self.H:SetAtlas("pvpqueue-button-casual-highlight", Const.TextureKit.IgnoreAtlasSize)
        self.Selected:SetAtlas("pvpqueue-button-casual-selected", Const.TextureKit.IgnoreAtlasSize)
    end

    if SpecializationUtil.IsSpecializationUnlocked(self.index) then
        self:Enable()
    else
        self:Disable()
    end

    self:SetActive(SpecializationUtil.GetActiveSpecialization() == self.index)
    self:SetPrestigeLock(isPrestigeLocked)

    if self:IsMouseOver() then
        self:OnLeave()
        self:OnEnter()
    end

    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        self.CurrencyBar:ClearCurrencies()
        self.Text_Add:Hide()

        local hasToken = false
        local SoFToken = TokenUtil.GetScrollOfFortuneForSpec(self.index)
        local SoFTalentToken = TokenUtil.GetScrollOfFortuneTalentsForSpec(self.index)

        if GetTokenCount(SoFToken) > 0 then
            self.CurrencyBar:AddToken(SoFToken)
            hasToken = true
        end

        if GetTokenCount(SoFTalentToken) > 0 then
            self.CurrencyBar:AddToken(SoFTalentToken)
            hasToken = true
        end

        if (hasToken) then
            self.Text:SetPoint("LEFT", self.SpecIcon, "RIGHT", 10, 10)
            self.CurrencyBar:Show()
            self.CurrencyBar:Update()

            local animatedToken = self:GetScrollList().animatedToken
            if animatedToken and ( (animatedToken.tokenType == SoFToken) or (animatedToken.tokenType == SoFTalentToken) ) then
                self.CurrencyBar:PlayCountAnimation(animatedToken.tokenType, animatedToken.count)
                self:GetScrollList().animatedToken = nil
            end
        else
            self.Text:SetPoint("LEFT", self.SpecIcon, "RIGHT", 10, 0)
            self.CurrencyBar:Hide()
        end
    else
        self.Text_Add:Show()
        self.CurrencyBar:Hide()
    end
end

function SpecListItemMixin:OnShow()
    self.prestigeLockEvent = EventRegistry:RegisterCallbackWithHandle("Specialization.PrestigeLockChanged", self.PrestigeLockChanged, self)
    self:RegisterEvent("MYSTIC_ENCHANT_SPECIALIZATION_LINK_UPDATED")
    self:RegisterEvent("EQUIPMENT_SET_SPECIALIZATION_LINK_UPDATED")
end

function SpecListItemMixin:OnHide()
    self:HideEditMode()
    self.prestigeLockEvent:Unregister()
    self.prestigeLockEvent = nil
    self:UnregisterEvent("MYSTIC_ENCHANT_SPECIALIZATION_LINK_UPDATED")
    self:UnregisterEvent("EQUIPMENT_SET_SPECIALIZATION_LINK_UPDATED")
end

function SpecListItemMixin:OnClick()
    local list = self:GetScrollList()
    local current = list:GetSelectedIndex()
    if current == self.index then
        list:SetSelectedIndex(nil, ScrollListMixin.UpdateType.Always)
        self:OnDeselected()
        return
    end

    list:SetSelectedIndex(self.index, ScrollListMixin.UpdateType.Always)
    self:OnSelected()
end

function SpecListItemMixin:OnEnter()
    GameTooltip_GenericTooltip(self, "ANCHOR_RIGHT")
end 

function SpecListItemMixin:OnLeave()
    GameTooltip:Hide()
end

function SpecListItemMixin:HideEditMode()
    local iconSelector = self:GetScrollList().IconSelector
    
    if iconSelector.callback then
        iconSelector.callback.Unregister()
        iconSelector.owner = nil
    end

    iconSelector:Hide()
end

function SpecListItemMixin:ToggleEditMode()
    local iconSelector = self:GetScrollList().IconSelector

    iconSelector:Hide()

    if (iconSelector.owner) then
        iconSelector.callback.Unregister()
        if (iconSelector.owner == self) then
            iconSelector.owner = nil
            return
        end
    end

    iconSelector.owner = self
    
    iconSelector.callback = iconSelector:RegisterCallbackWithHandle("OnTextAndIconChange", function(_, name, icon)
        local owner = iconSelector.owner
        if owner then
            owner:SaveIcon(icon)
            owner:CommitNameChange(name)
        end
    end)

    local name = self:GetText()
    local icon = self.SpecIcon.Icon:GetTexture()

    iconSelector:EditExisting(name, icon)
end

function SpecListItemMixin:CommitNameChange(name)
    self:SetText(name)
    SpecializationUtil.SetSpecializationName(self.index, name)
end

function SpecListItemMixin:SaveIcon(icon)
    self.SpecIcon.Icon:SetTexture(icon)
    SpecializationUtil.SetSpecializationIcon(self.index, icon)
end

function SpecListItemMixin:OnSelected()
    if not self:IsExpanded() then
        if C_Player:IsCustomClass() then
            self:ToggleExpanded(122)
        else
            self:ToggleExpanded(166)
        end
    end
end

function SpecListItemMixin:OnDeselected()
    self:Collapse()
end

function SpecListItemMixin:ActivateSpec()
    if C_CharacterAdvancement.IsPending() then
        StaticPopup_Show("CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES")
        return
    end

    SpecializationUtil.ActivateSpecialization(self.index)
end

function SpecListItemMixin:SetEquipmentSet(setName)
    local selectFrame = self:GetScrollList().SelectFrame
    if selectFrame.parent == self.ExpandedContent.EquipmentSet then
        selectFrame:Hide()
        selectFrame.parent = nil
    end

    if type(setName) == "number" then
        if setName > 0 and setName <= MAX_EQUIPMENT_SETS_PER_PLAYER then
            setName = GetEquipmentSetInfo(setName)
            SpecializationUtil.SetSpecializationEquipmentSet(self.index, setName)
        else
            setName = nil
        end
    end

    local setIcon = setName and GetEquipmentSetInfoByName(setName)
    if setName and setIcon then
        self.ExpandedContent.EquipmentSet.Icon:SetIcon("Interface\\Icons\\"..setIcon)
        self.ExpandedContent.EquipmentSet:SetText(setName)
        self.ExpandedContent.EquipmentSet.Text:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
        self.ExpandedContent.EquipmentSet.tooltipTitle = RIGHT_CLICK_TO_UNLINK_EQUIPMENT_SET
    else
        self.ExpandedContent.EquipmentSet.Icon:SetIcon("")
        self.ExpandedContent.EquipmentSet:SetText(NO_EQUIPMENT_SET_LINKED)
        self.ExpandedContent.EquipmentSet.Text:SetVertexColor(DISABLED_FONT_COLOR:GetRGB())
        self.ExpandedContent.EquipmentSet.tooltipTitle = CLICK_TO_LINK_EQUIPMENT_SET
    end
end

function SpecListItemMixin:SaveEquipmentSet(setIndex)
    local setName
    if setIndex then
        setName = GetEquipmentSetInfo(setIndex)
    end
    self:SetEquipmentSet(setName)
    SpecializationUtil.SetSpecializationEquipmentSet(self.index, setName)
end

function SpecListItemMixin:SetEnchantPreset(presetID)
    local selectFrame = self:GetScrollList().SelectFrame
    if selectFrame.parent == self.ExpandedContent.EnchantPreset then
        selectFrame:Hide()
        selectFrame.parent = nil
    end

    if presetID then
        local presetName = MysticEnchantManagerUtil.GetPresetName(presetID)
        local presetIcon = MysticEnchantManagerUtil.GetPresetIcon(presetID)
        if presetName then
            self.ExpandedContent.EnchantPreset.Icon:SetIcon(presetIcon)
            self.ExpandedContent.EnchantPreset:SetText(presetName)
            self.ExpandedContent.EnchantPreset.Text:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
            self.ExpandedContent.EnchantPreset.tooltipTitle = RIGHT_CLICK_TO_UNLINK_ENCHANT_PRESET
        else
            self.ExpandedContent.EnchantPreset.Icon:SetIcon("")
            self.ExpandedContent.EnchantPreset:SetText(NO_ENCHANT_PRESET_LINKED)
            self.ExpandedContent.EnchantPreset.Text:SetVertexColor(DISABLED_FONT_COLOR:GetRGB())
            self.ExpandedContent.EnchantPreset.tooltipTitle = CLICK_TO_LINK_ENCHANT_PRESET
        end
    else
        self.ExpandedContent.EnchantPreset.Icon:SetIcon("")
        self.ExpandedContent.EnchantPreset:SetText(NO_ENCHANT_PRESET_LINKED)
        self.ExpandedContent.EnchantPreset.Text:SetVertexColor(DISABLED_FONT_COLOR:GetRGB())
        self.ExpandedContent.EnchantPreset.tooltipTitle = CLICK_TO_LINK_ENCHANT_PRESET
    end
end

function SpecListItemMixin:SaveEnchantPreset(presetID)
    self:SetEnchantPreset(presetID)
    SpecializationUtil.SetSpecializationEnchantPreset(self.index, presetID)
end

function SpecListItemMixin:EditEquipmentSet()
    local selectFrame = self:GetScrollList().SelectFrame
    if selectFrame.parent == self.ExpandedContent.EquipmentSet then
        selectFrame:Hide()
        selectFrame.parent = nil
        return
    end
    selectFrame.parent = self.ExpandedContent.EquipmentSet
    selectFrame.ScrollList.GetSetInfo = GetEquipmentSetInfo
    selectFrame.ScrollList.SetPreset = GenerateClosure(self.SaveEquipmentSet, self)
    selectFrame.ScrollList:SetGetNumResultsFunction(GetNumEquipmentSets)
    selectFrame:Show()
    selectFrame:ClearAndSetPoint("TOP", self.ExpandedContent.EquipmentSet, "BOTTOM", 16, -2)
    selectFrame.ScrollList:SetTemplate("SpecListPresetItemTemplate")
    selectFrame.ScrollList:ScrollToBegin()
    selectFrame.ScrollList:RefreshScrollFrame()
end

function SpecListItemMixin:EditEnchantPreset()
    local selectFrame = self:GetScrollList().SelectFrame
    if selectFrame.parent == self.ExpandedContent.EnchantPreset then
        selectFrame:Hide()
        selectFrame.parent = nil
        return
    end
    selectFrame.parent = self.ExpandedContent.EnchantPreset
    selectFrame.ScrollList.GetSetInfo = MysticEnchantManagerUtil.GetPresetInfo
    selectFrame.ScrollList.SetPreset = GenerateClosure(self.SaveEnchantPreset, self)
    selectFrame.ScrollList:SetGetNumResultsFunction(C_MysticEnchantPreset.GetNumPresets)
    selectFrame:Show()
    selectFrame:ClearAndSetPoint("TOP", self.ExpandedContent.EnchantPreset, "BOTTOM", 16, -2)
    selectFrame.ScrollList:SetTemplate("SpecListPresetItemTemplate")
    selectFrame.ScrollList:ScrollToBegin()
    selectFrame.ScrollList:RefreshScrollFrame()
end

function SpecListItemMixin:SetActive(active)
    self.ExpandedContent.ActivateButton:SetEnabled(not active)

    self.SpecIcon.Settings:Show()
    self.LockButton:Show()

    if active then
        OldSpecializationButtonMixin.SetActive(self)
        self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        self.SpecIcon.Icon:SetDesaturated(false)
        self.tooltipTitle = nil
        self.tooltipText = nil
    else
        if self:IsEnabled() == 1 then
            OldSpecializationButtonMixin.SetEnabled(self)
            self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
            self.SpecIcon.Icon:SetDesaturated(false)
            self.tooltipTitle = nil
            self.tooltipText = nil
        else
            self.LockButton:Hide()
            self.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
            self.Text_Add:SetText(RED_FONT_COLOR:WrapText(LOCKED))
            self.SpecIcon.KnownBorder:Hide()
            self.SpecIcon.Icon:SetDesaturated(true)
            self.tooltipTitle = SPECIALIZATION_LABEL .. " " .. self.index
            self.tooltipText = SPEC_UNKNOWN_HINT

            self.SpecIcon.Settings:Hide()
        end
    end
end

function SpecListItemMixin:SetPrestigeLock(isLocked)
    self.isPrestigeLocked = isLocked

    if isLocked then
        self.LockButton:SetNormalAtlas("spell-list-locked")
        self.LockButton.tooltipTitle = string.format(SPEC_PRESTIGE_UNLOCK_TITLE, self:GetText())
        self.LockButton.tooltipText = SPEC_PRESTIGE_UNLOCK
        self.LockButton:SetAlpha(1)
    else
        self.LockButton:SetNormalAtlas("spell-list-unlocked")
        self.LockButton.tooltipTitle = LOCK.." "..(self:GetText() or SPECIALIZATION_LABEL.." "..self.index)
        self.LockButton.tooltipText = SPEC_PRESTIGE_LOCK
        self.LockButton:SetAlpha(0.7)
    end

    if self:IsEnabled() == 1 then
        self.LockButton:Enable()
    else
        self.LockButton:Disable()
    end
end

function SpecListItemMixin:GetPrestigeLock()
    return self.isPrestigeLocked
end

function SpecListItemMixin:ToggleLocked()
    local isPrestigeLocked = self:GetPrestigeLock()

    if isPrestigeLocked then
        StaticPopup_Show("UNLOCK_SPEC_CONFIRM", self:GetText(), nil, self.index)
        return
    end

    SpecializationUtil.ToggleSpecializationPrestigeLock(self.index)
end 

function SpecListItemMixin:PrestigeLockChanged(specID)
    if (specID == self.index) then
        self:Update()
    end
end

function SpecListItemMixin:EQUIPMENT_SET_SPECIALIZATION_LINK_UPDATED()
    self:Update()
end

function SpecListItemMixin:MYSTIC_ENCHANT_SPECIALIZATION_LINK_UPDATED()
    self:Update()
end

function SpecListItemMixin:Layout()
    OldSpecializationButtonMixin.Layout(self)

    self.Text:SetWidth(130)
    self.Text_Add:Hide()

    self.ExpandedContent.EquipmentSet.Icon:SetBackgroundAtlas("emptyslot-disabled")
    self.ExpandedContent.EquipmentSet.Icon:SetBackgroundSize(28, 28)
    self.ExpandedContent.EnchantPreset.Icon:SetBackgroundAtlas("emptyslot-disabled")
    self.ExpandedContent.EnchantPreset.Icon:SetBackgroundSize(28, 28)
    self.LockButton:SetHighlightAtlas("spell-list-locked")

    self.SpecIcon:ClearAndSetPoint("TOPLEFT", 12, -(self:GetHeight()-self.SpecIcon:GetHeight())/2)
    self.LockButton:ClearAndSetPoint("TOPRIGHT", -8, -(self:GetHeight()-self.LockButton:GetHeight())/2)

    self.CurrencyBar:SetJustify("LEFT")
    self.CurrencyBar.Left:Hide()
    self.CurrencyBar.Right:Hide()
    self.CurrencyBar.Center:Hide()

    if C_Player:IsCustomClass() then
        self.ExpandedContent:SetHeight(82)
        self.ExpandedContent.EnchantPreset:Hide()
    end
end