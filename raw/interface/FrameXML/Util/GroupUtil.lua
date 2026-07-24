GroupUtil = {}

local GetNumRaidMembers = GetNumRaidMembers
local GetNumPartyMembers = GetNumPartyMembers
local UnitName = UnitName
local GetRaidRosterInfo = GetRaidRosterInfo
local IsPartyLeader = IsPartyLeader
local UnitIsPartyLeader = UnitIsPartyLeader
local UnitIsUnit = UnitIsUnit
local IsRaidLeader = IsRaidLeader
local IsRaidOfficer = IsRaidOfficer

function GroupUtil.GetNumPartyMembers()
    return GetNumPartyMembers()
end

function GroupUtil.GetNumGroupMembers()
    local numRaidMembers = GetNumRaidMembers()
    if numRaidMembers > 0 then
        return numRaidMembers
    else
        return GetNumPartyMembers() + 1
    end
end

function GroupUtil.EnumerateGroupMembers()
    local numRaidMembers = GetNumRaidMembers()
    if numRaidMembers > 0 then
        return GroupUtil.EnumerateRaidMembers()
    else
        return GroupUtil.EnumeratePartyMembers()
    end
end

function GroupUtil.EnumerateGroupPets()
    local numRaidMembers = GetNumRaidMembers()
    if numRaidMembers > 0 then
        return GroupUtil.EnumerateRaidPets()
    else
        return GroupUtil.EnumeratePartyPets()
    end
end

function GroupUtil.EnumerateRaidMembers()
    local numRaidMembers = GetNumRaidMembers()
    local i = 0
    return function()
        i = i + 1
        if i <= numRaidMembers then
            return "raid" .. i
        end
    end
end

function GroupUtil.EnumerateRaidPets()
    local numRaidMembers = GetNumRaidMembers()
    local i = 0
    return function()
        i = i + 1
        if i <= numRaidMembers then
            return "raidpet" .. i
        end
    end
end


function GroupUtil.EnumeratePartyMembers()
    local numPartyMembers = GetNumPartyMembers()
    local i = 0
    return function()
        i = i + 1
        if i == 1 then -- we always want to return the player first
            return "player"
        elseif (i - 1) <= numPartyMembers then
            return "party" .. (i - 1)
        end
    end
end

function GroupUtil.EnumeratePartyPets()
    local numPartyMembers = GetNumPartyMembers()
    local i = 0
    return function()
        i = i + 1
        if i == 1 then -- we always want to return the player's pet first
            return "pet"
        elseif (i - 1) <= numPartyMembers then
            return "partypet" .. (i - 1)
        end
    end
end

function GroupUtil.GetGroupLeaderUnit()
    if GetNumRaidMembers() > 0 then
        if IsRaidLeader() then
            return "player", UnitName("player")
        end
        for i = 1, GetNumRaidMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if rank == 2 then
                return "raid"..i, name
            end
        end
    else
        if IsPartyLeader() then
            return "player", UnitName("player")
        end

        for i = 1, GetNumPartyMembers() do
            if UnitIsPartyLeader("party"..i) then
                return "party"..i, UnitName("party"..i)
            end
        end
    end
end

function GroupUtil.UnitIsGroupLeader(unit)
    if GetNumRaidMembers() > 0 then
        if UnitIsUnit(unit, "player") then
            return IsRaidLeader()
        end
        local _, _, subgroup, _, _, _, _, _, _, _, isLeader = GetRaidRosterInfo(tonumber(string.sub(unit, 5)))
        return isLeader
    else
        if UnitIsUnit(unit, "player") then
            return IsPartyLeader()
        end
        return UnitIsPartyLeader(unit)
    end
end

function GroupUtil.UnitIsGroupAssistant(unit)
    if GetNumRaidMembers() > 0 then
        if UnitIsUnit(unit, "player") then
            return IsRaidOfficer()
        end
        local _, _, subgroup, _, _, _, _, _, _, _, _, isAssistant = GetRaidRosterInfo(tonumber(string.sub(unit, 5)))
        return isAssistant
    else
        return false
    end
end

function GroupUtil.GetUsedGroups(tab)	--Fills out the table with which groups have people.
    for i = 1, MAX_RAID_GROUPS do
        tab[i] = false
    end
    if GroupUtil.IsInRaid() then
        local subgroup, _
        for i = 1, GetNumRaidMembers() do
            _, _, subgroup = GetRaidRosterInfo(i)
            tab[subgroup] = true
        end
    elseif GetNumPartyMembers() > 0 then
        tab[1] = true
    end
    return tab
end

function GroupUtil.IsInGroup()
    return GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
end 

function GroupUtil.IsInRaid()
    return GetNumRaidMembers() > 0
end 