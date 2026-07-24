C_Instance = {}

function C_Instance.IsInRaid()
	local inInstance, instanceType = IsInInstance()

	if inInstance then
		return instanceType == "raid"
	end
	
	return false
end

function C_Instance.IsInDungeon()
	local inInstance, instanceType = IsInInstance()

	if inInstance then
		return instanceType == "party"
	end

	return false
end

function C_Instance.IsInPVE()
	return C_Instance.IsInRaid() or C_Instance.IsInDungeon()
end

function C_Instance.IsInBattleground()
	local inInstance, instanceType = IsInInstance()

	if inInstance then
		return instanceType == "pvp"
	end

	return false
end

function C_Instance.IsInArena()
	local inInstance, instanceType = IsInInstance()

	if inInstance then
		return instanceType == "arena"
	end

	return false
end

function C_Instance.IsInPVP()
	return C_Instance.IsInArena() or C_Instance.IsInBattleground()
end

function C_Instance.HasCheckpoint()
	if not C_Instance.IsInRaid() then
		return false
	end

	local enabled = GetCheckpointsEnabled()
	if enabled == nil then
		return HAS_RAID_CHECKPOINT -- this will be nil when aio is removed completely
	end

	return enabled
end

function C_Instance:CanUseCheckpoint()
	if not C_Player:IsDead() then
		return false
	end

	local gameMode = GetCustomGameMode()

	if bit.contains(gameMode, Enum.GameMode.Ironman) then
		return false
	end

	if bit.contains(gameMode, Enum.GameMode.Survivalist) then
		return false
	end

	if bit.contains(gameMode, Enum.GameMode.Felforged) then
		return false
	end

	if UnitExists("boss1") then
		return false
	end

	return true
end 

function C_Instance:GetSavedMapAndDifficulty()
	local locks = {}

	for difficultyID = 1, 4 do
		for isRaid = 0, 1 do
			for _, mapID in ipairs(C_LootLockout.ListInstanceBinds(isRaid == 1, difficultyID)) do
				tinsert(locks, {mapID = mapID, difficultyID = difficultyID})
			end
		end
	end
	
	return locks
end

function C_Instance:GetInstanceLocks()
	local numInstances = GetNumSavedInstances()
	
	local savedInstances = {}

	-- add default instances
	for i = 1, numInstances do
		local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName = GetSavedInstanceInfo(i)
		local mapID = GetMapID(instanceName)

		savedInstances[mapID] = savedInstances[mapID] or {}
		savedInstances[mapID][instanceDifficulty] = {
			mapID = mapID,
			instanceName = instanceName,
			instanceID = instanceID,
			instanceReset = instanceReset,
			instanceDifficulty = instanceDifficulty,
			locked = locked,
			extended = extended,
			instanceIDMostSig = instanceIDMostSig,
			isRaid = isRaid,
			maxPlayers = maxPlayers,
			difficultyName = difficultyName,
		}
	end
	
	local lockouts = GetLootLockouts("player")
	for mapID, difficulties in pairs(lockouts) do
		if not savedInstances[mapID] then
			savedInstances[mapID] = {}
		end

		for difficultyID in pairs(difficulties) do
			local difficulty = difficultyID + 1
			if not savedInstances[mapID][difficulty] then
				numInstances = numInstances + 1
				savedInstances[mapID][difficulty] = {
					mapID = mapID,
					instanceName = GetMapName(mapID),
					instanceID = -1,
					instanceReset = -1,
					instanceDifficulty = difficulty,
					locked = true,
					extended = false,
					instanceIDMostSig = 0,
					isRaid = true,
					maxPlayers = 25,
					difficultyName = _G["RAID_DIFFICULTY"..difficulty],
					lockout = GetEncounterDatasForMapAndDifficulty("player", mapID, difficulty),
				}
			else
				savedInstances[mapID][difficulty].lockout = GetEncounterDatasForMapAndDifficulty("player", mapID, difficulty)
			end
		end
	end
	
	local instanceList = {}

	for _, difficulties in pairs(savedInstances) do
		for _, instance in pairs(difficulties) do
			tinsert(instanceList, instance)
		end
	end

	return instanceList, #instanceList
end
