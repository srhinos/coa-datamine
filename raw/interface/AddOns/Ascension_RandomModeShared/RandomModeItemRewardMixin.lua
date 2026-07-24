RandomModeItemRewardMixin = CreateFromMixins("ItemIconTemplateMixin")

function RandomModeItemRewardMixin:OnLoad()
    ItemIconTemplateMixin.OnLoad(self)
    self:SetRounded(true)
    self:SetBorderAtlas("services-cover-ring")
    self:SetBorderOffset(0, -2)
    self:SetBorderSize(47, 47)
    
    self:SetBackgroundAtlas("services-ring-large-glowspin")
    self:SetBackgroundSize(94, 94)
    
    self:SetOverlayTexture("Interface\\BUTTONS\\UI-CheckBox-Check")
    self:SetOverlaySize(32, 32)
    self:SetOverlayColor(0, 1, 0, 1)
    self.Overlay:Hide()
    
    self:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local highlight = self:GetHighlightTexture()

    if highlight then
        highlight:SetSize(47, 47)
        highlight:ClearAndSetPoint("CENTER")
        highlight:SetBlendMode("ADD")
    end
    
    self.Background.Animation = self.Background:CreateAnimationGroup()
    self.Background.Animation:SetLooping("REPEAT")
    local rotation = self.Background.Animation:CreateAnimation("Rotation")
    rotation:SetDuration(60)
    rotation:SetDegrees(-360)
    rotation:SetOrder(1)
    rotation:SetSmoothing("NONE")
end

function RandomModeItemRewardMixin:OnShow()
    self.Background.Animation:Play()
end 

function RandomModeItemRewardMixin:OnHide()
    -- this doesnt play while hidden
    -- but im pretty sure the client still checks if its shown every frame if left playing
    self.Background.Animation:Stop()
end 

function RandomModeItemRewardMixin:SetClaimed(claimed)
    if claimed then
        self.Background:Hide()
        self.Overlay:Show()
        self:SetIconColor(0.5, 0.5, 0.5, 1)
    else
        self.Background:Show()
        self.Overlay:Hide()
        self:SetIconColor(1, 1, 1, 1)
    end
end

RandomModeLargeItemRewardMixin = CreateFromMixins("RandomModeItemRewardMixin")

function RandomModeLargeItemRewardMixin:OnLoad()
    ItemIconTemplateMixin.OnLoad(self)
    self:SetRounded(true)
    self:SetBorderAtlas("services-cover-ring")
    self:SetBorderOffset(0, -2)
    self:SetBorderSize(56, 56)

    self:SetBackgroundAtlas("services-ring-large-glowspin")
    self:SetBackgroundSize(108, 108)

    self:SetOverlayTexture("Interface\\BUTTONS\\UI-CheckBox-Check")
    self:SetOverlaySize(48, 48)
    self:SetOverlayColor(0, 1, 0, 1)
    self.Overlay:Hide()

    self:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local highlight = self:GetHighlightTexture()
    if highlight then
        highlight:SetSize(48, 48)
        highlight:ClearAndSetPoint("CENTER")
        highlight:SetBlendMode("ADD")
    end

    self.Background.Animation = self.Background:CreateAnimationGroup()
    self.Background.Animation:SetLooping("REPEAT")
    local rotation = self.Background.Animation:CreateAnimation("Rotation")
    rotation:SetDuration(60)
    rotation:SetDegrees(-360)
    rotation:SetOrder(1)
    rotation:SetSmoothing("NONE")
end