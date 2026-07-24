--[[
    * Heavily based on healpredict.lua from ElvUI 3.3.5.
    
    * Caches and communicates the player's outgoing heals to other clients using addon messages.
]]
do
    local enterWorld
    enterWorld = EventRegistry:RegisterFrameEventAndCallbackWithHandle("PLAYER_ENTERING_WORLD", function()
        RegisterInterfaceEvent("UNIT_HEAL_PREDICTION")
        enterWorld:Unregister()
        enterWorld = nil
    end)
end
HealPredictionUtil = {}
HealPredictionUtil.Prefix = "HPU"
HealPredictionUtil.MessageType = {
    Heal = 1,
    Stop = 2,
    Delay = 3,
}

local CacheIndex = {
    TotalAmount = 1,
    CastCount = 2,
    AverageAmount = 3,
    NeedReset = 4,
}

local playerName = UnitName("player")

local healCache = {}
local healCacheHandler = CreateFrame("Frame")
local predictionCacheDirect = {}
local predictionCachePeriodic = {}
-- Per-sender periodic prediction cache: sender -> spellID -> {sum, count, avg, recalcFlag}
local predictionCachePeriodicBySender = {}
local predictionCacheHandler = CreateFrame("Frame")
local predictionEventHandler = CreateFrame("Frame")

-- Active periodic heals (HoTs) tracking: target -> sender -> [spellID]=true
local activePeriodic = {}

-- Party Heals
local PrayerOfHealing = GetSpellInfo(596) or "Prayer of Healing" -- heals target and their party 

-- Smart Heals
local ChainHeal = GetSpellInfo(2747) or "Chain Heal" -- heals nearby group members
local PrayerOfPreservation = GetSpellInfo(888571) or "Prayer of Preservation" -- heals nearby group members
local Tranquility = GetSpellInfo(740) or "Tranquility" -- heals nearby group members

-- Beacon Heals
local BeaconOfLight = GetSpellInfo(53563) or "Beacon of Light" -- heals target and beacon

-- Spells to ignore in prediction
local IGNORED_SPELL_IDS = {
    [34299] = true,    -- Leader of the Pack
    [1134299] = true,  -- Leader of the Pack (bronzebeard druid)
}

local function sortByLowestHealthPercent(a, b)
    if a[2] == b[2] then
        return a[1] < b[1]
    end
    return a[2] < b[2]
end

local function GetSmartHealTargets(includePlayer)
    local targets = {}
    local unitToken = GetGroupUnitToken()
    for i = 1, GroupUtil.GetNumGroupMembers() do
        local unit = unitToken .. i
        if UnitExists(unit) and CheckInteractDistance(unit, 4) then
            if includePlayer or not UnitIsUnit("player", unit) then
                table.insert(targets, { UnitName(unit), UnitHealthPercent(unit) })
            end
        end
    end

    -- party doesnt include player
    if includePlayer and unitToken == "party" then
        table.insert(targets, { playerName, UnitHealthPercent("player") })
    end

    table.sort(targets, sortByLowestHealthPercent)
    return targets
end

local function GetGroupHealTargets(unit)
    local targets = {}
    if IsInRaid() then
        local name = UnitName(unit)
        local unitSubgroup
        for i = 1, GroupUtil.GetNumGroupMembers() do
            local unitToken = "raid" .. i
            local raidName, _, subgroup = GetRaidRosterInfo(i)
            if raidName == name then
                unitSubgroup = subgroup
            end
            targets[subgroup] = targets[subgroup] or {}
            tinsert(targets[subgroup], { raidName, UnitHealthPercent(unitToken) })
        end

        if unitSubgroup then
            table.sort(targets[unitSubgroup], sortByLowestHealthPercent)
            return targets[unitSubgroup]
        end
    else
        for i = 1, GroupUtil.GetNumGroupMembers() do
            local unitToken = "party" .. i
            local unitName = UnitName(unitToken)
            if unitName then
                tinsert(targets, { unitName, UnitHealthPercent(unitToken) })
            end
        end

        table.insert(targets, { playerName, UnitHealthPercent("player") })
        table.sort(targets, sortByLowestHealthPercent)
        return targets
    end
end

--
-- Communication
--
local function SendComm(...)
    local msg = table.concat({...}, ":")
    if UnitInBattleground("player") then
        SendAddonMessage(HealPredictionUtil.Prefix, msg, "BATTLEGROUND")
    elseif GroupUtil.IsInRaid() then
        SendAddonMessage(HealPredictionUtil.Prefix, msg, "RAID")
    elseif GroupUtil.IsInGroup() then
        SendAddonMessage(HealPredictionUtil.Prefix, msg, "PARTY")
    end
end

local function OnComm(event, prefix, msg, channel, sender)
    if prefix ~= HealPredictionUtil.Prefix then return end
    local messageType, arg2, arg3, arg4 = string.split(":", msg)
    messageType = messageType and tonumber(messageType)
    if messageType == HealPredictionUtil.MessageType.Heal then
        local target, amount, castTime = arg2, arg3, arg4
        healCacheHandler:AddHeal(sender, target, amount, castTime)
    elseif messageType == HealPredictionUtil.MessageType.Remove then
        healCacheHandler:RemoveHeal(sender)
    elseif messageType == HealPredictionUtil.MessageType.Delay then
        local delay = arg2
        healCacheHandler:DelayHeal(sender, delay)
    end
end
EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_ADDON", OnComm)

local function SendHealComm(target, amount, castTime)
    SendComm(HealPredictionUtil.MessageType.Heal, target, amount, castTime)
end

local function SendStopComm()
    SendComm(HealPredictionUtil.MessageType.Remove)
end

local function SendDelayComm(delay)
    SendComm(HealPredictionUtil.MessageType.Delay, delay)
end

--
-- Special Group Healing
--
-- Post Special heals are heals that happen after healing has been applied. ex tranquility.
local PostSpecialHeals = {}
-- Special heals are heals that happen during the cast. ex chain heal.
local SpecialHeals = {}

-- Tranquility
PostSpecialHeals[Tranquility] = function(spellID)
    healCacheHandler:RemoveHeal(playerName)
    SendStopComm()

    local _, _, _, _, startTime, endTime = UnitChannelInfo("player")
    if startTime and endTime then
        local castTime = endTime - startTime
        local predictedAmount = predictionCacheHandler:GetDirectPrediction(spellID)
        local targets = GetSmartHealTargets(true)
        for _,target in ipairs(targets) do
            healCacheHandler:AddHeal(playerName, target[1], predictedAmount, castTime)
            SendHealComm(target[1], predictedAmount, castTime)
        end
    end

    predictionEventHandler.pendingHeal = true
end

-- Prayer of Preservation
PostSpecialHeals[PrayerOfPreservation] = function(spellID)
    healCacheHandler:RemoveHeal(playerName)
    SendStopComm()

    local _, _, _, _, startTime, endTime = UnitChannelInfo("player")
    if startTime and endTime then
        local castTime = endTime - startTime
        local predictedAmount = predictionCacheHandler:GetDirectPrediction(spellID)
        local targets = GetSmartHealTargets(true)
        for _,target in ipairs(targets) do
            healCacheHandler:AddHeal(playerName, target[1], predictedAmount, castTime)
            SendHealComm(target[1], predictedAmount, castTime)
        end
    end

    predictionEventHandler.pendingHeal = true
end

-- Chain Heal
--[[SpecialHeals[ChainHeal] = function(currentTarget, healAmount, castTime, spellID)
    -- this is probably too inaccurate since it will recalc distance for each hop
    -- ex if player b is 30 yards away my smart heal will find them
    -- but if player c is 30 yards away from player b, and 60 yards away from me
    -- chain heal will find them but GetSmartHealTargets wont.
    -- more misleading than just not showing

    local predictedAmount = predictionCacheHandler:GetDirectPrediction(spellID)
    local targets = GetSmartHealTargets(true)
    for i = 1, 3 do
        local target = targets[i]
        if target then
            healCacheHandler:AddHeal(playerName, target[1], predictedAmount, castTime)
            SendHealComm(target[1], predictedAmount, castTime)
        end
    end
end]]

-- Prayer of Healing
SpecialHeals[PrayerOfHealing] = function(currentTarget, healAmount, castTime, spellID)
    local targets = GetGroupHealTargets(currentTarget)
    for i = 1, 5 do
        local target = targets[i]
        if target then
            healCacheHandler:AddHeal(playerName, target[1], healAmount, castTime)
            SendHealComm(target[1], healAmount, castTime)
        end
    end
end

local function SendInterfaceEventGUID(guid)
    if string.isNilOrEmpty(guid) then
        return
    end

    local tokens = {GetTokenIDsFromGUID(guid)}
    for _, unitToken in ipairs(tokens) do
        SignalEvent("UNIT_HEAL_PREDICTION", unitToken)
    end
end

local function SendInterfaceEvent(unit)
    if string.isNilOrEmpty(unit) then
        return
    end

    local guid = UnitGUID(unit)
    SendInterfaceEventGUID(guid)
end

-- 
-- Pending Heal Cache
--
-- use attributes so this can be used bo secure and insecure frames
function healCacheHandler:OnAttributeChanged(name, value)
    if name == "cache" then
        local sender, target, amount, duration = string.split(":", value)
        if not sender or not target or not amount or not duration then
            return
        end
        if not healCache[target] then
            healCache[target] = {}
        end
        local time = GetTime() + tonumber(duration) / 1000
        healCache[target][sender] = {tonumber(amount), time}
        SendInterfaceEvent(target)

    elseif name == "remove" then
        if not value then
            return
        end
        local affectedUnits = {}
        for target, senders in pairs(healCache) do
            for targetSender in pairs(senders) do
                if value == targetSender then
                    healCache[target][targetSender] = nil
                    table.insert(affectedUnits, target)
                end
            end
        end

        for _, affectedUnit in ipairs(affectedUnits) do
            SendInterfaceEvent(affectedUnit)
        end
        
    elseif name == "delay" then
        local sender, delay = string.split(":", value)
        delay = delay and tonumber(delay)
        if not sender or not delay then
            return
        end
        delay = delay / 1000
        local affectedUnits = {}
        for target, senders in pairs(healCache) do
            for targetSender, amount in pairs(senders) do
                if sender == targetSender then
                    amount[2] = amount[2] + delay
                    table.insert(affectedUnits, target)
                end
            end
        end

        for _, affectedUnit in ipairs(affectedUnits) do
            SendInterfaceEvent(affectedUnit)
        end
    end
end
healCacheHandler:SetScript("OnAttributeChanged", healCacheHandler.OnAttributeChanged)

function healCacheHandler:AddHeal(sender, target, amount, duration)
    if not sender or not target or not amount or not duration then
        return
    end
    self:SetAttribute("cache", sender .. ":" .. target .. ":" .. tostring(amount) .. ":" .. tostring(duration))
end

function healCacheHandler:RemoveHeal(sender)
    if not sender then
        return
    end
    self:SetAttribute("remove", sender)
end

function healCacheHandler:DelayHeal(sender, delay)
    if not sender or not delay then
        return
    end
    
    self:SetAttribute("delay", sender .. ":" .. tostring(delay))
end

--
-- Prediction Cache
--
function predictionCacheHandler:OnAttributeChanged(name, value)
    if name == "recalc_direct" then
        local spellID = value
        if predictionCacheDirect[spellID] then
            predictionCacheDirect[spellID][4] = true
        end
    elseif name == "recalc_periodic" then
        local spellID = value
        if predictionCachePeriodic[spellID] then
            predictionCachePeriodic[spellID][4] = true
        end
    elseif name == "add_direct" then
        local spellID, amount = string.split(":", value)
        spellID = spellID and tonumber(spellID)
        amount = amount and tonumber(amount)
        if not spellID or not amount then
            return
        end
        if not predictionCacheDirect[spellID] then
            predictionCacheDirect[spellID] = { 0, 0, 0 }
        end
        local cache = predictionCacheDirect[spellID]
        if cache[CacheIndex.NeedReset] then
            cache[CacheIndex.NeedReset] = nil
            cache[CacheIndex.TotalAmount] = amount
            cache[CacheIndex.CastCount] = 1
            cache[CacheIndex.AverageAmount] = amount
        else
            cache[CacheIndex.TotalAmount] = cache[CacheIndex.TotalAmount] + amount
            cache[CacheIndex.CastCount] = cache[CacheIndex.CastCount] + 1
            cache[CacheIndex.AverageAmount] = cache[CacheIndex.TotalAmount] / cache[CacheIndex.CastCount]

            if cache[CacheIndex.CastCount] > 50000 then -- dont let this get too large
                cache[CacheIndex.CastCount] = math.ceil(cache[CacheIndex.CastCount] * 0.01)
                cache[CacheIndex.TotalAmount] = math.ceil(cache[CacheIndex.TotalAmount] * 0.01)
            end
        end
    elseif name == "add_periodic" then
        local spellID, amount = string.split(":", value)
        spellID = spellID and tonumber(spellID)
        amount = amount and tonumber(amount)
        if not spellID or not amount then
            return
        end
        if not predictionCachePeriodic[spellID] then
            predictionCachePeriodic[spellID] = { 0, 0, 0 }
        end
        local cache = predictionCachePeriodic[spellID]
        if cache[CacheIndex.NeedReset] then
            cache[CacheIndex.NeedReset] = nil
            cache[CacheIndex.TotalAmount] = amount
            cache[CacheIndex.CastCount] = 1
            cache[CacheIndex.AverageAmount] = amount
        else
            cache[CacheIndex.TotalAmount] = cache[CacheIndex.TotalAmount] + amount
            cache[CacheIndex.CastCount] = cache[CacheIndex.CastCount] + 1
            cache[CacheIndex.AverageAmount] = cache[CacheIndex.TotalAmount] / cache[CacheIndex.CastCount]
            if cache[CacheIndex.CastCount] > 50000 then -- dont let this get too large
                cache[CacheIndex.CastCount] = math.ceil(cache[CacheIndex.CastCount] * 0.01)
                cache[CacheIndex.TotalAmount] = math.ceil(cache[CacheIndex.TotalAmount] * 0.01)
            end
        end
    elseif name == "add_periodic_sender" then
        local sender, spellID, amount = string.split(":", value)
        spellID = spellID and tonumber(spellID)
        amount = amount and tonumber(amount)
        if not sender or not spellID or not amount then
            return
        end
        predictionCachePeriodicBySender[sender] = predictionCachePeriodicBySender[sender] or {}
        if not predictionCachePeriodicBySender[sender][spellID] then
            predictionCachePeriodicBySender[sender][spellID] = { 0, 0, 0 }
        end
        local cache = predictionCachePeriodicBySender[sender][spellID]
        if cache[4] then
            cache[4] = nil
            cache[1] = amount
            cache[2] = 1
            cache[3] = amount
        else
            cache[1] = cache[1] + amount
            cache[2] = cache[2] + 1
            cache[3] = cache[1] / cache[2]
        end
    end
end
predictionCacheHandler:SetScript("OnAttributeChanged", predictionCacheHandler.OnAttributeChanged)

function predictionCacheHandler:GetDirectPrediction(spellID)
    if predictionCacheDirect[spellID] then
        return predictionCacheDirect[spellID][3]
    end
    return 0
end

function predictionCacheHandler:GetPeriodicPrediction(spellID)
    if predictionCachePeriodic[spellID] then
        return predictionCachePeriodic[spellID][3]
    end
    return 0
end

function predictionCacheHandler:GetPeriodicPredictionForSender(sender, spellID)
    if sender and spellID then
        local bySender = predictionCachePeriodicBySender[sender]
        if bySender and bySender[spellID] then
            return bySender[spellID][3]
        end
    end
    return 0
end

function predictionCacheHandler:ResetDirectCache(spellID)
    if not spellID then
        return
    end
    predictionCacheHandler:SetAttribute("recalc_direct", spellID)
end

function predictionCacheHandler:ResetPeriodicCache(spellID)
    if not spellID then
        return
    end
    predictionCacheHandler:SetAttribute("recalc_periodic", spellID)
end

-- Backward-compatible; treat as direct heal cache by default
function predictionCacheHandler:ResetCache(spellID)
    if not spellID then
        return
    end
    predictionCacheHandler:SetAttribute("recalc_direct", spellID)
end

function predictionCacheHandler:CacheDirectHeal(spellID, amount)
    if not spellID or not amount or amount < 0 then
        return
    end
    predictionCacheHandler:SetAttribute("add_direct", tostring(spellID) .. ":" .. tostring(amount))
end

function predictionCacheHandler:CachePeriodicHeal(spellID, amount)
    if not spellID or not amount or amount < 0 then
        return
    end
    predictionCacheHandler:SetAttribute("add_periodic", tostring(spellID) .. ":" .. tostring(amount))
end

function predictionCacheHandler:CachePeriodicHealForSender(sender, spellID, amount)
    if not sender or not spellID or not amount or amount < 0 then
        return
    end
    predictionCacheHandler:SetAttribute("add_periodic_sender", tostring(sender) .. ":" .. tostring(spellID) .. ":" .. tostring(amount))
end

-- Backward-compatible; if called, route to direct cache
function predictionCacheHandler:CacheHeal(spellID, amount)
    return predictionCacheHandler:CacheDirectHeal(spellID, amount)
end

--
-- Event Handler
--

-- Helpers to verify inventory changes and clear prediction caches

local function BuildInventorySignature()
    -- Only include equipped item IDs; fastest possible
    local first = INVSLOT_FIRST_EQUIPPED or 1
    local last = INVSLOT_LAST_EQUIPPED or 19
    local parts = {}
    for slot = first, last do
        local itemID = GetInventoryItemID("player", slot) or 0
        parts[#parts + 1] = tostring(itemID)
    end
    return table.concat(parts, ",")
end

local function ClearPredictionCaches()
    -- Prefer using handler reset APIs per spellID for correctness, and zero out immediately
    for spellID, cache in pairs(predictionCacheDirect) do
        predictionCacheHandler:ResetDirectCache(spellID)
        if cache then
            cache[1], cache[2], cache[3] = 0, 0, 0
            cache[4] = true
        end
    end
    for spellID, cache in pairs(predictionCachePeriodic) do
        predictionCacheHandler:ResetPeriodicCache(spellID)
        if cache then
            cache[1], cache[2], cache[3] = 0, 0, 0
            cache[4] = true
        end
    end
    -- Clear only the local player's per-sender periodic entries
    if predictionCachePeriodicBySender[playerName] then
        if wipe then
            wipe(predictionCachePeriodicBySender[playerName])
        else
            for k in pairs(predictionCachePeriodicBySender[playerName]) do
                predictionCachePeriodicBySender[playerName][k] = nil
            end
        end
        predictionCachePeriodicBySender[playerName] = nil
    end
end

local function CheckInventoryChange(frame)
    local sig = BuildInventorySignature()
    if frame.lastInventorySignature ~= sig then
        frame.lastInventorySignature = sig
        ClearPredictionCaches()
    end
end

predictionEventHandler:SetScript("OnEvent", OnEventToMethod)
predictionEventHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
predictionEventHandler:RegisterEvent("UNIT_SPELLCAST_SENT")
predictionEventHandler:RegisterEvent("UNIT_SPELLCAST_START")
predictionEventHandler:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
-- Inventory/level/spell change related events (equipment only)
predictionEventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
predictionEventHandler:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
predictionEventHandler:RegisterEvent("PLAYER_LEVEL_UP")
predictionEventHandler:RegisterEvent("ASCENSION_SPELLS_UPDATED")

predictionEventHandler:RegisterEvent("UNIT_SPELLCAST_FAILED")
predictionEventHandler:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
predictionEventHandler:RegisterEvent("UNIT_SPELLCAST_STOP")
predictionEventHandler:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
predictionEventHandler:RegisterEvent("UNIT_SPELLCAST_DELAYED")

function predictionEventHandler:COMBAT_LOG_EVENT_UNFILTERED(_, subEvent, _, sourceName, _, destGUID, destName, _, spellID, spellName, _, amountOrAuraType, _, absorbed, critical)
    -- Handle periodic heals for all senders to build per-sender averages and active state
    if subEvent == "SPELL_PERIODIC_HEAL" then
        -- Ignore specific spells entirely from predictions
        if IGNORED_SPELL_IDS[spellID] then
            return
        end
        local amount = amountOrAuraType + (absorbed or 0)
        -- cache per-sender periodic prediction
        if sourceName and spellID and amount then
            predictionCacheHandler:CachePeriodicHealForSender(sourceName, spellID, amount)
        end
        return
    elseif subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REFRESH" then
        local auraType = amountOrAuraType
        if auraType == "BUFF" and destName then
            -- For Beacon logic, only track for local player
            if sourceName == playerName and spellName == BeaconOfLight then
                self.beaconTarget = destName
            end
            -- Activate periodic prediction strictly when a buff aura is applied or refreshed
            -- Additionally ensure the aura's spell is helpful and not explicitly ignored
            if sourceName and spellID and C_Spell.IsHelpfulSpell(spellID, true) and not IGNORED_SPELL_IDS[spellID] then
                activePeriodic[destName] = activePeriodic[destName] or {}
                activePeriodic[destName][sourceName] = activePeriodic[destName][sourceName] or {}
                activePeriodic[destName][sourceName][spellID] = true
            end
            if destGUID then
                SendInterfaceEventGUID(destGUID)
            end
        end

    elseif subEvent == "SPELL_AURA_REMOVED" then
        local auraType = amountOrAuraType
        if auraType == "BUFF" and destName then
            if sourceName == playerName and spellName == BeaconOfLight and self.beaconTarget == destName then
                self.beaconTarget = nil
            end
            if activePeriodic[destName] and sourceName and spellID then
                if activePeriodic[destName][sourceName] and activePeriodic[destName][sourceName][spellID] ~= nil then
                    activePeriodic[destName][sourceName][spellID] = false
                    if destGUID then
                        SendInterfaceEventGUID(destGUID)
                    end
                end
            end
        end
    elseif subEvent == "UNIT_DIED" or subEvent == "UNIT_DESTROYED" or subEvent == "UNIT_DISSIPATES" then
        if destName then
            if healCache[destName] then
                healCache[destName] = nil
            end
            if activePeriodic[destName] then
                activePeriodic[destName] = nil
            end
            if destGUID then
                SendInterfaceEventGUID(destGUID)
            end
        end
    end
    
    if sourceName ~= playerName then
        return
    end

    if subEvent == "SPELL_HEAL" then
        -- Ignore specific spells entirely from predictions
        if IGNORED_SPELL_IDS[spellID] then
            return
        end
        local amount = amountOrAuraType + (absorbed or 0)
        predictionCacheHandler:CacheDirectHeal(spellID, amount)

        if PostSpecialHeals[spellName] then
            PostSpecialHeals[spellName](spellID)
        end
    end
end

function predictionEventHandler:UNIT_SPELLCAST_SENT(unit, _, _, target)
    if unit ~= "player" then
        return
    end

    if string.isNilOrEmpty(target) then
        -- get target name 
        self.currentTarget = UnitCanAssist("player", "target") and UnitName("target") or playerName
    else
        self.currentTarget = target
    end
end

function predictionEventHandler:UNIT_SPELLCAST_START(unit)
    if unit ~= "player" then
        return
    end

    if not self.currentTarget then
        return
    end

    local spellName, _, _, _, startTime, endTime, _, _, _, spellID = UnitCastingInfo("player")
    if not spellID then
        spellName, _, _, _, startTime, endTime, _, _, spellID = UnitChannelInfo("player")
    end

    if not spellName or not C_Spell.IsHelpfulSpell(spellID, true) then
        return
    end
    
    local castTime = endTime - startTime
    if IGNORED_SPELL_IDS[spellID] then
        return
    end
    local healAmount = predictionCacheHandler:GetDirectPrediction(spellID)


    healCacheHandler:AddHeal(playerName, self.currentTarget, healAmount, castTime)
    SendHealComm(self.currentTarget, healAmount, castTime)
    
    if self.beaconTarget then
        if not UnitIsUnit(self.currentTarget, self.beaconTarget) then
            healCacheHandler:AddHeal(playerName, self.beaconTarget, healAmount, castTime)
            SendHealComm(self.beaconTarget, healAmount, castTime)
        end
    end

    if SpecialHeals[spellName] then
        SpecialHeals[spellName](self.currentTarget, healAmount, castTime, spellID)
    end
    
    self.pendingHeal = true
end
predictionEventHandler.UNIT_SPELLCAST_CHANNEL_START = predictionEventHandler.UNIT_SPELLCAST_START

function predictionEventHandler:UNIT_SPELLCAST_FAILED(unit)
    if unit ~= "player" then
        return
    end
    if self.pendingHeal then
        self.pendingHeal = false
        healCacheHandler:RemoveHeal(playerName)
        SendStopComm()
    end
end
predictionEventHandler.UNIT_SPELLCAST_INTERRUPTED = predictionEventHandler.UNIT_SPELLCAST_FAILED
predictionEventHandler.UNIT_SPELLCAST_STOP = predictionEventHandler.UNIT_SPELLCAST_FAILED
predictionEventHandler.UNIT_SPELLCAST_CHANNEL_STOP = predictionEventHandler.UNIT_SPELLCAST_FAILED

function predictionEventHandler:UNIT_SPELLCAST_DELAYED(unit, delay)
    if unit ~= "player" then
        return
    end
    healCacheHandler:DelayHeal(playerName, delay)
    SendDelayComm(delay)
end

-- Initialize baseline inventory signature on entering world
function predictionEventHandler:PLAYER_ENTERING_WORLD()
    if not self.lastInventorySignature then
        self.lastInventorySignature = BuildInventorySignature()
    else
        CheckInventoryChange(self)
    end
end

function predictionEventHandler:PLAYER_EQUIPMENT_CHANGED()
    CheckInventoryChange(self)
end


function predictionEventHandler:PLAYER_LEVEL_UP()
    ClearPredictionCaches()
end

function predictionEventHandler:ASCENSION_SPELLS_UPDATED()
    ClearPredictionCaches()
end

--
-- Mimic retail api for UnitGetIncomingHeals
--
function UnitGetIncomingHeals(unit, casterUnit)
    if not unit or not UnitExists(unit) then
        return 0
    end

    if UnitIsDeadOrGhost(unit) then
        return 0
    end

    local name = UnitName(unit)

    if not healCache[name] then
        return 0
    end

    local healer = casterUnit and UnitExists(casterUnit) and UnitName(casterUnit)

    local incHealing, time = 0, GetTime()

    if healer and name ~= healer then
        local cache = healCache[name] and healCache[name][healer]
        if cache then
            if cache[2] < time then
                healCache[name][healer] = nil
            else
                incHealing = cache[1]
            end
        end
    else
        for healer, cache in pairs(healCache[name]) do
            if cache[2] < time then
                healCache[name][healer] = nil
            else
                incHealing = incHealing + cache[1]
            end
        end
    end

    -- Include active periodic heals average tick amounts while their buffs are active
    if activePeriodic[name] then
        if healer and name ~= healer then
            local spells = activePeriodic[name][healer]
            if spells then
                for spellID, isActive in pairs(spells) do
                    if isActive then
                        incHealing = incHealing + predictionCacheHandler:GetPeriodicPredictionForSender(healer, spellID)
                    end
                end
            end
        else
            for sender, spells in pairs(activePeriodic[name]) do
                for spellID, isActive in pairs(spells) do
                    if isActive then
                        incHealing = incHealing + predictionCacheHandler:GetPeriodicPredictionForSender(sender, spellID)
                    end
                end
            end
        end
    end

    return incHealing
end