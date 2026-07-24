-- Handles primary stat related functions

C_PrimaryStat = C_PrimaryStat or {}
--local PRIMARY_STAT_NAME_FORMAT

if IsCustomClass() then
    -- COA PRIMARY STATS
    PRIMARY_STAT_NAME_FORMAT = "PRIMARY_STAT_%d_NAME_COA"

    C_PrimaryStat.internalIds = {
        1149, -- Strength
        1150, -- Agility
        1151, -- Intellect
        1152, -- Spirit
        nil, -- Stamina (reserved)
        18149, -- Duality
    }

    C_PrimaryStat.SpellToID = {
        [84864] = Enum.PrimaryStat.Strength, -- Strength
        [84865] = Enum.PrimaryStat.Agility, -- Agility
        [84866] = Enum.PrimaryStat.Intellect, -- Intellect
        [84867] = Enum.PrimaryStat.Spirit, -- Spirit
        [129243] = Enum.PrimaryStat.Duality, -- Duality
        
    }

    C_PrimaryStat.Auras = {
        954687, -- Primary Stat: Strength
        954688, -- Primary Stat: Agility
        954689, -- Primary Stat: Intellect
        954690, -- Primary Stat: Spirit
        nil, -- Stamina
        954699, -- Primary Stat: Duality
    }

    C_PrimaryStat.AuraToID = {
        [954687] = Enum.PrimaryStat.Strength, -- Strength
        [954688] = Enum.PrimaryStat.Agility, -- Agility
        [954689] = Enum.PrimaryStat.Intellect, -- Intellect
        [954690] = Enum.PrimaryStat.Spirit, -- Spirit
        [954699] = Enum.PrimaryStat.Duality -- Duality
    }

else
    -- EVERYTHING ELSE PRIMARY STATS
    PRIMARY_STAT_NAME_FORMAT = "PRIMARY_STAT%d_NAME"

    C_PrimaryStat.internalIds = {
        1149, -- Strength
        1150, -- Agility
        1151, -- Intellect
        1152, -- Spirit
        nil, -- Stamina (reserved)
        18149, -- Duality
    }

    C_PrimaryStat.SpellToID = {
        [84864] = Enum.PrimaryStat.Strength, -- Strength
        [84865] = Enum.PrimaryStat.Agility, -- Agility
        [84866] = Enum.PrimaryStat.Intellect, -- Intellect
        [84867] = Enum.PrimaryStat.Spirit, -- Spirit
        [129243] = Enum.PrimaryStat.Duality,
    }

    C_PrimaryStat.Auras = {
        954687, -- Primary Stat: Strength
        954688, -- Primary Stat: Agility
        954689, -- Primary Stat: Intellect
        954690, -- Primary Stat: Spirit
        nil, -- placeholder stamina
        954699, -- Primary Stat: Duality
    }

    C_PrimaryStat.AuraToID = {
        [954687] = Enum.PrimaryStat.Strength, -- Strength
        [954688] = Enum.PrimaryStat.Agility, -- Agility
        [954689] = Enum.PrimaryStat.Intellect, -- Intellect
        [954690] = Enum.PrimaryStat.Spirit, -- Spirit
        [954699] = Enum.PrimaryStat.Duality, -- Duality
    }

end


function C_PrimaryStat:GetInternalID(id)
    return self.internalIds[id]
end

function C_PrimaryStat:SetPrimaryStat(id)
    if C_Player:InCombat() then return end
    if IsActiveBattlefieldArena() then return end
    local internalID = self.internalIds[id]
    if internalID and not (PRIMARY_STATS[id] and IsSpellKnown(PRIMARY_STATS[id])) then
        CharacterAdvancementUtil.ConfirmOrLearnID(internalID)
        return true
    end
end

function C_PrimaryStat:GetActivePrimaryStat()
    if C_CharacterAdvancement.IsPendingBuildAvailable() then
        for id, internalId in pairs(self.internalIds) do
            local rank = C_CharacterAdvancement.GetPendingRankByEntryID(internalId)
            if rank and (rank > 0) then
                return id
            end
        end
    end

    for id, spellId in ipairs(PRIMARY_STATS) do
        if IsSpellKnown(spellId) then
            return id
        end
    end
end

function C_PrimaryStat:GetPrimaryStatAura(id)
    if id > 4 then
        id = self:GetPrimaryStatID(id)
    end
    
    if not id then return end
    
    return self.Auras[id]
end

function C_PrimaryStat:GetUnitPrimaryStat(unit)
    if not unit then return end
    return GetUnitPrimaryStat(unit)
end

function C_PrimaryStat:GetPrimaryStatInfo(id)
    if not id then return end
    local spellId = PRIMARY_STATS[id]
    if not spellId then return end

    local internalId = self.internalIds[id]
    local spellName, _, icon = GetSpellInfo(spellId)
    local statName = _G[format(PRIMARY_STAT_NAME_FORMAT, id)]

    return spellId, internalId, icon, statName, spellName
end

function C_PrimaryStat:GetPrimaryStatID(spellId)
    return self.SpellToID[spellId]
end

function C_PrimaryStat:GetPrimaryStatSpell(id)
    return PRIMARY_STATS[id]
end