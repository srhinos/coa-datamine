-- RapidRollingSpells.lua
-- Unified spell selection, exclusion, and lock state management for Rapid Rolling UI.

WildCardRapidRollingMixin = WildCardRapidRollingMixin or {}

-- Unified iterator to find build spells and match them against Advancement entries
function WildCardRapidRollingMixin:IterateBuildSpells(build, checkFunc, actionFunc)
    if not build or not build.Spells then
        return
    end
    for _, spell in ipairs(build.Spells) do
        if not checkFunc or checkFunc(spell) then
            local entry = C_CharacterAdvancement.GetEntryBySpellID(spell.Spell)
            if entry then
                actionFunc(entry, spell)
            end
        end
    end
end

-- Parametric helper to select (desire) spells matching specific criteria
function WildCardRapidRollingMixin:DesireBuildSpellsByAttribute(build, attributeKey)
    if not build then
        return
    end
    self:UnregisterEvent("WILDCARD_DESIRED_ENTRIES_CHANGED")
    self:IterateBuildSpells(build, function(spell)
        return attributeKey == nil or spell[attributeKey]
    end, function(entry)
        if C_Wildcard.CanAddDesiredID(entry.ID, entry.Type) then
            self:SaveDesiredEntry(entry.ID, entry.Type)
        end
    end)
    self:RegisterEvent("WILDCARD_DESIRED_ENTRIES_CHANGED")
    self:Refresh(true)
end

function WildCardRapidRollingMixin:DesireBuildCoreSpells(build)
    self:DesireBuildSpellsByAttribute(build, "IsCoreAbility")
end

function WildCardRapidRollingMixin:DesireBuildOptimalSpells(build)
    self:DesireBuildSpellsByAttribute(build, "IsOptimalAbility")
end

function WildCardRapidRollingMixin:DesireBuildEmpoweringSpells(build)
    self:DesireBuildSpellsByAttribute(build, "IsEmpoweringAbility")
end

function WildCardRapidRollingMixin:DesireBuildSynergisticSpells(build)
    self:DesireBuildSpellsByAttribute(build, "IsSynergisticAbility")
end

function WildCardRapidRollingMixin:DesireBuildAllSpells(build)
    if not build then
        return
    end
    self:UnregisterEvent("WILDCARD_DESIRED_ENTRIES_CHANGED")
    C_Wildcard.ClearDesiredSpells()
    local specID = SpecializationUtil.GetActiveSpecialization()
    if specID and RapidRollDesired[specID] then
        wipe(RapidRollDesired[specID])
    end
    self:IterateBuildSpells(build, nil, function(entry)
        if C_Wildcard.CanAddDesiredID(entry.ID, entry.Type) then
            self:SaveDesiredEntry(entry.ID, entry.Type)
        end
    end)
    self:RegisterEvent("WILDCARD_DESIRED_ENTRIES_CHANGED")
    self:Refresh(true)
    C_Quest:SendPathToAscensionEvent("ACTION_WILDCARD_DESIRE_ALL_SPELLS")
end

function WildCardRapidRollingMixin:UndesireBuildAllSpells(build)
    if not build then
        return
    end
    self:UnregisterEvent("WILDCARD_UNDESIRED_ENTRIES_CHANGED")
    C_Wildcard.ClearUndesiredSpells()
    local specID = SpecializationUtil.GetActiveSpecialization()
    if specID and RapidRollUndesired[specID] then
        wipe(RapidRollUndesired[specID])
    end

    local spellsToKeep = {}
    local keepSynergistic = not self.UndesireSynergistic:GetBoolValue()
    local keepEmpowering = not self.UndesireEmpowering:GetBoolValue()

    self:IterateBuildSpells(build, nil, function(entry, spell)
        if spell.IsSynergisticAbility then
            if keepSynergistic then
                spellsToKeep[entry.ID] = true
            end
        elseif spell.IsEmpoweringAbility then
            if keepEmpowering then
                spellsToKeep[entry.ID] = true
            end
        else
            spellsToKeep[entry.ID] = true
        end
    end)

    for _, entry in ipairs(C_CharacterAdvancement.GetKnownTalentEntries()) do
        if not spellsToKeep[entry.ID] and C_Wildcard.CanAddUndesiredID(entry.ID, entry.Type) then
            self:SaveUndesiredEntry(entry.ID, entry.Type)
        end
    end
    
    for _, entry in ipairs(C_CharacterAdvancement.GetKnownSpellEntries()) do
        if not spellsToKeep[entry.ID] and C_Wildcard.CanAddUndesiredID(entry.ID, entry.Type) then
            self:SaveUndesiredEntry(entry.ID, entry.Type)
        end
    end
    
    self.savedBuild = build

    self:RegisterEvent("WILDCARD_UNDESIRED_ENTRIES_CHANGED")
    self:Refresh(true)
    C_Quest:SendPathToAscensionEvent("ACTION_WILDCARD_UNLEARN_ALL_NON_BUILD_SPELLS")
end

function WildCardRapidRollingMixin:StartUndesireAll(build)
    self:UndesireBuildAllSpells(build)
    self.undesireAll = true
end

function WildCardRapidRollingMixin:StopUndesireAll()
    self.undesireAll = false
    self:UpdateUndesireAllButton()
end

-- Parametric helper to lock/unlock spells matching specific criteria
function WildCardRapidRollingMixin:LockBuildSpellsByAttribute(build, attributeKey, shouldLock)
    if not build then
        return
    end
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:IterateBuildSpells(build, function(spell)
        return attributeKey == nil or spell[attributeKey]
    end, function(entry)
        if C_CharacterAdvancement.IsKnownID(entry.ID) then
            local isLocked = C_CharacterAdvancement.IsLockedID(entry.ID)
            if shouldLock and not isLocked then
                C_CharacterAdvancement.LockID(entry.ID)
            elseif not shouldLock and isLocked then
                C_CharacterAdvancement.UnlockID(entry.ID)
            end
        end
    end)
    self:RegisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:Refresh(true)
end

function WildCardRapidRollingMixin:LockBuildSpells(build)
    self:LockBuildSpellsByAttribute(build, nil, true)
end

function WildCardRapidRollingMixin:LockBuildCoreSpells(build)
    self:LockBuildSpellsByAttribute(build, "IsCoreAbility", true)
end

function WildCardRapidRollingMixin:LockBuildOptimalSpells(build)
    self:LockBuildSpellsByAttribute(build, "IsOptimalAbility", true)
end

function WildCardRapidRollingMixin:LockBuildEmpoweringSpells(build)
    self:LockBuildSpellsByAttribute(build, "IsEmpoweringAbility", true)
end

function WildCardRapidRollingMixin:LockBuildSynergisticSpells(build)
    self:LockBuildSpellsByAttribute(build, "IsSynergisticAbility", true)
end

function WildCardRapidRollingMixin:UnlockBuildEmpoweringSpells(build)
    self:LockBuildSpellsByAttribute(build, "IsEmpoweringAbility", false)
end

function WildCardRapidRollingMixin:UnlockBuildSynergisticSpells(build)
    self:LockBuildSpellsByAttribute(build, "IsSynergisticAbility", false)
end
