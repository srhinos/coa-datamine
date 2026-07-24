HelpMenuItemRecoveryPanelMixin = {}

local CATEGORY_CACHE_TIME = 300

local CategoryIcon = {
	[Enum.RecoveryCategory.DisenchantedItems] = "GarrMission_MissionIcon-Enchanting",
	[Enum.RecoveryCategory.DeletedCharacters] = "GarrMission_MissionIcon-Recruit",
	[Enum.RecoveryCategory.VendoredItems] = "GarrMission_MissionIcon-Provision",
	[Enum.RecoveryCategory.DeletedItems] = "GarrMission_MissionIcon-Engineering",
	[Enum.RecoveryCategory.RecylcedItems] = "GarrMission_MissionIcon-Salvage",
	[Enum.RecoveryCategory.WildCardRoll] = "GarrMission_MissionIcon-Logistics",
    [Enum.RecoveryCategory.Worldforged] = "GarrMission_MissionIcon-Exploration",
}

local CategoryString = {
	[Enum.RecoveryCategory.DisenchantedItems] = "RECOVERY_SERVICE_CATEGORY_DISENCHANTED_ITEM",
	[Enum.RecoveryCategory.DeletedCharacters] = "RECOVERY_SERVICE_CATEGORY_DELETED_CHARACTER",
	[Enum.RecoveryCategory.VendoredItems] = "RECOVERY_SERVICE_CATEGORY_VENDORED_ITEM",
	[Enum.RecoveryCategory.DeletedItems] = "RECOVERY_SERVICE_CATEGORY_DELETED_ITEM",
	[Enum.RecoveryCategory.RecylcedItems] = "RECOVERY_SERVICE_CATEGORY_MYTHIC_RECYCLING",
	[Enum.RecoveryCategory.WildCardRoll] = "RECOVERY_SERVICE_CATEGORY_WILDCARD_ROLLS",
    [Enum.RecoveryCategory.Worldforged] = "RECOVERY_SERVICE_CATEGORY_WORLDFORGED_ITEM",
}

local ConfigCategory = {
	[Enum.RecoveryCategory.DisenchantedItems] = "CONFIG_RECOVERY_DISENCHANTED_ITEM_ENABLED",
	[Enum.RecoveryCategory.DeletedCharacters] = "CONFIG_RECOVERY_DELETED_CHARACTER_ENABLED",
	[Enum.RecoveryCategory.VendoredItems] = "CONFIG_RECOVERY_VENDORED_ITEM_ENABLED",
	[Enum.RecoveryCategory.DeletedItems] = "CONFIG_RECOVERY_DELETED_ITEM_ENABLED",
	[Enum.RecoveryCategory.RecylcedItems] = "CONFIG_RECOVERY_MYTHIC_RECYCLING_ENABLED",
	[Enum.RecoveryCategory.WildCardRoll] = "CONFIG_RECOVERY_WILDCARD_ROLLS_ENABLED",
    [Enum.RecoveryCategory.Worldforged] = "CONFIG_RECOVERY_WORLDFORGED_ITEM_ENABLED",
}

local CategoryID = table.invert(CategoryString)

function HelpMenuItemRecoveryPanelMixin:OnLoad()
	self.queriedCategories = {}

	self:RegisterEvent("RECOVERY_QUERY_RESULT")
	self:RegisterEvent("RECOVERY_RESULT")

	self:SetupItemScroll()
	self:SetupTabSystem()
	
	self.Categories.Background:SetAtlas("professions-background-summarylist", Const.TextureKit.IgnoreAtlasSize)
	self.Categories.Divider:SetAtlas("help-divider", Const.TextureKit.UseAtlasSize)
	self.RecoveryScroll.Background:SetAtlas("auctionhouse-background-buy-noncommodities-market", Const.TextureKit.IgnoreAtlasSize)
	self.RecoveryScroll:GetSelectedHighlight():SetAtlas("search-select", Const.TextureKit.IgnoreAtlasSize)
	self.RecoveryScroll:GetSelectedHighlight():SetAlpha(0.8)

	self.LoadingFrame:SetFrameLevel(self:GetFrameLevel() + 20)
	self.ErrorFrame:SetFrameLevel(self:GetFrameLevel() + 20)
	
	-- hook recover to show loading frame
	hooksecurefunc(C_RecoveryService, "RecoverCategoryItemAtIndex", function()
		self.LoadingFrame:Show()
	end)
end

function HelpMenuItemRecoveryPanelMixin:OnShow()
	self:RefreshTabs()
	self:MarkAllCategoriesDirty()
	local tabID = self.Categories:GetCurrentTabID()
	if tabID then
		local tab = self.Categories:GetTabByID(tabID)
		self:UpdateLimitedCountLabel(tab.categoryID)
		self:QueryCategoryByID(tab.categoryID)
	end
	
	self.gamemodeCallback = C_GameMode:RegisterCallbackWithHandle("OnGameModeChanged",  GenerateClosure(self.RefreshTabs, self))
end

function HelpMenuItemRecoveryPanelMixin:OnHide()
	self.gamemodeCallback:Unregister()
end

function HelpMenuItemRecoveryPanelMixin:RefreshTabs()
	local draftEnabled = C_GameMode:IsGameModeActive(Enum.GameMode.Draft)
	local wildcardEnabled = C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)

	if draftEnabled then
		if self.HandOfFateTabID then
			self.Categories:ShowTabID(self.HandOfFateTabID)
		end
	elseif self.HandOfFateTabID then
		self.Categories:HideTabID(self.HandOfFateTabID)
	end
	
	if wildcardEnabled then
		if self.ScrollOfFortuneTabID then
			self.Categories:ShowTabID(self.ScrollOfFortuneTabID)
		end
		if self.WildCardRollTabID then
			self.Categories:ShowTabID(self.WildCardRollTabID)
		end
	else
		if self.ScrollOfFortuneTabID then
			self.Categories:HideTabID(self.ScrollOfFortuneTabID)
		end
		if self.WildCardRollTabID then
			self.Categories:HideTabID(self.WildCardRollTabID)
		end
	end
	
	if wildcardEnabled or draftEnabled then
		if self.SkillCardTabID then
			self.Categories:ShowTabID(self.SkillCardTabID)
		end
	elseif self.SkillCardTabID then
		self.Categories:HideTabID(self.SkillCardTabID)
	end
	
	for _, tab in self.Categories:EnumerateTabs() do
		local categoryID = tab.categoryID
		local config = ConfigCategory[categoryID]
		if config then
			tab:SetTabEnabled(C_Config.GetBoolConfig(config), FEATURE_UNAVAILABLE_AT_THIS_TIME)
		end
	end
end

function HelpMenuItemRecoveryPanelMixin:SetupItemScroll()
	self.RecoveryScroll:SetTemplate("RecoveryItemTemplate")
	self.RecoveryScroll:SetGetNumResultsFunction(function()
		if self.currentCategory then
			return C_RecoveryService.GetNumItemsInCategory(self.currentCategory) or 0
		end
		return 0
	end)
end

function HelpMenuItemRecoveryPanelMixin:SetupTabSystem()
	local recoveryCategories = table.invert(Enum.RecoveryCategory)
	local tabSystem = self.Categories
	MixinAndLoadScripts(tabSystem, "TabSystemMixin")

	tabSystem:SetTabSelectedSound(SOUNDKIT.UCHARACTERSHEETTAB)
	tabSystem:SetTabPoint("TOP", 0, 0)
	tabSystem:SetTabLayout(function(tabIndex, tab, previousTab)
		tab:SetPoint("TOP", previousTab, "BOTTOM", 0, -8)
	end)
	tabSystem:SetTabTemplate("HelpMenuRecoveryTabTemplate")
	tabSystem:RegisterCallback("OnTabSelected", self.OnTabSelected, self)

	local tab
	for categoryID in pairs(recoveryCategories) do
		tab = tabSystem:AddTab(_G["RECOVERY_CATEGORY"..categoryID])
		tab:SetIcon(CategoryIcon[categoryID], 42)
		tab.categoryID = categoryID

		local showTab = true
		if (categoryID == Enum.RecoveryCategory.WildCardRoll) then
			showTab = C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)
			self.WildCardRollTabID = tab:GetTabID()
		end
		
		if showTab then
			tabSystem:ShowTabID(tab:GetTabID())
		else
			tabSystem:HideTabID(tab:GetTabID())
		end
	end
end

function HelpMenuItemRecoveryPanelMixin:QueryCategoryByID(categoryID)
	local category = self:GetCategoryName(categoryID)
	if not category then
		C_Logger.Error("No category found for ID: %s", (categoryID or "nil"))
		return
	end
	self:MarkCategoryQueried(category)
	self.LoadingFrame:Show()
	C_RecoveryService.QueryCategory(category)
end

function HelpMenuItemRecoveryPanelMixin:GetCategoryName(categoryID)
	return CategoryString[categoryID]
end

function HelpMenuItemRecoveryPanelMixin:GetCategoryID(category)
	return CategoryID[category]
end

function HelpMenuItemRecoveryPanelMixin:GetCurrentCategory()
	return self.currentCategory
end

function HelpMenuItemRecoveryPanelMixin:ShouldQueryCategory(category)
	local timeSinceQueried = category and self.queriedCategories[category]
	if not timeSinceQueried or timeSinceQueried:GreaterThan(CATEGORY_CACHE_TIME) then
		return true
	end
end

function HelpMenuItemRecoveryPanelMixin:MarkCategoryQueried(category)
	if not category then
		return C_Logger.Error("Got nil when trying to MarkCategoryQueried")
	end

	if not self.queriedCategories[category] then
		self.queriedCategories[category] = TimeSince:Now()
	else
		self.queriedCategories[category]:ResetToNow()
	end
end

function HelpMenuItemRecoveryPanelMixin:MarkCategoryDirty(category)
	if not category then
		return C_Logger.Error("Got nil when trying to MarkCategoryDirty")
	end

	if self.queriedCategories[category] then
		self.queriedCategories[category]:ResetTo(-CATEGORY_CACHE_TIME-1)
	end
end

function HelpMenuItemRecoveryPanelMixin:MarkAllCategoriesDirty()
	for category in pairs(self.queriedCategories) do
		self:MarkCategoryDirty(category)
	end
end

function HelpMenuItemRecoveryPanelMixin:ResetSearch()
	self.RecoveryScroll.Search:SetText("")
	self:UpdateFilter()
end

function HelpMenuItemRecoveryPanelMixin:UpdateLimitedCountLabel(categoryID)
	local label = self.RecoveryScroll and self.RecoveryScroll.LimitedCountLabel
	if not label then
		return
	end

	local textKey = "HELP_RECOVERY_LIMITED_COUNT_CATEGORY" .. (categoryID or "")
	label:SetText(_G[textKey] or HELP_RECOVERY_LIMITED_COUNT)
end

function HelpMenuItemRecoveryPanelMixin:OnTabSelected(tabID, tab)
	self.RecoveryScroll:CollapseExpandedButton()
	self.RecoveryScroll:ScrollToBegin()
	self.RecoveryScroll:SetSelectedIndex(nil, ScrollListMixin.UpdateType.OnlyNewIndex)
	self.currentCategory = self:GetCategoryName(tab.categoryID)
	self:UpdateLimitedCountLabel(tab.categoryID)
	if self:ShouldQueryCategory(self.currentCategory) then
		self:QueryCategoryByID(tab.categoryID)
	else
		self:ResetSearch()
	end
end

function HelpMenuItemRecoveryPanelMixin:UpdateFilter()
	local text = self.RecoveryScroll.Search:GetText()
	if not text then
		text = ""
	else
		text = text:lower():trim()
	end
	
	local searchChanged = self.currentSearch ~= text
	self.currentSearch = text
	C_RecoveryService.UpdateFilter(self.currentCategory, text)
	if searchChanged then
		self.RecoveryScroll:CollapseExpandedButton()
		self.RecoveryScroll:SetSelectedIndex(nil, ScrollListMixin.UpdateType.Always)
	else
		self.RecoveryScroll:RefreshScrollFrame()
	end
end

function HelpMenuItemRecoveryPanelMixin:RECOVERY_QUERY_RESULT(category)
	self.LoadingFrame:Hide()
	local categoryID = self:GetCategoryID(category)
	if not categoryID then
		C_Logger.Error("Could not find a category ID for %s", (category or "nil"))
		return
	end

	C_Logger.Info("Successfully Queried Recovery %s", category)
	if category == self.currentCategory then
		self:ResetSearch()
	end
end

function HelpMenuItemRecoveryPanelMixin:RECOVERY_RESULT(category, result)
	self.LoadingFrame:Hide()
	C_Logger.Info("Recovery Result: %s for %s", result, category)
	
	local recoveryIndex = result and result:find("RECOVERY_")
	local recoveryMessage = recoveryIndex and result and result:sub(recoveryIndex)

	if not recoveryMessage then
		C_Logger.Error("Could not find a recovery message in %s", (result or "nil"))
		self.ErrorFrame:SetText(RECOVERY_FAILED, _G[result] or result)
		self.ErrorFrame:Show()
		return
	end

	if recoveryMessage == "RECOVERY_OK" then
		self.RecoveryScroll:CollapseExpandedButton()
		self.RecoveryScroll:SetSelectedIndex(nil, ScrollListMixin.UpdateType.Always)
	else
		self.ErrorFrame:SetText(RECOVERY_FAILED, _G[recoveryMessage] or _G[result] or result)
		self.ErrorFrame:Show()
	end
end 
