-- TODO: Make filter work with scrols
RE_QUALITY_ARTIFACT_NAME = RE_QUALITY_ARTIFACT_NAME or "Artifact"
-------------------------------------------------------------------------------
--                          ECCollectionFrameMixin                           --
-------------------------------------------------------------------------------
ECCollectionFrameMixin = {}

function ECCollectionFrameMixin:OnLoad()
	self:Layout()

	self.tabs = {
		[Enum.ECCollectionTabs.ScrollsTab] = self.ScrollsTab,
		[Enum.ECCollectionTabs.CollectionTab] = self.CollectionTab,
	}

	PanelTemplates_SetNumTabs(self, #self.tabs)
	self:SetupFilters()
	
	Collections:HookScript("OnHide", function()
		self:ResetFiltersAndSearch()
	end)
end

function ECCollectionFrameMixin:SetupFilters()
	self.Filter:RegisterCallback("OnFilterChanged", GenerateClosure(self.UpdateFilter, self))
	-- known filters
	self.Filter:AddFilterOption("RE_FILTER_KNOWN", self.Filter:CreateFilterInfo("TRANSMOG_COLLECTED", nil, nil, nil, "FILTER_TOOLTIP_KNOWN_ENCHANTS"))
	self.Filter:AddFilterOption("RE_FILTER_UNKNOWN", self.Filter:CreateFilterInfo("TRANSMOG_NOT_COLLECTED", nil, nil, nil, "UNKNOWN_ENCHANTS_TOOLTIP"))

	-- quality filter
	local isHeroFreepickLayout = EnchantCollectionUtil:IsHeroFreepickLayout()
	local function HasConfiguredSlots(config)
		return not isHeroFreepickLayout or (C_Config.GetIntConfig(config) or 0) > 0
	end

	self.Filter:AddOptionSpacer()
	self.Filter:AddCategoryOption("QUALITY", "QUALITY", "FILTER_QUALITY_TOOLTIP")
	self.Filter:AddSubFilterOption("QUALITY", "RE_FILTER_UNCOMMON", self.Filter:CreateFilterInfo("ITEM_QUALITY2_DESC", ITEM_QUALITY_COLORS[2]))
	if HasConfiguredSlots("CONFIG_MAX_RARE_RANDOM_ENCHANTS") then
		self.Filter:AddSubFilterOption("QUALITY", "RE_FILTER_RARE", self.Filter:CreateFilterInfo("ITEM_QUALITY3_DESC", ITEM_QUALITY_COLORS[3]))
	end
	if HasConfiguredSlots("CONFIG_MAX_EPIC_RANDOM_ENCHANTS") then
		self.Filter:AddSubFilterOption("QUALITY", "RE_FILTER_EPIC", self.Filter:CreateFilterInfo("ITEM_QUALITY4_DESC", ITEM_QUALITY_COLORS[4]))
	end
	if HasConfiguredSlots("CONFIG_MAX_LEGENDARY_RANDOM_ENCHANTS") then
		self.Filter:AddSubFilterOption("QUALITY", "RE_FILTER_LEGENDARY", self.Filter:CreateFilterInfo("ITEM_QUALITY5_DESC", ITEM_QUALITY_COLORS[5]))
	end

	-- class filter for default classes 
	if IsDefaultClass("player") and HasConfiguredSlots("CONFIG_MAX_ARTIFACT_RANDOM_ENCHANTS") then
		-- only default classes have artifact enchants
		self.Filter:AddSubFilterOption("QUALITY", "RE_FILTER_ARTIFACT", self.Filter:CreateFilterInfo("RE_QUALITY_ARTIFACT_NAME", ITEM_QUALITY_COLORS[6]))
	end

	self.Filter:AddCategoryOption("CLASS", CLASS)
	local classes = { "WARRIOR", "PALADIN", "HUNTER","ROGUE","PRIEST","DEATHKNIGHT","SHAMAN","MAGE","WARLOCK","DRUID" }
	for _, class in ipairs(classes) do
		local classFilterKey = "RE_FILTER_CLASS_"..class
		if class == "DEATHKNIGHT" then
			classFilterKey = "RE_FILTER_CLASS_DEATH_KNIGHT"
		end
		self.Filter:AddSubFilterOption("CLASS", classFilterKey, self.Filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName(class), nil, "groupfinder-icon-class-"..class))
		for _, spec in ipairs(C_ClassInfo.GetAllSpecs(class)) do
			local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
			self.Filter:AddSubFilterOption(classFilterKey, classFilterKey.."_SPEC_"..spec, self.Filter:CreateFilterInfo(specInfo.Name, nil, "Interface\\Icons\\"..specInfo.SpecFilename))
		end
	end

	local function IsOnCollectionTab()
		return PanelTemplates_GetSelectedTab(self) == Enum.ECCollectionTabs.CollectionTab
	end

	self.Filter:AddOptionSpacer(IsOnCollectionTab)
	self.Filter:AddFilterOption("RE_FILTER_WORLDFORGED", self.Filter:CreateFilterInfo("FILTER_WORLDFORGED", nil, nil, IsOnCollectionTab, "FILTER_WORLDFORGED_TOOLTIP"))
	self.Filter:AddFilterOption("RE_FILTER_NOT_WORLDFORGED", self.Filter:CreateFilterInfo("FILTER_EXCL_WORLDFORGED", nil, nil, IsOnCollectionTab, "FILTER_EXCL_WORLDFORGED_TOOLTIP"))
end

function ECCollectionFrameMixin:UpdateFilter()
	local selectedTab = PanelTemplates_GetSelectedTab(self)
	local tabFrame = selectedTab and self.tabs and self.tabs[selectedTab]
	if tabFrame and tabFrame.OnShow then
		tabFrame:OnShow(1)
	end
end

function ECCollectionFrameMixin:GetSearchString()
	return self.Search:GetText()
end

function ECCollectionFrameMixin:ResetFiltersAndSearch()
	self.Search:SetText("")
	self.Search:ClearFocus()
	self.Filter:ClearFilters()

	if (PanelTemplates_GetSelectedTab(self) == Enum.ECCollectionTabs.CollectionTab) then
		if self.CollectionTab.savedFilter then
			for k, v in pairs(self.CollectionTab.savedFilter) do
				self.Filter:SetFilter(k, v)
			end
		else
			if self:GetParent():IsAnyEnchantKnown() then
				self.Filter:SetFilter("RE_FILTER_KNOWN", true)
			end

			if IsDefaultClass("player") then
				local class = C_Player:GetClass()
				if class == "DEATHKNIGHT" then
					self.Filter:SetFilter("RE_FILTER_CLASS_DEATH_KNIGHT", true)
				else
					self.Filter:SetFilter("RE_FILTER_CLASS_"..class, true)
				end
			end
		end
	end
end

function ECCollectionFrameMixin:ApplyQualityFilter(quality)
	quality = quality or 0
	
	if quality == 2 then
		self.Filter:SetFilter("RE_FILTER_UNCOMMON", true)
	elseif quality == 3 then
		self.Filter:SetFilter("RE_FILTER_RARE", true)
	elseif quality == 4 then
		self.Filter:SetFilter("RE_FILTER_EPIC", true)
	elseif quality == 5 then
		self.Filter:SetFilter("RE_FILTER_LEGENDARY", true)
	elseif quality == 6 then
		self.Filter:SetFilter("RE_FILTER_ARTIFACT", true)
	end
end

function ECCollectionFrameMixin:SetTab(id)
	if PanelTemplates_GetSelectedTab(self) == Enum.ECCollectionTabs.CollectionTab then
		local filter = self.Filter:GetFilter()
		if next(filter) then
			self.CollectionTab.savedFilter = table.Copy(filter)
		else
			self.CollectionTab.savedFilter = nil
		end
	end
	PanelTemplates_SetTab(self, id)
	CloseDropDownMenus()
	for i = 1, #self.tabs do
		if (i == id) then
			BaseFrameFadeIn(self.tabs[i])
			self:GetParent():OnCollectionTabSwitch(i)
			self:ResetFiltersAndSearch()
		else
			BaseFrameFadeOut(self.tabs[i])
		end
	end
end

function ECCollectionFrameMixin:Layout()
	self.ScrollsTab = CreateFrame("FRAME", "$parent.ScrollsTab", self, "ScrollListTemplate")
	self.ScrollsTab:SetPoint("TOPLEFT")
	self.ScrollsTab:SetPoint("BOTTOMRIGHT")
	self.ScrollsTab.ScrollFrame:SetHeight(510) -- crutch for not to break HybridScroll_CreateButtons
	self.ScrollsTab:Hide()

	MixinAndLoadScripts(self.ScrollsTab, ECScrollsTabMixin)

	self.CollectionTab = CreateFrame("FRAME", "$parent.CollectionTab", self, nil)
	self.CollectionTab:SetPoint("TOPLEFT")
	self.CollectionTab:SetPoint("BOTTOMRIGHT")
	self.CollectionTab:Hide()
	MixinAndLoadScripts(self.CollectionTab, ECCollectionsTabMixin)

	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAtlas("Enchant-Collection-Frame-Background", Const.TextureKit.UseAtlasSize)
	self.bg:SetPoint("CENTER", 0, 0)

	self.cornerTopLeft = self:CreateTexture(nil, "ARTWORK")
	self.cornerTopLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	self.cornerTopLeft:SetSize(147, 149)
	self.cornerTopLeft:SetPoint("TOPLEFT", self, 0, 0)

	self.cornerTopRight = self:CreateTexture(nil, "ARTWORK")
	self.cornerTopRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	self.cornerTopRight:SetSize(147, 149)
	self.cornerTopRight:SetPoint("TOPRIGHT", self, 0, 0)
	self.cornerTopRight:SetTexCoord(0.464844, 0.181641, 0.416016, 0.703125)

	self.shadowTop = self:CreateTexture(nil, "OVERLAY")
	self.shadowTop:SetTexture("Interface\\COMMON\\ShadowOverlay-Top")
	self.shadowTop:SetPoint("TOPLEFT", self.cornerTopLeft, "TOPRIGHT", 0, 0)
	self.shadowTop:SetPoint("BOTTOMRIGHT", self.cornerTopRight, "BOTTOMLEFT", 0, 0)
	self.shadowTop:SetAlpha(0.6)

	self.cornerBottomLeft = self:CreateTexture(nil, "OVERLAY")
	self.cornerBottomLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	self.cornerBottomLeft:SetSize(147, 149)
	self.cornerBottomLeft:SetPoint("BOTTOMLEFT", self, 0, 0)
	self.cornerBottomLeft:SetTexCoord(0.181641, 0.464844, 0.703125, 0.416016)

	self.cornerBottomRight = self:CreateTexture(nil, "OVERLAY")
	self.cornerBottomRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	self.cornerBottomRight:SetSize(147, 149)
	self.cornerBottomRight:SetPoint("BOTTOMRIGHT", self, 0, 0)
	self.cornerBottomRight:SetTexCoord(0.464844, 0.181641, 0.703125, 0.416016)

	self.shadowBottom = self:CreateTexture(nil, "OVERLAY")
	self.shadowBottom:SetTexture("Interface\\COMMON\\ShadowOverlay-Bottom")
	self.shadowBottom:SetPoint("TOPLEFT", self.cornerBottomLeft, "TOPRIGHT", 0, 0)
	self.shadowBottom:SetPoint("BOTTOMRIGHT", self.cornerBottomRight, "BOTTOMLEFT", 0, 0)
	self.shadowBottom:SetAlpha(0.6)

	self.shadowLeft = self:CreateTexture(nil, "OVERLAY")
	self.shadowLeft:SetTexture("Interface\\COMMON\\ShadowOverlay-left")
	self.shadowLeft:SetPoint("TOPLEFT", self.cornerTopLeft, "BOTTOMLEFT", 0, 0)
	self.shadowLeft:SetPoint("BOTTOMRIGHT", self.cornerBottomLeft, "TOPRIGHT", 0, 0)

	self.shadowRight = self:CreateTexture(nil, "OVERLAY")
	self.shadowRight:SetTexture("Interface\\COMMON\\ShadowOverlay-Right")
	self.shadowRight:SetPoint("TOPRIGHT", self.cornerTopRight, "BOTTOMRIGHT", 0, 0)
	self.shadowRight:SetPoint("BOTTOMLEFT", self.cornerBottomRight, "TOPLEFT", 0, 0)

	self.Tab1 = CreateFrame("BUTTON", "$parentTab1", self, "TabButtonTemplate")
	self.Tab1:SetText(ENCHANT_COLLECTION_SCROLLS)
	self.Tab1:SetID(Enum.ECCollectionTabs.ScrollsTab)
	self.Tab1:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 4, 0)
	self.Tab1:SetScript("OnClick", function(self)
		self:GetParent():SetTab(self:GetID())
	end)
	self.Tab1:GetScript("OnLoad")(self.Tab1) -- for resize
	self.Tab1:SetFrameLevel(self.NineSlice:GetFrameLevel()+1)

	self.Tab2 = CreateFrame("BUTTON", "$parentTab2", self, "TabButtonTemplate")
	self.Tab2:SetText(ENCHANT_COLLECTION_COLLECTION)
	self.Tab2:SetID(Enum.ECCollectionTabs.CollectionTab)
	self.Tab2:SetPoint("LEFT", self.Tab1, "RIGHT", 4, 0)
	self.Tab2:SetScript("OnClick", function(self)
		self:GetParent():SetTab(self:GetID())
	end)
	self.Tab2:GetScript("OnLoad")(self.Tab2) -- for resize
	self.Tab2:SetFrameLevel(self.NineSlice:GetFrameLevel()+1)

	self.Filter = CreateFrame("BUTTON", "$parentFilter", self, "FilterDropDownButtonTemplate")
	self.Filter:SetSize(78, 22)
	self.Filter:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -12, 6)

	self.Search = CreateFrame("EditBox", "$parentFilter", self, "SearchBoxTemplate")
	self.Search:SetSize(256, 22)
	self.Search:SetPoint("RIGHT", self.Filter, "LEFT", -8, 0)

	self.Search:SetScript("OnTextChanged", function(self)
		if self:HasFocus() then
			SearchBoxTemplate_OnTextChanged(self)
			self:GetParent():UpdateFilter()
		end
	end)
          
	self.Search:SetScript("OnTextSet", function(self)
		self:GetParent():UpdateFilter()
	end)
end


