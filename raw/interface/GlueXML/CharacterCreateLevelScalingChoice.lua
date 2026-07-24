CharacterCreateLevelScalingEnableMixin = CreateFromMixins("CharacterCreateChoiceMixin")

function CharacterCreateLevelScalingEnableMixin:OnLoad()
    CharacterCreateChoiceMixin.OnLoad(self)
    self.Icon:SetIconNormal("ExperienceIconLevelScaling")
    self.Background:SetAtlas("ExperienceArtLevelScaling", Const.TextureKit.IgnoreAtlasSize)
    self.Icon:UpdateText(ENABLE_LEVEL_SCALING, ENABLE_LEVEL_SCALING_TOOLTIP)
end

function CharacterCreateLevelScalingEnableMixin:OnClick(button)
    CharacterCreateChoiceMixin.OnClick(self, button)

    local characterName = CharSelectCharacterName:GetText()

    if characterName then
        NewCharacterSetupUtil.SetCharacterData(characterName, "enableLevelScaling", true)
    end
end

CharacterCreateLevelScalingDisableMixin = CreateFromMixins("CharacterCreateChoiceMixin")

function CharacterCreateLevelScalingDisableMixin:OnLoad()
    CharacterCreateChoiceMixin.OnLoad(self)
    self.Icon:SetIconNormal("ExperienceIconNoLevelScaling")
    self.Background:SetAtlas("ExperienceArtNoLevelScaling", Const.TextureKit.IgnoreAtlasSize)
    self.Icon:UpdateText(DISABLE_LEVEL_SCALING, DISABLE_LEVEL_SCALING_TOOLTIP)
end

function CharacterCreateLevelScalingDisableMixin:OnClick(button)
    CharacterCreateChoiceMixin.OnClick(self, button)

    local characterName = CharSelectCharacterName:GetText()

    if characterName then
        NewCharacterSetupUtil.SetCharacterData(characterName, "enableLevelScaling", false)
    end
end 