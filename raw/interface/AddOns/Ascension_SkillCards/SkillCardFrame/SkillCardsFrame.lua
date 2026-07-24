HelpTips["SKILL_CARDS_FILTER_AND_SEARCH"] = {
    text = SKILL_CARDS_FILTER_HELP,
    parent  = "SkillCardsFrameFilter",
    targetPoint = HelpTip.Point.BottomEdgeCenter,
}

local ARTIFACT_QUALITY_LABEL = RE_QUALITY_ARTIFACT_NAME or FILTER_QUALITY_ARTIFACT or "Artifact"

local RARITY_BAR_QUALITIES = {
	{ quality = Enum.ItemQuality.Uncommon,  label = ITEM_QUALITY2_DESC },
	{ quality = Enum.ItemQuality.Rare,      label = ITEM_QUALITY3_DESC },
	{ quality = Enum.ItemQuality.Epic,      label = ITEM_QUALITY4_DESC },
	{ quality = Enum.ItemQuality.Legendary, label = ITEM_QUALITY5_DESC },
}

local ALL_SKILL_CARD_TYPES = {
	Enum.SkillCardType.SkillNormal,
	Enum.SkillCardType.SkillGolden,
	Enum.SkillCardType.LuckyNormal,
	Enum.SkillCardType.LuckyGolden,
	Enum.SkillCardType.TalentNormal,
	Enum.SkillCardType.TalentGolden,
}

local STARTER_FILTER_MODE = {
	Include = "INCLUDE",
	Exclude = "EXCLUDE",
}

local function HasPrestigedOnce()
	if GetPrestigeLevel then
		local prestigeLevel = GetPrestigeLevel()
		return (prestigeLevel or 0) > 0
	end

	return C_Player:IsPrestiged()
end

local filterOptions = {
	{ text = KNOWN_SKILLCARDS, tooltip = KNOWN_SKILLCARDS_TOOLTIP, key = Enum.SkillCardFilters.Collected },
	{ text = TRANSMOG_NOT_COLLECTED, tooltip = "", key = Enum.SkillCardFilters.NotCollected },
	{
		text = STARTERS_SKILLCARDS,
		tooltip = STARTERS_SKILLCARDS_TOOLTIP,
		key = Enum.SkillCardFilters.Starters,
		hiddenOnTabs = {
			[Enum.SkillCardTabs.SkillCardsTab] = true,
			[Enum.SkillCardTabs.StarterCardsTab] = true,
		},
	},
	{ spacer = true },
	{ text = QUALITY, tooltip = FILTER_QUALITY_TOOLTIP, menuList = {
			{ text = ITEM_QUALITY_COLORS[1].hex..ITEM_QUALITY1_DESC, key = Enum.SkillCardFilters.Common},
			{ text = ITEM_QUALITY_COLORS[2].hex..ITEM_QUALITY2_DESC, key = Enum.SkillCardFilters.Uncommon},
			{ text = ITEM_QUALITY_COLORS[3].hex..ITEM_QUALITY3_DESC, key = Enum.SkillCardFilters.Rare},
			{ text = ITEM_QUALITY_COLORS[4].hex..ITEM_QUALITY4_DESC, key = Enum.SkillCardFilters.Epic},
			{ text = ITEM_QUALITY_COLORS[5].hex..ITEM_QUALITY5_DESC, key = Enum.SkillCardFilters.Legendary},
			{ text = ITEM_QUALITY_COLORS[6].hex..ARTIFACT_QUALITY_LABEL, key = Enum.SkillCardFilters.Artifact},
		}
	},
}

local tabs = {
	[Enum.SkillCardTabs.SkillCardsTab] = {
		text = SKILL_CARD_ABILITY_CARDS,
		cardTypes = {Enum.SkillCardType.SkillNormal, Enum.SkillCardType.SkillGolden},
		cardAtlases = {"SkillCardNormalQuality", "SkillCardGoldQuality"},
		cardTypeNames = {SKILL_CARD_NORMAL_COLLECTION, SKILL_CARD_GOLDEN_COLLECTION},
		showRarityBar = true,
		starterFilterMode = STARTER_FILTER_MODE.Exclude,
	},
	[Enum.SkillCardTabs.StarterCardsTab] = {
		text = STARTERS_SKILLCARDS,
		cardTypes = {Enum.SkillCardType.SkillNormal, Enum.SkillCardType.SkillGolden},
		slotCardTypes = {Enum.SkillCardType.StarterNormal, Enum.SkillCardType.StarterGolden},
		cardAtlases = {"SkillCardNormalQuality", "SkillCardGoldQuality"},
		cardTypeNames = {SKILL_CARD_NORMAL_COLLECTION, SKILL_CARD_GOLDEN_COLLECTION},
		starterFilterMode = STARTER_FILTER_MODE.Include,
	},
	[Enum.SkillCardTabs.LuckyCardsTab] = {
		text = SKILL_CARD_LUCKY_CARDS,
		cardTypes = {Enum.SkillCardType.LuckyNormal, Enum.SkillCardType.LuckyGolden},
		cardAtlases = {"LuckyCardNormalQuality", "LuckyCardGoldQuality"},
		cardTypeNames = {LUCKY_CARD_NORMAL_COLLECTION, LUCKY_CARD_GOLDEN_COLLECTION},
	},
	[Enum.SkillCardTabs.TalentCardsTab] = {
		text = SKILL_CARD_TALENT_CARDS,
		cardTypes = {Enum.SkillCardType.TalentNormal, Enum.SkillCardType.TalentGolden},
		cardAtlases = {"SkillCardNormalQuality", "SkillCardGoldQuality"},
		cardTypeNames = {TALENT_CARD_NORMAL_COLLECTION, TALENT_CARD_GOLDEN_COLLECTION},
	},
	[Enum.SkillCardTabs.BoostersTab] = {
		text = SKILL_CARD_BOOSTERS_TAB,
	},
}

local tabOrder = {
	Enum.SkillCardTabs.StarterCardsTab,
	Enum.SkillCardTabs.SkillCardsTab,
	Enum.SkillCardTabs.LuckyCardsTab,
	Enum.SkillCardTabs.TalentCardsTab,
	Enum.SkillCardTabs.BoostersTab,
}
-------------------------------------------------------------------------------
--                                   Mixin                                   --
-------------------------------------------------------------------------------
SkillCardsFrameMixin = CreateFromMixins(CallbackRegistryMixin)

SkillCardsFrameMixin.events = {
	--"CLAIM_SKILL_CARD_RESULT",
	"PENDING_SKILL_CARD_ADDED",
	"PENDING_SKILL_CARD_REMOVED",
	--"BONUS_SEALED_CARD_PACK_REWARDED",
	"BONUS_SEALED_CARD_PACK_PROGRESS_UPDATE",
	"SKILL_CARD_AUTO_REVEALED",
	"SKILL_CARD_COLLECTION_ITEM_USED",
	"SKILL_CARD_UPDATED",
	--"PURCHASE_SEALED_CARD_RESULT",
}

function SkillCardsFrameMixin:GetDefaultTab()
	if C_Player:GetLevel() == 1 then
		return Enum.SkillCardTabs.StarterCardsTab
	end

	return Enum.SkillCardTabs.SkillCardsTab
end

function SkillCardsFrameMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:SetScript("OnEvent", OnEventToMethod)
	--[[self:GenerateCallbackEvents(
	{
		"OnPendingSkillCardAdded",
	})]]--

	self:Layout()

	PanelTemplates_SetNumTabs(self, #tabOrder)

	_G[self:GetName().."CloseButton"]:SetScript("OnClick", function()
		if (self:GetParent() == Collections) then
	    	HideUIPanel(Collections)
	    else
	    	self:Hide()
	    end
	end)

	self.Filter:Initialize(GenerateClosure(self.GenerateFilterDropdown, self))
	self.Filter.ClearFilters = GenerateClosure(self.ClearFilters, self)

	self.Search:SetScript("OnTextSet", GenerateClosure(self.UpdateFilter, self))
	self.Search:SetScript("OnTextChanged", function(self)
		if self:HasFocus() then
			SearchBoxTemplate_OnTextChanged(self)
			self:GetParent():UpdateFilter()
		end
	end)

	for _, tabID in ipairs(tabOrder) do
		self["Tab"..tabID]:SetScript("OnClick", SkillCardsFrameMixin.OnSetTabClick)
	end

	self:SetTab(self:GetDefaultTab())

	self.ScrollListNormal:RegisterCallback("OnSelectedIndex", self.OnCardSelected, self)
	self.ScrollListGolden:RegisterCallback("OnSelectedIndex", self.OnCardSelected, self)

	self.ScrollListNormal:RegisterCallback("OnEnterNoResults", self.ShowFilterHelp, self)
	self.ScrollListGolden:RegisterCallback("OnEnterNoResults", self.ShowFilterHelp, self)

	self.ScrollListNormal:RegisterCallback("OnLeaveNoResults", self.HideFilterHelp, self)
	self.ScrollListGolden:RegisterCallback("OnLeaveNoResults", self.HideFilterHelp, self)

	self:ApplyGameModeSettings()
	C_GameMode:RegisterCallback("OnGameModeChanged", GenerateClosure(self.OnGameModeChanged, self))
end

function SkillCardsFrameMixin:RegisterEvents()
	for _, event in pairs(self.events) do
		self:HookEvent(event)
	end

	self:HookBucketEvent("CLAIM_SKILL_CARD_RESULT", 0.2) -- to reduce load when mass revealing
end

function SkillCardsFrameMixin:LayoutVisibleTabs()
	local previousTab

	for _, tabID in ipairs(tabOrder) do
		local tab = self["Tab"..tabID]
		tab:ClearAllPoints()

		if tab:IsShown() then
			if previousTab then
				tab:SetPoint("LEFT", previousTab, "RIGHT", 4, 0)
			else
				tab:SetPoint("BOTTOMLEFT", self.TabInsetFrame, "TOPLEFT", 56, 0)
			end

			previousTab = tab
		end
	end
end

function SkillCardsFrameMixin:ResetTabDefaults()
	for _, tabID in ipairs(tabOrder) do
		self["Tab"..tabID]:Show()
		PanelTemplates_EnableTab(self, tabID)
		self["Tab"..tabID].disabledTooltip = nil
	end

	self:LayoutVisibleTabs()
end

function SkillCardsFrameMixin:SelectFallbackTabIfNeeded()
	local selectedTab = PanelTemplates_GetSelectedTab(self)
	if not selectedTab then
		return
	end

	local tabFrame = self["Tab"..selectedTab]
	if tabFrame and (not tabFrame:IsShown() or tabFrame.isDisabled) then
		self:SetTab(self:GetDefaultTab())
	end
end

function SkillCardsFrameMixin:UpdateRarityBarVisibility(tabID)
	local tab = tabs[tabID]

	if C_GameMode:IsGameModeActive(Enum.GameMode.Draft) and tab and tab.showRarityBar then
		self.RarityBarContainer:Show()
		self:UpdateRarityBars()
	else
		self.RarityBarContainer:Hide()
	end
end

function SkillCardsFrameMixin:ApplyGameModeSettings()
	self:ResetTabDefaults()

	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		self["Tab"..Enum.SkillCardTabs.LuckyCardsTab]:Hide()
	elseif C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
		self["Tab"..Enum.SkillCardTabs.LuckyCardsTab]:Hide()
		self["Tab"..Enum.SkillCardTabs.TalentCardsTab]:Hide()
	end

	self:LayoutVisibleTabs()
	self:SelectFallbackTabIfNeeded()
	self:UpdateRarityBarVisibility(PanelTemplates_GetSelectedTab(self))
end

function SkillCardsFrameMixin:OnGameModeChanged()
	self:ApplyGameModeSettings()
end

function SkillCardsFrameMixin:GetActiveSkillCardQualityCosts()
	local costs = {}
	for _, info in ipairs(RARITY_BAR_QUALITIES) do
		costs[info.quality] = 0
	end

	for _, cardType in ipairs(ALL_SKILL_CARD_TYPES) do
		local maxCards = C_SkillCard.GetMaxCardCount(cardType) or 0
		for i = 1, maxCards do
			local cardData = C_SkillCard.GetSkillCardInfoAtIndex(cardType, i)
			if cardData then
				local quality = Enum.SkillCardQuality[cardData.Quality]
				local qualityCost = cardData.QualityCost or 0
				if quality and qualityCost > 0 and costs[quality] then
					costs[quality] = costs[quality] + qualityCost
				end
			end
		end
	end

	return costs
end

function SkillCardsFrameMixin:UpdateRarityBars()
	local costs = self:GetActiveSkillCardQualityCosts()

	for _, info in ipairs(RARITY_BAR_QUALITIES) do
		local bar = self.RarityBars[info.quality]
		local amount = costs[info.quality] or 0
		local limit = C_CharacterAdvancement.GetQualityLimit(info.quality)

		bar.RarityGemContainer:SetNumGems(limit or amount, amount)
	end
end

function SkillCardsFrameMixin:OnShow()
	if self:GetDefaultTab() == Enum.SkillCardTabs.StarterCardsTab then
		self:SetTab(Enum.SkillCardTabs.StarterCardsTab)
	end

	self:RegisterEvent("UNIT_AURA")
	self:ApplyGameModeSettings()
	self:RegisterEvents()
end

function SkillCardsFrameMixin:OnHide()
	self:UnregisterEvent("UNIT_AURA")
	self:UnhookAllEvents()
end

function SkillCardsFrameMixin:IsCardCompatibleWithActiveTab(cardID, rank)
	local selectedTab = PanelTemplates_GetSelectedTab(self)
	local tab = tabs[selectedTab]
	if not tab or not tab.cardTypes then
		return false
	end

	local cardData = SkillCardUtil.GetSkillCardInfo(cardID, rank or 1)
	if not cardData or not cardData.IsCollected then
		return false
	end

	-- Check if the card's type is compatible with this tab's acceptable collection card types
	local typeMatched = false
	for _, acceptedType in ipairs(tab.cardTypes) do
		if cardData.Type == acceptedType then
			typeMatched = true
			break
		end
	end

	if not typeMatched then
		return false
	end

	-- Check starter filters if applicable
	local isStarterCard = SkillCardUtil.IsStarterCardData(cardData)
	if tab.starterFilterMode == STARTER_FILTER_MODE.Include then
		if not isStarterCard then
			return false
		end
	elseif tab.starterFilterMode == STARTER_FILTER_MODE.Exclude then
		if isStarterCard then
			return false
		end
	end

	return true
end

function SkillCardsFrameMixin:OnCardSelected(cardID, rank)
	if self:IsCardCompatibleWithActiveTab(cardID, rank) then
		self.TabInsetFrame:SelectCard(cardID, rank)
	end
end

function SkillCardsFrameMixin:OnSetTabClick()
	self:GetParent():SetTab(self:GetID())
end

function SkillCardsFrameMixin:OnTabEnter()
	if self:IsEnabled() == 0 and self.disabledTooltip then
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(self.disabledTooltip, RED_FONT_COLOR:GetRGB())
		GameTooltip:Show()
	end
end

function SkillCardsFrameMixin:OnTabLeave()
	GameTooltip:Hide()
end

function SkillCardsFrameMixin:ShouldShowFilterOption(item)
	if item.hiddenOnTabs then
		return not(item.hiddenOnTabs[PanelTemplates_GetSelectedTab(self)])
	end

	return true
end

function SkillCardsFrameMixin:GenerateFilterDropdown(dropdown, level, menuList)
	level = level or 1
	local items = menuList or filterOptions

	for _, item in ipairs(items) do
		if (not(item.tab) or (item.tab == PanelTemplates_GetSelectedTab(self))) and self:ShouldShowFilterOption(item) then
			if item.spacer then
				UIDropDownMenu_AddSpace(level)
			else
				local info = UIDropDownMenu_CreateInfo()
				info.text = item.text
				info.hasArrow = item.menuList ~= nil

				if (item.tooltip) then
					info.tooltipTitle = item.text
					info.tooltipText = item.tooltip
				end

				if not info.hasArrow then
					info.checked = self:GetFilterKey(item.key) and 1 or false
					info.func = function(_, _, _, checked) if not(checked) then self:AddFilterKey(item.key) else self:RemoveFilterKey(item.key) end end
				else
					info.menuList = item.menuList
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end

	EventRegistry:TriggerEvent("SkillCardsFrameMixin.GenerateFilterDropdown")
end

function SkillCardsFrameMixin:UpdateFilter()
	self.Filter.ClearFiltersButton:SetShown(self.filter and next(self.filter) ~= nil)
	self.ScrollListNormal:Refresh()
	self.ScrollListGolden:Refresh()
end

function SkillCardsFrameMixin:AddFilterKey(key)
	if not(self:GetFilterKey(key)) then
		table.insert(self:GetFilter(), key)
	end
	self:UpdateFilter()
end

function SkillCardsFrameMixin:RemoveFilterKey(key)
	for i, v in pairs(self:GetFilter()) do
		if (v == key) then
			table.remove(self:GetFilter(), i)
		end
	end
	self:UpdateFilter()
end

function SkillCardsFrameMixin:ClearFilters()
	if not self.filter then return true end
	wipe(self.filter)

	self:UpdateFilter()
	return true
end

function SkillCardsFrameMixin:GetSearchString()
	return self.Search:GetText()
end

function SkillCardsFrameMixin:GetFilter()
	self.filter = self.filter or {}

	return self.filter
end

function SkillCardsFrameMixin:ResetFiltersAndSearch()
	self.Search:SetText("")
	self.Search:ClearFocus()
	self:ClearFilters()

	-- TODO: Remove if complains about it
	if SkillCardUtil.HasAnyCardCollected(self.ScrollListNormal:GetCardType()) or SkillCardUtil.HasAnyCardCollected(self.ScrollListGolden:GetCardType()) then
		self:AddFilterKey(Enum.SkillCardFilters.Collected)
	end
end

function SkillCardsFrameMixin:GetFilterKey(key)
	for _, v in pairs(self:GetFilter()) do
		if (v == key) then
			return v
		end
	end

	return
end

function SkillCardsFrameMixin:SetTab(id)
	PanelTemplates_SetTab(self, id)
	CloseDropDownMenus()
	local tab = tabs[id]

	if not(tab) then
		return
	end

	if (id == Enum.SkillCardTabs.BoostersTab) then -- load boosters special tab
		self.ScrollListNormal:Hide()
		self.ScrollListGolden:Hide()
		self.TabInsetFrame:Hide()
		self.Filter:Hide()
		self.Search:Hide()
		self.RarityBarContainer:Hide()

		self.UnlockFrame:Show()
		return
	end

	self.UnlockFrame:Hide()

	self.Search:Show()
	self.Filter:Show()
	self.ScrollListNormal:Show()
	self.ScrollListGolden:Show()
	self.TabInsetFrame:Show()

	local collectionCardTypeNormal, collectionCardTypeGolden = unpack(tab.collectionCardTypes or tab.cardTypes)
	local slotCardTypeNormal, slotCardTypeGolden = unpack(tab.slotCardTypes or tab.cardTypes)
	local cardAtlasNormal, cardAtlasGolden = unpack(tab.cardAtlases)
	local cardNamesNormal, cardNamesGolden = unpack(tab.cardTypeNames)

	self.ScrollListNormal.Header.Text:SetText(cardNamesNormal)
	self.ScrollListGolden.Header.Text:SetText(cardNamesGolden)
	self.ScrollListNormal:LoadCards(collectionCardTypeNormal, tab.starterFilterMode)
	self.ScrollListGolden:LoadCards(collectionCardTypeGolden, tab.starterFilterMode)

	self.TabInsetFrame:SetCardAtlases(cardAtlasNormal, cardAtlasGolden)
	self.TabInsetFrame:SetCardTypes(slotCardTypeNormal, slotCardTypeGolden)
	self:ResetFiltersAndSearch()
	self:UpdateRarityBars()
	self:UpdateRarityBarVisibility(id)
end

function SkillCardsFrameMixin:ShowFilterHelp()
	HelpTip:Show("SKILL_CARDS_FILTER_AND_SEARCH")
end

function SkillCardsFrameMixin:HideFilterHelp()
	HelpTip:Hide("SKILL_CARDS_FILTER_AND_SEARCH")
end

--[[function SkillCardsFrameMixin:PURCHASE_SEALED_CARD_RESULT(result)
	if result == "PURCHASE_SEALED_CARD_OK" then 
		self:TriggerEvent("OnPurchaseSealedCardResult")
	end
end]]--

function SkillCardsFrameMixin:PENDING_SKILL_CARD_ADDED(...)
	self:SetTab(Enum.SkillCardTabs.BoostersTab)
	self.UnlockFrame:PENDING_SKILL_CARD_ADDED(...)

	--self:TriggerEvent("OnPendingSkillCardAdded")
end

function SkillCardsFrameMixin:SKILL_CARD_AUTO_REVEALED(...)
	self:SetTab(Enum.SkillCardTabs.BoostersTab)
	self.UnlockFrame:SKILL_CARD_AUTO_REVEALED(...)
end

function SkillCardsFrameMixin:SKILL_CARD_COLLECTION_ITEM_USED(...)
	self:SetTab(Enum.SkillCardTabs.BoostersTab)
	self.UnlockFrame:SKILL_CARD_COLLECTION_ITEM_USED(...)
end

function SkillCardsFrameMixin:PENDING_SKILL_CARD_REMOVED(...)
	self:SetTab(Enum.SkillCardTabs.BoostersTab)
	self.UnlockFrame:PENDING_SKILL_CARD_REMOVED(...)
end

function SkillCardsFrameMixin:BONUS_SEALED_CARD_PACK_PROGRESS_UPDATE(...)
	self:SetTab(Enum.SkillCardTabs.BoostersTab)
	self.UnlockFrame:BONUS_SEALED_CARD_PACK_PROGRESS_UPDATE(...)
end

function SkillCardsFrameMixin:CLAIM_SKILL_CARD_RESULT()
	self:SetTab(Enum.SkillCardTabs.BoostersTab)
	self.UnlockFrame:CLAIM_SKILL_CARD_RESULT()
end

function SkillCardsFrameMixin:SKILL_CARD_UPDATED()
	self:UpdateRarityBars()
end

function SkillCardsFrameMixin:UNIT_AURA(unit)
	if unit == "player" then
		self:ApplyGameModeSettings()
	end
end

function SkillCardsFrameMixin:Layout()
	self:SetSize(1060, 698)

	PortraitFrame_SetIcon(self, "Interface\\Icons\\inv_inscription_darkmooncard_putrescence")
	PortraitFrame_SetTitle(self, UNLOCK_SKILL_CARDS_TITLE)

	self.Filter = CreateFrame("BUTTON", "$parentFilter", self, "FilterDropDownMenuTemplate")
	self.Filter:SetSize(78, 22)
	self.Filter:SetPoint("TOPRIGHT", -12, -30)

	self.Search = CreateFrame("EditBox", "$parentFilter", self, "SearchBoxTemplate")
	self.Search:SetSize(256, 22)
	self.Search:SetPoint("RIGHT", self.Filter, "LEFT", -8, 0)

	self.TabInsetFrame = CreateFrame("FRAME", "$parent.TabInsetFrame", self, "SkillCardInsetFrameTemplate")
	self.TabInsetFrame:SetPoint("TOPLEFT", 4, -58)
	self.TabInsetFrame:SetPoint("BOTTOMLEFT", 4, 28)
	self.TabInsetFrame:SetWidth(766)
	MixinAndLoadScripts(self.TabInsetFrame, SkillCardTabMixin)

	self.UnlockFrame = CreateFrame("FRAME", "$parent.UnlockFrame", self, "SkillCardInsetFrameTemplate")
	self.UnlockFrame:SetFrameLevel(self.TabInsetFrame:GetFrameLevel())
	self.UnlockFrame:SetPoint("TOPLEFT", 4, -58)
	self.UnlockFrame:SetPoint("BOTTOMLEFT", 4, 6)
	self.UnlockFrame:SetWidth(1051)
	self.UnlockFrame:Hide()
	self.UnlockFrame:EnableMouse(true)
	MixinAndLoadScripts(self.UnlockFrame, SkillCardUnlockFrameMixin)
	
	self.ScrollListNormal = CreateFrame("FRAME", "$parent.ScrollListNormal", self, "ScrollListTemplate")
	self.ScrollListNormal:SetPoint("TOPLEFT", self.TabInsetFrame, "TOPRIGHT", 4, -20)
	self.ScrollListNormal:SetPoint("BOTTOMLEFT", self.TabInsetFrame, "RIGHT", 4, -12)
	self.ScrollListNormal:SetWidth(283)
	MixinAndLoadScripts(self.ScrollListNormal, SkillCardsScrollMixin)

	self.ScrollListGolden = CreateFrame("FRAME", "$parent.ScrollListGolden", self, "ScrollListTemplate")
	self.ScrollListGolden:SetPoint("TOPLEFT", self.TabInsetFrame, "RIGHT", 4, -32)
	self.ScrollListGolden:SetPoint("BOTTOMLEFT", self.TabInsetFrame, "BOTTOMRIGHT", 4, -25)
	self.ScrollListGolden:SetWidth(283)
	MixinAndLoadScripts(self.ScrollListGolden, SkillCardsScrollMixin)

	self.ScrollListHelperFrame = CreateFrame("FRAME", "$parent.ScrollListHelperFrame", self)
	self.ScrollListHelperFrame:SetFrameLevel(self.ScrollListNormal:GetFrameLevel()+10)
	self.ScrollListHelperFrame:SetPoint("TOPLEFT", self.ScrollListNormal, "TOPLEFT", 0, 0)
	self.ScrollListHelperFrame:SetPoint("BOTTOMRIGHT", self.ScrollListGolden, "BOTTOMRIGHT", 0, 0)

	for _, tabID in ipairs(tabOrder) do
		local tab = CreateFrame("BUTTON", "$parentTab"..tabID, self, "TabButtonTemplate")
		tab:SetText(tabs[tabID].text)
		tab:SetID(tabID)
		tab:GetScript("OnLoad")(tab)
		tab:SetFrameLevel(self.TabInsetFrame.NineSlice:GetFrameLevel()+1)
		tab:SetMotionScriptsWhileDisabled(true)
		tab:SetScript("OnEnter", SkillCardsFrameMixin.OnTabEnter)
		tab:SetScript("OnLeave", SkillCardsFrameMixin.OnTabLeave)

		self["Tab"..tabID] = tab
	end

	self:LayoutVisibleTabs()

	self:CreateRarityBars()
end

function SkillCardsFrameMixin:CreateRarityBars()
	self.RarityBarContainer = CreateFrame("FRAME", "$parentRarityBarContainer", self)
	self.RarityBarContainer:SetPoint("BOTTOMLEFT", self.TabInsetFrame, "BOTTOMLEFT", 0, 36)
	self.RarityBarContainer:SetPoint("BOTTOMRIGHT", self.TabInsetFrame, "BOTTOMRIGHT", 0, 36)
	self.RarityBarContainer:SetHeight(26)
	self.RarityBarContainer:Hide()

	local bg = self.RarityBarContainer:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.5)

	self.RarityBars = {}
	local barWidth = 180
	local prevBar

	for _, info in ipairs(RARITY_BAR_QUALITIES) do
		local bar = CreateFrame("BUTTON", nil, self.RarityBarContainer)
		bar:SetSize(barWidth, 22)

		if prevBar then
			bar:SetPoint("LEFT", prevBar, "RIGHT", 4, 0)
		end

		bar.Left = bar:CreateTexture(nil, "BACKGROUND")
		bar.Left:SetAtlas("collapse-button-left", Const.TextureKit.IgnoreAtlasSize)
		bar.Left:SetSize(76, 22)
		bar.Left:SetPoint("TOPLEFT")
		bar.Left:SetPoint("BOTTOMLEFT")

		bar.Right = bar:CreateTexture(nil, "BACKGROUND")
		bar.Right:SetAtlas("collapse-button-right", Const.TextureKit.IgnoreAtlasSize)
		bar.Right:SetSize(76, 22)
		bar.Right:SetPoint("TOPRIGHT")
		bar.Right:SetPoint("BOTTOMRIGHT")

		bar.Middle = bar:CreateTexture(nil, "BACKGROUND")
		bar.Middle:SetAtlas("collapse-button-middle", Const.TextureKit.IgnoreAtlasSize)
		bar.Middle:SetPoint("TOPLEFT", bar.Left, "TOPRIGHT", -20, 0)
		bar.Middle:SetPoint("BOTTOMRIGHT", bar.Right, "BOTTOMLEFT", 20, 0)

		bar.Text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		bar.Text:SetPoint("LEFT", 8, 0)
		bar.Text:SetText(ITEM_QUALITY_COLORS[info.quality]:WrapText(info.label))

		bar.RarityGemContainer = CreateFrame("FRAME", nil, bar, "RarityGemContainerTemplate")
		bar.RarityGemContainer:SetSize(200, 16)
		bar.RarityGemContainer:SetPoint("LEFT", bar.Text, "RIGHT", 4, 0)
		bar.RarityGemContainer:SetGemSize(16)
		bar.RarityGemContainer:SetGemQuality(info.quality)
		bar.RarityGemContainer:SetOrientation({ "BOTTOMLEFT", "BOTTOMRIGHT", -2, 0 })

		self.RarityBars[info.quality] = bar
		prevBar = bar
	end

	local totalWidth = (#RARITY_BAR_QUALITIES * barWidth) + ((#RARITY_BAR_QUALITIES - 1) * 4)
	self.RarityBars[RARITY_BAR_QUALITIES[1].quality]:SetPoint("LEFT", self.RarityBarContainer, "CENTER", -(totalWidth / 2), 0)
end
