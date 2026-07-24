ScrollListItemBaseMixin = {}

function ScrollListItemBaseMixin:Init(args)
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.args = args
end

function ScrollListItemBaseMixin:Update()
	error("ScrollListItemBaseMixin:Update must be set by template", 3)
end

function ScrollListItemBaseMixin:OnSelected()
end

function ScrollListItemBaseMixin:OnRightClick()
end

function ScrollListItemBaseMixin:OnEnter()
end

function ScrollListItemBaseMixin:OnLeave()
end

function ScrollListItemBaseMixin:SetIndex(index)
	local newIndex = self.index ~= index
	self.index = index
	self:Update(newIndex)
end

function ScrollListItemBaseMixin:OnClick(button)
	if button == "RightButton" then
		self:OnRightClick()
		return
	end

	local list = self:GetScrollList()
	local current = list:GetSelectedIndex()
	if current == self.index and not list:AllowSelectingSelected() then
		self:OnSelected()
		return
	end
	
	list:SetSelectedIndex(self.index, ScrollListMixin.UpdateType.Always)
	self:OnSelected()
end

function ScrollListItemBaseMixin:GetScrollList()
	return self:GetParent():GetParent():GetParent()
end

function ScrollListItemBaseMixin:GetScrollFrame()
	return self:GetParent():GetParent()
end

function ScrollListItemBaseMixin:Expand(height)
	if not self:IsExpanded() then
		local scrollFrame = self:GetScrollFrame()
		HybridScrollFrame_ExpandButton(scrollFrame, self.index, height)
		if self:IsVisible() then
			self:GetScrollList():RefreshScrollFrame()
		end
	end
end

function ScrollListItemBaseMixin:Collapse()
	if self:IsExpanded() then
		HybridScrollFrame_CollapseButton(self:GetScrollFrame())
		if self:IsVisible() then
			self:GetScrollList():RefreshScrollFrame()
		end
	end
end 

function ScrollListItemBaseMixin:IsExpanded()
	return HybridScrollFrame_GetExpandedButton(self:GetScrollFrame()) == self.index
end

function ScrollListItemBaseMixin:ToggleExpanded(height)
	if self:IsExpanded() then
		self:Collapse()
		return false
	else
		self:Expand(height)
		return true
	end
end

function ScrollListItemBaseMixin:IsSelected()
	return self:GetScrollList():GetSelectedIndex() == self.index
end 