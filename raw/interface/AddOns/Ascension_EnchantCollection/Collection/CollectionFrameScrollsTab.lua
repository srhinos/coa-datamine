ECScrollsTabMixin = {}

local GetMoreScrollsData = {Entry = -1}

function ECScrollsTabMixin:OnLoad()
	self:Layout()

	self.numFilteredScrolls = 0

	self:SetGetNumResultsFunction(function() return self:GetNumResults() end)
end

function ECScrollsTabMixin:InitScroll()
	self:SetTemplate("EnchantCollectionScrollListItem")
	self:Refresh()
end

function ECScrollsTabMixin:OnShow()
	if not(self.isInitialized) then
		self:InitScroll()
	end

	self:RefreshScrollData()
end

function ECScrollsTabMixin:Refresh()
	local searchText = self:GetParent():GetSearchString():trim()
	C_MysticEnchant.SetMysticScrollFilter(searchText, self:GetParent().Filter:GetFilter())
	self.numFilteredScrolls = C_MysticEnchant.GetNumFilteredMysticScrolls() or 0

	self.NoResultsFrame:Hide()

	if (self.isInitialized) then
		self:RefreshScrollFrame()
		self:RefreshSelection()
	end
end

function ECScrollsTabMixin:GetUntrainedScrolls()
	return GetItemCount(ItemData.UNTARNISHED_MYSTIC_SCROLL) or 0
end

function ECScrollsTabMixin:GetNumResults()
	return (self.numFilteredScrolls or 0) + 1
end

function ECScrollsTabMixin:GetItemData(index)
	if index == self:GetNumResults() then
		GetMoreScrollsData.Name = ENCHANT_COLLECTION_GET_MORE_SCROLLS
		return GetMoreScrollsData
	end

	return C_MysticEnchant.GetFilteredMysticScrollAtIndex(index) or {}
end

function ECScrollsTabMixin:GetItemDataByIDUnfiltered(itemID)
	for i = 1, self.numFilteredScrolls or 0 do
		local v = C_MysticEnchant.GetFilteredMysticScrollAtIndex(i)
		if (v and v.Entry == itemID) then
			return v
		end
	end

	local searchText = self:GetParent():GetSearchString():trim()
	local filter = self:GetParent().Filter:GetFilter()

	C_MysticEnchant.SetMysticScrollFilter("", {})
	local numUnfilteredScrolls = C_MysticEnchant.GetNumFilteredMysticScrolls() or 0
	for i = 1, numUnfilteredScrolls do
		local v = C_MysticEnchant.GetFilteredMysticScrollAtIndex(i)
		if (v and v.Entry == itemID) then
			C_MysticEnchant.SetMysticScrollFilter(searchText, filter)
			return v
		end
	end

	C_MysticEnchant.SetMysticScrollFilter(searchText, filter)
end

function ECScrollsTabMixin:RefreshSelection()
	self:SetSelectedIndex(nil)

	for i = 1, self:GetNumResults() do
		local v = self:GetItemData(i)
		if (v and self.selectedEntry == v.Entry) then
			self:SetSelectedIndex(i)
			return 
		end
	end
end

function ECScrollsTabMixin:SetSelectedItem(itemID)
	self.selectedEntry = itemID
	
	for i = 1, self:GetNumResults() do
		local v = self:GetItemData(i)
		if (v and v.Entry == itemID) then
			self:RefreshSelection()
			return 
		end
	end
end

function ECScrollsTabMixin:RefreshScrollData(waitingForReforge)
	if waitingForReforge then
		return
	end
	
 	self:Refresh()
end

function ECScrollsTabMixin:GetEnchantCollection()
	return self:GetParent():GetParent()
end

function ECScrollsTabMixin:Layout()
	self:SetPoint("BOTTOMRIGHT")
	self:SetSize(self:GetParent():GetSize())

	self.InsetFrame:Hide()
	self.InsetFrame = CreateFrame("FRAME", "$parent.InsetFrame", self)
	self.InsetFrame:SetPoint("TOPLEFT")
	self.InsetFrame:SetPoint("BOTTOMRIGHT", self.ScrollFrame, "BOTTOMRIGHT")
	self.InsetFrame:Show()

	self.NoResultsFrame = CreateFrame("FRAME", "$parent.NoResultsFrame", self, nil)
	self.NoResultsFrame:SetPoint("CENTER", 0, 0)
	self.NoResultsFrame:SetSize(self:GetParent():GetSize())
	self.NoResultsFrame:SetFrameLevel(self:GetFrameLevel()+4)
	MixinAndLoadScripts(self.NoResultsFrame, ECLargeDisabledTextFrameMixin)
	self.NoResultsFrame.Text:SetText(ENCHANT_COLLECTION_EMPTY_SEARCH)
end
