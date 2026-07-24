SkillCardsScrollMixin = CreateFromMixins(CallbackRegistryMixin)

local STARTER_FILTER_MODE = {
	Include = "INCLUDE",
	Exclude = "EXCLUDE",
}

local function CopyFilters(filters)
	local copiedFilters = {}

	if not(filters) then
		return copiedFilters
	end

	for i, filter in ipairs(filters) do
		copiedFilters[i] = filter
	end

	return copiedFilters
end

local function RemoveFilterKey(filters, key)
	for i = #filters, 1, -1 do
		if (filters[i] == key) then
			table.remove(filters, i)
		end
	end
end

function SkillCardsScrollMixin:GetNumResults()
	local results = #self.filteredIndices

	if not(results) or (results == 0) then
		self.NoResultsFrame:Show()
	else
		self.NoResultsFrame:Hide()
	end

	return results
end

function SkillCardsScrollMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self:Layout()
	self.isGolden = false
	self.filteredIndices = {}

	self:SetGetNumResultsFunction(GenerateClosure(self.GetNumResults, self))
	self:SetTemplate("SkillCardsScrollItem")
	self:GetSelectedHighlight():SetTexture("") -- TODO: Maybe work with selection in future

	self:GenerateCallbackEvents({
		"OnEnterNoResults",
		"OnLeaveNoResults",
		"OnSelectedIndex",
	})

	self.NoResultsFrame:SetScript("OnEnter", function() self:TriggerEvent("OnEnterNoResults") end)
	self.NoResultsFrame:SetScript("OnLeave", function() self:TriggerEvent("OnLeaveNoResults") end)
end

function SkillCardsScrollMixin:OnShow()
	self:Refresh()
end

function SkillCardsScrollMixin:ShouldIncludeCard(cardData)
	if not(cardData) then
		return false
	end

	local isStarterCard = SkillCardUtil.IsStarterCardData(cardData)

	if (self.starterFilterMode == STARTER_FILTER_MODE.Include) then
		return isStarterCard
	end

	if (self.starterFilterMode == STARTER_FILTER_MODE.Exclude) then
		return not(isStarterCard)
	end

	return true
end

function SkillCardsScrollMixin:RebuildFilteredIndices()
	wipe(self.filteredIndices)

	local numSkillCards = SkillCardUtil.GetNumSkillCards(self:GetCardType()) or 0

	for index = 1, numSkillCards do
		local cardData = SkillCardUtil.GetSkillCardAtIndex(self:GetCardType(), index)
		if self:ShouldIncludeCard(cardData) then
			table.insert(self.filteredIndices, index)
		end
	end
end

function SkillCardsScrollMixin:Refresh()
	local filters = CopyFilters(self:GetParent():GetFilter())

	if self.starterFilterMode then
		RemoveFilterKey(filters, Enum.SkillCardFilters.Starters)
	end

	SkillCardUtil.SetSkillCardFilter(self:GetCardType(), self:GetParent():GetSearchString(), filters)
	self:RebuildFilteredIndices()
	self:RefreshScrollFrame()
end

function SkillCardsScrollMixin:GetCardType()
	return self.cardType
end

function SkillCardsScrollMixin:SetCardType(cardType)
	self.cardType = cardType
	self.isGolden = SkillCardUtil.IsCardTypeGolden(self.cardType)
end

function SkillCardsScrollMixin:SetStarterFilterMode(starterFilterMode)
	self.starterFilterMode = starterFilterMode
end

function SkillCardsScrollMixin:LoadCards(cardType, starterFilterMode)
	self:SetCardType(cardType)
	self:SetStarterFilterMode(starterFilterMode)
	wipe(self.filteredIndices)
end

function SkillCardsScrollMixin:IsGolden()
	return self.isGolden
end

function SkillCardsScrollMixin:GetItemData(index)
	local filteredIndex = self.filteredIndices[index]

	if not(filteredIndex) then
		return
	end

	return SkillCardUtil.GetSkillCardAtIndex(self:GetCardType(), filteredIndex)
end

function SkillCardsScrollMixin:OnSelectedIndex(index)
	local cardData = self:GetItemData(index)
	if cardData then
		self:TriggerEvent("OnSelectedIndex", cardData.CardID, cardData.Rank)
	end
end

function SkillCardsScrollMixin:Layout()
	self.Header = CreateFrame("FRAME", "$parent.Header", self, "CollapsibleHeaderTemplate")
	self.Header:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
	self.Header:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -3, 0)
	self.Header:SetHeight(20)
	self.Header:SetWidth(228)

	self.ScrollFrame:SetHeight(self:GetHeight()-18)

	self.NoResultsFrame = CreateFrame("FRAME", "$parent.NoResultsFrame", self)
	self.NoResultsFrame:SetWidth(192)
	self.NoResultsFrame:SetHeight(96)
	self.NoResultsFrame:SetPoint("CENTER")
	self.NoResultsFrame:EnableMouse(true)

	self.NoResultsFrame.NoResultsText = self.NoResultsFrame:CreateFontString(nil, "OVERLAY")
	self.NoResultsFrame.NoResultsText:SetPoint("CENTER")
	self.NoResultsFrame.NoResultsText:SetFontObject(GameFontDisableLarge)
	self.NoResultsFrame.NoResultsText:SetWidth(192)
	self.NoResultsFrame.NoResultsText:SetText(SKILL_CARD_NOTHING_FOUND)
end
