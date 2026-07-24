C_CrowdControl = {
    Active = {},
    HasControl = true,
}

C_Hook:Register(C_CrowdControl, "UNIT_AURA")
C_Hook:Register(C_CrowdControl, "COMBAT_LOG_EVENT_UNFILTERED")
C_Hook:Register(C_CrowdControl, "PLAYER_ENTERING_WORLD")
C_Hook:Register(C_CrowdControl, "CROWD_CONTROL_ADDED")
C_Hook:Register(C_CrowdControl, "CROWD_CONTROL_REMOVED")

function C_CrowdControl:PLAYER_ENTERING_WORLD()
    self:UNIT_AURA("player")
end

function C_CrowdControl:UNIT_AURA(unit)
    if unit ~= "player" then return end

    local toRemove = {}

    for id, data in pairs(self.Active) do
        if not data.lockoutSchool then
            toRemove[id] = true
        end
    end

    for i = 1, 255 do
        local name, _, icon, _, _, duration, expirationTime, _, _, _, spellID = UnitAura("player", i, "HARMFUL")

        if spellID and name then
            if CROWD_CONTROL_DATA[spellID] then

                if toRemove[spellID] then
                    toRemove[spellID] = nil
                end

                if self.Active[spellID] then
                    local currentExpire = self.Active[spellID].expirationTime

                    if expirationTime > currentExpire then
                        self.Active[spellID].duration = duration
                        self.Active[spellID].expirationTime = expirationTime
                        C_Hook:SendEvent("CROWD_CONTROL_UPDATED", spellID)
                    end
                else
                    if CROWD_CONTROL_DATA[spellID].ccType ~= CROWD_CONTROL_TYPE_PACIFY then
                        self.Active[spellID] = { name = name, icon = icon, duration = duration, expirationTime = expirationTime }
                        C_Hook:SendEvent("CROWD_CONTROL_ADDED", spellID)
                    end
                end
            end
        else
            break
        end
    end

    for spellID in pairs(toRemove) do
        self.Active[spellID] = nil
        C_Hook:SendEvent("CROWD_CONTROL_REMOVED", spellID)
    end
end

local CHANNEL_SPELLS_WITH_CD = {
    -- Death Knight
    [42650] = true, -- Army of the Dead

    -- Druid
    [740] = true, -- Tranquility (Rank 1)
    [8918] = true, -- Tranquility (Rank 2)
    [9862] = true, -- Tranquility (Rank 3)
    [9863] = true, -- Tranquility (Rank 4)
    [26983] = true, -- Tranquility (Rank 5)
    [48446] = true, -- Tranquility (Rank 6)
    [48447] = true, -- Tranquility (Rank 7)

    -- Warlock
    [29893] = true, -- Ritual of Souls (Rank 1)
    [58887] = true, -- Ritual of Souls (Rank 2)
    [698] = true, -- Ritual of Summoning

    -- Mage
    [12051] = true, -- Evocation
    [43987] = true, -- Ritual of Refreshments (Rank 1)
    [58659] = true, -- Ritual of Refreshments (Rank 2)

    -- Priest
    [64843] = true, -- Divine Hymn
    [64901] = true, -- Hymn of Hope
    [47540] = true, -- Pennance (Rank 1)
    [53005] = true, -- Pennance (Rank 2)
    [53006] = true, -- Pennance (Rank 3)
    [53007] = true, -- Pennance (Rank 4)
    [888571] = true, -- Prayer of Preservation (Rank 1)
    [888572] = true, -- Prayer of Preservation (Rank 2)
    [888573] = true, -- Prayer of Preservation (Rank 3)
    [888574] = true, -- Prayer of Preservation (Rank 4)
    [888575] = true, -- Prayer of Preservation (Rank 5)
    [888576] = true, -- Prayer of Preservation (Rank 6)
}

-- Handles Interrupts
function C_CrowdControl:COMBAT_LOG_EVENT_UNFILTERED(...)
    local _, subEvent, _, _, _, _, targetName, _, spellID, _, _, interruptedSpellID, spellName, lockoutSchool = ...

    if CROWD_CONTROL_DATA[spellID] and subEvent == "SPELL_INTERRUPT" and targetName == C_Player:GetName() and lockoutSchool then
        local _, _, icon = GetSpellInfo(spellID)
        local _, duration = GetSpellCooldown(spellName)

        if CHANNEL_SPELLS_WITH_CD[interruptedSpellID] then
            duration = CROWD_CONTROL_DATA[spellID].lockout
        end

        if not duration then
            return
        end

        local expirationTime = GetTime() + duration

        if self.Active[spellID] then
            local currentTime = GetTime()
            local currentDuration = self.Active[spellID].expirationTime - currentTime
            local newDuration = expirationTime - currentTime

            if newDuration > currentDuration then
                self.Active[spellID].duration = duration
                self.Active[spellID].expirationTime = expirationTime
                self.Active[spellID].lockoutSchool = lockoutSchool
                self.Active[spellID].timer:Cancel()

                local timer = Timer.After(duration, function()
                    self.Active[spellID] = nil
                    C_Hook:SendEvent("CROWD_CONTROL_REMOVED", spellID)
                end)

                self.Active[spellID].timer = timer
                C_Hook:SendEvent("CROWD_CONTROL_UPDATED", spellID)
            end
        else
            local timer = Timer.After(duration, function()
                self.Active[spellID] = nil
                C_Hook:SendEvent("CROWD_CONTROL_REMOVED", spellID)
            end)
            self.Active[spellID] = { name = spellName, icon = icon, duration = duration, expirationTime = expirationTime, lockoutSchool = lockoutSchool, timer = timer }
            C_Hook:SendEvent("CROWD_CONTROL_ADDED", spellID)
        end
    end
end

function C_CrowdControl:CROWD_CONTROL_ADDED(...)
    if self.HasControl then
        self.HasControl = false
        C_Hook:SendEvent("PLAYER_CONTROL_LOST")
    end
end

function C_CrowdControl:CROWD_CONTROL_REMOVED(...)
    if self.HasControl then return end

    if not next(self.Active) then
        C_Hook:SendEvent("PLAYER_CONTROL_GAINED")
    end
end

function C_CrowdControl:GetCrowdControlInfo(spellID)
    local name, icon, duration, expirationTime, startTime, priority, lockoutSchool, displayName

    local data = self.Active[spellID]

    if data then
        name = data.name
        icon = data.icon
        duration = data.duration
        expirationTime = data.expirationTime
        startTime = expirationTime and duration and expirationTime - duration
        lockoutSchool = data.lockoutSchool

        local spellData = CROWD_CONTROL_DATA[spellID]
        priority = spellData.priority or CROWD_CONTROL_TYPES[spellData.ccType].priority
        displayName = _G[spellData.display] or spellData.display
    end

    return name, icon, duration, expirationTime, startTime, priority, displayName, lockoutSchool
end

function C_CrowdControl:GetActiveCrowdControl()
    local cc = {}
    for spellId in pairs(self.Active) do
        tinsert(cc, spellId)
    end

    return cc
end