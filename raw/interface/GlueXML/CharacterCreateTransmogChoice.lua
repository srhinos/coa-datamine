CharacterCreateTransmogChoiceEnableMixin = CreateFromMixins("CharacterCreateChoiceMixin")

function CharacterCreateTransmogChoiceEnableMixin:OnLoad()
    CharacterCreateChoiceMixin.OnLoad(self)
    self.Icon:SetIconNormal("ExperienceIconTmogEnabled")
    self.Background:SetAtlas("ExperienceArtTmog", Const.TextureKit.IgnoreAtlasSize)
    self.Icon:UpdateText(ENABLE_TRANSMOG, ENABLE_TRANSMOG_TOOLTIP)
end

function CharacterCreateTransmogChoiceEnableMixin:OnClick(button)
    CharacterCreateChoiceMixin.OnClick(self, button)
    
    local characterName = CharSelectCharacterName:GetText()

    if characterName then
        NewCharacterSetupUtil.SetCharacterData(characterName, "enableTransmog", true)
    end
end

CharacterCreateTransmogChoiceDisableMixin = CreateFromMixins("CharacterCreateChoiceMixin")

function CharacterCreateTransmogChoiceDisableMixin:OnLoad()
    CharacterCreateChoiceMixin.OnLoad(self)
    self.Icon:SetIconNormal("ExperienceIconTmogDisabled")
    self.Background:SetAtlas("ExperienceArtNoTmog", Const.TextureKit.IgnoreAtlasSize)
    self.Icon:UpdateText(DISABLE_TRANSMOG, DISABLE_TRANSMOG_TOOLTIP)
end

function CharacterCreateTransmogChoiceDisableMixin:OnClick(button)
    CharacterCreateChoiceMixin.OnClick(self, button)

    local characterName = CharSelectCharacterName:GetText()

    if characterName then
        NewCharacterSetupUtil.SetCharacterData(characterName, "enableTransmog", false)
    end
end 

--
-- level scaling
--
