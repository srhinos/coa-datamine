SpecializationUtil = {}

local enterWorldCallback
enterWorldCallback = EventRegistry:RegisterFrameEventAndCallbackWithHandle("PLAYER_ENTERING_WORLD", function()
	EventRegistry:RegisterFrameEventAndCallback("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED", SpecializationUtil.ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED)
	enterWorldCallback:Unregister()
	enterWorldCallback = nil
end)

local saveFile = "SpecializationSaved"
local ReadCustomWTF = ReadCustomWTF
local WriteCustomWTF = WriteCustomWTF
local SpecializationSavedDB = {}

-- load saved spec db
local function LoadSaveStates()
	if not ReadCustomWTF or not WriteCustomWTF then
		ReadCustomWTF = _G["ReadCustomWTF"]
		WriteCustomWTF = _G["WriteCustomWTF"]
	end

	local compressed = ReadCustomWTF(saveFile)
	if compressed and strlen(compressed) > 0 then
		local data = C_Serialize:DeserializeDecompressFromPrint(compressed)
		if data then
			SpecializationSavedDB = data
		end
	end
end

LoadSaveStates()

local function GetDB()
	local dbKey = UnitName("player") .. "-" .. GetRealmName()
	if not SpecializationSavedDB[dbKey] then
		SpecializationSavedDB[dbKey] = {}
	end
	return SpecializationSavedDB[dbKey]
end

local function CreateDefaultSpecializationInfo(index)
	local db = GetDB()
	if db[index] and db[index].name and db[index].icon then
		return
	end
	
	db[index] = {
		name = SPECIALIZATION_LABEL .. " " .. index,
		icon = "Interface\\Icons\\inv_misc_book_16",
		isPrestigeLocked = true,
	}
end

function SpecializationUtil.WriteSavedSpecializations()
	if not issecure() then
		return C_Logger.Error("Tried to write %s.wtf from insecure code!", saveFile)
	end
	local compressed = C_Serialize:SerializeCompressForPrint(SpecializationSavedDB)
	if compressed then
		WriteCustomWTF(saveFile, compressed)
	end
end

function SpecializationUtil.GetActiveSpecialization()
	local activeSpecID = C_CharacterAdvancement.GetActiveSpecID()
	
	return activeSpecID
end 

function SpecializationUtil.GetNumSpecializations()
	return #SPEC_SWAP_SPELLS
end

function SpecializationUtil.GetNumSpecializationsUnlocked()
	local numUnlocked = 0
	for i = 1, SpecializationUtil.GetNumSpecializations() do
		if SpecializationUtil.IsSpecializationUnlocked(i) then
			numUnlocked = i
		else
			return numUnlocked -- specs are unlocked sequentially so this should be fine
		end
	end
	return numUnlocked
end

function SpecializationUtil.SetSpecializationName(specID, name)
	local db = GetDB()
	if not db[specID] then
		CreateDefaultSpecializationInfo(specID)
	end
	
	if string.isNilOrEmpty(name) then
		name = SPECIALIZATION_LABEL.." "..self.index
	end
	
	db[specID].name = name
	SpecializationUtil.WriteSavedSpecializations()
end

function SpecializationUtil.SetSpecializationIcon(specID, icon)
	local db = GetDB()
	if not db[specID] then
		CreateDefaultSpecializationInfo(specID)
	end

	db[specID].icon = icon
	SpecializationUtil.WriteSavedSpecializations()
end

function SpecializationUtil.ToggleSpecializationPrestigeLock(specID)
	local db = GetDB()

	if not db[specID] then
		CreateDefaultSpecializationInfo(specID)
	end

	db[specID].isPrestigeLocked = not(db[specID].isPrestigeLocked)
	
	EventRegistry:TriggerEvent("Specialization.PrestigeLockChanged", specID)
	SpecializationUtil.WriteSavedSpecializations()
end

function SpecializationUtil.SetSpecializationEquipmentSet(specID, setName)
	SetEquipmentSetIDForSpecialization(specID, setName)
end

function SpecializationUtil.SetSpecializationEnchantPreset(specID, presetID)
	SetMysticEnchantPresetIDForSpecialization(specID, presetID)
end

function SpecializationUtil.GetSpecializationInfo(specID)
	SpecializationUtil.ConvertOldSavedSpec(specID)
	local db = GetDB()
	if not db[specID] then
		CreateDefaultSpecializationInfo(specID)
	end
	
	local info = db[specID]
	local specName = info.name
	local icon = info.icon
	local equipmentSet = GetEquipmentSetIDForSpecialization(specID)
	local enchantPreset = GetMysticEnchantPresetIDForSpecialization(specID)
	local isPrestigeLocked = info.isPrestigeLocked
	return specName, icon, equipmentSet, enchantPreset, isPrestigeLocked
end

function SpecializationUtil.GetCurrentSpecializationInfo()
	local specID = SpecializationUtil.GetActiveSpecialization()
	return SpecializationUtil.GetSpecializationInfo(specID)
end

function SpecializationUtil.GetSpecializationSpell(specID)
	return SPEC_SWAP_SPELLS[specID]
end

function SpecializationUtil.IsSpecializationUnlocked(specID)
	if specID > #SPEC_SWAP_SPELLS or specID < 1 then return false end

	-- We always know spec 1
	if specID == 1 then return true end

	local spellID = SPEC_SWAP_SPELLS[specID]
	return spellID and spellID > 0 and IsSpellKnown(spellID)
end

function SpecializationUtil.IsSpecializationBuildDraft(specID)
	return IsBuildDraftModeEnabled(specID)
end 

function SpecializationUtil.IsCurrentSpecialization(specID)
	return C_CharacterAdvancement.GetActiveSpecID() == specID
end

function SpecializationUtil.EquipSetForSpecID(specID)
	local _, _, setName = SpecializationUtil.GetSpecializationInfo(specID)
	if setName then
		EquipmentManager_EquipSet(setName)
	end
end

function SpecializationUtil.ActivatePresetForSpecID(specID)
	local _, _, _, presetID = SpecializationUtil.GetSpecializationInfo(specID)
	if presetID then
		MysticEnchantManagerUtil.AttemptOperation("Activate", "CanActivate", presetID)
	end
end

local function InternalActivateSpecialization(specID)
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON_50)
	local spell = SpecializationUtil.GetSpecializationSpell(specID)
	if spell then
		if GetUnitSpeed("player") == 0 then
			CastSpecialSpell(spell)
			HideUIPanel(Collections)
		else
			UIErrorsFrame:AddMessage(ERR_CHANGE_SPEC_MOVING, RED_FONT_COLOR:GetRGB())
		end
	else
		C_Logger.Error("Tried to activate spec " .. (specID or "nil") .. " but it has no spell associated with it.")
	end
end

local function InternalActivateCheckForBuildDraft(specID)
	local currentSpec = SpecializationUtil.GetActiveSpecialization()
	if not SpecializationUtil.IsSpecializationBuildDraft(currentSpec) and SpecializationUtil.IsSpecializationBuildDraft(specID) then
		StaticPopup_Show("CHANGE_SPEC_BUILD_DRAFT", nil, nil, GenerateClosure(InternalActivateSpecialization, specID))
	else
		InternalActivateSpecialization(specID)
	end
end

function SpecializationUtil.ActivateSpecialization(specID)
	local hasTameSpell = IsSpellKnown(1515) or  -- Check Tame Beast
						 IsSpellKnown(91634) or -- Check Tame Dragonkin
						 IsSpellKnown(91606) or -- Check Tether Elemental
						 IsSpellKnown(891) or -- Check Dominate Undead
						 IsSpellKnown(890) -- Check Enslave Demon
	
	if hasTameSpell then
		StaticPopup_Show("CHANGE_SPEC_STABLE_PET", nil, nil, GenerateClosure(InternalActivateCheckForBuildDraft, specID))
		return
	end

	InternalActivateCheckForBuildDraft(specID)
end 

function SpecializationUtil.ConvertOldSavedSpec(index)
	if AscensionUI_CDB and AscensionUI_CDB.CA2 then
		local name = AscensionUI_CDB.CA2.SpecNamesCustom and AscensionUI_CDB.CA2.SpecNamesCustom[index]
		local icon = AscensionUI_CDB.CA2.SpecIconsCustom and AscensionUI_CDB.CA2.SpecIconsCustom[index]
		local equipmentSet = AscensionUI_CDB.CA2.SpecEnchantPreset and AscensionUI_CDB.CA2.SpecEnchantPreset[index]
		local enchantPreset = AscensionUI_CDB.CA2.SpecEquipmentSet and AscensionUI_CDB.CA2.SpecEquipmentSet[index]

		if name and icon then
			local db = GetDB()
			db[index] = db[index] or {}
			db[index].name = name
			db[index].icon = icon
			db[index].equipmentSet = equipmentSet
			db[index].enchantPreset = enchantPreset
		end
		
		if AscensionUI_CDB.CA2.SpecNamesCustom then
			AscensionUI_CDB.CA2.SpecNamesCustom[index] = nil
		end
		if AscensionUI_CDB.CA2.SpecIconsCustom then
			AscensionUI_CDB.CA2.SpecIconsCustom[index] = nil
		end
		if AscensionUI_CDB.CA2.SpecEnchantPreset then
			AscensionUI_CDB.CA2.SpecEnchantPreset[index] = nil
		end
		if AscensionUI_CDB.CA2.SpecEquipmentSet then
			AscensionUI_CDB.CA2.SpecEquipmentSet[index] = nil
		end
	end
end

function SpecializationUtil.ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED(_, specID)
	SpecializationUtil.EquipSetForSpecID(specID)
	SpecializationUtil.ActivatePresetForSpecID(specID)
end