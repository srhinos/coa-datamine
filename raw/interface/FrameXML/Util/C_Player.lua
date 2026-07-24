C_Player = { 
    currentLevel = nil,
    lastPetTalentPoints = nil,
}

local DevRealms = {
    "Twisting Nether",
    "Proudmoore",
    "Fizzcrank",
    "Moroes",
    "Thunderbluff",
}

function C_Player:GetName()
    return UnitName("player")
end

function C_Player:GetLevel()
    return self.currentLevel or UnitLevel("player")
end

function C_Player:IsMaxLevel()
    return self:GetLevel() >= GetMaxLevel()
end

function C_Player:GetClass()
    local name, class, id, mask = UnitClassBase("player")
    return class, id, mask
end

function C_Player:GetRace()
    local race = select(2, UnitRace("player"))
    local raceID = Enum.Race[race]
    return race, raceID
end

function C_Player:GetSex()
    local sex = UnitSex("player")
    local name = sex == 3 and "Female" or "Male"
    return sex, name
end

function C_Player:IsGM()
    return C_AccountInfo.GetGMLevel() > 0
end

function C_Player:IsDefaultClass()
    return IsDefaultClass("player")
end

function C_Player:IsHero()
    return IsHeroClass("player")
end

function C_Player:IsCustomClass()
    return IsCustomClass("player")
end

function C_Player:IsPrestiged()
    return C_Player:HasAura(9930831)
end

function C_Player:HasAura(auraID)
    return C_Aura.UnitHasAura("player", auraID)
end

-- checks for having a specific debuff ID
-- Calling HasDebuff is significantly more expensive than HasAura.
-- If you do not care if it's a buff or debuff, use HasAura instead.
function C_Player:HasDebuff(debuffID)
    return AuraUtil.HasDebuff("player", debuffID, false, AuraUtil.Predicate.MatchesSpellID)
end

-- Checks for having a specific buff ID
-- Calling HasBuff is significantly more expensive than HasAura.
-- If you do not care if it's a buff or debuff, use HasAura instead.
function C_Player:HasBuff(buffID)
    return AuraUtil.HasBuff("player", buffID, false, AuraUtil.Predicate.MatchesSpellID)
end

function C_Player:IsImmune()
    return AuraUtil.HasImmunity("player")
end

function C_Player:IsHighRisk()
    return self:GetRuleset() == Enum.Ruleset.HighRiskPvP
end

function C_Player:IsNoRiskPvP()
    return self:GetRuleset() == Enum.Ruleset.NoRiskPvP
end

function C_Player:IsNoRiskPvE()
    return self:GetRuleset() == Enum.Ruleset.NoRiskPvE
end

function C_Player:IsNoRiskPvPOrHigher()
    local ruleset = self:GetRuleset()
    return ruleset == Enum.Ruleset.NoRiskPvP or ruleset == Enum.Ruleset.HighRiskPvP
end

function C_Player:HasRuleset()
    return self:GetRuleset() ~= 0
end

function C_Player:GetFaction()
    return UnitFactionGroup("player")
end

function C_Player:IsWorldPVP()
    local pvpType = GetZonePVPInfo()

    if not UnitIsPVP("player") then
        return false
    end

    if pvpType == "contested" then return true end
    if pvpType == "hostile" then return true end
    if pvpType == "combat" then return true end
    return false
end

function C_Player:IsDead()
    return UnitIsDead("player")
end

function C_Player:InCombat()
    return UnitAffectingCombat("player") or InCombatLockdown()
end

function C_Player:IsInGroup()
    return GroupUtil.GetNumGroupMembers() > 1
end

function C_Player:IsInRaid()
    return GetNumRaidMembers() > 0
end

function C_Player:IsGroupLeader()
    return toboolean(IsRaidLeader() or IsRaidOfficer() or IsPartyLeader())
end

function C_Player:GetAverageItemLevel()
    return UnitAverageItemLevel("player")
end

function C_Player:GetCurrentCompanion()
    for i = 1, GetNumCompanions("CRITTER") do
        local creatureID, creatureName, spellID, icon, isSummoned = GetCompanionInfo("CRITTER", i)
        if isSummoned then
            return creatureID, creatureName, spellID, icon
        end
    end
end

function C_Player:GetRuleset()
    if self:HasBuff(1004019) then -- High Risk
        return Enum.Ruleset.HighRiskPvP
    end
    if self:HasBuff(1004119) then -- No Risk (PvP)
        if self:HasBuff(9931032) then -- No Risk (PvE)
            return Enum.Ruleset.NoRiskPvE
        end

        return Enum.Ruleset.NoRiskPvP
    end

    return Enum.Ruleset.None
end

function C_Player:SetRuleset(ruleset)
    if not RULESETS[ruleset] then return end
    CastSpellByID(RULESETS[ruleset])
end

function C_Player:GetRulesetCooldown()
    local cd = 0
    for _, spellId in pairs(RULESETS) do
        local start, duration = GetSpellCooldown(spellId)
        duration = (start + duration) - GetTime()
        if duration > 0 and duration > cd then
            cd = duration
        end
    end

    return cd
end

function C_Player:UpdatePvEPower()
    local totalPvEPower = 0

    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local id = GetInventoryItemID('player', slot)
        if id then
            local pvePower = C_Item:GetSlotItemPower(slot)
            totalPvEPower = totalPvEPower + pvePower
        end
    end

    totalPvEPower = min(totalPvEPower, PVE_POWER_CAP)

    if issecure() then
        self.pvePower = totalPvEPower
    end
    return totalPvEPower
end

function C_Player:GetPvEPower()
    return UnitPvEPower("player")
end

function C_Player:GetPvPPower()
    return UnitPvPPower("player")
end

function C_Player:IsTitansGrip()
    return IsSpellIDKnown(46917) or IsSpellIDKnown(1134994)
end

function C_Player:GetCurrentMapContinentZone()
    local _continent, _zone = GetCurrentMapContinent(), GetCurrentMapZone()
    SetMapToCurrentZone()
    local continent, zone = GetCurrentMapContinent(), GetCurrentMapZone()
    SetMapZoom(_continent, _zone)
    
    return continent, zone
end

function C_Player:GetCurrentMapInfo()
    local _continent, _zone = GetCurrentMapContinent(), GetCurrentMapZone()
    SetMapToCurrentZone()
    local mapFile, height, width = GetMapInfo()
    SetMapZoom(_continent, _zone)

    return mapFile, height, width
end

function C_Player:GetCurrentMapExpansion()
    local _continent, _zone = GetCurrentMapContinent(), GetCurrentMapZone()
    SetMapToCurrentZone()
    local expansion = GetMapExpansion()
    SetMapZoom(_continent, _zone)

    return expansion
end

do -- IsEffectivelyTank
    -- we need to cache this because IsKnownID can be expensive
    -- this function is also called VERY OFTEN
    local isEffectivelyTank
    local tankAurasToCheck = {}

    local function UpdateIsEffectivelyTankCache()
        wipe(tankAurasToCheck)
        local class = select(2, UnitClass("player"))
        if class == "HERO" then
            if C_CharacterAdvancement.IsKnownID(1360) then -- Savage Defense
                return true
            end

            if C_CharacterAdvancement.IsKnownID(913) then -- Survival Of Fittest
                return true
            end

            if C_CharacterAdvancement.IsKnownID(758) then -- Improved RF
                return true
            end

            if C_CharacterAdvancement.IsKnownID(875) then -- Sacred Duty
                return true
            end

            if C_CharacterAdvancement.IsKnownID(766) then -- Shield Spec
                return true
            end

            if C_CharacterAdvancement.IsKnownID(796) then -- Shield Mastery
                return true
            end

            if C_CharacterAdvancement.IsKnownID(794) then -- Imp Def Stance
                return true
            end
        elseif class == "WARRIOR" then
            if C_CharacterAdvancement.IsKnownID(12353) then -- Imp Def Stance
                return true
            end

            if C_CharacterAdvancement.IsKnownID(12310) then -- Shield Block
                tinsert(tankAurasToCheck, 1100071)
                -- defensive stance
                -- have to check because glad stance might take this talent too
                return true
            end
        elseif class == "PALADIN" then
            if C_CharacterAdvancement.IsKnownID(13956) then -- Improved RF
                return true
            end

            if C_CharacterAdvancement.IsKnownID(13977) then -- Sacred Duty
                return true
            end

            if C_CharacterAdvancement.IsKnownID(13984) then -- Holy Shield
                return true
            end
        elseif class == "DRUID" then
            if C_CharacterAdvancement.IsKnownID(13167) then -- Survival Of Fittest
                return true
            end

            if C_CharacterAdvancement.IsKnownID(13159) then -- Natural Reaction
                return true
            end

            -- if you dont have the other 2, you're either low lvl or not a tank probably.
            -- this is to try and catch low lvl bear tanks in the safest way possible.
            if C_CharacterAdvancement.IsKnownID(13136) then -- Thick Hide
                tinsert(tankAurasToCheck, 1109634) -- dire bear
                tinsert(tankAurasToCheck, 1105487) -- bear
            end
        elseif class == "SHAMAN" then
            if C_CharacterAdvancement.IsKnownID(13399) then -- Shield Spec
                return true
            end

            if C_CharacterAdvancement.IsKnownID(13701) then -- Spirit Guard
                return true
            end

            if MysticEnchantUtil.IsEnchantApplied(1134980) then -- Earthen Guardian
                return true
            end
        elseif class == "DEMONHUNTER" then
            return C_CharacterAdvancement.IsKnownID(4009)
        elseif class == "FLESHWARDEN" then
            return C_CharacterAdvancement.IsKnownID(4018)
        elseif class == "GUARDIAN" then
            return C_CharacterAdvancement.IsKnownID(4019)
        elseif class == "MONK" then
            return C_CharacterAdvancement.IsKnownID(4023)
        elseif class == "SONOFARUGAL" then
            return C_CharacterAdvancement.IsKnownID(4027)
        elseif class == "SUNCLERIC" then
            if C_CharacterAdvancement.IsKnownID(4048) or 
               C_CharacterAdvancement.IsKnownID(6550) or 
               C_CharacterAdvancement.IsKnownID(29504) then
                return true
            end
        elseif class == "PROPHET" then
            return C_CharacterAdvancement.IsKnownID(4054)
        elseif class == "REAPER" then
            return C_CharacterAdvancement.IsKnownID(4057)
        elseif class == "WITCHHUNTER" then
            return C_CharacterAdvancement.IsKnownID(7553)
        elseif class == "STARCALLER" then
            if C_CharacterAdvancement.IsKnownID(7689) or 
               C_CharacterAdvancement.IsKnownID(30221) then
                return true
            end
        elseif class == "WILDWALKER" then
            return C_CharacterAdvancement.IsKnownID(4064)
        end
        return false
    end
    
    EventRegistry:RegisterFrameEventAndCallback("ASCENSION_KNOWN_ENTRIES_UPDATED", function()
        isEffectivelyTank = UpdateIsEffectivelyTankCache()
    end)
    
    function C_Player:IsEffectivelyTank()
        if isEffectivelyTank == nil then
            isEffectivelyTank = UpdateIsEffectivelyTankCache()
        end

        if next(tankAurasToCheck) then
            for _, auraID in ipairs(tankAurasToCheck) do
                if C_Player:HasAura(auraID) then
                    return isEffectivelyTank
                end
            end

            return false
        end

        return isEffectivelyTank
    end
end

function C_Player:PLAYER_LEVEL_UP(level)
    self.currentLevel = level
end

function C_Player:PLAYER_ENTERING_WORLD()
    self.currentLevel = UnitLevel("player")
end

function C_Player:UNIT_PET()
    local unspent = GetUnspentTalentPoints(false, true)
    if unspent ~= nil then
        if self.lastPetTalentPoints and unspent < self.lastPetTalentPoints then
            C_Quest:SendPathToAscensionEvent("ACTION_SELECT_A_PET_TALENT")
        end
        self.lastPetTalentPoints = unspent
    end

    if GetNumTalents(1, false, true) > 0 and unspent and unspent > 0 then
        C_Quest:AddAutoQuestPopUp(Enum.Quests.PTAscension.PetTalents)
    end
end

C_Hook:Register(C_Player, "PLAYER_LEVEL_UP")
C_Hook:Register(C_Player, "PLAYER_ENTERING_WORLD")
if C_Player:IsHero() then
    C_Hook:Register(C_Player, "PET_TALENT_UPDATE, UNIT_PET", "UNIT_PET")
end
