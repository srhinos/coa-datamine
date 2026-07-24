PathAppendixItemMixin = CreateFromMixins("ScrollListItemBaseMixin")

function PathAppendixItemMixin:OnMouseDown()
    self.Pushed:Show()
    self.Normal:Hide()
    self.Title:SetPoint("LEFT", 24, -1)
end

function PathAppendixItemMixin:OnMouseUp()
    self.Pushed:Hide()
    self.Normal:Show()
    self.Title:SetPoint("LEFT", 26, 0)
end

function PathAppendixItemMixin:Update()
    local isSelected = self:IsSelected()
    self.Selected:SetShown(isSelected)

    local keyword = C_Tutorial.GetKeywordAtIndex(self.index)

    self.Title:SetText(keyword)
end