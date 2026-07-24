local ReadCustomWTF, WriteCustomWTF = ReadCustomWTF, WriteCustomWTF
local WTFFileName = "Keystones"
local KeystoneBests

local KeystoneDungeons = {
	[Enum.Expansion.Vanilla] = {
		2694, -- Ragefire Chasm
		2696, -- Deadmines
		2691, -- Wailing Caverns
		2008, -- Shadowfang Keep
		2700, -- Blackfathom Deeps
		2702, -- Stormwind Stockades
		2708, -- Scarlet Monastery: Graveyard
		2706, -- Razorfen Kraul
		2710, -- Razorfen Downs
		2855, -- Scarlet Monastery: Library
		2704, -- Gnomeregan
		2853, -- Sarelet Monastery: Armory
		2712, -- Uldaman
		2854, -- Scarlet Monastery: Cathedral
		2716, -- Maraudon Orange Cyrstal
		2962, -- Maraudon Purple Cyrstal
		2714, -- Zul'Farrak
		2963, -- Maraudon Pristine Waters
		2718, -- Sunken Temple
		53, -- Lower Scholomance
		56, -- Upper Scholomance
		2030, -- Blackrock Depths: Prison
		2032, -- Lower Blackrock Spire
		2040, -- Stratholme - Main Gate
		2034, -- Dire Maul - East
		2044, -- Upper Blackrock Spire
		2036, -- Dire Maul - West
		2276, -- Blackrock Depths - Upper City
		2274, -- Stratholme - Service Entrance
		2038, -- Dire Maul - North
	},
	[Enum.Expansion.TBC]     = {
		--263, -- The Black Morass
		270, -- The Shattered Halls
		262, -- Shadow Labrynth
		309, -- The Mechanar
		266, -- Steamvault
		269, -- Hellfire Ramparts
		259, -- Auchenai Crypts 
		267, -- The Underbog
		308, -- The Botanica
		261, -- Sethekk Halls
		268, -- Blood Furnace
		265, -- The Slave Pens
		271, -- The Arcatraz
		260, -- Mana Tombs
		--264, -- The Escape from Durnholde
	},
	[Enum.Expansion.WoTLK] = {
		3289, -- Utgarde Pinnacle
		3290, -- The Culling of Stratholme
		3291, -- The Oculus
		3292, -- Halls of Lightning
		3293, -- Halls of Stone
		3294, -- Drak'Tharon Keep
		3295, -- Gundrak
		3296, -- Ahn'kahet: The Old Kingdom
		3297, -- Violet Hold
		3298, -- The Nexus
		3299, -- Azjol-Nerub
		3300, -- Utgarde Keep
		3301, -- Pit of Saron
		3302, -- Halls of Reflection
	}
}

C_Keystones = {}

function C_Keystones.GetPlayerSaveKey()
	if not C_Keystones.playerSaveKey then
		C_Keystones.playerSaveKey = UnitName("player") .. " - " .. GetRealmName("player")
	end

	return C_Keystones.playerSaveKey
end

function C_Keystones.GetCurrentSetString()
	local affixes = C_MythicPlus.GetCurrentAffixes()
	table.sort(affixes)
	local affixString
	for i, affixID in ipairs(affixes) do
		if i > 1 then
			affixString = format("%s,%d", affixString, affixID)
		else
			affixString = tostring(affixID)
		end
	end

	return affixString
end

-- Returns best run for a given set of affixes
-- Returns {{Affixes}, DungeonID, {Players}, Time, Level, Date}
function C_Keystones.GetSetBest(affixSetString, expansion)
	if not affixSetString then return end

	if not expansion then
		expansion = GetExpansionLevel()
	end

	if KeystoneBests[expansion][affixSetString] then
		return KeystoneBests[expansion][affixSetString][C_Keystones.GetPlayerSaveKey()]
	end
end

-- Returns best run for the current set of affixes
-- Returns {{Affixes}, DungeonID, {Players}, Time, Overtime, Level, Date}
function C_Keystones.GetCurrentSetBest()
	--[[return {
		Affixes = {
			2191069,
			2191059,
			2191048,
			2191036,
			2129150,
		},
		DungeonID = 2030,
		Players = {
			{"Andrew", "HERO"}
		},
		Time = 1983,
		Overtime = false,
		Level = 38,
		Date = 1672231663,
	}]]
	return C_Keystones.GetSetBest(C_Keystones.GetCurrentSetString())
end

-- Returns the best run for a given dungeon ID
-- Returns {{Affixes}, DungeonID, {Players}, Time, Overtime, Level, Date}
function C_Keystones.GetDungeonBest(dungeonID)
	if KeystoneBests[dungeonID] then
		return KeystoneBests[dungeonID][C_Keystones.GetPlayerSaveKey()]
	end
end

-- Saves the best run for a given dungeon ID, updating best run for the current set if eligible
function C_Keystones.SaveKeystoneRun(dungeonID, finalTime, overtime, level, a)
	if not a then
		assert(issecure(), "C_Keystones.SaveKeystoneRun: Cannot save keystones through insecure code")
	end
	local isNewBest, isNewRecord = true, true

	-- check if this is better than our best for this set
	local current = C_Keystones.GetCurrentSetBest()
	if current then
		if current.Level > level or (current.DungeonID == dungeonID and current.Time < finalTime) then
			isNewBest = false
		end
	end

	-- we have this key already, check if saved is better
	if C_Keystones.GetDungeonBest(dungeonID) then
		local thisBest = C_Keystones.GetDungeonBest(dungeonID)
		if thisBest.Level > level or thisBest.Time < finalTime then
			isNewRecord = false
		end
	end

	-- not best or new dungeon record
	if not isNewBest and not isNewRecord then
		return
	end

	local newRun = {
		Affixes   = C_MythicPlus.GetCurrentAffixes(),
		DungeonID = dungeonID,
		Players   = {},
		Time      = finalTime,
		Overtime  = overtime,
		Level     = level,
		Date      = time(),
	}

	-- save local player
	local _, playerClass = UnitClass("player")
	local playerName = UnitName("player")
	tinsert(newRun.Players, { playerName, playerClass })

	if a then
		for i = 1, 4 do
			tinsert(newRun.Players, { playerName..i, "HERO" })
		end
	end

	-- save party members
	for i = 1, GetNumPartyMembers() do
		local unitToken = "party" .. i
		local _, class = UnitClass(unitToken)
		local name = UnitName(unitToken)

		tinsert(newRun.Players, { name, class })
	end

	if not KeystoneBests[dungeonID] then
		KeystoneBests[dungeonID] = {}
	end

	if isNewRecord then
		KeystoneBests[dungeonID][C_Keystones.GetPlayerSaveKey()] = newRun
	end

	if isNewBest then
		local affixString = C_Keystones.GetCurrentSetString()
		if not affixString then return end
		if not KeystoneBests[GetExpansionLevel()][affixString] then
			KeystoneBests[GetExpansionLevel()][affixString] = {}
		end
		KeystoneBests[GetExpansionLevel()][affixString][C_Keystones.GetPlayerSaveKey()] = newRun
	end

	local compressed = C_Serialize:SerializeCompressForPrint(KeystoneBests)
	WriteCustomWTF(WTFFileName, compressed)
end

-- Returns dungeon name, texture key, and the best run (if any)
function C_Keystones.GetKeystoneDungeonInfo(dungeonID)
	local name, _, _, _, _, _, _, _, _, texture = GetLFGDungeonInfo(dungeonID)
	if not name then return end

	local bestRun = C_Keystones.GetDungeonBest(dungeonID)

	return name, texture, bestRun
end

-- Returns the dungeon IDs for a given expansion
function C_Keystones.GetTimedDungeonsForExpansion(expansion)
	if not expansion then
		expansion = GetExpansionLevel()
	end

	return KeystoneDungeons[expansion]
end

-- Returns the itemID of the players current keystone
function C_Keystones.GetKeystoneInInventoryItemID()
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			if itemID and C_MythicPlus.IsItemKeystone(itemID) then
				return itemID
			end
		end
	end
end

-- Returns the players current keystone
function C_Keystones.GetKeystoneInInventory()
	local itemID = C_Keystones.GetKeystoneInInventoryItemID()
	if itemID then
		return C_MythicPlus.GetKeystoneInfo(itemID)
	end
end

-- Returns: mplusprofile:1:0:0:0:0:20:0:0:0:0:0:0:0:0 or mplusprofile:0:10:0:0:8:0:0:0:0:0:0
function C_Keystones.GetProfileLink(expansion)
	if not expansion then
		expansion = MClamp(GetExpansionLevel(), 0, 1)
	end
	local dungeons = C_Keystones.GetTimedDungeonsForExpansion(expansion)
	local bests = ""
	for _, dungeonID in ipairs(dungeons) do
		local _, _, bestRun = C_Keystones.GetKeystoneDungeonInfo(dungeonID)
		if bestRun then
			bests = bests .. ":" .. bestRun.Level
		else
			bests = bests .. ":0"
		end
	end
	return format("|cff2aa2ff|Hmplusprofile:%s%s|h[%s's Keystone Profile]|h", expansion, bests, UnitName("player"))
end

local function FormatBestPlayer(player)
	if not player then
		return ""
	end
	
	return player[1]..Enum.Class[player[2]]
end

-- Returns: mplusrun:time:overtime:affix1:affix2:affix3:affix4:affix5:player1:player2:player3:player4:player5
function C_Keystones.GetDungeonBestLink(dungeonID)
	local dungeonName, _, bestRun = C_Keystones.GetKeystoneDungeonInfo(dungeonID)
	if not bestRun then
		return format("|cff2aa2ff|Hmplusrun:-1:0:0:0:0:0:0:0:0:0:0:0|h[%s's Best %s]|h", UnitName("player"), dungeonName) 
	end

	return format("|cff2aa2ff|Hmplusrun:%d:%d:%d:%d:%d:%d:%d:%s:%s:%s:%s:%s|h[%s's Best %s]|h",
	              bestRun.Time, bestRun.Overtime and 1 or 0, bestRun.Affixes[1] or 0, bestRun.Affixes[2] or 0, bestRun.Affixes[3] or 0, bestRun.Affixes[4] or 0, bestRun.Affixes[5] or 0,
	              FormatBestPlayer(bestRun.Players[1]), FormatBestPlayer(bestRun.Players[2]), FormatBestPlayer(bestRun.Players[3]), FormatBestPlayer(bestRun.Players[4]), FormatBestPlayer(bestRun.Players[5]), 
	              UnitName("player"), dungeonName)
end

function C_Keystones:MYTHIC_PLUS_COUNTDOWN_STARTED(seconds)
	if not MythicPlusObjectiveTracker then
		MythicPlus_LoadUI()
	end

	MythicPlusObjectiveTracker:Show()
	CountdownTimer:StartTimer(seconds)
end

function C_Keystones:MYTHIC_PLUS_STARTED()
	if not MythicPlusObjectiveTracker then
		MythicPlus_LoadUI()
	end

	if not MythicPlusObjectiveTracker:IsShown() then
		MythicPlusObjectiveTracker:Show()
	end
end

function C_Keystones:MYTHIC_PLUS_COMPLETE(success)
	local keystone = C_MythicPlus.GetActiveKeystoneInfo()
	local finalTime, totalTime = C_MythicPlus.GetActiveKeystoneTime()
	self.SaveKeystoneRun(keystone.dungeonID, totalTime - finalTime, not success, keystone.keystoneLevel)
end

function C_Keystones:ASCENSION_MYTHIC_PLUS_KEYSTONE_ACTIVATION_WINDOW_VISIBILITY_CHANGED()
	MythicPlus_LoadUI()
	SocketKeystoneFrame:SetKeystone()
end

-- Get Best Keystones from WTF
local function ReadKeystoneBests()
	local compressed = ReadCustomWTF(WTFFileName)

	if compressed and strlen(compressed) > 0 then
		local data = C_Serialize:DeserializeDecompressFromPrint(compressed)
		if type(data) == "table" then
			return data
		end
	end

	return {
		[Enum.Expansion.Vanilla] = {},
		[Enum.Expansion.TBC]     = {},
		[Enum.Expansion.WoTLK]   = {},
	}
end

KeystoneBests = ReadKeystoneBests()

C_Hook:Register(C_Keystones, "MYTHIC_PLUS_COUNTDOWN_STARTED")
C_Hook:Register(C_Keystones, "MYTHIC_PLUS_STARTED")
C_Hook:Register(C_Keystones, "MYTHIC_PLUS_COMPLETE")
C_Hook:Register(C_Keystones, "ASCENSION_MYTHIC_PLUS_KEYSTONE_ACTIVATION_WINDOW_VISIBILITY_CHANGED")