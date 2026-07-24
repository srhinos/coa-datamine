-------------------------------------------------------------------------------
--                           ECCollectionsItemMixin                           --
-------------------------------------------------------------------------------
ECCollectionsTabMixin = {}

function ECCollectionsTabMixin:OnLoad()
	self.buttonCollection = CreateFramePoolCollection()
	self.page = 1
	self.maxPage = 1
	self.entriesPerPage = EnchantCollectionUtil.maxCollectionButtons
	self.buttonIDToButton = {}
	self.filteredResults = {}
	self.maxResults = 0

	self:EnableMouseWheel(true)

	self:Layout()
end

function ECCollectionsTabMixin:OnShow(pageIndex)
	if (pageIndex) then
		self.page = pageIndex
	end
	
	self:OnPageChanged()
end

function ECCollectionsTabMixin:ReleaseAllButtons()
	self.buttonIDToButton = {}
	self.buttonCollection:ReleaseAll()
end

function ECCollectionsTabMixin:AcquireButton()
	local pool, isNewPool = self.buttonCollection:GetOrCreatePool("BUTTON", self, "EnchantCollectionCollectionButton", nil)

	local button, isNew = pool:Acquire()

	return button
end

function ECCollectionsTabMixin:GetQueriedEnchantData(index)
	return self.filteredResults[index]
end

function ECCollectionsTabMixin:GetEnchantCollection()
	return self:GetParent():GetParent()
end

function ECCollectionsTabMixin:RefreshSelected(spellID)
	self.selectedSpellID = spellID
	self:DisplayResults()
end

function ECCollectionsTabMixin:GetSelectedSpellID()
	return self.selectedSpellID
end

function ECCollectionsTabMixin:OnSelectCollectionEnchant(index)
	local spellID = self.filteredResults[index] and self.filteredResults[index].SpellID

	self:GetEnchantCollection():OnSelectCollectionEnchant(spellID)
end

function ECCollectionsTabMixin:OnCollectionEnchantOnEnter(index)
	local REData = C_MysticEnchant.GetEnchantInfoBySpell(self.filteredResults[index].SpellID)

	if not(REData) then
		return
	end

	self:GetEnchantCollection():TooltipAddStackData(self.filteredResults[index].SpellID)
end

function ECCollectionsTabMixin:OnMouseWheel(delta)
	if (delta < 0) then
		self:NextPage()
	else
		self:PreviousPage()
	end
end

function ECCollectionsTabMixin:NextPage()
	PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA)

	if self.page >= self.maxPage then
		self.page = self.maxPage
	else
		self.page = self.page + 1
	end

	self:OnPageChanged()
end

function ECCollectionsTabMixin:PreviousPage()
	PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA)

	if self.page <= 1 then
		self.page = 1
	else
		self.page = self.page - 1
	end

	self:OnPageChanged()
end

function ECCollectionsTabMixin:OnPageChanged()
	self:DisplayResults()
end

function ECCollectionsTabMixin:DisplayResults()
	-- QueryEnchants(int entriesPerPage, int page, string query, array<string> additionalFilterTypes)
	self:ReleaseAllButtons()

	--dprint(string.format("C_MysticEnchant.QueryEnchants %s, %s, '%s', ", self.entriesPerPage, self.page, self:GetParent():GetSearchString()))
	--dprint(unpack(self:GetParent():GetFilter()))
	
	self.filteredResults, self.maxPage = C_MysticEnchant.QueryEnchants(self.entriesPerPage, self.page, self:GetParent():GetSearchString(), self:GetParent().Filter:GetFilter())
	
	self.PageText:SetFormattedText(MERCHANT_PAGE_NUMBER, self.page, self.maxPage)

	if (self.page == self.maxPage) then
		self.PageRightButton:Disable()
	else
		self.PageRightButton:Enable()
	end

	if (self.page <= 1) then
		self.PageLeftButton:Disable()
	else
		self.PageLeftButton:Enable()
	end

	if (next(self.filteredResults)) then
		for i = 1, math.min(#self.filteredResults, self.entriesPerPage) do
			local button = self:AcquireButton()
			button:Init(i)
			button:Show()

			self.buttonIDToButton[i] = button

			if (i == 1) then
				button:SetPoint("TOPLEFT", self, "TOPLEFT", 36, -36)
			elseif (i == 7) then
				button:SetPoint("TOP", self, "TOP", 0, -36)
			elseif (i == 13) then
				button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -36, -36)
			else
				button:SetPoint("TOP", self.buttonIDToButton[i-1], "BOTTOM", 0, -4)
			end
		end

		self.PageText:Show()
		self.PageLeftButton:Show()
		self.PageRightButton:Show()
		self.NoResultsFrame:Hide()
	else
		self.PageText:Hide()
		self.PageLeftButton:Hide()
		self.PageRightButton:Hide()
		self.NoResultsFrame:Show()
	end
end

function ECCollectionsTabMixin:Layout()
	self.PageText = self:CreateFontString(nil, "OVERLAY")
	self.PageText:SetFontObject(GameFontHighlight)
	--self.PageText:SetSize(180, 0)
	self.PageText:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -12, 36)

	self.PageLeftButton = CreateFrame("BUTTON", "$parent.PageLeftButton", self, "LeftButtonTemplate")
	self.PageLeftButton:SetScript("OnClick", function(self)
		self:GetParent():PreviousPage()
	end)
	self.PageLeftButton:SetPoint("LEFT", self.PageText, "RIGHT", 12, 0)

	self.PageRightButton = CreateFrame("BUTTON", "$parent.PageRightButton", self, "RightButtonTemplate")
	self.PageRightButton:SetScript("OnClick", function(self)
		self:GetParent():NextPage()
	end)
	self.PageRightButton:SetPoint("LEFT", self.PageLeftButton, "RIGHT", 8, 0)

	self.NoResultsFrame = CreateFrame("FRAME", "$parent.NoResultsFrame", self, nil)
	self.NoResultsFrame:SetPoint("CENTER", 0, 0)
	self.NoResultsFrame:SetSize(self:GetParent():GetSize())
	self.NoResultsFrame:SetFrameLevel(self:GetFrameLevel()+4)
	MixinAndLoadScripts(self.NoResultsFrame, ECLargeDisabledTextFrameMixin)
	self.NoResultsFrame.Text:SetText(ENCHANT_COLLECTION_EMPTY_SEARCH)
end