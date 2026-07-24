-- Helper functions relating to UnitAura

AuraUtil = {}

AuraUtil.AuraType = {
	Buff = "BUFF",
	Debuff = "DEBUFF",
}

AuraUtil.AuraFilters =
{
	Helpful = "HELPFUL",
	Harmful = "HARMFUL",
	Raid = "RAID",
	Player = "PLAYER",
	Cancelable = "CANCELABLE",
	NotCancelable = "NOT_CANCELABLE",
};

--name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id
AuraUtil.Predicate = {
	MatchesSpellID = function(input, ...) return input == select(11, ...) end,
	MatchesAuraGroup = function(input, ...) local id = select(11, ...) return id and input[id] end,
	NameContains = function(input, ...) local name = ... return input and name and input:lower():find(name, 1, true) end,
	CheckFunction = function(input, ...) local id = select(11, ...) return id and input(id) end,
}

local function GetBestPredicate(input)
	if type(input) == "string" and not tonumber(input) then
		return AuraUtil.Predicate.NameContains
	elseif type(input) == "table" then
		return AuraUtil.Predicate.MatchesAuraGroup
	else
		return AuraUtil.Predicate.MatchesSpellID
	end
end


function AuraUtil.HasAura(unit, auraID, onlyMine, predicate)
	return AuraUtil.GetAura(unit, auraID, onlyMine, predicate) ~= nil
end

function AuraUtil.HasDebuff(unit, debuffID, onlyMine, predicate)
	return AuraUtil.GetDebuff(unit, debuffID, onlyMine, predicate)
end

function AuraUtil.HasBuff(unit, buffID, onlyMine, predicate)
	return AuraUtil.GetBuff(unit, buffID, onlyMine, predicate) ~= nil
end

function AuraUtil.GetAura(unit, auraID, onlyMine, predicate)
	local name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id = AuraUtil.GetBuff(unit, auraID, onlyMine, predicate)
	if not name then
		name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id = AuraUtil.GetDebuff(unit, auraID, onlyMine, predicate)
	end

	return name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id
end

function AuraUtil.GetDebuff(unit, debuffID, onlyMine, predicate)
	local filter = "HARMFUL"
	if onlyMine then
		filter = filter .. "|PLAYER"
	end

	if not predicate then
		predicate = GetBestPredicate(debuffID)
	end

	for i = 1, 40 do
		local name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id = UnitAura(unit, i, filter)
		if not id then
			return
		end
		if predicate(debuffID, name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id) then
			return name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id
		end
	end
end

function AuraUtil.GetBuff(unit, buffID, onlyMine, predicate)
	local filter = "HELPFUL"
	if onlyMine then
		filter = filter .. "|PLAYER"
	end

	if not predicate then
		predicate = GetBestPredicate(buffID)
	end

	for i = 1, 40 do
		local name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id = UnitAura(unit, i, filter)
		if not id then
			return
		end

		if predicate(buffID, name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id) then
			return name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id
		end
	end
end

function AuraUtil.MakeAuraGroup(...)
	local t = ...
	if type(t) == "table" then
		return table.invert(t)
	end

	return table.invert({ ... })
end

function AuraUtil.HasImmunity(unit)
	return AuraUtil.GetAura(unit, C_Spell.IsImmunitySpell, nil, AuraUtil.Predicate.CheckFunction)
end 

function AuraUtil.HasAbsorb(unit)
	return AuraUtil.GetAura(unit, IsAbsorbSpell, nil, AuraUtil.Predicate.CheckFunction)
end 

function AuraUtil.UnitShouldShowBuff(unit, name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID)
	return (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") and not shouldConsolidate and duration > 0 and duration <= 300
end

function AuraUtil.UnitShouldShowDebuff(unit, name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID)
	return not shouldConsolidate and (duration <= 300 or canStealOrPurge)
end

function AuraUtil.IsPriorityDebuff(name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID)
	if unitCaster == "player" then
		if spellID == 6788 or spellID == 1106788 then --Weakened Soul
			return true
		elseif spellID == 25771 or spellID == 1125771 then -- Forbearance
			return true
		end
	end

	return false
end

-- 10.x downport compat
function AuraUtil.UnpackAuraData(auraData)
	if not auraData then
		return nil;
	end
	
	return auraData.name,
	auraData.rank,
	auraData.icon,
	auraData.applications,
	auraData.dispelName,
	auraData.duration,
	auraData.expirationTime,
	auraData.sourceUnit,
	auraData.isStealable,
	auraData.shouldConsolidate,
	auraData.spellId
end

function AuraUtil.PackAuraData(...)
	local name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id = ...
	if not name then
		return
	end
	return {
		name = name,
		rank = rank,
		icon = icon,
		applications = count,
		dispelName = debuffType,
		duration = duration,
		expirationTime = expires,
		sourceUnit = caster,
		isStealable = stealable,
		shouldConsolidate = consolidate,
		spellID = id,
	}
end

function UnitPackedAura(unit, index, filter)
	local packed = AuraUtil.PackAuraData(UnitAura(unit, index, filter))
	packed.index = index
	packed.unit = unit
	packed.filter = filter
	return packed;
end

local function FindAuraRecurse(predicate, unit, filter, auraIndex, predicateArg1, predicateArg2, predicateArg3, ...)
	if ... == nil then
		return nil; -- Not found
	end
	if predicate(predicateArg1, predicateArg2, predicateArg3, ...) then
		return ...;
	end
	auraIndex = auraIndex + 1;
	return FindAuraRecurse(predicate, unit, filter, auraIndex, predicateArg1, predicateArg2, predicateArg3, UnitAura(unit, auraIndex, filter));
end

-- Find an aura by any predicate, you can pass in up to 3 predicate specific parameters
-- The predicate will also receive all aura params, if the aura data matches return true
function AuraUtil.FindAura(predicate, unit, filter, predicateArg1, predicateArg2, predicateArg3)
	local auraIndex = 1;
	return FindAuraRecurse(predicate, unit, filter, auraIndex, predicateArg1, predicateArg2, predicateArg3, UnitAura(unit, auraIndex, filter));
end

-- Finds the first aura that matches the name
-- Notes:
--		aura names are not unique!
--		aura names are localized, what works in one locale might not work in another
--			consider that in English two auras might have different names, but once localized they have the same name, so even using the localized aura name in a search it could result in different behavior
--		the unit could have multiple auras with the same name, this will only find the first
function AuraUtil.FindAuraByName(auraName, auraRank, unit, filter)
	return UnitAura(unit, auraName, auraRank, filter or "");
end

function AuraUtil.ForEachAura(unit, filter, maxCount, func, usePackedAura)
	for i = 1, (maxCount or 40) do
		local name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id = UnitAura(unit, i, filter)
		if not name then
			return
		end
		if usePackedAura then
			func(AuraUtil.PackAuraData(name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id))
		else
			func(name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id)
		end
	end
end

function AuraUtil.MakeFilter(...)
	return strjoin("|", ...)
end

local TrackedAuras = {}
local AuraWatcherFrame = CreateFrame("Frame")

function AuraWatcherFrame:OnEvent(event, unit)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:MarkDirty()
	elseif UnitIsUnit(unit, "player") then
		self:MarkDirty()
	end
end
AuraWatcherFrame:SetScript("OnEvent", AuraWatcherFrame.OnEvent)

function AuraWatcherFrame:MarkDirty()
	self:SetScript("OnUpdate", self.Update)
end

function AuraWatcherFrame:UpdateTrackedAuras(filter)
	for i = 1, 40 do
		local name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id = UnitAura("player", i, AuraUtil.MakeFilter(filter))
		if not name then
			return
		end

		local trackedAura = TrackedAuras[id]
		if trackedAura then
			-- Aura still exists, dont remove
			trackedAura._markedForRemoval = nil

			-- update stacks
			if trackedAura.applications < count then
				AuraWatchUtil:TriggerEvent("AuraStackGained", trackedAura)
				trackedAura.applications = count
			elseif trackedAura.applications > count then
				AuraWatchUtil:TriggerEvent("AuraStackRemoved", trackedAura)
				trackedAura.applications = count
			end

			trackedAura.duration = duration
			trackedAura.expirationTime = expires
		else
			-- New aura, add it to the table
			local aura = AuraUtil.PackAuraData(name, rank, icon, count, debuffType, duration, expires, caster, stealable, consolidate, id)
			TrackedAuras[id] = aura
			AuraWatchUtil:TriggerEvent("AuraAdded", aura)
		end
	end
end

function AuraWatcherFrame:Update()
	self:SetScript("OnUpdate", nil)

	-- mark to remove auras
	for id, trackedAura in pairs(TrackedAuras) do
		trackedAura._markedForRemoval = true
	end
	
	-- gathers all active auras and triggers stacks/added events
	self:UpdateTrackedAuras(AuraUtil.AuraFilters.Helpful)
	self:UpdateTrackedAuras(AuraUtil.AuraFilters.Harmful)

	-- removes any auras not found
	for id, trackedAura in pairs(TrackedAuras) do
		if trackedAura._markedForRemoval then
			trackedAura._markedForRemoval = nil
			AuraWatchUtil:TriggerEvent("AuraRemoved", trackedAura)
			TrackedAuras[id] = nil
		end
	end
end

AuraWatchUtil = CreateFromMixins("CallbackRegistryMixin")
CallbackRegistryMixin.OnLoad(AuraWatchUtil)

AuraWatchUtil:GenerateCallbackEvents({
	"AuraAdded",
	"AuraStackGained",
	"AuraStackRemoved",
	"AuraRemoved"
})

-- 
-- These probably can be removed in the future if the aura watcher is ever used baseline.
-- since we have no use at this moment (aug 4th 2025) im leaving this opt in
-- just in the case it causes fps issues on bad pcs.
-- Can probably optimize if bad pcs struggle and we need this baseline.
function AuraWatchUtil.EnableAuraWatch()
	AuraWatcherFrame:RegisterEvent("UNIT_AURA")
	if PLAYER_ENTERED_WORLD then
		AuraWatcherFrame:MarkDirty()
	else
		AuraWatcherFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
end

function AuraWatchUtil.DisableAuraWatch()
	AuraWatcherFrame:UnregisterEvent("UNIT_AURA")
	AuraWatcherFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	AuraWatcherFrame:SetScript("OnUpdate", nil)
end

function AuraWatchUtil.IsEnabled()
	return AuraWatcherFrame:IsEventRegistered("UNIT_AURA") == 1
end

--/run AuraWatchUtil:RegisterCallback("AuraAdded", function(_, aura) print(aura.spellID, "Added!") end) AuraWatchUtil:RegisterCallback("AuraRemoved", function(_, aura) print(aura.spellID, "Removed!") end)
--/run AuraWatchUtil:RegisterCallback("AuraRemoved", function(_, aura) print(aura.spellID, "Removed!") end)