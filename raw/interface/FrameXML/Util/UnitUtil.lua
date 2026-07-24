function GetCreatureIDFromGUID(guid)
	if not guid then return end
	return tonumber(strsub(guid, 6, 12), 16)
end

function GetCreatureIDFromUnit(unit)
	if not unit then return end
	return GetCreatureIDFromGUID(UnitGUID(unit))
end

function GetCreatureSpawnIDFromGUID(guid)
	if not guid then return end
	return tonumber(strsub(guid, 15, 18), 16)
end

function GetCreatureSpawnIDFromUnit(unit)
	if not unit then return end
	return GetCreatureSpawnIDFromGUID(UnitGUID(unit))
end

function GetGroupUnitToken()
	if GetNumRaidMembers() > 0 then
		return "raid"
	else
		return "party"
	end
end

function GetCreatureNameByID(id)
	local creature = Creature:CreateFromID(id)
	if not creature then return "|cffff0000BAD CREATURE ID|r" end
	creature:Query() 
	return creature:GetName() or RED_FONT_COLOR:WrapText(RETRIEVING_DATA)
end

function UnitPvEPower(unit)
	local totalPvEPower = 0

	for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local id = GetInventoryItemTrueID(unit, slot)
		if id then
			local itemInfo = GetItemInfoInstant(id)
			if itemInfo then
				totalPvEPower = totalPvEPower + (itemInfo.pvePower or 0)
			end
		end
	end

	totalPvEPower = min(totalPvEPower, PVP_POWER_CAP)

	return totalPvEPower
end

function UnitPvPPower(unit)
	local totalPvPPower = 0

	for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local id = GetInventoryItemTrueID(unit, slot)
		if id then
			local itemInfo = GetItemInfoInstant(id)
			if itemInfo then
				totalPvPPower = totalPvPPower + (itemInfo.pvpPower or 0)
			end
		end
	end

	totalPvPPower = min(totalPvPPower, PVP_POWER_CAP)

	return totalPvPPower
end

-- returns Enum.PrimaryStat if the unit has a stat buff.
function UnitPrimaryStat(unit)
	return GetUnitPrimaryStat(unit)
end

-- returns true if the unit is in your party or raid
function UnitInGroup(unit)
	if not unit then return end
	return UnitInParty(unit) or UnitInRaid(unit)
end

-- returns true if the unit has an immunity
function UnitIsImmune(unit)
	return AuraUtil.HasImmunity(unit)
end

-- returns true if the unit has an absorb effect. 
-- does not return absorb amount, client does not know this information.
function UnitHasAbsorb(unit)
	return AuraUtil.HasAbsorb(unit)
end

local function GetGUIDType(guid)
	return bit.band(tonumber(guid:sub(5,5), 16) or 0, 0x7)
end

function GUIDIsPet(guid)
	if not guid then return end
	if GetGUIDType(guid) == 4 then
		return true
	end
end

function GUIDIsPlayer(guid)
	if not guid then return end
	if GetGUIDType(guid) == 0 then
		return true
	end
end

function GUIDIsNPC(guid)
	if not guid then return end
	if GetGUIDType(guid) == 3 then
		return true
	end
end

function GUIDIsVehicle(guid)
	if not guid then return end
	local unitTypeMask = tonumber(guid:sub(5,5), 16)
	if unitTypeMask == 5 then
		return true
	end
end

function UnitIsPet(unit)
	if not unit or not UnitExists(unit) then
		return false
	end

	return GUIDIsPet(UnitGUID(unit))
end

-- checks unit name cvars and returns true if the unit should display a name above its head
function UnitShouldDisplayName(unit)
	if not unit or not UnitExists(unit) then
		return false

	elseif UnitIsUnit("player", unit) then
		return C_CVar.GetBool("UnitNameOwn")

	elseif not UnitIsPlayer(unit) then
		return C_CVar.GetBool("UnitNameNPC")

	elseif UnitIsPlayer(unit) then
		if UnitIsFriend("player", unit) then
			return C_CVar.GetBool("UnitNameFriendlyPlayerName")
		else
			return C_CVar.GetBool("UnitNameEnemyPlayerName")
		end

	elseif UnitIsPet(unit) then
		if UnitIsFriend("player", unit) then
			return C_CVar.GetBool("UnitNameFriendlyPetName")
		else
			return C_CVar.GetBool("UnitNameEnemyPetName")
		end
	end
	
	return true
end

function GetPlayerUIDFromGUID(guid)
	return tonumber(guid:sub(12, 18), 16)
end

function GetPlayerUID(unit)
	if not unit then return end
	return GetPlayerUIDFromGUID(UnitGUID(unit))
end

function UnitFullName(unit)
	return UnitName(unit), unit == "player" and GetRealmName() or nil
end

function GetAverageItemLevel()
	return UnitAverageItemLevel("player")
end