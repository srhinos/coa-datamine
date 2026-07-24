BuildViewSectionListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function BuildViewSectionListItemMixin:OnLoad()
    self:SetNormalAtlas("buildcreator-category")
    self:SetHighlightAtlas("buildcreator-category-highlight")
end

function BuildViewSectionListItemMixin:Update()
    local parent = self:GetScrollList():GetParent()
    self:SetText(parent:GetCategoryHeader(self.index))
end 

function BuildViewSectionListItemMixin:OnSelected()
    self:GetScrollList():GetParent():SelectCategory(self.index)
end 