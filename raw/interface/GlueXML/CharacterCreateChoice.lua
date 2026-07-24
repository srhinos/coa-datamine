CharacterCreateStepMixin = {}

function CharacterCreateStepMixin:OnStepComplete()
    TutorialExpereinceSelect:NextStep()
end

CharacterCreateChoiceMixin = CreateFromMixins("TutorialExperienceButtonMixin")

function CharacterCreateChoiceMixin:OnLoad()
    TutorialExperienceButtonMixin.Layout(self)

    self.Background:SetPoint("BOTTOMRIGHT", -12, 0)
    self.ArtOverlay:SetPoint("BOTTOMRIGHT", -12, 0)

    self.ArtOverlay.AnimOut:SetScript("OnFinished", function()
        self.ArtOverlay:Hide()
    end)
end

function CharacterCreateChoiceMixin:OnShow()
    self:SetChecked(false)
end

function CharacterCreateChoiceMixin:OnClick()
    self:GetParent():OnStepComplete()
end