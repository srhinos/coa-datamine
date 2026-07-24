C_AddonPanel = {
	addons = {},
	addonsByName = {},
	addonsByIndex = {},
	saveFile = "AddonPresets",
}

local ReadCustomWTF = ReadCustomWTF
local WriteCustomWTF = WriteCustomWTF
local saveStates = {}

local function LoadSaveStates()
	if not ReadCustomWTF or not WriteCustomWTF then
		ReadCustomWTF = _G["ReadCustomWTF"]
		WriteCustomWTF = _G["WriteCustomWTF"]
	end

	local compressed = ReadCustomWTF(C_AddonPanel.saveFile)
	if compressed and strlen(compressed) > 0 then
		local data = C_Serialize:DeserializeDecompressFromPrint(compressed)
		if data then
			saveStates = data
		end
	end
end

AddonInfoMixin = {}

function AddonInfoMixin:SetAddon(index)
	self.id = index
	self.name, self.title, self.notes, self.enabled, self.loadable, self.reason, self.security = GetAddOnInfo(index)

	if not IsKnownAddon(self.name) and not C_CVar.GetBool("loadUnknownAddOns") then
		self.loadable = false
		self.reason = "NOT_LAUNCHER"
	end

	self.enabled = self.enabled or false

	if self.initialState == nil then
		self.initialState = self.enabled
	end

	if InGlue() then
		self.url = self.enabled
		self.enableState = GetAddOnEnableState(AddonPanel.selectedCharacter, self.id)
		self.enabled = self.enableState > 0
		self.initialState = self.enabled -- unused in glue
	else
		self.enableState = self.enabled and 2 or 0
		self.version = GetAddOnMetadata(self.name, "Version")
		self.author = GetAddOnMetadata(self.name, "Author")
		self.iconTexture = GetAddOnMetadata(self.name, "X-IconTexture")
		if self.initialState == nil then
			self.initialState = self.enabled
		end
	end
	self.dependencies = { GetAddOnDependencies(self.id) }
end

function AddonInfoMixin:Refresh()
	if not self.id then return end
	self:SetAddon(self.id)
end

LoadSaveStates()

local HIDDEN_ADDONS = {
	["Ascension_AddonPanel"] = true,
}

function C_AddonPanel:InitializeAddonList()
	for i = 1, GetNumAddOns() do
		local name = GetAddOnInfo(i)
		if HIDDEN_ADDONS[name] then
			if InGlue() then
				EnableAddOn(nil, i)
			else
				EnableAddOn(i)
			end
		else
			local addon = CreateFromMixins(AddonInfoMixin)
			addon:SetAddon(i)
			tinsert(self.addons, addon)
			self.addonsByName[name] = addon
			self.addonsByIndex[i] = addon
		end
	end

	table.sort(self.addons, function(l, r)
		-- only compare up until first space or _
		local lval = l.name:match("([%a!]*)"):lower()
		local rval = r.name:match("([%a!]*)"):lower()

		if lval == rval then
			if #l.dependencies == 0 and #r.dependencies > 0 then
				return true
			elseif #l.dependencies > 0 and #r.dependencies == 0 then
				return false
			else
				return l.name:lower() < r.name:lower()
			end
		end
		return l.name:lower() < r.name:lower()
	end)
end

function C_AddonPanel:GetAddonObject(name)
	if type(name) == "number" then
		return self.addonsByIndex[name]
	else
		return self.addonsByName[name]
	end
end

function C_AddonPanel:RefreshAddonData()
	for i, addon in ipairs(self.addons) do
		if HIDDEN_ADDONS[addon.name] then
			tremove(self.addons, i)
			return C_AddonPanel:RefreshAddonData() -- restart
		else
			addon:Refresh()
		end
	end
end

function C_AddonPanel:UpdateAddonList()
	if not IsExtensionsLoaded() then return end
	for _, addon in ipairs({GetSecureAddons()}) do
		if addon ~= "Ascension_UIDevelopmentTools" then
			HIDDEN_ADDONS[addon] = true
		end
	end

	if #self.addons == 0 then
		self:InitializeAddonList()
	else
		self:RefreshAddonData()
	end
end

function C_AddonPanel:EnableHiddenAddons()
	local hiddenAddons = {GetSecureAddons()}
	hiddenAddons = table.invert(hiddenAddons)
	for i = 1, GetNumAddOns() do
		local name = GetAddOnInfo(i)
		if hiddenAddons[name] then
			if InGlue() then
				EnableAddOn(nil, i)
			else
				EnableAddOn(i)
			end
		end
	end
end

function C_AddonPanel:IsSecureAddon(id)
	local name = GetAddOnInfo(id)
	return HIDDEN_ADDONS[name] or name:sub(1, 9) == "Blizzard_"
end

function C_AddonPanel:GetNumInsecureAddons()
	if #self.addons == 0 then
		C_AddonPanel:UpdateAddonList()
	end
	return #self.addons
end

function C_AddonPanel:EnumerateAddOns()
	if #self.addons == 0 then
		C_AddonPanel:UpdateAddonList()
	end
	return ipairs(self.addons)
end

function C_AddonPanel:HasConfigurableAddons()
	return C_AddonPanel:GetNumInsecureAddons() > 0
end

function C_AddonPanel:GetAddonIndex(addonToFind, addons)
	if not addons then addons = self.addons end
	for i, addon in ipairs(self.addons) do
		if addon == addonToFind or addon.name == addonToFind then
			return i
		end
	end
end

function C_AddonPanel:GetAddonIndexRaw(addonToFind)
	for i = 1, GetNumAddOns() do
		local name = GetAddOnInfo(i)
		if name == addonToFind then
			return i
		end
	end
end

function C_AddonPanel:GetSearchedAddons(searchText, selectedAddon)
	C_AddonPanel:UpdateAddonList()
	if not searchText or strlen(searchText) == 0 then
		return self.addons, C_AddonPanel:GetAddonIndex(selectedAddon)
	end

	local addons = {}
	local selectedIndex
	for _, addon in ipairs(self.addons) do
		if self:IsAddonSearched(addon, searchText) then
			tinsert(addons, addon)
			if selectedAddon == addon then
				selectedIndex = #addons
			end
		end
	end
	
	return addons, selectedIndex
end

function C_AddonPanel:IsAddonSearched(addon, searchText)
	if not searchText or strlen(searchText) == 0 then return true end
	searchText = searchText:lower()
	if addon.name:lower():find(searchText) or addon.title and addon.title:lower():find(searchText) then
		return true
	end

	return false
end

function C_AddonPanel:GetAddonDisabledBy(addon)
	if InGlue() then
		local state = GetAddOnEnableState(nil, addon.id)
		if state == 0 then
			return ALL
		end

		if state == 2 then
			return
		end

		local names
		for i=1, GetNumCharacters() do
			local name = GetCharacterInfo(i)
			state = GetAddOnEnableState(name, addon.id)
			if state == 0 then
				if names then
					names = names .. ", " .. name
				else
					names = name
				end
			end
		end
		
		return names
	else
		if addon.enabled then
			return
		end
		
		return C_Player:GetName()
	end
end

function C_AddonPanel:MakeSaveState()
	self:UpdateAddonList()
	
	local state = {}

	for _, addon in ipairs(self.addons) do
		tinsert(state, { addon.name, addon.enableState == 2 })
	end
	
	return state
end

function C_AddonPanel:RestoreSaveState(state)
	for _, data in ipairs(state) do
		local name, enabled = unpack(data)
		if InGlue() then
			local char = AddonPanel:IsShown() and AddonPanel.selectedCharacter
			local index = C_AddonPanel:GetAddonIndexRaw(name)
			if index then
				if enabled then
					EnableAddOn(char, index)
				else
					DisableAddOn(char, index)
				end
			end
		else
			if enabled  then
				EnableAddOn(name)
			else
				DisableAddOn(name)
			end
		end
	end
end

function C_AddonPanel:WriteSaveState(id, state, write)
	saveStates[id] = state
	if not write then return end
	local compressed = C_Serialize:SerializeCompressForPrint(saveStates)
	if compressed then
		WriteCustomWTF(self.saveFile, compressed)
	end
end

function C_AddonPanel:GetSaveState(id)
	return saveStates[id]
end

function C_AddonPanel:GetSaveStateIDs()
	local ids = {}
	for id in pairs(saveStates) do
		tinsert(ids, id)
	end
	
	return ids
end

function C_AddonPanel:DeleteSaveState(id)
	self:WriteSaveState(id, nil, true)
end