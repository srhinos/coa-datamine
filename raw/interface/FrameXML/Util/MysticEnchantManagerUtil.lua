local FREE_PRESETS = 0

MysticEnchantManagerUtil = {}

local saveFile = "MysticEnchantSaved"
local ReadCustomWTF = ReadCustomWTF
local WriteCustomWTF = WriteCustomWTF
local MysticEnchantSavedDB = {}

-- load saved mystic enchant db
local function LoadSaveStates()
	if not ReadCustomWTF or not WriteCustomWTF then
		ReadCustomWTF = _G["ReadCustomWTF"]
		WriteCustomWTF = _G["WriteCustomWTF"]
	end

	local compressed = ReadCustomWTF(saveFile)
	if compressed and strlen(compressed) > 0 then
		local data = C_Serialize:DeserializeDecompressFromPrint(compressed)
		if data then
			MysticEnchantSavedDB = data
		end
	end
end

LoadSaveStates()

local function GetDB()
	local dbKey = UnitName("player") .. "-" .. GetRealmName()
	if not MysticEnchantSavedDB[dbKey] then
		MysticEnchantSavedDB[dbKey] = {}
	end
	return MysticEnchantSavedDB[dbKey]
end


local PresetUnlockItem = Item:CreateFromID(ItemData.UNLOCK_ENCHANT_PRESET)

function MysticEnchantManagerUtil.GetEditablePreset()
	return MysticEnchantManagerUtil.editablePreset
end

function MysticEnchantManagerUtil.SetEditablePreset(index)
	MysticEnchantManagerUtil.editablePreset = index
end

function MysticEnchantManagerUtil.GetPresetUnlockItem()
	return PresetUnlockItem
end

function MysticEnchantManagerUtil.GetMaxPresets()
	return MAX_MYSTIC_ENCHANT_PRESETS
end

function MysticEnchantManagerUtil.GetFreePresets()
	return FREE_PRESETS -- ??
end

function MysticEnchantManagerUtil.HasUnlockItem()
	return GetItemCount(PresetUnlockItem:GetItemID()) > 0
end

function MysticEnchantManagerUtil.GetNumPresets()
	local numPresets = C_MysticEnchantPreset.GetNumPresets()

	if (numPresets < MysticEnchantManagerUtil.GetFreePresets()) then
		numPresets = numPresets + (MysticEnchantManagerUtil.GetFreePresets() - numPresets) -- 2 unlocked at max level
	elseif (numPresets < MysticEnchantManagerUtil.GetMaxPresets()) then
		numPresets = numPresets + 1 -- add unlock option
	end

	return numPresets
end

function MysticEnchantManagerUtil.GetPresetData(index)
	return C_MysticEnchantPreset.GetPresetData(index)
end

function MysticEnchantManagerUtil.GetActualPresetName(index)
	local db = GetDB()
	if db[index] then
		return db[index].name
	end
end

function MysticEnchantManagerUtil.GetPresetName(index)
	return MysticEnchantManagerUtil.GetActualPresetName(index) or (ENCHANT_SPECIALIZATION.." "..index)
end

function MysticEnchantManagerUtil.GetActivePreset()
	local numPresets = C_MysticEnchantPreset.GetNumPresets()
	if not numPresets or numPresets == 0 then
		return 1
	else
		for i = 1, numPresets do
			local _, isActive = MysticEnchantManagerUtil.GetPresetData(i)
			if isActive then
				return i
			end
		end
	end

	return 1
end

function MysticEnchantManagerUtil.GetActualPresetIcon(index)
	local db = GetDB()
	if db[index] then
		return db[index].icon
	end
end

function MysticEnchantManagerUtil.GetPresetIcon(index)
	return MysticEnchantManagerUtil.GetActualPresetIcon(index) or PresetUnlockItem:GetIcon()
end

function MysticEnchantManagerUtil.UpdatePresetSlotMap(index, slotMap, slotMapLayout)
	local db = GetDB()
	db[index] = db[index] or {}

	db[index].slotMap = slotMap
	db[index].slotMapLayout = slotMapLayout

	MysticEnchantManagerUtil.WritePresets()
end

function MysticEnchantManagerUtil.GetPresetSlotMap(index)
	local db = GetDB()
	if db[index] then
		return db[index].slotMap, db[index].slotMapLayout
	end
end

function MysticEnchantManagerUtil.GetPresetInfo(index)
	return MysticEnchantManagerUtil.GetPresetName(index), MysticEnchantManagerUtil.GetPresetIcon(index)
end

function MysticEnchantManagerUtil.SaveCurrentAndActivateIndex(index)
	return MysticEnchantManagerUtil.AttemptOperation("Activate", "CanActivate", index)
end

function MysticEnchantManagerUtil.WritePresets()
	if not issecure() then
		return C_Logger.Error("Tried to write %s.wtf from insecure code!", saveFile)
	end
	local compressed = C_Serialize:SerializeCompressForPrint(MysticEnchantSavedDB)
	if compressed then
		WriteCustomWTF(saveFile, compressed)
	end
end

function MysticEnchantManagerUtil.UpdatePresetData(name, icon)
	local index = MysticEnchantManagerUtil.GetEditablePreset()

	if not index then
		return
	end

	local db = GetDB()
	db[index] = db[index] or {}

	db[index].name = name
	db[index].icon = icon

	MysticEnchantManagerUtil.WritePresets()

	if index == MysticEnchantManagerUtil.GetActivePreset() then
		C_Hook:SendEvent("MYSTIC_ENCHANT_PRESET_SET_ACTIVE_RESULT")
	end
end

function MysticEnchantManagerUtil.AttemptOperation(func, checkFunc, ...)
	dprint("MysticEnchantManagerUtil.AttemptOperation "..func..", "..checkFunc)

	dprint(...)

	local success, errorTable = C_MysticEnchantPreset[checkFunc](...)

	if not success then
		if errorTable then
			for _, errorStr in pairs(errorTable) do
				errorStr = _G[errorStr] or errorStr
				SendSystemMessage("|cffFF0000"..errorStr.."|r")
				UIErrorsFrame:AddMessage(errorStr, 1, 0, 0)
			end
		end
		return false
	end

	C_MysticEnchantPreset[func](...)
	return true
end
