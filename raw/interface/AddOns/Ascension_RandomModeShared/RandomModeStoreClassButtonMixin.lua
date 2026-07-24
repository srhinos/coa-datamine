RandomModeStoreClassButtonMixin = CreateFromMixins("BorderIconTemplateMixin")

function RandomModeStoreClassButtonMixin:OnLoad()
    SetParentArray(self, "buttons")
    self:SetRounded(true)
    self:SetBorderSize(36, 36)
    self:SetBorderAtlas("draft-ring")

    self:SetOverlayBlendMode("ADD")
    self:SetOverlayTexture("Interface\\GLUES\\CHARACTERCREATE\\IconBorderRace_H")
    self:SetOverlaySize(65, 65)
    self:SetOverlayOffset(0, 0)
    self.Overlay:Hide()

    self.Highlight:SetAtlas("bags-roundhighlight", Const.TextureKit.IgnoreAtlasSize)

    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function RandomModeStoreClassButtonMixin:SetClass(class)
    self:SetIconAtlas("class-round-"..class)
    self.filterKey = "FILTER_SKILL_CARD_SPELL_FAMILY_"..class

    if class == "DEATHKNIGHT" then
        self.filterKey = "FILTER_SKILL_CARD_SPELL_FAMILY_DEATH_KNIGHT"
    end
end

function RandomModeStoreClassButtonMixin:UpdateSelected(isSelected)
    self.Overlay:SetShown(isSelected)
end