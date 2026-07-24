EventTraceFilterItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function EventTraceFilterItemMixin:Update()
    self.Alternate:SetShown(self.index % 2 == 0)
    local filter = EventTrace.GetFilterAtIndex(self.index)
    self.LeftLabel:SetText(filter)
end 

function EventTraceFilterItemMixin:RemoveFilter()
    EventTrace.RemoveFilterAtIndex(self.index)
end 