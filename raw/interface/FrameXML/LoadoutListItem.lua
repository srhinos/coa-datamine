LoadoutListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function LoadoutListItemMixin:OnLoad()
    self:SetNormalAtlas("spell-list-button")
    self:GetNormalTexture():SetDrawLayer("BACKGROUND")
    self:SetHighlightAtlas("spell-list-button-highlight")
    self:GetHighlightTexture():SetAlpha(0.7)
    self.Icon:SetBorderSize(40, 40)
    self.Icon:SetBackgroundSize(40, 40)
    self.Icon:SetScript("OnEnter", GenerateClosure(self.OnEnter, self))
    self.Icon:SetBackgroundAtlas("emptyslot-disabled")
    self.ExpandedContent.Background:SetAtlas("spec-thumbnail-hero-hero", Const.TextureKit.IgnoreAtlasSize)
end

function LoadoutListItemMixin:Update()
    if self.index > TalentLoadoutUtil.GetNumLoadouts() then
        -- get more display
        self:SetActive(false)
        self:UnlockHighlight()
        self:GetHighlightTexture():SetAtlas("spell-list-button-highlight", Const.TextureKit.IgnoreAtlasSize)
        self:HideEditMode()
        self.Edit:Hide()
        self.tooltipTitle = TALENT_LOADOUT_S:format(self.index)
        self.tooltipText = TALENT_LOADOUT_HINT
        self:SetText(self.tooltipTitle)
        self.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
        self.Icon:SetIconAtlas("communities-icon-addgroupplus")
    else
        -- loadout display
        local loadout = TalentLoadoutUtil.GetLoadoutAtIndex(self.index)
        self.loadout = loadout
        self.tooltipTitle = nil
        self.tooltipText = nil

        self:Enable()
        self.Icon:SetIcon("Interface\\Icons\\inv_custom_reforgerandomscroll")
        self:SetText(loadout.Name)
        self.ExpandedContent:SetShown(self:IsExpanded())
        self:HideEditMode()

        if self:IsSelected() then
            self:LockHighlight()
            self:GetHighlightTexture():SetAtlas("spell-list-button-selected", Const.TextureKit.IgnoreAtlasSize)
        else
            self:UnlockHighlight()
            self:GetHighlightTexture():SetAtlas("spell-list-button-highlight", Const.TextureKit.IgnoreAtlasSize)
        end


        self:SetActive(TalentLoadoutUtil.GetActiveLoadoutUUID() == loadout.UUID)
        self.Edit:Show()
    end
end

function LoadoutListItemMixin:OnHide()
    self:HideEditMode()
end


function LoadoutListItemMixin:OnClick()
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

function LoadoutListItemMixin:OnEnable()
    self.Edit:Show()
end

function LoadoutListItemMixin:OnDisable()
    self.Edit:Hide()
end

function LoadoutListItemMixin:OnEnter()
    GameTooltip_GenericTooltip(self, "ANCHOR_RIGHT")
end

function LoadoutListItemMixin:OnLeave()
    GameTooltip:Hide()
end

function LoadoutListItemMixin:ShowEditMode()
    self.EditBox:Show()
end

function LoadoutListItemMixin:HideEditMode()
    self.EditBox:Hide()
end

function LoadoutListItemMixin:ToggleEditMode()
    if self.EditBox:IsShown() then
        self:HideEditMode()
    else
        self:ShowEditMode()
    end
end

function LoadoutListItemMixin:CommitNameChange()
    local name = self.EditBox:GetText()
    if not string.isNilOrEmpty(name) then
        TalentLoadoutUtil.RenameLoadoutAtIndex(self.index, name)
        self:SetText(name)
    end
    self:HideEditMode()
end

function LoadoutListItemMixin:OnSelected()
    if not self:IsExpanded() then
        self:ToggleExpanded(166)
    end
end

function LoadoutListItemMixin:OnDeselected()
    self:Collapse()
end

function LoadoutListItemMixin:ActivateLoadout()
    TalentLoadoutUtil.ActivateLoadoutAtIndex(self.index)
    self.ExpandedContent.ActivateButton:SetEnabled(false)
end

function LoadoutListItemMixin:SetActive(active)
    self.ExpandedContent.ActivateButton:SetEnabled(not active)
    if active then
        self:SetNormalAtlas("spell-list-button-active")
        self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        self.Icon:SetIconDesaturated(false)
        self.ExpandedContent.Border:SetAtlas("spec-thumbnailborder-on", Const.TextureKit.IgnoreAtlasSize)
        self.ExpandedContent.Background:SetVertexColor(0.4, 0.4, 0.4)
        self.Icon:SetBorderAtlas("quickslot-border-gold")
        self:SetAlpha(1)
    else
        self:SetNormalAtlas("spell-list-button")
        if self:IsEnabled() == 1 then
            self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
            self.Icon:SetIconDesaturated(false)
            self:SetAlpha(1)
        else
            self.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
            self.Icon:SetIconDesaturated(true)
            self:SetAlpha(0.5)
        end
        self.ExpandedContent.Border:SetAtlas("spec-thumbnailborder-off", Const.TextureKit.IgnoreAtlasSize)
        self.ExpandedContent.Background:SetVertexColor(0.2, 0.2, 0.2)
        self.Icon:SetBorderAtlas("quickslot-border-grey")
    end
end

