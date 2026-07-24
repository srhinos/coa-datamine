TalentLoadoutUtil = CreateFromMixins(CallbackRegistryMixin)
TalentLoadoutUtil:OnLoad()

TalentLoadoutUtil:GenerateCallbackEvents({
    "OWNED_LOADOUTS_CHANGED",
    "ACTIVE_LOADOUT_CHANGED",
})

C_Hook:Register(TalentLoadoutUtil, "CHARACTER_ADVANCEMENT_LOADOUT_ACTIVE_PAYLOAD")
C_Hook:Register(TalentLoadoutUtil, "CHARACTER_ADVANCEMENT_LOADOUT_OWNED_PAYLOAD")
C_Hook:Register(TalentLoadoutUtil, "PLAYER_ENTERING_WORLD")

local loadouts = {}
local activeLoadout

function TalentLoadoutUtil.ActivateLoadout(uuid)
    C_CharacterAdvancement.ActivateLoadout(uuid)
end

function TalentLoadoutUtil.ActivateLoadoutAtIndex(index)
    local loadout = loadouts[index]
    C_CharacterAdvancement.ActivateLoadout(loadout.UUID)
end

function TalentLoadoutUtil.GetActiveLoadoutUUID()
    return activeLoadout
end

function TalentLoadoutUtil.RenameLoadout(uuid, name)
    name = name:trim()
    name = name:sub(1, 36)
    if name == "" then
        return
    end

    C_CharacterAdvancement.SetLoadoutName(uuid, name)
end

function TalentLoadoutUtil.RenameLoadoutAtIndex(index, name)
    local loadout = loadouts[index]
    name = name:trim()
    name = name:sub(1, 36)
    if name == "" then
        return
    end

    C_CharacterAdvancement.SetLoadoutName(loadout.UUID, name)
end

function TalentLoadoutUtil.SetLoadoutSortOrder(uuid, sortOrder)
    C_CharacterAdvancement.SetLoadoutSortOrder(uuid, sortOrder)
end

function TalentLoadoutUtil.GetNumLoadouts()
    return #loadouts
end

function TalentLoadoutUtil.GetLoadoutAtIndex(index)
    return loadouts[index]
end

function TalentLoadoutUtil:CHARACTER_ADVANCEMENT_LOADOUT_ACTIVE_PAYLOAD(json)
    local jsonObject = C_Serialize:FromJSON(json)
    if not jsonObject then
        return
    end
    activeLoadout = jsonObject.UUID
    self:TriggerEvent("ACTIVE_LOADOUT_CHANGED", activeLoadout)
end

function TalentLoadoutUtil:CHARACTER_ADVANCEMENT_LOADOUT_OWNED_PAYLOAD(json)
    local jsonObject = C_Serialize:FromJSON(json)
    if not jsonObject then
        return
    end

    wipe(loadouts)
    table.sort(jsonObject.Items, function(a, b) return a.SortOrder < b.SortOrder end)

    for _, loadout in ipairs(jsonObject.Items) do
        local loadoutItem = {}
        local requiredTE = 0
        local requiredAE = 0
        local requiredLevel = 0
        for _, loadoutEntry in ipairs(loadout.Entries) do
            local entry = C_CharacterAdvancement.GetEntryByInternalID(loadoutEntry.ID)
            if entry then
                local spellID = loadoutEntry.Rank and entry.Spells[loadoutEntry.Rank] or entry.Spells[1]
                local ae = C_CharacterAdvancement.GetAbilityEssenceCost(spellID) or 0
                local te = C_CharacterAdvancement.GetTalentEssenceCost(spellID) or 0

                requiredLevel = max(entry.RequiredLevel, requiredLevel)
                requiredAE = requiredAE + ae
                requiredTE = requiredTE + te
            end
        end

        loadoutItem.RequiredLevel = max(requiredTE + 10, requiredLevel)
        loadoutItem.RequiredAE = requiredAE
        loadoutItem.RequiredTE = requiredTE
        loadoutItem.UUID = loadout.UUID
        loadoutItem.Name = loadout.Name
        tinsert(loadouts, loadoutItem)
    end

    self:TriggerEvent("OWNED_LOADOUTS_CHANGED")
end

function TalentLoadoutUtil:PLAYER_ENTERING_WORLD()
    TalentLoadoutUtil:CHARACTER_ADVANCEMENT_LOADOUT_OWNED_PAYLOAD(GetJsonCacheData("CHARACTER_ADVANCEMENT_LOADOUT_OWNED_PAYLOAD", 0))
    TalentLoadoutUtil:CHARACTER_ADVANCEMENT_LOADOUT_ACTIVE_PAYLOAD(GetJsonCacheData("CHARACTER_ADVANCEMENT_LOADOUT_ACTIVE_PAYLOAD", 0))
    C_Hook:Unregister(TalentLoadoutUtil, "PLAYER_ENTERING_WORLD")
end
