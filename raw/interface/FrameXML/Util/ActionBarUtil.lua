ActionBarUtil = {
	_spellCache = {},
	_macroCache = {}
}

local ReadCustomWTF, WriteCustomWTF = ReadCustomWTF, WriteCustomWTF

local function SaveActionBarState(actionBarState)
	local serialized = C_Serialize:SerializeCompressForPrint(actionBarState)
	WriteCustomWTF("SavedActionBar", serialized)
end

local function LoadActionBarState()
	local serialized = ReadCustomWTF("SavedActionBar")
	if serialized then
		local success, actionBarState = C_Serialize:DeserializeCompressForPrint(serialized)
		if success then
			return actionBarState
		end
	end
end

local MAX_ACTION_BUTTONS = 144
local POSSESSION_START = 121
local POSSESSION_END = 132
local MAX_MACROS = 54

function ActionBarUtil:FormatActionForSave(id)
	local actionType, actionId, subType, extraId = GetActionInfo(id)
	if not actionType then
		return
	end

	if actionType == "spell" then
		local spell
		if actionId and actionId ~= 0 then
			spell= GetSpellName(actionId, BOOKTYPE_SPELL)
		elseif extraId and extraId ~= 0 then
			spell = GetSpellInfo(extraId)
		end

		if spell then
			return { actionType, spell, subType, extraId }
		end
	elseif actionType == "macro" then
		local name, icon, macro = GetMacroInfo(actionId)
		if name and icon and macro then
			return { actionType, actionId, C_Deflate:CompressDeflate(name .. macro) }
		end
	else
		return { actionType, actionId, subType, extraId }
	end
end

function ActionBarUtil:PlaceAction(slot, actionInfo)
	ClearCursor()
	local actionType, actionId, subType = unpack(actionInfo)

	if actionType == "item" then
		PickupItem(actionId)

	elseif actionType == "spell" and actionId ~= nil then
		local name = actionId
		local spellId = C_Spell:GetSpellID(name)
		if self._spellCache[spellId] then
			PickupSpell(self._spellCache[spellId], BOOKTYPE_SPELL)
		end
		
	elseif actionType == "macro" then
		local serialized = subType
		if serialized and self._macroCache[serialized] then
			PickupMacro(self._macroCache[serialized])
		end

	elseif actionType == "companion" then
		PickupCompanion(subType, actionId)
	
	elseif actionType == "equipmentset" then
		for i = 1, GetNumEquipmentSets() do
			if GetEquipmentSetInfo(i) == actionId then
				PickupEquipmentSet(i)
				break
			end
		end
	end

	if GetCursorInfo() ~= actionType then
		ClearCursor()
		return
	end

	PlaceAction(slot)
end

function ActionBarUtil:GetActionBarState()
	local state = {}

	for i = 1, MAX_ACTION_BUTTONS do
		if i < POSSESSION_START or i > POSSESSION_END then
			state[i] = self:FormatActionForSave(i)
		end
	end
	
	return state
end

function ActionBarUtil:RestoreActionBarState(state)
	if not state then return end
	wipe(self._spellCache)
	wipe(self._macroCache)

	for tab = 1, MAX_SKILLLINE_TABS do
		local _, _, offset, numSpells = GetSpellTabInfo(tab)

		for i = 1, numSpells do
			local index = offset + i
			local spell, rank = GetSpellName(index, BOOKTYPE_SPELL)
			local spellId = C_Spell:GetSpellID(spell, rank)
			self._spellCache[spellId] = index
		end
	end

	for i = 1, MAX_MACROS do
		local name, _, macro = GetMacroInfo(i)

		if name and macro then
			local serialized = C_Deflate:CompressDeflate(name .. macro)
			if serialized then
				self._macroCache[serialized] = i
			end
		end
	end
	
	local soundToggle = GetCVar("Sound_EnableAllSound")
	SetCVar("Sound_EnableAllSound", 0)

	for i = 1, MAX_ACTION_BUTTONS do
		if i < POSSESSION_START or i > POSSESSION_END then
			local actionInfo = state[i]
			PickupAction(i)
			ClearCursor()

			if actionInfo then
				self:PlaceAction(i, actionInfo)
			end
		end
	end

	SetCVar("Sound_EnableAllSound", soundToggle)
end

function ActionBarUtil:FindSpellOnActionBar(spell)
	if not spell then return false end

	for i = 1, MAX_ACTION_BUTTONS do
		if i < POSSESSION_START or i > POSSESSION_END then
			local actionType, actionId, subType, extraId = GetActionInfo(i)
			if actionType == "spell" then
				if tonumber(spell) == extraId then
					return i
				elseif spell and GetSpellInfo(extraId) == spell then
					return i
				end
			elseif actionType == "macro" then
				local name = GetMacroSpell(actionId)
				if tonumber(spell) then
					spell = GetSpellInfo(spell)
				end

				if name and name == spell then
					return i
				end
			end
		end
	end

	if tonumber(spell) then
		spell = GetSpellInfo(spell)
	end

	if not spell then return false end

	for i = 1, GetNumShapeshiftForms() do
		local _, name = GetShapeshiftFormInfo(i)
		if name == spell then
			return i, true
		end
	end
	
	return false
end

function ActionBarUtil:FindItemOnActionBar(item)
	for i = 1, MAX_ACTION_BUTTONS do
		if i < POSSESSION_START or i > POSSESSION_END then
			local actionType, actionId = GetActionInfo(i)
			if actionType == "item" then
				if tonumber(item) == actionId then
					return i
				elseif item and GetItemInfo(actionId) == item then
					return i
				end
			elseif actionType == "macro" then
				local name = GetMacroItem(actionId)
				if tonumber(item) then
					item = GetItemInfo(item)
				end

				if name and name == item then
					return i
				end
			end
		end
	end

	return false
end

function ActionBarUtil:IsActionSpell(action, spell)
	local actionType, actionId, subType, extraId = GetActionInfo(action)
	if actionType == "spell" then
		if tonumber(spell) == actionId or tonumber(spell) == extraId then
			return true
		elseif spell and GetSpellInfo(extraId) == spell then
			return true
		end
	elseif actionType == "macro" then
		local name = GetMacroSpell(actionId)
		if tonumber(spell) then
			spell = GetSpellInfo(spell)
		end

		if name and name == spell then
			return true
		end
	end
	
	return false
end

function ActionBarUtil:IsActionItem(action, item)
	local actionType, actionId = GetActionInfo(action)
	if actionType == "item" then
		if tonumber(item) == actionId then
			return true
		elseif item and GetItemInfo(actionId) == item then
			return true
		end
	elseif actionType == "macro" then
		local name = GetMacroItem(actionId)
		if tonumber(item) then
			item = GetItemInfo(item)
		end

		if name and name == item then
			return true
		end
	end
	
	return false
end

function ActionBarUtil:FELFORGED_RESET_PAYLOAD()
	if not C_GameMode:IsGameModeActive(Enum.GameMode.Felforged) then
		self:GAME_MODE_UPDATE()
		return
	end

	local saved = LoadActionBarState()
	if saved then
		local state = C_Serialize:DeserializeDecompressFromPrint(saved)
		if state then
			self:RestoreActionBarState(state)
		end
	end
end

function ActionBarUtil:ZONE_CHANGED_NEW_AREA()
	if not C_GameMode:IsGameModeActive(Enum.GameMode.Felforged) then
		self:GAME_MODE_UPDATE()
		return
	end

	if C_Player:GetLevel() == 20 and not ZoneUtil.IsOnMap(806) then
		local state = self:GetActionBarState()
		SaveActionBarState(state)
	end
end

function ActionBarUtil:GAME_MODE_UPDATE()
	if not C_GameMode:IsGameModeActive(Enum.GameMode.Felforged) then
		C_Hook:Unregister(self, "FELFORGED_RESET_PAYLOAD")
		C_Hook:Unregister(self, "ZONE_CHANGED_NEW_AREA")
		C_Hook:Unregister(self, "PLAYER_LEVEL_UP")
	else
		C_Hook:Register(self, "FELFORGED_RESET_PAYLOAD")
		C_Hook:Register(self, "ZONE_CHANGED_NEW_AREA")
		C_Hook:Register(self, "PLAYER_LEVEL_UP")
	end
end

C_Hook:Register(ActionBarUtil, "GAME_MODE_UPDATE")