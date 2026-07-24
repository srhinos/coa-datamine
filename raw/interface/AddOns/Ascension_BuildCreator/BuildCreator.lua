local AddonName = ...
local AddonVersion = tonumber(GetAddOnMetadata(AddonName, "Version"))

local DefaultBuildCreatorSaved = {
	SavedBuilds = {}
}

BuildCreatorMixin = {}

local BuildCategories = {}

local CreateCategories = {
	Enum.BuildCreateCategory.Import,
	Enum.BuildCreateCategory.CurrentBuild,
}

function BuildCreatorMixin:OnLoad()
	PortraitFrame_SetIcon(self, "Interface\\Icons\\ability_priest_angelicfeather")
	PortraitFrame_SetTitle(self, HERO_ARCHITECT)
	self.CloseButton:SetScript("OnClick", function()
		HideUIPanel(Collections)
	end)

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("BUILD_CREATOR_CATEGORY_RESULT")
	self:RegisterEvent("BUILD_CREATOR_BUILD_RESULT")
	self:RegisterEvent("BUILD_CREATOR_ACTIVATE_RESULT")
	self:RegisterEvent("BUILD_CREATOR_DEACTIVATE_RESULT")
	self:RegisterEvent("BUILD_CREATOR_SAVE_RESULT")
	self:RegisterEvent("BUILD_CREATOR_CREATE_RESULT")
	self:RegisterEvent("BUILD_CREATOR_DELETE_RESULT")

	self.BuildScroll:SetTemplate("BuildListItemTemplate")
	self.BuildScroll:SetGetNumResultsFunction(C_BuildCreator.GetNumBuilds)
	
	local isWildCard = C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)

	if not isWildCard then
		tinsert(BuildCategories, Enum.BuildCategory.BuildDraft)
		tinsert(BuildCategories, Enum.BuildCategory.Leveling)
		tinsert(CreateCategories, Enum.BuildCreateCategory.Leveling)
	else
		tinsert(BuildCategories, Enum.BuildCategory.BuildDraftEndGamePvE)
		tinsert(BuildCategories, Enum.BuildCategory.BuildDraftEndGamePvP)
	end

	local maxLevel = GetMaxLevel()
	if maxLevel == 60 then
		tinsert(BuildCategories, Enum.BuildCategory.Level60PvE)
		tinsert(BuildCategories, Enum.BuildCategory.Level60PvP)
		tinsert(CreateCategories, Enum.BuildCreateCategory.Level60PvE)
		tinsert(CreateCategories, Enum.BuildCreateCategory.Level60PvP)
	elseif maxLevel == 70 then
		tinsert(BuildCategories, Enum.BuildCategory.Level70PvE)
		tinsert(BuildCategories, Enum.BuildCategory.Level70PvP)
		tinsert(CreateCategories, Enum.BuildCreateCategory.Level70PvE)
		tinsert(CreateCategories, Enum.BuildCreateCategory.Level70PvP)
	end

	if C_Player:GetLevel() == maxLevel or C_Player:IsGM() or isWildCard then
		tinsert(BuildCategories, Enum.BuildCategory.None)
		tinsert(BuildCategories, Enum.BuildCategory.History)
	end

	self.categories = BuildCategories
	self.isCreateMode = false
	self.CategoryScroll:SetTemplate("BuildListCategoryListItemTemplate")
	self.CategoryScroll:SetGetNumResultsFunction(function() return #self.categories end)
	self.CategoryScroll:GetSelectedHighlight():SetAtlas("buildcreator-category-highlight", Const.TextureKit.IgnoreAtlasSize)
	self.CategoryScroll:GetSelectedHighlight():SetBlendMode("ADD")
	self.CategoryScroll.Artwork:SetAtlas("buildcreator-category-art", Const.TextureKit.IgnoreAtlasSize)
	
	self.sort = { [Enum.BuildSort.RatingDescending] = true }
	self.Filter:RegisterCallback("OnFilterChanged", self.OnFilterChanged, self)
	self:InitializeFilterDropDown()
	self.Sorting:Initialize(GenerateClosure(self.InitializeSortDropDown, self), GenerateClosure(self.SetSorting, self, Enum.BuildSort.RatingDescending))
	
	self.pendingCallback = {}
end 

function BuildCreatorMixin:GetCategoryAtIndex(index)
	return self.categories[index]
end

function BuildCreatorMixin:GetCurrentCategory()
	return self.category
end

function BuildCreatorMixin:OnHide()
	StaticPopup_Hide("BUILD_CREATOR_SET_COMMENT")
	StaticPopup_Hide("BUILD_CREATOR_SET_ENCHANT_LEVEL")
end

function BuildCreatorMixin:ShowBuildList()
	self.CategoryScroll:Show()
	self.BuildScroll:Show()
	self.BuildScroll:SetSelectedIndex()
	self.SearchBox:Show()
	self.Filter:Show()
	self.Sorting:Show()
	self.BuildViewPanel:Hide()
	self.EditableBuildViewPanel:Hide()
	self.Filter:ClearFilters()
	if not self.category then
		self.CategoryScroll:SetSelectedIndex(2, ScrollListMixin.UpdateType.AlwaysSimulateClick)
	else
		for index, category in ipairs(self.categories) do
			if category == self.category then
				self.CategoryScroll:SetSelectedIndex(index)
			end
		end
	end
end

function BuildCreatorMixin:HideBuildList()
	self.CategoryScroll:Hide()
	self.BuildScroll:Hide()
	self.BuildScroll:SetSelectedIndex()
	self.SearchBox:Hide()
	self.Filter:Hide()
	self.Sorting:Hide()
	self.BuildViewPanel:Hide()
	self.EditableBuildViewPanel:Hide()
end

function BuildCreatorMixin:ShowCreateCategories()
	self.isCreateMode = true
	self.categories = table.Copy(CreateCategories)
	local showTip
	if BuildCreatorSaved and next(BuildCreatorSaved.SavedBuilds) then
		table.insert(self.categories, 1, Enum.BuildCreateCategory.SavedBuild)
		showTip = not self.HasSeenSavedBuildTip
	end
	self.CategoryScroll:RefreshScrollFrame()

	if showTip then
		local tip = {
			text = TIP_RESTORE_WIP_BUILD,
			textJustifyH = "CENTER",
			targetPoint = HelpTip.Point.BottomEdgeCenter,
			buttonStyle = HelpTip.ButtonStyle.GotIt,
			highlightTarget = HelpTip.TargetType.Box,
			strata = "TOOLTIP",
		}
		HelpTip:Show(self.CategoryScroll.ScrollFrame, tip, self.CategoryScroll.ScrollFrame.buttons[1])
		self.HasSeenSavedBuildTip = true -- once per session should be ok?
	end
end

function BuildCreatorMixin:ShowBuildCategories()
	self.isCreateMode = false
	self.categories = table.Copy(BuildCategories)
	tinsert(self.categories, 1, Enum.BuildCategory.ActiveBuild)
	self.CategoryScroll:RefreshScrollFrame()
end

function BuildCreatorMixin:ToggleCreate()
	if self.isCreateMode then
		self:ShowBuildCategories()
	else
		self:ShowCreateCategories()
	end
	self.ToggleCreateButton:SetText(self.isCreateMode and BROWSE_BUILDS or CREATE_BUILD)
end

function BuildCreatorMixin:OpenBuildEditor()
	self:HideBuildList()
	if not self.EditableBuildViewPanel:IsShown() then
		self.EditableBuildViewPanel.deserializeNext = true
		self.EditableBuildViewPanel:Show()
	else
		self.EditableBuildViewPanel:UpdatePendingBuild(true)
	end
end

function BuildCreatorMixin:SelectCategory(category)
	if category == Enum.BuildCategory.History then
		self.BuildScroll:SetGetNumResultsFunction(C_BuildCreator.GetNumBookmarkedBuilds)
		self.lastQueried = Enum.BuildCategory.History
	else
		self.BuildScroll:SetGetNumResultsFunction(C_BuildCreator.GetNumBuilds)
	end

	if category == Enum.BuildCategory.ActiveBuild then
		self:ViewBuildID(BuildCreatorUtil.GetActiveBuildID())
		return
	end

	if category == Enum.BuildCategory.Featured then
		category = Enum.BuildCategory.None
		self.Filter:SetToSingleFilter(Enum.BuildFilter.Featured)
	elseif category == Enum.BuildCategory.MyBuilds then
		category = Enum.BuildCategory.None
		self.Filter:SetToSingleFilter(Enum.BuildFilter.Owned)
	end

	if self.lastQueried == category then
		-- skip event because we want to return to where we were scrolled to / what search & filters we had set.
		self.category = category
		self:ShowBuildList()
		self:UpdateSearch()
		return
	end
	C_BuildCreator.QueryAllBuilds(category)
	self.lastQueried = category
	self:ShowLoading()
end

function BuildCreatorMixin:CreateBuild(category, deserialize)
	if category == Enum.BuildCreateCategory.Import then
		-- import build will specify to deserialize from popup
		if not deserialize then
			StaticPopup_Show("BUILD_CREATOR_IMPORT_BUILD")
			return
		else
			-- guess category for imports
			local maxLevel = GetMaxLevel()
			if maxLevel > 60 then
				category = Enum.BuildCreateCategory.Level70PvE
			else
				category = Enum.BuildCreateCategory.Level60PvE
			end
		end
	elseif category == Enum.BuildCreateCategory.CurrentBuild then
		C_BuildEditor.DiscardPendingBuild()
		self.EditableBuildViewPanel:ImportCurrentBuild()
		-- guess category for current build
		local maxLevel = GetMaxLevel()
		if maxLevel > 60 then
			category = Enum.BuildCreateCategory.Level70PvE
		else
			category = Enum.BuildCreateCategory.Level60PvE
		end
	elseif category == Enum.BuildCreateCategory.SavedBuild then
		-- saved builds will load the saved category.
		if not self.SavedBuildDropDown then
			local dropdown = CreateFrame("Frame", "BuildCreatorSavedBuildDropDown", self, "UIDropDownMenuTemplate")
			UIDropDownMenu_Initialize(dropdown, GenerateClosure(self.InitializeSavedBuildDropDown, self), "MENU")
			self.SavedBuildDropDown = dropdown
		end
		ToggleDropDownMenu(1, nil, self.SavedBuildDropDown, "cursor", 0, 0)
		return
	else
		-- categories above handle their own discarding
		-- saved builds will pass deserialize = true
		if not deserialize then
			C_BuildEditor.DiscardPendingBuild()
		end
	end
	self.category = category
	self.EditableBuildViewPanel:SetCategory(category)
	self:OpenBuildEditor()
	BuildCreatorUtil.ReleaseHeldSpell()
end

function BuildCreatorMixin:ConvertBuildEditorToCategory(category)
	local convertCategory = function()
		self:CreateBuild(category, true)
		local build = C_BuildEditor.GetPendingBuild()
		if category == Enum.BuildCreateCategory.Level60PvE or category == Enum.BuildCreateCategory.Level60PvP then
			for _, spell in ipairs(build.Spells) do
				C_BuildEditor.SetSpellLevel(spell.Spell, 60)
			end
		elseif category == Enum.BuildCreateCategory.Level70PvE or category == Enum.BuildCreateCategory.Level70PvP then
			for _, spell in ipairs(build.Spells) do
				C_BuildEditor.SetSpellLevel(spell.Spell, 70)
			end
		elseif category == Enum.BuildCreateCategory.Leveling then
			local maxLevel = GetMaxLevel()
			for _, spell in ipairs(build.Spells) do
				C_BuildEditor.SetSpellLevel(spell.Spell, maxLevel)
			end
		end
	end
	
	StaticPopup_Show("BUILD_CREATOR_CHANGE_BUILD_CATEGORY", nil, nil, convertCategory)
end

function BuildCreatorMixin:OnShow()
	C_Quest:SendPathToAscensionEvent("ACTION_OPEN_HERO_ARCHITECT")
	self:ShowBuildCategories()
	if not self.category then
		if BuildCreatorUtil.GetActiveBuildID() then
			self:ViewBuildID(BuildCreatorUtil.GetActiveBuildID())
		else
			self:ShowBuildList()
		end
	end
end

function BuildCreatorMixin:OnFilterChanged()
	self:UpdateSearch()
end

function BuildCreatorMixin:ApplyDefaultClassFilter()
	local filters = self.Filter:GetFilter()
	filters = table.Copy(filters)
	-- nasty hack to make it auto select your current class.
	if C_Player:IsHero() then
		filters["FILTER_CLASS_HERO"] = true
	else
		-- always filter to my class unless i have set to another class.
		local class = select(2, UnitClass("player"))
		if not self.Filter:IsFilteredFind("FILTER_CLASS_") then
			if class == "PROPHET" then
				filters["FILTER_CLASS_VENOMANCER"] = true
			elseif class == "FLESHWARDEN" then
				filters["FILTER_CLASS_FILTER_CLASS_KNIGHT_OF_XOROTH"] = true
			elseif class == "WILDWALKER" then
				filters["FILTER_CLASS_PRIMALIST"] = true
			elseif class == "DEATHKNIGHT" then
				filters["FILTER_CLASS_DEATH_KNIGHT"] = true
			else
				filters["FILTER_CLASS_"..class] = true
			end
		end
	end
	return filters
end

function BuildCreatorMixin:UpdateSearch()
	self.Sorting.ClearFiltersButton:SetShown(not self.sort[Enum.BuildSort.RatingDescending])
	if self.BuildScroll:IsVisible() then
		local text = self.SearchBox:GetText()
		
		C_BuildCreator.UpdateFilter(text, self:ApplyDefaultClassFilter(), self.sort)
		self.BuildScroll:RefreshScrollFrame()
	end
end

function BuildCreatorMixin:InitializeFilterDropDown()
	local filter = self.Filter
	filter:AddHeader(GENERAL_LABEL)

	filter:AddFilterOption(Enum.BuildFilter.Featured, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Featured))
	filter:AddFilterOption(Enum.BuildFilter.Owned, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Owned))
	filter:AddFilterOption(Enum.BuildFilter.Recent, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Recent))
	
	filter:AddOptionSpacer()

	filter:AddHeader(ROLE)

	local damageInfo = filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Damage, ROLE_COLORS["DAMAGE"], ROLE_ATLAS["DAMAGER"].."-micro")
	damageInfo.func = function()
		-- this is called before the filter sets the current filter
		-- so if were currently not enabled, we are enabling this filter
		if not filter:IsFiltered(Enum.BuildFilter.Damage) then
			filter:SetFilter(Enum.BuildFilter.Tank, false)
			filter:SetFilter(Enum.BuildFilter.Healer, false)
		end
	end
	filter:AddFilterOption(Enum.BuildFilter.Damage, damageInfo)

	local tankInfo = filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Tank, ROLE_COLORS["TANK"], ROLE_ATLAS["TANK"].."-micro")
	tankInfo.func = function()
		-- this is called before the filter sets the current filter
		-- so if were currently not enabled, we are enabling this filter
		if not filter:IsFiltered(Enum.BuildFilter.Tank) then
			filter:SetFilter(Enum.BuildFilter.Damage, false)
			filter:SetFilter(Enum.BuildFilter.Healer, false)
		end
	end
	filter:AddFilterOption(Enum.BuildFilter.Tank, tankInfo)

	local healerInfo = filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Healer, ROLE_COLORS["HEALER"], ROLE_ATLAS["HEALER"].."-micro")
	healerInfo.func = function()
		-- this is called before the filter sets the current filter
		-- so if were currently not enabled, we are enabling this filter
		if not filter:IsFiltered(Enum.BuildFilter.Healer) then
			filter:SetFilter(Enum.BuildFilter.Damage, false)
			filter:SetFilter(Enum.BuildFilter.Tank, false)
		end
	end
	filter:AddFilterOption(Enum.BuildFilter.Healer, healerInfo)
	
	filter:AddOptionSpacer()

	filter:AddHeader(COMPLEXITY_LABEL)

	filter:AddFilterOption(Enum.BuildFilter.Standard, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Standard, BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Standard], BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Standard]))
	filter:AddFilterOption(Enum.BuildFilter.Intermediate, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Intermediate, BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Intermediate], BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Intermediate]))
	filter:AddFilterOption(Enum.BuildFilter.Advanced, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Advanced, BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Advanced], BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Advanced]))
	filter:AddFilterOption(Enum.BuildFilter.Expert, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Expert, BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Expert], BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Expert]))
	filter:AddFilterOption(Enum.BuildFilter.Impossible, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Impossible, BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Impossible], BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Impossible]))

	filter:AddOptionSpacer()

	if C_Player:IsHero() then
		filter:AddHeader(PRIMARY_STAT)

		filter:AddFilterOption(Enum.BuildFilter.Strength, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Strength, STAT_COLORS["Strength"], PRIMARY_STAT_ATLAS["Strength"]))
		filter:AddFilterOption(Enum.BuildFilter.Agility, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Agility, STAT_COLORS["Agility"], PRIMARY_STAT_ATLAS["Agility"]))
		filter:AddFilterOption(Enum.BuildFilter.Intellect, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Intellect, STAT_COLORS["Intellect"], PRIMARY_STAT_ATLAS["Intellect"]))
		filter:AddFilterOption(Enum.BuildFilter.Spirit, filter:CreateFilterInfo("BUILD_"..Enum.BuildFilter.Spirit, STAT_COLORS["Spirit"], PRIMARY_STAT_ATLAS["Spirit"]))
	elseif C_Player:IsDefaultClass() then
		-- class filter
		filter:AddHeader(CLASS)

		-- Default classes
		filter:AddFilterOption("FILTER_CLASS_WARRIOR", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("WARRIOR"), nil, "groupfinder-icon-class-warrior"))
		filter:AddFilterOption("FILTER_CLASS_PALADIN", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("PALADIN"), nil, "groupfinder-icon-class-paladin"))
		filter:AddFilterOption("FILTER_CLASS_HUNTER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("HUNTER"), nil, "groupfinder-icon-class-hunter"))
		filter:AddFilterOption("FILTER_CLASS_ROGUE", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("ROGUE"), nil, "groupfinder-icon-class-rogue"))
		filter:AddFilterOption("FILTER_CLASS_PRIEST", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("PRIEST"), nil, "groupfinder-icon-class-priest"))
		filter:AddFilterOption("FILTER_CLASS_DEATH_KNIGHT", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("DEATHKNIGHT"), nil, "groupfinder-icon-class-deathknight"))
		filter:AddFilterOption("FILTER_CLASS_SHAMAN", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("SHAMAN"), nil, "groupfinder-icon-class-shaman"))
		filter:AddFilterOption("FILTER_CLASS_MAGE", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("MAGE"), nil, "groupfinder-icon-class-mage"))
		filter:AddFilterOption("FILTER_CLASS_WARLOCK", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("WARLOCK"), nil, "groupfinder-icon-class-warlock"))
		filter:AddFilterOption("FILTER_CLASS_DRUID", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("DRUID"), nil, "groupfinder-icon-class-druid"))
	elseif C_Player:IsCustomClass() then
		-- class filter
		filter:AddHeader(CLASS)

		-- Custom classes
		filter:AddFilterOption("FILTER_CLASS_BARBARIAN", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("BARBARIAN"), nil, "groupfinder-icon-class-barbarian"))
		filter:AddFilterOption("FILTER_CLASS_WITCH_DOCTOR", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("WITCHDOCTOR"), nil, "groupfinder-icon-class-witchdoctor"))
		filter:AddFilterOption("FILTER_CLASS_DEMON_HUNTER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("DEMONHUNTER"), nil, "groupfinder-icon-class-demonhunter"))
		filter:AddFilterOption("FILTER_CLASS_WITCH_HUNTER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("WITCHHUNTER"), nil, "groupfinder-icon-class-witchhunter"))
		filter:AddFilterOption("FILTER_CLASS_STORMBRINGER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("STORMBRINGER"), nil, "groupfinder-icon-class-stormbringer"))
		filter:AddFilterOption("FILTER_CLASS_KNIGHT_OF_XOROTH", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("FLESHWARDEN"), nil, "groupfinder-icon-class-fleshwarden"))
		filter:AddFilterOption("FILTER_CLASS_GUARDIAN", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("GUARDIAN"), nil, "groupfinder-icon-class-guardian"))
		filter:AddFilterOption("FILTER_CLASS_MONK", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("MONK"), nil, "groupfinder-icon-class-monk"))
		filter:AddFilterOption("FILTER_CLASS_SON_OF_ARUGAL", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("SONOFARUGAL"), nil, "groupfinder-icon-class-sonofarugal"))
		filter:AddFilterOption("FILTER_CLASS_RANGER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("RANGER"), nil, "groupfinder-icon-class-ranger"))
		filter:AddFilterOption("FILTER_CLASS_CHRONOMANCER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("CHRONOMANCER"), nil, "groupfinder-icon-class-chronomancer"))
		filter:AddFilterOption("FILTER_CLASS_NECROMANCER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("NECROMANCER"), nil, "groupfinder-icon-class-necromancer"))
		filter:AddFilterOption("FILTER_CLASS_PYROMANCER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("PYROMANCER"), nil, "groupfinder-icon-class-pyromancer"))
		filter:AddFilterOption("FILTER_CLASS_CULTIST", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("CULTIST"), nil, "groupfinder-icon-class-cultist"))
		filter:AddFilterOption("FILTER_CLASS_STARCALLER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("STARCALLER"), nil, "groupfinder-icon-class-starcaller"))
		filter:AddFilterOption("FILTER_CLASS_SUN_CLERIC", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("SUNCLERIC"), nil, "groupfinder-icon-class-suncleric"))
		filter:AddFilterOption("FILTER_CLASS_TINKER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("TINKER"), nil, "groupfinder-icon-class-tinker"))
		filter:AddFilterOption("FILTER_CLASS_VENOMANCER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("PROPHET"), nil, "groupfinder-icon-class-prophet"))
		filter:AddFilterOption("FILTER_CLASS_REAPER", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("REAPER"), nil, "groupfinder-icon-class-reaper"))
		filter:AddFilterOption("FILTER_CLASS_PRIMALIST", filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName("WILDWALKER"), nil, "groupfinder-icon-class-wildwalker"))
	end
end

function BuildCreatorMixin:SetSorting(sort)
	wipe(self.sort)
	self.sort[sort] = true
	self:UpdateSearch()
end

local function CreateSortInfo(self, key)
	local info = UIDropDownMenu_CreateInfo()
	info.text = _G["BUILD_"..key]
	info.arg1 = key
	info.checked = self.sort[key]
	info.func = function()
		self:SetSorting(key)
	end
	UIDropDownMenu_AddButton(info)
end

function BuildCreatorMixin:InitializeSortDropDown(dropdown, level, menuList)
	if not self.Sorting:IsVisible() then return end
	local info
	info = UIDropDownMenu_CreateInfo()
	info.isTitle = true
	info.text = BUILD_SORT_RATING
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, level)

	CreateSortInfo(self, Enum.BuildSort.RatingDescending)
	CreateSortInfo(self, Enum.BuildSort.RatingAscending)

	UIDropDownMenu_AddSpace(level)

	info = UIDropDownMenu_CreateInfo()
	info.isTitle = true
	info.text = BUILD_SORT_DATE
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, level)

	CreateSortInfo(self, Enum.BuildSort.DateDescending)
	CreateSortInfo(self, Enum.BuildSort.DateAscending)
end

function BuildCreatorMixin:ShowLoading(text, subtext)
	self:HideError()
	self.Loading:Show()
	self.Loading:SetText(text or "", subtext or "")
end

function BuildCreatorMixin:HideLoading()
	self.Loading:Hide()
end

function BuildCreatorMixin:ShowError(text, subtext)
	self:HideLoading()
	self.Error:Show()
	self.Error:SetText(text or "", subtext or "")
end

function BuildCreatorMixin:HideError()
	self.Error:Hide()
end

function BuildCreatorMixin:ViewBuild(build)
	self:HideBuildList()
	self.BuildViewPanel:Show()
	self.BuildViewPanel:SetBuild(build)
end

function BuildCreatorMixin:ViewBuildID(buildID)
	local build = C_BuildCreator.GetBuild(buildID)
	if build then
		return self:ViewBuild(build)
	end
	self:ShowLoading()
	C_BuildCreator.QueryBuild(buildID)
end

function BuildCreatorMixin:ContinueOnLoad(buildID, callback)
	local build = C_BuildCreator.GetBuild(buildID)
	if build then
		callback(build)
		return
	end
	if not self.pendingCallback[buildID] then
		self:ShowLoading()
		self.pendingCallback[buildID] = self.pendingCallback[buildID] or {}
		tinsert(self.pendingCallback[buildID], callback)
		C_BuildCreator.QueryBuild(buildID)
	end
end

function BuildCreatorMixin:PromptPublishBuild()
	local build = C_BuildEditor.GetPendingBuild()
	if build then
		local parentCategory = BuildCreatorUtil.GetParentCategory(build.Category)
		local category
		if parentCategory then
			category = _G["BUILDCREATOR_CATEGORY_" .. parentCategory:upper()] .. " " .. _G["BUILDCREATOR_CATEGORY_" .. build.Category:upper()]
		else
			category = _G["BUILDCREATOR_CATEGORY_" .. build.Category:upper()]
		end
		StaticPopup_Show("BUILD_CREATOR_PUBLISH_BUILD", build.Name, category)
	end
end

function BuildCreatorMixin:PublishBuild()
	local publishSent, failReason = C_BuildEditor.PublishBuild()
	if publishSent then
		self:ShowLoading(PUBLISHING_BUILD)
	else
		self:ShowError(PUBLISH_BUILD_FAILED, _G[failReason] or failReason)
	end
end

function BuildCreatorMixin:PromptEditBuild()
	if self.BuildViewPanel:IsVisible() then
		StaticPopup_Show("BUILD_CREATOR_EDIT_BUILD", self.BuildViewPanel.build.Name, nil, self.BuildViewPanel.build)
	end
end

function BuildCreatorMixin:PromptDeleteBuild()
	if self.BuildViewPanel:IsVisible() then
		StaticPopup_Show("BUILD_CREATOR_DELETE_BUILD", self.BuildViewPanel.build.Name, nil, self.BuildViewPanel.build.ID)
	end
end

function BuildCreatorMixin:EditBuild(build)
	self.category = build.Category
	self.EditableBuildViewPanel:SetCategory(build.Category)
	C_BuildEditor.EditBuild(build.ID)
	self:OpenBuildEditor()
	BuildCreatorUtil.ReleaseHeldSpell()
end

function BuildCreatorMixin:DeleteBuild(buildID)
	local success, failReason = C_BuildCreator.DeleteBuild(buildID)
	if success then
		self:ShowLoading()
	else
		self:ShowError(DELETE_BUILD_FAILED, _G[failReason] or failReason)
	end
end

function BuildCreatorMixin:SerializePendingBuild()
	local build = C_BuildEditor.GetPendingBuild()
	if build then
		if build.Name:len() > 0 and build.Name ~= "Build Name" then
			local serializedBuild = C_Serialize:SerializeCompressForPrint(build)
			if serializedBuild then
				BuildCreatorSaved.SavedBuilds[build.Name] = serializedBuild
			end
		end
	end
end

function BuildCreatorMixin:InitializeSavedBuildDropDown(dropdown, level, menuList)
	if not BuildCreatorSaved then return end

	local info
	if menuList then
		info = UIDropDownMenu_CreateInfo()
		info.isTitle = true
		info.text = menuList
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.text = EDIT_BUILD
		info.notCheckable = true
		info.func = function()
			self:RestoreSavedBuild(menuList)
		end
		UIDropDownMenu_AddButton(info, level)
		
		info = UIDropDownMenu_CreateInfo()
		info.text = DELETE
		info.notCheckable = true
		info.func = function()
			StaticPopup_Show("BUILD_CREATOR_DELETE_SAVED_BUILD", menuList, nil, function()
				self:DiscardSavedBuild(menuList)
				CloseDropDownMenus()
			end)
		end
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.text = CLOSE
		info.func = function() CloseDropDownMenus(level) end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)
		return
	end

	info = UIDropDownMenu_CreateInfo()
	info.isTitle = true
	info.text = BUILDCREATOR_CREATEBUTTON_SAVEDBUILD
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, level)

	for savedBuild in pairs(BuildCreatorSaved.SavedBuilds) do
		info = UIDropDownMenu_CreateInfo()
		info.text = savedBuild
		info.func = function()
			self:RestoreSavedBuild(savedBuild)
		end
		info.menuList = savedBuild
		info.hasArrow = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)
	end

	info = UIDropDownMenu_CreateInfo()
	info.text = CLOSE
	info.func = function() CloseDropDownMenus(level) end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, level)
end

function BuildCreatorMixin:DiscardSavedBuild(name)
	BuildCreatorSaved.SavedBuilds[name] = nil
end

function BuildCreatorMixin:RestoreSavedBuild(name)
	local build = BuildCreatorSaved.SavedBuilds[name]
	if not build then
		return
	end
	
	local deserializedBuild = C_Serialize:DeserializeDecompressFromPrint(build)
	if not deserializedBuild then
		return
	end
	
	C_BuildEditor.DiscardPendingBuild()
	C_BuildEditor.SetName(deserializedBuild.Name)
	C_BuildEditor.SetIcon(deserializedBuild.Icon)
	C_BuildEditor.SetCategory(deserializedBuild.Category)
	C_BuildEditor.SetDescription(deserializedBuild.Description)
	C_BuildEditor.SetRoles(deserializedBuild.Roles)
	C_BuildEditor.SetPrimaryStat(deserializedBuild.PrimaryStat)
	C_BuildEditor.SetDifficultyRating(deserializedBuild.DifficultyRating)
	
	for _, spell in ipairs(deserializedBuild.Spells) do
		C_BuildEditor.AddSpell(spell)
	end
	
	for _, enchant in ipairs(deserializedBuild.RandomEnchants) do
		C_BuildEditor.AddRandomEnchant(enchant)
	end
	
	for _, armor in ipairs(deserializedBuild.ArmorTypes) do
		C_BuildEditor.AddArmorType(armor)
	end

	for _, weapon in ipairs(deserializedBuild.WeaponTypes) do
		C_BuildEditor.AddWeaponType(weapon)
	end

	self:CreateBuild(deserializedBuild.Category, true)
	return true
end

local function ModernizeSavedVariable(savedTable, default)
	if not savedTable then
		default.__version = AddonVersion
		return default
	end

	-- do specific version modernizations here
	if savedTable.__version ~= AddonVersion then
		C_Logger.Info("Updated BuildCreator Saved Variables to Version: %.1f", AddonVersion)
		for k, v in pairs(default) do
			if not savedTable[k] then
				savedTable[k] = v
			end
		end

		savedTable.__version = AddonVersion
	end
	
	return savedTable
end

function BuildCreatorMixin:ADDON_LOADED(addon)
	if addon == "Ascension_BuildCreator" then
		self:UnregisterEvent("ADDON_LOADED")
		BuildCreatorSaved = ModernizeSavedVariable(BuildCreatorSaved, DefaultBuildCreatorSaved)
	end
end

function BuildCreatorMixin:BUILD_CREATOR_CATEGORY_RESULT(category)
	self:HideLoading()
	self.SearchBox:SetText("")
	C_BuildCreator.UpdateFilter("", self:ApplyDefaultClassFilter(), self.sort)
	self.category = category
	self:ShowBuildList()
	self.BuildScroll:RefreshScrollFrame()
end

function BuildCreatorMixin:BUILD_CREATOR_BUILD_RESULT(result, buildID)
	C_Logger.Info("BUILD_CREATOR_BUILD_RESULT: %s, %s", buildID, result)
	self:HideLoading()
	local build = C_BuildCreator.GetBuild(buildID)
	if build then
		if self.pendingCallback[buildID] then
			for _, callback in ipairs(self.pendingCallback[buildID]) do
				callback(build)
			end
			self.pendingCallback[buildID] = nil
			return
		else
			return self:ViewBuild(build)
		end
	elseif self:IsShown() then
		self:ShowError(VIEW_BUILD_ERROR, _G[result] or result)
	end
end

function BuildCreatorMixin:BUILD_CREATOR_ACTIVATE_RESULT(result)
	C_Logger.Info("BUILD_CREATOR_ACTIVATE_RESULT: %s", result)
	self:HideLoading()
	if result == "ACTIVATE_BUILD_OK" then
		if self.BuildViewPanel:IsVisible() then
			self.BuildViewPanel:UpdateControlButtons()
		else
			self.BuildScroll:RefreshScrollFrame()
		end
		self.CategoryScroll:RefreshScrollFrame()
		return
	end

	self.Error.DeactivateButton:SetShown(result == "ACTIVATE_BUILD_DRAFTED_BUILD_ALREADY_DRAFTED")
	self:ShowError(ACTIVATE_BUILD_FAILED, _G[result] or result)
end

function BuildCreatorMixin:BUILD_CREATOR_DEACTIVATE_RESULT(result)
	C_Logger.Info("BUILD_CREATOR_DEACTIVATE_RESULT: %s", result)
	self:HideLoading()
	if result == "DEACTIVATE_BUILD_OK" then
		if self.BuildViewPanel:IsVisible() then
			self.BuildViewPanel:UpdateControlButtons()
		else
			self.BuildScroll:RefreshScrollFrame()
		end
		self.CategoryScroll:RefreshScrollFrame()
		return
	end

	self:ShowError(DEACTIVATE_BUILD_FAILED, _G[result] or result)
end

function BuildCreatorMixin:BUILD_CREATOR_SAVE_RESULT(result, buildID)
	C_Logger.Info("BUILD_CREATOR_SAVE_RESULT: %s, %s", result, buildID)
	self:HideLoading()
	result = result:gsub("SAVE_BUILD_", "PUBLISH_BUILD_")
	if result == "PUBLISH_BUILD_OK" then
		self:ViewBuildID(buildID)
		return
	end
	self:ShowError(PUBLISH_BUILD_FAILED, _G[result] or result)
end

function BuildCreatorMixin:BUILD_CREATOR_CREATE_RESULT(result, buildID)
	C_Logger.Info("BUILD_CREATOR_CREATE_RESULT: %s, %s", result, buildID)
	self:HideLoading()
	result = result:gsub("CREATE_BUILD_", "PUBLISH_BUILD_")

	if result == "PUBLISH_BUILD_OK" then
		local build = C_BuildCreator.GetBuild(buildID)
		if build then
			self:DiscardSavedBuild(build.Name)
			self:ViewBuild(build)
		else
			-- view build ID will query the build
			self:ViewBuildID(buildID)
		end
		return
	end
	self:ShowError(PUBLISH_BUILD_FAILED, _G[result] or result)
end

function BuildCreatorMixin:BUILD_CREATOR_DELETE_RESULT(result)
	C_Logger.Info("BUILD_CREATOR_DELETE_RESULT: %s", result)
	self:HideLoading()

	if result == "DELETE_BUILD_OK" then
		if self.category then
			self:SelectCategory(self.category)
		else
			self:ShowBuildList()
		end
		return
	end

	self:ShowError(DELETE_BUILD_FAILED, _G[result] or result)
end