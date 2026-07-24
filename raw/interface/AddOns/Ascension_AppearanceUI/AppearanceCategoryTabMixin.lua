AppearanceCategoryTabMixin = CreateFromMixins("TabSystemTabMixin")
AppearanceCategoryTabMixin.UpdateWidth = nop

function AppearanceCategoryTabMixin:OnLoad()
    self.Highlight:SetAtlas("bags-roundhighlight", Const.TextureKit.IgnoreAtlasSize)
    self:SetCheckedAtlas("transmog-nav-slot-selected", true)
    self.Border:SetAtlas("GarrMission_PortraitRing_Enemy", Const.TextureKit.IgnoreAtlasSize)
    self.NormalTexture:SetDrawLayer("BACKGROUND")
end

function AppearanceCategoryTabMixin:SetCategory(categoryID, icon)
    self.categoryID = categoryID
    self.NormalTexture:SetPortraitTexture("Interface\\Icons\\"..(icon or "INV_Misc_QuestionMark"))
    self.NormalTexture:SetDesaturated(true)
end 

function AppearanceCategoryTabMixin:GetCategory()
    return self.categoryID
end 