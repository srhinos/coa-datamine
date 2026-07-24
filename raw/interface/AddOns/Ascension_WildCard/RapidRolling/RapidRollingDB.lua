-- RapidRollingDB.lua
-- Profile and Database state management for Rapid Rolling UI.

WildCardRapidRollingMixin = WildCardRapidRollingMixin or {}

function WildCardRapidRollingMixin:GetRapidRollingCDB()
    WildCardRapidRollingCDB = WildCardRapidRollingCDB or {}
    WildCard.CDB = WildCard.CDB or WildCardRapidRollingCDB
    return WildCard.CDB
end

function WildCardRapidRollingMixin:GetRapidRollingState()
    if type(C_Wildcard.GetRapidRollingState) == "function" then
        return C_Wildcard.GetRapidRollingState()
    end
end

function WildCardRapidRollingMixin:CopyFilter(filter)
    local copy = {}
    if filter then
        for key, value in pairs(filter) do
            copy[key] = value
        end
    end
    return copy
end

function WildCardRapidRollingMixin:GetRapidRollingFilterState()
    local specID = SpecializationUtil.GetActiveSpecialization()
    if not specID then
        return
    end

    local cdb = self:GetRapidRollingCDB()
    cdb.FilterState = cdb.FilterState or {}
    cdb.FilterState[specID] = cdb.FilterState[specID] or {}
    return cdb.FilterState[specID]
end

local function BuildRapidRollingSelectionArray(savedEntries, canAddFunc, isSelectedFunc, toRemove)
    local selections = {}

    for entryType in pairs(savedEntries) do
        for id in pairs(savedEntries[entryType]) do
            local canAdd = type(canAddFunc) == "function" and canAddFunc(id, entryType)
            local isSelected = type(isSelectedFunc) == "function" and isSelectedFunc(id, entryType)
            if canAdd or isSelected then
                table.insert(selections, { ID = id, Type = entryType })
            else
                table.insert(toRemove, { entryType, id })
            end
        end
    end

    return selections
end

local function PruneSavedRapidRollingSelections(savedEntries, toRemove)
    for _, info in ipairs(toRemove) do
        savedEntries[info[1]][info[2]] = nil
    end
    wipe(toRemove)
end

local function RestoreRapidRollingSelectionsFallback(selections, addFunc)
    if type(addFunc) ~= "function" then
        return
    end

    for _, selection in ipairs(selections) do
        addFunc(selection.ID, selection.Type)
    end
end

function WildCardRapidRollingMixin:RestoreSavedSelections()
    RapidRollDesired = RapidRollDesired or {}
    RapidRollUndesired = RapidRollUndesired or {}

    local specID = SpecializationUtil.GetActiveSpecialization()
    if not specID then
        return
    end

    local toRemove = {}
    local savedDesired = RapidRollDesired[specID] or {}
    local desiredSelections = BuildRapidRollingSelectionArray(savedDesired, C_Wildcard.CanAddDesiredID, C_Wildcard.IsDesiredID, toRemove)
    PruneSavedRapidRollingSelections(savedDesired, toRemove)
    RapidRollDesired[specID] = savedDesired

    local savedUndesired = RapidRollUndesired[specID] or {}
    local undesiredSelections = BuildRapidRollingSelectionArray(savedUndesired, C_Wildcard.CanAddUndesiredID, C_Wildcard.IsUndesiredID, toRemove)
    PruneSavedRapidRollingSelections(savedUndesired, toRemove)
    RapidRollUndesired[specID] = savedUndesired
    toRemove = nil

    if type(C_Wildcard.SetRapidRollingSelections) == "function" then
        local ok, reason = C_Wildcard.SetRapidRollingSelections(desiredSelections, undesiredSelections)
        if not ok and reason then
            self:ShowRapidRollingError(reason)
        end
    else
        RestoreRapidRollingSelectionsFallback(desiredSelections, C_Wildcard.AddDesiredID)
        RestoreRapidRollingSelectionsFallback(undesiredSelections, C_Wildcard.AddUndesiredID)
    end
end

function WildCardRapidRollingMixin:SaveFilterState()
    if self.restoringFilterState then
        return
    end

    local state = self:GetRapidRollingFilterState()
    if not state then
        return
    end

    state.DesiredFilter = self:CopyFilter(self.DesiredFilter:GetFilter())
    state.UndesiredFilter = self:CopyFilter(self.UndesiredFilter:GetFilter())
    state.DesiredSearchText = self.DesiredSearchBox:GetText()
    state.UndesiredSearchText = self.UndesiredSearchBox:GetText()
end

function WildCardRapidRollingMixin:RestoreFilterState()
    local state = self:GetRapidRollingFilterState()
    if not state then
        return
    end

    self.restoringFilterState = true

    self.DesiredFilter:ClearFilters()
    self.UndesiredFilter:ClearFilters()
    self.DesiredSearchBox:SetText(state.DesiredSearchText or "")
    self.UndesiredSearchBox:SetText(state.UndesiredSearchText or "")

    for key, value in pairs(state.DesiredFilter or {}) do
        self.DesiredFilter:SetFilter(key, value)
    end

    for key, value in pairs(state.UndesiredFilter or {}) do
        self.UndesiredFilter:SetFilter(key, value)
    end

    self.restoringFilterState = nil
end

function WildCardRapidRollingMixin:SaveDesiredEntry(entryID, entryType)
    C_Wildcard.AddDesiredID(entryID, entryType)
    local specID = SpecializationUtil.GetActiveSpecialization()
    RapidRollDesired[specID] = RapidRollDesired[specID] or {}
    RapidRollDesired[specID][entryType] = RapidRollDesired[specID][entryType] or {}
    RapidRollDesired[specID][entryType][entryID] = true
end

function WildCardRapidRollingMixin:SaveUndesiredEntry(entryID, entryType)
    C_Wildcard.AddUndesiredID(entryID, entryType)
    local specID = SpecializationUtil.GetActiveSpecialization()
    RapidRollUndesired[specID] = RapidRollUndesired[specID] or {}
    RapidRollUndesired[specID][entryType] = RapidRollUndesired[specID][entryType] or {}
    RapidRollUndesired[specID][entryType][entryID] = true
end

function WildCardRapidRollingMixin:RemoveDesiredEntry(entryID, entryType)
    C_Wildcard.RemoveDesiredID(entryID, entryType)
    local specID = SpecializationUtil.GetActiveSpecialization()
    RapidRollDesired[specID] = RapidRollDesired[specID] or {}
    RapidRollDesired[specID][entryType] = RapidRollDesired[specID][entryType] or {}
    RapidRollDesired[specID][entryType][entryID] = nil
end

function WildCardRapidRollingMixin:RemoveUndesiredEntry(entryID, entryType)
    C_Wildcard.RemoveUndesiredID(entryID, entryType)
    local specID = SpecializationUtil.GetActiveSpecialization()
    RapidRollUndesired[specID] = RapidRollUndesired[specID] or {}
    RapidRollUndesired[specID][entryType] = RapidRollUndesired[specID][entryType] or {}
    RapidRollUndesired[specID][entryType][entryID] = nil
end
