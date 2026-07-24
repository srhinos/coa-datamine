--[[
This entire library has been nuked since Ascension does not use standard talents.
Spam inspecting everyone is completely pointless.
]]--

local MAJOR = "LibTalentQuery-1.0"
local lib = LibStub:NewAscensionLibrary(MAJOR)
if not lib then return end
if not lib.events then
	lib.events = LibStub("CallbackHandler-1.0"):New(lib)
end
local frame = lib.frame
if not frame then
	frame = CreateFrame("Frame", MAJOR .. "_Frame")
	lib.frame = frame
end
frame:UnregisterAllEvents()
frame:Hide()

lib.Query = nop
lib.CheckInspectQueue = nop
lib.NotifyInspect = nop
lib.Reset = nop
lib.INSPECT_TALENT_READY = nop
lib.PLAYER_ENTERING_WORLD = nop
lib.PLAYER_LEAVING_WORLD = nop
lib.PLAYER_LOGIN = nop


--[[
Name: LibTalentQuery-1.0
Revision: $Rev: 84 $
Author: Rich Martel (richmartel@gmail.com)
Documentation: http://wowace.com/wiki/LibTalentQuery-1.0
SVN: svn://svn.wowace.com/wow/libtalentquery-1-0/mainline/trunk
Description: Library to help with querying unit talents
Dependancies: LibStub, CallbackHandler-1.0
License: LGPL v2.1

Example Usage:
	local TalentQuery = LibStub:GetLibrary("LibTalentQuery-1.0")
	TalentQuery.RegisterCallback(self, "TalentQuery_Ready")

	local raidTalents = {}
	...
	TalentQuery:Query(unit)
	...
	function MyAddon:TalentQuery_Ready(e, name, realm, unitid)
		local isnotplayer = not UnitIsUnit(unitid, "player")
		local spec = {}
		for tab = 1, GetNumTalentTabs(isnotplayer) do
			local treename, _, pointsspent = GetTalentTabInfo(tab, isnotplayer)
			tinsert(spec, pointsspent)
		end
		raidTalents[UnitGUID(unitid)] = spec
	end
]]

--[[local MAJOR, MINOR = "LibTalentQuery-1.0", 90000 + tonumber(("$Rev: 84 $"):match("(%d+)"))

local lib = LibStub:NewAscensionLibrary(MAJOR, MINOR)
if not lib then return end

local INSPECTDELAY = 1
local INSPECTTIMEOUT = 5
if not lib.events then
    lib.events = LibStub("CallbackHandler-1.0"):New(lib)
end

local validateTrees
local enteredWorld = IsLoggedIn()
local frame = lib.frame
if not frame then
    frame = CreateFrame("Frame", MAJOR .. "_Frame")
    lib.frame = frame
end
frame:UnregisterAllEvents()
frame:RegisterEvent("INSPECT_CHARACTER_ADVANCEMENT_RESULT")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(this, event, ...)
    return lib[event](lib, ...)
end)

do
    local lastUpdateTime = 0
    frame:SetScript("OnUpdate", function(this, elapsed)
        lastUpdateTime = lastUpdateTime + elapsed
        if lastUpdateTime > INSPECTDELAY then
            lib:CheckInspectQueue()
            lastUpdateTime = 0
        end
    end)
    frame:Hide()
end

local inspectQueue = lib.inspectQueue or {}
lib.inspectQueue = inspectQueue
local garbageQueue = lib.garbageQueue or {}	-- Added a second queue to things. Inspects that initially fail are now
lib.garbageQueue = garbageQueue				-- thrown into second queue will will be processed once main queue is empty

if next(inspectQueue) then
    frame:Show()
end

local UnitIsPlayer = _G.UnitIsPlayer
local UnitName = _G.UnitName
local UnitExists = _G.UnitExists
local UnitGUID = _G.UnitGUID
local GetNumRaidMembers = _G.GetNumRaidMembers
local GetNumPartyMembers = _G.GetNumPartyMembers
local UnitIsVisible = _G.UnitIsVisible
local UnitIsConnected = _G.UnitIsConnected
local UnitCanAttack = _G.UnitCanAttack
local CanInspect = _G.CanInspect

local function UnitFullName(unit)
    local name, realm = UnitName(unit)
    local namerealm = realm and realm ~= "" and name .. "-" .. realm or name
    return namerealm
end

-- GuidToUnitID
local function GuidToUnitID(guid)
    local prefix, min, max = "raid", 1, GetNumRaidMembers()
    if max == 0 then
        prefix, min, max = "party", 0, GetNumPartyMembers()
    end

    -- Prioritise getting direct units first because other players targets
    -- can change between notify and event which can bugger things up
    for i = min, max do
        local unit = i == 0 and "player" or prefix .. i
        if (UnitGUID(unit) == guid) then
            return unit
        end
    end

    -- This properly detects target units
    if (UnitGUID("target") == guid) then
        return "target"
    elseif (UnitGUID("focus") == guid) then
        return "focus"
    elseif (UnitGUID("mouseover") == guid) then
        return "mouseover"
    end

    for i = min, max + 3 do
        local unit
        if i == 0 then
            unit = "player"
        elseif i == max + 1 then
            unit = "target"
        elseif i == max + 2 then
            unit = "focus"
        elseif i == max + 3 then
            unit = "mouseover"
        else
            unit = prefix .. i
        end
        if (UnitGUID(unit .. "target") == guid) then
            return unit .. "target"
        elseif (i <= max and UnitGUID(unit.."pettarget") == guid) then
            return unit .. "pettarget"
        end
    end
    return nil
end

-- Query
function lib:Query(unit)
    if (UnitLevel(unit) < 10 or UnitName(unit) == UNKNOWN) then
        return
    end

    self.lastQueuedInspectReceived = nil
    if UnitIsUnit(unit, "player") then
        self.events:Fire("TalentQuery_Ready", UnitName("player"), nil, "player")
    else
        if type(unit) ~= "string" then
            error(("Bad argument #2 to 'Query'. Expected %q, received %q (%s)"):format("string", type(unit), tostring(unit)), 2)
        elseif not UnitExists(unit) or not UnitIsPlayer(unit) then
            error(("Bad argument #2 to 'Query'. %q is not a valid player unit"):format(tostring(unit)), 2)
        elseif not UnitExists(unit) or not UnitIsPlayer(unit) then
            error(("Bad argument #2 to 'Query'. %q does not require a server query before reading talents"):format("player"), 2)
        else
            local name = UnitFullName(unit)
            if (not inspectQueue[name]) then
                inspectQueue[name] = UnitGUID(unit)
                garbageQueue[name] = nil
            end
            frame:Show()
        end
    end
end

-- CheckInspectQueue
-- Originally, it would wait until no pending NotifyInspect() were expected, and then do it's own.
-- It was also only bother looking at ready results if it had triggered the Notify for that occasion.
-- For the changes I've done, no assumption is made about which mod is performing NotifyInspect().
-- We note the name, unit, time of any inspects done whether from this queue or any other source,
-- we remove from our queue any we were expecting, and use a seperate event in case extra talent
-- info is any time wanted (opportunistic refreshes etc) - Zeksie, 20th May 2009
function lib:CheckInspectQueue()
    if (_G.AscensionInspectFrame and _G.AscensionInspectFrame:IsShown()) then
        return
    end

    if (_G.InspectFrame and _G.InspectFrame:IsShown()) then
        return
    end

    if (not self.lastInspectTime or self.lastInspectTime < GetTime() - INSPECTTIMEOUT) then
        self.lastInspectPending = 0
    end

    if (self.lastInspectPending > 0 or not enteredWorld) then
        return
    end

    if (self.lastQueuedInspectReceived and self.lastQueuedInspectReceived < GetTime() - 60) then
        -- No queued results received for a minute, so purge the queue as invalid and move on with our lives
        self.lastQueuedInspectReceived = nil
        inspectQueue = {}
        lib.inspectQueue = inspectQueue
        garbageQueue = {}
        lib.garbageQueue = garbageQueue
        frame:Hide()
        return
    end

    for name,guid in pairs(inspectQueue) do
        local unit = GuidToUnitID(guid)
        if (not unit) then
            inspectQueue[name] = nil
        else
            if (UnitIsVisible(unit) and UnitIsConnected(unit) and UnitIsPlayer(unit)) then
                C_CharacterAdvancement.InspectUnit(unit)
                break
            else
                garbageQueue[name] = guid	-- Not available, throw into secondary queue and continue
                inspectQueue[name] = nil
            end
        end
    end

    if (not next(inspectQueue)) then
        if (next(garbageQueue)) then
            -- Retry initially failed inspects
            lib.inspectQueue = garbageQueue
            inspectQueue = lib.inspectQueue
            lib.garbageQueue = {}
            garbageQueue = lib.garbageQueue
        else
            frame:Hide()
        end
    end
end

-- Ascension: Using C_CharacterAdvancement for inspection; NotifyInspect hook removed.
-- Hook C_CharacterAdvancement.InspectUnit to observe inspections triggered by other addons
if not lib.CA_InspectUnitHooked then
    if type(C_CharacterAdvancement) == "table" and C_CharacterAdvancement.InspectUnit then
        hooksecurefunc(C_CharacterAdvancement, "InspectUnit", function(unit)
            if not unit then return end
            if UnitExists(unit) and UnitIsPlayer(unit) and UnitIsVisible(unit) and UnitIsConnected(unit) then
                lib.lastInspectUnit = unit
                lib.lastInspectGUID = UnitGUID(unit)
                lib.lastInspectTime = GetTime()
                lib.lastInspectPending = lib.lastInspectPending + 1
                lib.lastInspectName = UnitFullName(unit)
            end
        end)
        lib.CA_InspectUnitHooked = true
    end
end

-- Reset
function lib:Reset()
    self.lastInspectPending = 0
    self.lastInspectUnit = nil
    self.lastInspectTime = nil
    self.lastInspectName = nil
    self.lastInspectGUID = nil
    self.lastInspectTree = nil
end

-- INSPECT_CHARACTER_ADVANCEMENT_RESULT
function lib:INSPECT_CHARACTER_ADVANCEMENT_RESULT(result)
    -- Decrement pending and only proceed when our outstanding request completes
    self.lastInspectPending = self.lastInspectPending - 1

    if (self.lastInspectName and self.lastInspectPending == 0) then
        -- Ensure unit didn’t change since request
        if (UnitGUID(self.lastInspectUnit) == self.lastInspectGUID) then
            local guid = inspectQueue[self.lastInspectName]
            inspectQueue[self.lastInspectName] = nil

            local name, realm = strsplit("-", self.lastInspectName)

            self.lastQueuedInspectReceived = GetTime()

            if (result == "CA_INSPECT_OK") then
                if (guid) then
                    self.events:Fire("TalentQuery_Ready", name, realm, self.lastInspectUnit)
                else
                    self.events:Fire("TalentQuery_Ready_Outsider", name, realm, self.lastInspectUnit)
                end
            else
                -- Inspection failed, re-queue for later
                garbageQueue[self.lastInspectName] = self.lastInspectGUID
            end
        end

        self:Reset()
        self:CheckInspectQueue()
    end
end

function lib:PLAYER_ENTERING_WORLD()
    -- We can't inspect other's talents until now
    -- We just get 0/0/0 back even though we get an INSPECT_TALENT_READY event
    enteredWorld = true
end

function lib:PLAYER_LEAVING_WORLD()
    enteredWorld = nil
end

function lib:PLAYER_LOGIN()
    validateTrees = {
        DRUID = "Balance",
        PRIEST = "Discipline",
        ROGUE = "Assassination",
        HUNTER = "Beast Mastery",
        WARLOCK = "Affliction",
        WARRIOR = "Arms",
        DEATHKNIGHT = "Blood",
        PALADIN = "Holy",
        SHAMAN = "Elemental",
        MAGE = "Arcane",
    }

    if (GetLocale() ~= "enUS" and GetLocale() ~= "enGB") then
        -- LibBabble-TalentTree-3.0 only loaded if present and not enUS
        local LBT = LibStub("LibBabble-TalentTree-3.0", true)
        if (not LBT) then
            LoadAddOn("LibBabble-TalentTree-3.0")
            LBT = LibStub("LibBabble-TalentTree-3.0", true)
        end
        LBT = LBT and LBT:GetLookupTable()
        if (LBT) then
            for class,tree1 in pairs(validateTrees) do
                validateTrees[class] = LBT[tree1]
            end
        else
            validateTrees = nil
        end
    end

    self.PLAYER_LOGIN = nil
end

lib:Reset()]]
