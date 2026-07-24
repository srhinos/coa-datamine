RandomModeCategoryTabMixin = CreateFromMixins("TabSystemTabMixin")

function RandomModeCategoryTabMixin:OnLoad()
    self.Highlight:SetAtlas("store-category-selected", Const.TextureKit.IgnoreAtlasSize)
    self.Selected:SetAtlas("store-category-hover", Const.TextureKit.IgnoreAtlasSize)
    self.Background:SetAtlas("store-category", Const.TextureKit.IgnoreAtlasSize)

    self.Icon:SetRounded(true)
    self.Icon:SetIcon("Interface\\Icons\\inv_custom_trainerBook")
    self.Icon:SetBorderSize(42, 42)
    self.Icon:SetBorderAtlas("category-icon-ring")
end

function RandomModeCategoryTabMixin:OnSelected()
    self:SetNormalFontObject("GameFontHighlight")
    self.Selected:Show()
end 

function RandomModeCategoryTabMixin:OnDeselected()
    self:SetNormalFontObject("GameFontNormal")
    self.Selected:Hide()
end

function RandomModeCategoryTabMixin:OnDisable()
    if self:IsTabEnabled() then
        return
    end
    self.Icon:SetDesaturated(true)
    self.Icon:SetBorderDesaturated(true)
    self.Background:SetDesaturated(true)
end 

function RandomModeCategoryTabMixin:OnEnable()
    self.Icon:SetDesaturated(false)
    self.Icon:SetBorderDesaturated(false)
    self.Background:SetDesaturated(false)
end 