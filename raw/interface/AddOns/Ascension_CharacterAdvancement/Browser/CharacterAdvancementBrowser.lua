local SPELLS_PER_ROW = 16
local MAX_TAGS_PER_ROW = 4
local MAX_ICON_LOADS_PER_FRAME = 4
local DEFAULT_TAG_SPACING_LEFT = 8

local SOON_UNLOCKED_CATEGORY = 42
local RECENTLY_UNLOCKED_CATEGORY = 31

local HIDDEN_CATEGORIES = {
	[RECENTLY_UNLOCKED_CATEGORY] = true,
	[SOON_UNLOCKED_CATEGORY] = true,
}
local RECENTLY_UNLOCKED_CATEGORIES = {
	[32] = true,
	[33] = true,
	[34] = true,
	[35] = true,
	[36] = true,
	[37] = true,
	[38] = true,
	[39] = true,
	[40] = true,
	[41] = true,
	[43] = true,
	[44] = true,
	[45] = true,
	[46] = true,
	[47] = true,
	[48] = true,
	[49] = true,
	[50] = true,
	[51] = true,
	[52] = true,
}
local RECENTLY_UNLOCKED_CATEGORIES_LOCKED = {
	[43] = true,
	[44] = true,
	[45] = true,
	[46] = true,
	[47] = true,
	[48] = true,
	[49] = true,
	[50] = true,
	[51] = true,
	[52] = true,
}

local function IsCategoryHidden(categoryID)
	if HIDDEN_CATEGORIES[categoryID] then
		return true
	end

	if RECENTLY_UNLOCKED_CATEGORIES[categoryID] and C_GameMode and C_GameMode.IsGameModeActive and Enum and Enum.GameMode and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		return true
	end

	return false
end


CA_BROWSER_UNLOCKS_AT_LEVEL = CA_BROWSER_UNLOCKS_AT_LEVEL or "Unlocks at level: %s"
CA_CLICK_TO_REMOVE_FILTER = CA_CLICK_TO_REMOVE_FILTER or "Click to remove filter"
CA_BROWSER_CLASS_TITLE_RECENTLY = CA_BROWSER_CLASS_TITLE_RECENTLY or "Recently unlocked |cffFFFFFF%s|r abilities"
CA_BROWSER_CLASS_TITLE_SOON = CA_BROWSER_CLASS_TITLE_SOON or "|cffFFFFFF%s|r abilities soon to be unlocked"

local FILTER_TO_STRING_TABLE = {
	["FILTER_KNOWN"] = CA_FILTER_KNOWN_IN_BUILD,
	["FILTER_UNKNOWN"] = CA_FILTER_UNKNOWN_IN_BUILD,
	["FILTER_KNOWN"] = CA_FILTER_KNOWN,
	["FILTER_UNKNOWN"] = CA_FILTER_UNKNOWN,
	["FILTER_CAN_ADD"] = CA_FILTER_CAN_ADD,
	["FILTER_CAN_REMOVE"] = CA_FILTER_CAN_REMOVE,
	["FILTER_CAN_LEARN"] = CA_FILTER_CAN_LEARN,
	["FILTER_CAN_UNLEARN"] = CA_FILTER_CAN_UNLEARN,
	["FILTER_QUALITY_NORMAL"] = ITEM_QUALITY_COLORS[1]:WrapText(ITEM_QUALITY1_DESC),
	["FILTER_QUALITY_UNCOMMON"] = ITEM_QUALITY_COLORS[2]:WrapText(ITEM_QUALITY2_DESC),
	["FILTER_QUALITY_RARE"] = ITEM_QUALITY_COLORS[3]:WrapText(ITEM_QUALITY3_DESC),
	["FILTER_QUALITY_EPIC"] = ITEM_QUALITY_COLORS[4]:WrapText(ITEM_QUALITY4_DESC),
	["FILTER_QUALITY_LEGENDARY"] = ITEM_QUALITY_COLORS[5]:WrapText(ITEM_QUALITY5_DESC),
	["FILTER_CLASS_DRUID"] = ClassInfoUtil.GetColoredClassName("DRUID"),
	["FILTER_CLASS_HUNTER"] = ClassInfoUtil.GetColoredClassName("HUNTER"),
	["FILTER_CLASS_MAGE"] = ClassInfoUtil.GetColoredClassName("MAGE"),
	["FILTER_CLASS_PALADIN"] = ClassInfoUtil.GetColoredClassName("PALADIN"),
	["FILTER_CLASS_PRIEST"] = ClassInfoUtil.GetColoredClassName("PRIEST"),
	["FILTER_CLASS_ROGUE"] = ClassInfoUtil.GetColoredClassName("ROGUE"),
	["FILTER_CLASS_SHAMAN"] = ClassInfoUtil.GetColoredClassName("SHAMAN"),
	["FILTER_CLASS_WARLOCK"] = ClassInfoUtil.GetColoredClassName("WARLOCK"),
	["FILTER_CLASS_WARRIOR"] = ClassInfoUtil.GetColoredClassName("WARRIOR"),
	["FILTER_CLASS_DEATH_KNIGHT"] = ClassInfoUtil.GetColoredClassName("DEATHKNIGHT"),
	["FILTER_TYPE_ABILITY"] = CA_FILTER_TYPE_ABILITY,
	["FILTER_TYPE_TALENT"] = CA_FILTER_TYPE_TALENT,
	["FILTER_TYPE_TRAIT"] = CA_FILTER_TYPE_TRAIT,
}

--
-- SpellTag Mixin 
--
CASpellTagMixin = CreateFromMixins("CallbackRegistryMixin")

function CASpellTagMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:SetHeight(16)
	self.Left:SetSize(32, 16)
	self.Right:SetSize(32, 16)
	self.Middle:SetHeight(16)
	self.Text:SetFontObject(GameFontHighlightSmall)

	self:GetHighlightTexture():SetAtlas("wow-tab-highlight", Const.TextureKit.IgnoreAtlasSize)
end

function CASpellTagMixin:UpdateLayout()
	self:SetWidth(math.max(64, self.Text:GetWidth()+16))
end

function CASpellTagMixin:SetTag(value)
	self.filter = nil
	self.tag = value

	local name = C_CharacterAdvancement.GetSpellTagTypeDisplayInfo(value) or value
	self.Text:SetText(name)
	self:UpdateLayout()
end

function CASpellTagMixin:SetFilter(filter)
	self.tag = nil
	self.filter = filter

	self.Text:SetText(FILTER_TO_STRING_TABLE[filter] or filter)

	self:UpdateLayout()
end

function CASpellTagMixin:OnClick()
	PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
	self:GetParent():OnButtonClick(self)
end

function CASpellTagMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.Text:GetText(), 1, 1, 1)
	GameTooltip:AddLine(CA_CLICK_TO_REMOVE_FILTER)
	GameTooltip:Show()
end

function CASpellTagMixin:OnLeave()
	GameTooltip:Hide()
end
--
-- SpellTag frame
--
CASpellTagFrameMixin = CreateFromMixins("CallbackRegistryMixin")

function CASpellTagFrameMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self:SetBackdrop(GameTooltip:GetBackdrop())
	self:SetBackdropColor(0, 0, 0, 0.8)
	self:SetBackdropBorderColor(0.6, 0.6, 0.6)

	self.framePool = CreateFramePool("Button", self, "CASpellTagTemplate")
	self.framesToID = {}

	self:GenerateCallbackEvents({ "OnSpellTagClicked"})
end

function CASpellTagFrameMixin:AllocateButton(button, layoutIndex)
	if ((layoutIndex-1)%MAX_TAGS_PER_ROW) == 0 then
		local prevRowTopLeft = self.framesToID[layoutIndex-MAX_TAGS_PER_ROW]

		if prevRowTopLeft then
			button:ClearAndSetPoint("TOPLEFT", prevRowTopLeft, "BOTTOMLEFT", 0, -DEFAULT_TAG_SPACING_LEFT/2)
		else
			button:ClearAndSetPoint("TOPLEFT", self.Text, "BOTTOMLEFT", 0, -DEFAULT_TAG_SPACING_LEFT/2)
		end
	else
		button:ClearAndSetPoint("LEFT", self.framesToID[layoutIndex-1], "RIGHT", DEFAULT_TAG_SPACING_LEFT/2, 0)
	end

	self:UpdateWidth()
end

function CASpellTagFrameMixin:UpdateWidth()
	local rowWidth = 12

	for i = 1, #self.framesToID do
		if ((i-1)%MAX_TAGS_PER_ROW) == 0 then
			rowWidth = 12
		end

		local button = self.framesToID[i]

		rowWidth = rowWidth + (button and (button:GetWidth() + (DEFAULT_TAG_SPACING_LEFT/2)) or 0)

		if self:GetWidth() < rowWidth then
			self:SetWidth(rowWidth)
		end
	end
end

function CASpellTagFrameMixin:OnButtonClick(button)
	self:TriggerEvent("OnSpellTagClicked", button.filter, button.tag)
end

function CASpellTagFrameMixin:SetUpSpellTags(filtersTable, spellTagsTable)
	self.framePool:ReleaseAll()
	wipe(self.framesToID)
	self.framesToID = {}

	self:SetWidth(16)

	-- 4 entries per row max

	local layoutIndex = 1

	for filter in pairs(filtersTable) do
		local button = self.framePool:Acquire()
		button:Show()
		button:SetFilter(filter)

		self.framesToID[layoutIndex] = button
		self:AllocateButton(button, layoutIndex)

		layoutIndex = layoutIndex + 1
	end

	for _, tag in pairs(spellTagsTable) do
		local button, isNew = self.framePool:Acquire()
		button:Show()
		button:SetTag(tag)

		self.framesToID[layoutIndex] = button
		self:AllocateButton(button, layoutIndex)

		layoutIndex = layoutIndex + 1
	end

	local totalRows = math.ceil((layoutIndex-1)/MAX_TAGS_PER_ROW)
	self:SetHeight((totalRows*16) + ((totalRows-1)*4) + 16 + 12)
end

--
-- Ability Mixin
--
CABrowserAbilityMixin = CreateFromMixins("CASpellButtonBaseMixin")

function CABrowserAbilityMixin:OnShow()
end

function CABrowserAbilityMixin:OnHide()
end

function CABrowserAbilityMixin:OnClick(button)
	PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
	CASpellButtonBaseMixin.OnClick(self, button)
end

function CABrowserAbilityMixin:OnLoad()
    CASpellButtonBaseMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)

    self.Icon.KnownGlow:SetAtlas("ca_known_glow", Const.TextureKit.IgnoreAtlasSize)
    self.Icon.KnownGlow:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
    self.Icon:SetBackgroundSize(58, 58)
    self.Icon:SetBackgroundTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
    self.Icon:SetBackgroundOffset(9.5, -9.5)

    self.ClassPoints.Count:SetVertexColor(1, 0, 0)
    self.ClassPoints:SetScript("OnEnter", GenerateClosure(CASpellButtonBaseMixin.OnEnterClassPoints, self))

    function self.Icon:SetIconDesaturated(desaturated)
    	BorderIconTemplateMixin.SetIconDesaturated(self, desaturated)
    	self:GetParent().Class.Icon:SetDesaturated(desaturated)
    end

    self.Class:SetScript("OnEnter", function(self)
    	local class = self:GetParent().entry.Class

    	if class then
    		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    		GameTooltip:AddLine(ClassInfoUtil.GetColoredClassName(string.upper(class)))
    	end

    	GameTooltip:Show()
	end)

	self.Class:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

    self.Suggested:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(SUGGESTED_ABILITY, 1, 1, 1)
		GameTooltip:AddLine(SUGGESTED_ABILITY_TOOLTIP)

    	GameTooltip:Show()
	end)

	self.Suggested:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end

function CABrowserAbilityMixin:OnEnter()
	if self.isClass then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.isSoonClass then
			GameTooltip:AddLine(CA_BROWSER_CLASS_TITLE_SOON:format(self.ClassPoints.Count:GetText()), 1, 0.82, 0, true)
		else
			GameTooltip:AddLine(CA_BROWSER_CLASS_TITLE_RECENTLY:format(self.ClassPoints.Count:GetText()), 1, 0.82, 0, true)
		end
		GameTooltip:Show()
	else
		CASpellButtonBaseMixin.OnEnter(self)
	end
end

function CABrowserAbilityMixin:SetDisabledVisual()
	CASpellButtonBaseMixin.SetDisabledVisual(self)
	self.Class.Icon:SetVertexColor(0.5, 0.5, 0.5, 0.5)
end

function CABrowserAbilityMixin:MakeClass(class, categoryID)
	self.isClass = true
	self.isSoonClass = false

	self.Icon:Hide()
	self.Suggested:Hide()
	self.Class:Hide()
	self.ClassPoints:Show()
	self.ClassPoints:ClearAndSetPoint("CENTER", 0, 0)
	self.ClassPoints:SetSize(24, 24)
	self.ClassPoints:SetBorderSize(40, 40)
	self.ClassPoints.Count:SetVertexColor(1, 1, 1)
	self.ClassPoints.Count:ClearAndSetPoint("BOTTOM", 0, -8)
	self.ClassPoints.Count:SetWidth(42)
	self.ClassPoints.Count:Hide()

	if RECENTLY_UNLOCKED_CATEGORIES_LOCKED[categoryID] then 
		--self.ClassPoints:SetIconAtlas("levelup-lock", false)
		--self.ClassPoints:SetSize(20, 24)
		self.isSoonClass = true
		self.ClassPoints:SetDesaturated(true)
	end

	if class then
		self.ClassPoints:SetIcon("Interface\\Icons\\classicon_" .. class:lower())
	end


	if class then
		self.ClassPoints.Count:SetText(LOCALIZED_CLASS_NAMES_MALE[class:upper()] or "")
	else
		dprint("|cffFF0000 class is nil for "..categoryID)
	end

	self.ClassPoints.Shadow:Hide()
	self.ClassPoints:EnableMouse(false)
	self:Disable()
end

function CABrowserAbilityMixin:SetEntry(entry, isSuggested)
	self.isClass = false

	self.Icon:Show()
	self.Class:Show()
	self.ClassPoints.Count:Show()
	self.ClassPoints.Count:SetVertexColor(1, 0, 0)
	self.ClassPoints.Count:ClearAndSetPoint("CENTER", self.ClassPoints, "BOTTOMRIGHT", -1, 2)
	self.ClassPoints:SetSize(14, 14)
	self.ClassPoints:SetBorderSize(19, 19)
	self.ClassPoints:ClearAndSetPoint("CENTER", self.Icon, "BOTTOMRIGHT", -4, 4)
	self.ClassPoints.Shadow:Show()
	self.ClassPoints:EnableMouse(true)

	self.Class.Icon:SetVertexColor(1, 1, 1, 1)
	self.Class:EnableMouse(true)
	self:Enable()
	CASpellButtonBaseMixin.SetEntry(self, entry)

	local class = entry.Class
	local classAtlas = string.lower("groupfinder-icon-class-"..class)
	local hasClassPoints = false

	self.ClassPoints:Hide()

	if CharacterAdvancementUtil.AreTalentGatesEnabled() then
		if entry.RequiredClassPoints and (entry.RequiredClassPoints > 0) then
			local diff = entry.RequiredClassPoints - C_CharacterAdvancement.GetClassPointInvestment(class, 0)
			if (diff > 0) then
                self.ClassPointsUsed = true
                self.ClassPoints:Show()
                self.ClassPoints:SetIcon("Interface\\Icons\\classicon_" .. class:lower())
                self.ClassPoints.Count:SetText(diff)
                self.ClassPoints:ClearAndSetPoint("BOTTOMRIGHT", 0, -2)

                hasClassPoints = true
            end
        end

        if not hasClassPoints then
        	if entry.RequiredAEInvestment and (entry.RequiredAEInvestment > 0) then
        		local diff = entry.RequiredAEInvestment - C_CharacterAdvancement.GetGlobalAEInvestment()
				if (diff > 0) then
	                self.ClassPointsUsed = true
	                self.ClassPoints:Show()
	                self.ClassPoints:SetIcon("Interface\\Icons\\inv_custom_abilityessence")
	                self.ClassPoints.Count:SetText(diff)
	                self.ClassPoints:ClearAndSetPoint("BOTTOMRIGHT", 0, -2)

	                hasClassPoints = true
	            end
        	end
        end
	end

	if not(hasClassPoints) and AtlasUtil:AtlasExists(classAtlas) then
		self.Class:Show()
		self.Class.Icon:SetAtlas(classAtlas, Const.TextureKit.IgnoreAtlasSize)
	else
		self.Class:Hide()
	end

	if BuildCreatorUtil.IsPickingSpells() then
		return
	end

	if not self:GetParent():GetAvailableStatus() then
        self.Icon:SetIconDesaturated(true)
        self:SetDisabledVisual()
	end

	if isSuggested then
		self.Suggested.Icon:SetAtlas("talents-search-notonactionbar", Const.TextureKit.IgnoreAtlasSize)
		self.Suggested:Show()
	else
		self.Suggested:Hide()
	end

	if C_CharacterAdvancement.IsSuggestionContextOverride(entry.ID) then
		self.Suggested:Show()
		self.Suggested.Icon:SetAtlas("talents-search-notonactionbarhidden", Const.TextureKit.IgnoreAtlasSize)
	end
end

--
-- browser row mixin
--
CABrowserRowMixin = CreateFromMixins(ScrollListItemBaseMixin)

function CABrowserRowMixin:OnLoad()
	self:EnableMouse(false)
	self.AbilityPool = CreateFramePool("Button", self, "CABrowserSpellButtonTemplate")

	self.Icon:SetScript("OnEnter", GenerateClosure(self.OnEnterCategoryButton, self))
	self.Icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

	self.delayedEntries = {}
	self.categoryID = nil
end

function CABrowserRowMixin:Init()
end

function CABrowserRowMixin:SetSelected()
end

function CABrowserRowMixin:OnSelected()
end

function CABrowserRowMixin:GetScrollParent()
	return self:GetParent():GetParent():GetParent()
end

function CABrowserRowMixin:GetAvailableStatus()
	return self.isAvailable
end

function CABrowserRowMixin:SetAvailableStatus(isAvailable)
	self.isAvailable = isAvailable
end

function CABrowserRowMixin:SetAvailableVisual(isAvailable, text, errorText)
	if not(isAvailable) then
		self.Icon.Icon:SetVertexColor(0, 0, 0)
     	self.Icon.Lock:Show()
     	self.Icon.Ring:SetVertexColor(0.5, 0.5, 0.5)
     	self.Icon.Text:SetText(errorText)
     	self.Icon.Text:SetTextColor(0.5, 0.5, 0.5)
     else
	    self.Icon.Icon:SetVertexColor(1, 1, 1)
	    self.Icon.Ring:SetVertexColor(1, 1, 1)
	    self.Icon.Lock:Hide()
	    self.Icon.Text:SetText(text)
	    self.Icon.Text:SetTextColor(1, 1, 1)
	end
end

function CABrowserRowMixin:OnEnterCategoryButton()
	GameTooltip:SetOwner(self.Icon, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.tooltipTitle, 1, 1, 1)
	GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, true)
	GameTooltip:Show()
end

function CABrowserRowMixin:UpdateCategoryVisual()
	local categoryID = RECENTLY_UNLOCKED_CATEGORIES[self:GetCategoryID()] and RECENTLY_UNLOCKED_CATEGORY or self:GetCategoryID()  -- hackfix for recently unlocked

	local reqLevel, name, icon, description = C_CharacterAdvancement.GetCategoryDisplayInfo(categoryID)

	if not name then return end

	SetPortraitToTexture(self.Icon.Icon, "Interface\\Icons\\"..icon)

	self.tooltipTitle = name
	self.tooltipText = description or "No description for this category is filled yet. Please update data."

    self:SetAvailableVisual(reqLevel <= UnitLevel("player"), name, name.." ("..string.format(CA_BROWSER_UNLOCKS_AT_LEVEL, "|cffFF0000"..reqLevel.."|r")..")|r")
end

function CABrowserRowMixin:LoadEntry(button, index)
	local entry, isSuggested = C_CharacterAdvancement.GetFilteredEntryAtIndexByCategory(self:GetCategoryID(), index)

	if entry then
		button.Icon.Icon:Show()
		button:SetEntry(entry, isSuggested)
		--button:MakeClass()
	end
end

function CABrowserRowMixin:LoadIconsOnUpdate()
	for i = 1, MAX_ICON_LOADS_PER_FRAME do
		local button, index = next(self.delayedEntries) 

		if button then
			self:LoadEntry(button, index)
			self.delayedEntries[button] = nil
		else
			self:SetScript("OnUpdate", nil)
		end
	end
end

function CABrowserRowMixin:SetCategoryID(value)
	self.categoryID = value
end

function CABrowserRowMixin:GetCategoryID()
	return self.categoryID
end

function CABrowserRowMixin:Update()
	local categoryID, startIndex, maxIndex = self:GetScrollParent():GetDataForIndex(self.index)
	local isClassCategory = RECENTLY_UNLOCKED_CATEGORIES[categoryID]

	self.AbilityPool:ReleaseAll()
	wipe(self.delayedEntries)
	self:SetScript("OnUpdate", nil)

	if not categoryID then
		dprint("error. no category id")
		return
	end

	self:SetCategoryID(categoryID)

	if startIndex < 0 then -- we should display category icon
		self:UpdateCategoryVisual()
		self.Icon:Show()
		self.Shadow:Show()
		return
	end

	local reqLevel, _, _, _, shouldStaggerDisplayingEntries = C_CharacterAdvancement.GetCategoryDisplayInfo(categoryID)

	self:SetAvailableStatus(UnitLevel("player") >= reqLevel)

	self.Icon:Hide()
	self.Shadow:Hide()

	for i = 1, math.min(SPELLS_PER_ROW, (maxIndex-startIndex)) do
		local index

		if isClassCategory then
			local shift = math.ceil((startIndex+1)/SPELLS_PER_ROW) -- always -x index in class rows
			index = startIndex+i - shift
		else
			index = startIndex+i
		end

        button = self.AbilityPool:Acquire()
        button:SetPoint("LEFT", ( 24 + ((i - 1) % SPELLS_PER_ROW) * 44), 0)
        button:Show()
        button.ClassPoints:SetDesaturated(false)

        if isClassCategory and (index == 0) then
        	button:MakeClass(CharacterAdvancementUtil.GetClassFileForEntry(C_CharacterAdvancement.GetFilteredEntryAtIndexByCategory(categoryID, index+1)), categoryID)
        elseif isClassCategory and (i == 1) then
        	button:Hide()
        else
	        if shouldStaggerDisplayingEntries then -- categories thousands of entries, optimize it for better performance
	        	button.Icon.Icon:Hide()
	        	button.Class:Hide()
	        	button.Suggested:Hide()
	        	self.delayedEntries[button] = index
	        else
	        	self:LoadEntry(button, index)
	        end
	    end
    end

    if next(self.delayedEntries) then
    	self:SetScript("OnUpdate", self.LoadIconsOnUpdate)
    end
end

--
-- browser mixin
--
CABrowserMixin = CreateFromMixins(ScrollListMixin)

function CABrowserMixin:BuildCategoryMap()
	wipe(self.categoryMap)
	self.categoryMap = {}
	self.totalRows = 0
	self.firstRecentCategoryID = nil -- "rowindex = startindex"

	local categories = C_CharacterAdvancement.GetCategories(true)
	local hasDisabledCategory = false

	for i = 1, #categories do
		local categoryID = categories[i]
		local categoryTotalResults = C_CharacterAdvancement.GetNumFilteredEntriesByCategory(categoryID) 
		local categoryTakesRows = math.ceil(categoryTotalResults/SPELLS_PER_ROW)
		local reqLevel = C_CharacterAdvancement.GetCategoryDisplayInfo(categoryID)

		if categoryTakesRows > 0 then
			if hasDisabledCategory then
				categoryTakesRows = 1 -- display just category name
			elseif RECENTLY_UNLOCKED_CATEGORIES[categoryID] then -- for recently unlocked, display header only for 1st recently unlocked

				categoryTotalResults = categoryTotalResults + categoryTakesRows -- add 1 blank element for each row
				local categoryTakesRowsNew = math.ceil(categoryTotalResults/SPELLS_PER_ROW)

				if categoryTakesRowsNew > categoryTakesRows then
					categoryTotalResults = categoryTotalResults + (categoryTakesRowsNew-categoryTakesRows)
				end

				categoryTakesRows = math.ceil(categoryTotalResults/SPELLS_PER_ROW)

				if not self.firstRecentCategoryID then
					self.firstRecentCategoryID = categoryID
					categoryTakesRows = categoryTakesRows + 1
				end
			else
				categoryTakesRows = categoryTakesRows + 1 -- add 1 extra row for category name
			end
		end

		if reqLevel > UnitLevel("player") then
			hasDisabledCategory = true
		end

		if IsCategoryHidden(categoryID) then
			categoryTakesRows = 0
			categoryTotalResults = 0
		end

		self.categoryMap[i] = {categoryID, categoryTakesRows, categoryTotalResults}
		self.totalRows = self.totalRows + categoryTakesRows
	end

	if self.totalRows == 0 then
		self.NoSearchResults:Show()
	else
		self.NoSearchResults:Hide()
	end
end

function CABrowserMixin:GetNumResults()
	return self.totalRows
end

function CABrowserMixin:GetDataForIndex(index) -- returns categoryID, startIndex, maxIndex
	local totalRows = 0
	
	for i = 1, #self.categoryMap do
		local categoryID = self.categoryMap[i][1]
		local categoryTakesRows = self.categoryMap[i][2]
		local categoryTotalResults = self.categoryMap[i][3]

		if (totalRows+categoryTakesRows) >= index then -- we're in right category
			local rowInCategory = index - totalRows

			if RECENTLY_UNLOCKED_CATEGORIES[categoryID] and (categoryID ~= self.firstRecentCategoryID) then -- for recently unlocked, display header only for 1st recently unlocked
				return categoryID, (rowInCategory-1)*SPELLS_PER_ROW, categoryTotalResults
			end

			return categoryID, (rowInCategory-2)*SPELLS_PER_ROW, categoryTotalResults -- -2 for to start listing spells from 2nd line
		end

		totalRows = totalRows + categoryTakesRows
	end
end

function CABrowserMixin:OnLoad()
	self.totalRows = 0
	self.categoryMap = {}

	self:SetGetNumResultsFunction(GenerateClosure(self.GetNumResults, self))
	self:SetTemplate("CABrowserRowTemplate")
	self:GetSelectedHighlight():SetTexture("") 

	self.ScrollFrame:EnableMouse(false)
end

function CABrowserMixin:DisplaySearchResults(searchQuery, filterOutput)
	--dprint("CABrowserMixin:DisplaySearchResults")

	local categories = C_CharacterAdvancement.GetCategories(true)

	-- SPELL_CATEGORY_RECENTLY_UNLOCKED = 31;
	
	local hasDisabledCategory = false

	for i = 1, #categories do
		local categoryID = categories[i]
		local reqLevel = C_CharacterAdvancement.GetCategoryDisplayInfo(categoryID)

		if reqLevel <= UnitLevel("player") or not(hasDisabledCategory) then
			if not IsCategoryHidden(categoryID) then
				C_CharacterAdvancement.SetFilteredEntriesByCategory(categoryID, filterOutput[2], searchQuery or "", filterOutput[1])
			end
		end

		if reqLevel > UnitLevel("player") then
			hasDisabledCategory = true
		end
	end

	self:BuildCategoryMap()
	self:RefreshScrollFrame()
end
