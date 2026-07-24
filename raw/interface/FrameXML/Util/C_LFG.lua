C_LFG = {
    RequiredRandomItemLevel = {
        [1258]= 40, -- Random Classic Heroic
        [2258]= 58, -- Random Classic Mythic
        [418] = 70, -- Random Burning Crusade Heroic
        [419] = 108, -- Random Burning Crusade Mythic
    },
    RequiredRandomPVEPower = {
        [2258]= 350, -- Random Classic Mythic
        [419] = 350, -- Random Burning Crusade Mythic
    },
    ScalingDungeons = {
        [1]=true,
        [4]=true,
        [6]=true,
        [8]=true,
        [10]=true,
        [12]=true,
        [16]=true,
        [14]=true,
        [18]=true,
        [20]=true,
        [22]=true,
        [24]=true,
        [26]=true,
        [28]=true,
        [163]=true,
        [164]=true,
        [165]=true,
        [272]=true,
        [273]=true,
    },
    RequiresGameEvent = {
        -- TBC Heroics
        [418] = Enum.GameEvent.TBCHeroics,
        [187] = Enum.GameEvent.HeroicHellfire, -- Blood Furnace
        [188] = Enum.GameEvent.HeroicHellfire, -- Hellfire Ramparts
        [189] = Enum.GameEvent.HeroicHellfire, -- Shattered Halls
        [184] = Enum.GameEvent.HeroicCoilfang, -- Slave Pens
        [185] = Enum.GameEvent.HeroicCoilfang, -- The Steamvault
        [186] = Enum.GameEvent.HeroicCoilfang, -- Underbog
        [178] = Enum.GameEvent.HeroicAuchindoun, -- Auchenai Crypts
        [179] = Enum.GameEvent.HeroicAuchindoun, -- Mana-Tombs
        [180] = Enum.GameEvent.HeroicAuchindoun, -- Sethekk Halls
        [181] = Enum.GameEvent.HeroicAuchindoun, -- Shadow Labyrinth
        [190] = Enum.GameEvent.HeroicTempestKeep, -- The Arcatraz
        [191] = Enum.GameEvent.HeroicTempestKeep, -- The Botanica
        [192] = Enum.GameEvent.HeroicTempestKeep, -- The Mechanar
        [182] = Enum.GameEvent.HeroicCavernsOfTime, -- The Black Morass
        [183] = Enum.GameEvent.HeroicCavernsOfTime, -- The Escape From Durnholde
        -- TBC Mythics
        [419] = Enum.GameEvent.TBCMythics,
        [268] = Enum.GameEvent.MythicHellfire, -- Blood Furnace
        [269] = Enum.GameEvent.MythicHellfire, -- Hellfire Ramparts
        [270] = Enum.GameEvent.MythicHellfire, -- Shattered Halls
        [265] = Enum.GameEvent.MythicCoilfang, -- Slave Pens
        [266] = Enum.GameEvent.MythicCoilfang, -- The Steamvault
        [267] = Enum.GameEvent.MythicCoilfang, -- Underbog
        [259] = Enum.GameEvent.MythicAuchindoun, -- Auchenai Crypts
        [260] = Enum.GameEvent.MythicAuchindoun, -- Mana-Tombs
        [261] = Enum.GameEvent.MythicAuchindoun, -- Sethekk Halls
        [262] = Enum.GameEvent.MythicAuchindoun, -- Shadow Labyrinth
        [271] = Enum.GameEvent.MythicTempestKeep, -- The Arcatraz
        [308] = Enum.GameEvent.MythicTempestKeep, -- The Botanica
        [309] = Enum.GameEvent.MythicTempestKeep, -- The Mechanar
        [263] = Enum.GameEvent.MythicCavernsOfTime, -- The Black Morass
        [264] = Enum.GameEvent.MythicCavernsOfTime, -- The Escape From Durnholde
        -- Vanilla Heroics
        [1030] = Enum.GameEvent.HeroicBlackrockDepths, -- Blackrock Depths - Prison
        [1276] = Enum.GameEvent.HeroicBlackrockDepths, -- Blackrock Depths - Upper City
        [1034] = Enum.GameEvent.HeroicDireMaul, -- Dire Maul - East
        [1036] = Enum.GameEvent.HeroicDireMaul, -- Dire Maul - West
        [1038] = Enum.GameEvent.HeroicDireMaul, -- Dire Maul - North
        [1032] = Enum.GameEvent.HeroicBlackrockSpire, -- Lower Blackrock Spire
        [1002] = Enum.GameEvent.HeroicScholomance, -- Scholomance
        [1040] = Enum.GameEvent.HeroicStratholme, -- Stratholme - Main Gate
        [1274] = Enum.GameEvent.HeroicStratholme, -- Stratholme - Service Entrance
        [1258] = { -- Random Classic Heroic
            Enum.GameEvent.HeroicBlackrockSpire,
            Enum.GameEvent.HeroicBlackrockDepths,
            Enum.GameEvent.HeroicScholomance,
            Enum.GameEvent.HeroicStratholme,
            Enum.GameEvent.HeroicMaraudon,
            Enum.GameEvent.HeroicDireMaul,
        },
        -- Vanilla Mythics
        [2030] = Enum.GameEvent.MythicBlackrockDepths, -- Blackrock Depths - Prison
        [2276] = Enum.GameEvent.MythicBlackrockDepths, -- Blackrock Depths - Upper City
        [2034] = Enum.GameEvent.MythicDireMaul, -- Dire Maul - East
        [2036] = Enum.GameEvent.MythicDireMaul, -- Dire Maul - West
        [2038] = Enum.GameEvent.MythicDireMaul, -- Dire Maul - North
        [2032] = Enum.GameEvent.MythicBlackrockSpire, -- Lower Blackrock Spire
        [2002] = Enum.GameEvent.MythicScholomance, -- Scholomance
        [2040] = Enum.GameEvent.MythicStratholme, -- Stratholme - Main Gate
        [2274] = Enum.GameEvent.MythicStratholme, -- Stratholme - Service Entrance
        [2258] = { -- Random Classic Mythic
            Enum.GameEvent.MythicBlackrockSpire,
            Enum.GameEvent.MythicBlackrockDepths,
            Enum.GameEvent.MythicScholomance,
            Enum.GameEvent.MythicStratholme,
            Enum.GameEvent.MythicMaraudon,
            Enum.GameEvent.MythicDireMaul,
        },
    },
    RequiredExpansion = {
        [417] = 1,
        [418] = 1,
        [419] = 1,
    }
}

function C_LFG:IsRandomDungeonDisplayable(id)
    if not id then return false end
	local _, _, minLevel, maxLevel, _, _, _, expansionLevel = GetLFGDungeonInfo(id)
    expansionLevel = self.RequiredExpansion[id] or expansionLevel
	local myLevel = C_Player:GetLevel()
	return myLevel >= minLevel and myLevel <= maxLevel and GetExpansionLevel() >= expansionLevel
end

function C_LFG:IsScalingDungeon(dungeonId)
    return self.ScalingDungeons[dungeonId]
end

function C_LFG:CanUseLFD()
    if not ChallengeUtil.CanUseGroupFinder() then
        return false, "CHALLENGES_NO_GROUP_FINDER"
    end

    return C_Player:GetLevel() >= SHOW_LFD_LEVEL, format(LFD_REQUIRED_LEVEL, SHOW_LFD_LEVEL)
end

function C_LFG:CanUseGroupFinder()
    if not ChallengeUtil.CanUseGroupFinder() then
        return false, "CHALLENGES_NO_GROUP_FINDER"
    end

    if not C_Config.GetBoolConfig("CONFIG_GROUP_FINDER_ENABLED") then
        return false, FEATURE_UNAVAILABLE_AT_THIS_TIME
    end
    
    return true
end

function C_LFG:CanUseManastorm()
    if not C_Config.GetBoolConfig("CONFIG_MANASTORM_ENABLED") then
        return false, "MANASTORM_NOT_AVAILABLE"
    end
    return C_Player:GetLevel() >= 10, "MANASTORM_REQUIRED_LEVEL"
end

function C_LFG:CanUseRandomLFD(dungeonId)
    if not ChallengeUtil.CanUseGroupFinder() then
        return false, "CHALLENGES_NO_GROUP_FINDER"
    end
    if self.RequiresGameEvent[dungeonId] then
        local events = self.RequiresGameEvent[dungeonId]
        local error = INSTANCE_UNAVAILABLE_DIFFICULTY_NOT_RELEASED
        if C_Realm.IsSeasonal() then
            error = error .. "\n" .. CHECK_TIMELINE_FOR_UNLOCK_DATE
        end
        if type(events) == "table" then
            if not GameEventUtil.IsAnyEventActive(unpack(events)) then
                return false, error
            end
        elseif type(events) == "number" then
            if not GameEventUtil.IsEventActive(events) then
                return false, error
            end
        end
    end

    -- check pve power
    local requiredPVEPower = self.RequiredRandomPVEPower[dungeonId]

    if requiredPVEPower then
        local PVEPower = C_Player:GetPvEPower()
        if PVEPower < requiredPVEPower then
            return false, format(MUST_HAVE_S_PVE_POWER_OR_HIGHER, requiredPVEPower)
        end
    end
    
    -- check ilvl
    local requiredItemLevel = self.RequiredRandomItemLevel[dungeonId]

    if requiredItemLevel then
        local averageItemLevel = C_Player:GetAverageItemLevel()
        if averageItemLevel < requiredItemLevel then
            return false, format(MUST_OBTAIN_ILVL_S_OR_HIGHER, requiredItemLevel)
        end
    end

    return true
end

function C_LFG:GetLFGDungeonRewards(dungeonId)
    local doneToday, moneyBase, moneyVar, experienceBase, experienceVar, numRewards = GetLFGDungeonRewards(dungeonId)
    local rewards = {}

    local name, texturePath, quantity, itemID
    for i = 1, numRewards do
        name, texturePath, quantity, itemID = GetLFGDungeonRewardInfo(dungeonId, i)
        if itemID then
            tinsert(rewards, { itemID, quantity })
        end
    end

    return doneToday, moneyBase, moneyVar, experienceBase, experienceVar, #rewards, rewards
end
