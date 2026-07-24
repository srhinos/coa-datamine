AddonTooltip = nil

if InGlue() then
	AddonTooltip = GlueTooltip
else
	UIPanelWindows["AddonPanel"] = { area = "center", pushable = 0, whileDead = 1 }
	AddonTooltip = GameTooltip
end

AddonPanelMixin = {
	addons = {},
}

function AddonPanelMixin:OnLoad()
	local function getNumResults()
		if not self.addons then return 0 end
		return #self.addons
	end
	
	self.AddonList:GetSelectedHighlight():SetAtlas("addons_list_active", Const.TextureKit.IgnoreAtlasSize)
	self.AddonList:SetGetNumResultsFunction(getNumResults)
	self.AddonList:SetTemplate("AddonScrollListItemTemplate", self)
	
	self.SearchBox.Instructions:SetText(ADDONS_SEARCH_INSTRUCTIONS)
	self.NineSlice.Title:SetText(ADDONS)

	if InGlue() then
		self:CreateCharacterDropdown()
		self:EnableKeyboard(true)
		self:SetScript("OnKeyDown", self.OnKeyDown)
	else
		self:RegisterForDrag("LeftButton")
	end

	UIDropDownMenu_Initialize(self.PresetDropdown, function(dropdown, level, menuList)
		self:InitializePresetDropdown(dropdown, level, menuList)
	end, "MENU")
end

function AddonPanelMixin:OnShow()
	self:RefreshAddonList()

	if not InGlue() then
		self.saveState = C_AddonPanel:MakeSaveState()
	else
		GlueClickBlocker:SetFrameStrata("MEDIUM")
		GlueClickBlocker:Show()
	end
end 

function AddonPanelMixin:OnHide()
	if self.saveState then
		C_AddonPanel:RestoreSaveState(self.saveState)
	end

	if InGlue() then
		GlueClickBlocker:Hide()
	end
end

function AddonPanelMixin:SelectAddon(addon)
	self.selectedAddon = addon
	self.AddonInfo:SetAddon(addon)
end

function AddonPanelMixin:RefreshAddonList()
	local addons = C_AddonPanel:GetSearchedAddons(self.searchText)
	self.addons = addons

	local selectedIndex = C_AddonPanel:GetAddonIndex(self.selectedAddon, addons)

	if not selectedIndex then
		self:SelectAddon(self.addons[1])
		self.AddonList:SetSelectedIndex(1, ScrollListMixin.UpdateType.OnlyNewIndex)
	else
		self:SelectAddon(self.selectedAddon)
		self.AddonList:SetSelectedIndex(selectedIndex, ScrollListMixin.UpdateType.OnlyNewIndex)
	end

	self.AddonList:RefreshScrollFrame()
end

function AddonPanelMixin:Search(text)
	text = text:gsub("%s+", "")
	self.searchText = text
	self:RefreshAddonList()
end

function AddonPanelMixin:Close()
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
	if InGlue() then
		ResetAddOns()
		self:Hide()
	else
		HideUIPanel(self)
	end
end

function AddonPanelMixin:Apply()
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
	if InGlue() then
		SaveAddOns()
		self:Hide()
	else
		self.saveState = nil
		ReloadUI()
	end
end

function AddonPanelMixin:OnKeyDown(key)
	if key == "ESCAPE" then
		self:Close()
	elseif key == "ENTER" then
		self:Apply()
	elseif key == "PRINTSCREEN" then
		Screenshot()
	end
end

function AddonPanelMixin:LoadPreset(id)
	local preset = C_AddonPanel:GetSaveState(id)
	if not preset then return end

	UIDropDownMenu_SetSelectedValue(self.PresetDropdown, id)
	UIDropDownMenu_SetText(self.PresetDropdown, id)
	C_AddonPanel:RestoreSaveState(preset)
	self:RefreshAddonList()
end

function AddonPanelMixin:ShowDialog(dialog, arg1, arg2, data)
	if StaticPopup_Show then
		StaticPopup_Show(dialog, arg1, arg2, data)
	elseif GlueDialog_Show then
		GlueDialog_Show(dialog, arg1, data)
	end
end

function AddonPanelMixin:CreateNewPreset()
	self:ShowDialog("NAME_ADDON_PRESET")
end

function AddonPanelMixin:RenamePreset(oldID)
	local state = C_AddonPanel:GetSaveState(oldID)
	local data = { state = state, oldID = oldID }
	self:ShowDialog("RENAME_ADDON_PRESET", oldID, nil, data)
end

function AddonPanelMixin:InitializePresetDropdown(dropdown, level, menuList)
	if not level or level == 1 then
		local count = 0
		for i, id in ipairs(C_AddonPanel:GetSaveStateIDs()) do
			local state = C_AddonPanel:GetSaveState(id)
			local info = UIDropDownMenu_CreateInfo()
			info.text = id
			info.value = id
			info.menuList = id
			info.keepShownOnClick = true
			info.hasArrow = true
			UIDropDownMenu_AddButton(info, level)
			count = i
		end

		if count >= 8 then return end

		local info = UIDropDownMenu_CreateInfo()
		ADDON_CREATE_PRESET = "Create New Preset"
		info.text = CreateAtlasMarkup("communities-icon-addchannelplus", 0.7, 0, 0) .. " " .. GREEN_FONT_COLOR:WrapText(ADDON_CREATE_PRESET)
		info.func = function() self:CreateNewPreset() CloseDropDownMenus() end
		UIDropDownMenu_AddButton(info, level)
	else
		local info = UIDropDownMenu_CreateInfo()
		info.text = CreateAtlasMarkup("communities-icon-notification", 0.6, 0, 0) .. " " .. ADDON_LOAD_PRESET
		info.func = function() self:LoadPreset(menuList) CloseDropDownMenus() end
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.text = CreateAtlasMarkup("communities-icon-lock", 0.6, 0, 0) .. " " .. ADDON_SAVE_PRESET
		info.func = function()
			self:ShowDialog("SAVE_ADDON_PRESET", menuList, nil, menuList)
			CloseDropDownMenus()
		end
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.text = CreateAtlasMarkup("communities-icon-addchannelplus", 0.6, -4, 0) .. ADDON_RENAME_PRESET
		info.func = function() self:RenamePreset(menuList) CloseDropDownMenus() end
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.text = CreateAtlasMarkup("communities-icon-redx", 0.6, 0, 0) .. " " .. ADDON_REMOVE_PRESET
		info.func = function()
			self:ShowDialog("DELETE_ADDON_PRESET", menuList, nil, menuList)
			CloseDropDownMenus()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end

-- only relevant in glue
if InGlue() then
	function AddonPanelMixin:CharacterDropdownClick(button)
		UIDropDownMenu_SetSelectedValue(self.CharacterDropdown, button.value)
		if button.value == ALL then
			self.selectedCharacter = nil
		else
			self.selectedCharacter = button.value
		end
		self:RefreshAddonList()
	end

	function AddonPanelMixin:InitializeCharacterDropdown()
		local selectedValue = UIDropDownMenu_GetSelectedValue(self.CharacterDropdown)
		local info = UIDropDownMenu_CreateInfo()
		info.text = ALL
		info.value = ALL
		info.func = function(...) self:CharacterDropdownClick(...) end
		if ( not selectedValue ) then
			info.checked = 1
		end
		UIDropDownMenu_AddButton(info)

		for i=1, GetNumCharacters() do
			info.text = GetCharacterInfo(i)
			info.value = GetCharacterInfo(i)
			info.func = function(...) self:CharacterDropdownClick(...) end
			if ( selectedValue == info.value ) then
				info.checked = 1
			else
				info.checked = nil
			end
			UIDropDownMenu_AddButton(info)
		end
	end

	function AddonPanelMixin:CreateCharacterDropdown()
		self.CharacterDropdown = CreateFrame("Frame", "$parentDropdown", self.AddonInfo, "UIDropDownMenuTemplate")

		local text = self.CharacterDropdown:CreateFontString("$parentLabel", "OVERLAY", "GlueFontNormalSmall")
		text:SetText(CONFIGURE_MODS_FOR)
		text:SetPoint("RIGHT", self.CharacterDropdown, "LEFT", 4, 2)

		self.CharacterDropdown:SetPoint("BOTTOMRIGHT", -120, 0)
		self.AddonInfo.LoadOutOfDate:ClearAndSetPoint("BOTTOMRIGHT", self.AddonInfo, "BOTTOMRIGHT", -12, 38)

		UIDropDownMenu_Initialize(self.CharacterDropdown, function() self:InitializeCharacterDropdown() end)
		UIDropDownMenu_SetSelectedValue(self.CharacterDropdown, ALL)
	end
end 