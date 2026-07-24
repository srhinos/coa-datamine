RandomModeSpecItemMixin = CreateFromMixins("OldSpecializationButtonMixin")

function RandomModeSpecItemMixin:Update()
    local name, icon = SpecializationUtil.GetSpecializationInfo(self.index)
    self:SetText(name)
    self.SpecIcon.Icon:SetTexture(icon)

    if SpecializationUtil.IsSpecializationUnlocked(self.index) then
        self:Enable()
    else
        self:Disable()
    end
    
    self:SetActive(self:IsSelected())

    if self:IsShown() and self:IsMouseOver() then
        self:OnLeave()
        self:OnEnter()
    end
end

function RandomModeSpecItemMixin:OnEnter()
    GameTooltip_GenericTooltip(self, "ANCHOR_LEFT")
end

function RandomModeSpecItemMixin:OnLeave()
    GameTooltip:Hide()
end

function RandomModeSpecItemMixin:HasFreeRewards()
    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        return C_WildcardRewards.GetNumClaimableScrollOfFortuneRewards(self.index, true) > 0
    elseif C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
        return C_DraftRewards.GetNumClaimableHandOfFateRewards(self.index, true) > 0
    end
end

function RandomModeSpecItemMixin:HasClaimableRewards()
    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        return C_WildcardRewards.GetNumClaimableScrollOfFortuneRewards(self.index, false) > 0
    elseif C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
        return C_DraftRewards.GetNumClaimableHandOfFateRewards(self.index, false) > 0
    end
end

function RandomModeSpecItemMixin:SetActive(active)
    local isEnabled = self:IsEnabled() == 1
    if active then
        OldSpecializationButtonMixin.SetActive(self)
        self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        self.SpecIcon.Icon:SetDesaturated(false)
        self.tooltipTitle = nil
        self.tooltipText = nil
    else
        if isEnabled then
            OldSpecializationButtonMixin.SetEnabled(self)
            self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
            self.SpecIcon.Icon:SetDesaturated(false)
            self.tooltipTitle = nil
            self.tooltipText = nil
        else
            self.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
            self.Text_Add:SetText(RED_FONT_COLOR:WrapText(LOCKED))
            self.SpecIcon.KnownBorder:Hide()
            self.SpecIcon.Icon:SetDesaturated(true)
            self.tooltipTitle = SPECIALIZATION_LABEL .. " " .. self.index
            self.tooltipText = SPEC_UNKNOWN_HINT
        end
    end

    if isEnabled then
        if  self:HasFreeRewards() then
            self.Text_Add:SetText(FREE_REWARDS_AVAILABLE)
            self.Text_Add:SetTextColor(GREEN_FONT_COLOR:GetRGB())
        elseif self:HasClaimableRewards() then
            self.Text_Add:SetText(REWARDS_AVAILABLE)
            self.Text_Add:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        elseif SpecializationUtil.GetActiveSpecialization() == self.index then
            self.Text_Add:SetText(CURRENT_SPECIALIZATION)
            self.Text_Add:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        else
            self.Text_Add:SetText("")
        end
    end
end