SocialToastMixin = {}

function SocialToastMixin:OnLoad()
end

function SocialToastMixin:OnShow()
    self.AnimIn:Play()
    self.Glow.AnimIn:Play()
    self.AnimOut:Play()
end

function SocialToastMixin:OnEnter()
    if self.AnimOut:IsPlaying() then
        self.AnimOut.wasPlaying = true
        self.AnimOut:Stop()
    end
end

function SocialToastMixin:OnLeave()
    if self.AnimOut.wasPlaying then
        self.AnimOut:Play()
        self.AnimOut.wasPlaying = nil
    end
end

function SocialToastMixin:OnClick()
    if self.CloseButton then
        self.CloseButton:Click()
    end
end

SocialToastCloseButtonMixin = {}

function SocialToastCloseButtonMixin:OnEnter()
    self:GetParent():OnEnter();
end

function SocialToastCloseButtonMixin:OnLeave()
    self:GetParent():OnLeave();
end

function SocialToastCloseButtonMixin:OnClick()
    self:GetParent().AnimOut.wasPlaying = nil
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    self:GetParent():Hide();
end

UpdateAlertToastMixin = CreateFromMixins(SocialToastMixin)

function UpdateAlertToastMixin:OnShow()
    if CharacterDataUnknownToast:IsVisible() then
        return
    end
    self.AnimIn:Play()
    self.Glow.AnimIn:Play()
    PlaySound(SOUNDKIT.UI_PET_BATTLESTART_01)
end

UnknownCharacterDataToastMixin = CreateFromMixins(SocialToastMixin)

function UnknownCharacterDataToastMixin:OnShow()
    if UpdateAlertToast:IsVisible() then
        UpdateAlertToast:Hide()
    end
    self.AnimIn:Play()
    self.Glow.AnimIn:Play()
    PlaySound(SOUNDKIT.UI_PET_BATTLESTART_01)
end

function UnknownCharacterDataToastMixin:OnUpdate()
    if C_Player:GetName() ~= "Unknown" then
        self:Hide()
    end
end


AccountInfractionToastMixin = CreateFromMixins("SocialToastMixin")

function AccountInfractionToastMixin:OnLoad()
    SocialToastMixin.OnLoad(self)
    self.Icon:SetPortraitTexture("Interface\\Icons\\Mail_GMIcon")
    self.IconBorder:SetAtlas("pvpqueue-rewardring-large", Const.TextureKit.IgnoreAtlasSize)
    self.IconBorder:Show()
end

function AccountInfractionToastMixin:OnShow()
    self.AnimIn:Play()
    self.Glow.AnimIn:Play()
    PlaySound(SOUNDKIT.UI_PET_BATTLESTART_01)
end