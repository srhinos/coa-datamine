ProfessionUtil = {}

local PROFESSION_INFO = {}

local ProfessionSkillRanks = {
    75,
    150,
    225,
    300,
    375,
    450,
}
function ProfessionUtil.GetNearestMaxSkill(skillMaxRank)
    local nearestRank = 0
    for _, rank in ipairs(ProfessionSkillRanks) do
        if skillMaxRank < rank then
            return nearestRank
        end
        nearestRank = rank
    end
end

function ProfessionUtil.GetProfessionByID(skillID)
    local skillName, skillRank, skillModifier, skillMaxRank, isAbandonable, skillDescription = GetSkillInfo(skillID)
    local info = PROFESSION_INFO[skillID]
    local currentRankSpell = skillMaxRank and info.Ranks[ProfessionUtil.GetNearestMaxSkill(skillMaxRank)]
    local craftingSpell
    if not info.NoCraftingSpell then
        if info.CraftingSpell then
            craftingSpell = (IsSpellKnown(info.CraftingSpell)) and info.CraftingSpell
        elseif currentRankSpell then
            craftingSpell = currentRankSpell
        end
    end
    
    local rankText = currentRankSpell and select(2, GetSpellInfo(currentRankSpell))
    return skillName or info.Name, rankText, info.Icon, skillRank, skillModifier, skillMaxRank, craftingSpell, currentRankSpell, isAbandonable, skillDescription
end

function ProfessionUtil.GetSpecialization(skillID)
    local info = PROFESSION_INFO[skillID]
    if info.Specializations then
        for _, spellID in ipairs(info.Specializations) do
            if IsSpellKnown(spellID) then
                return spellID
            end
        end
    end
end

function ProfessionUtil.GetSpecializations(skillID)
    local info = PROFESSION_INFO[skillID]
    return info and info.Specializations
end

function ProfessionUtil.GetKnownUtilitySpells(skillID)
    local info = PROFESSION_INFO[skillID]
    local utilitySpells = {}
    if info.UtilitySpells then
        for _, utility in ipairs(info.UtilitySpells) do
            if type(utility) == "table" then
                for _, spellID in ipairs(utility) do
                    -- this table needs to be sorted highest rank -> lowest rank.
                    -- only add the first known spell if any
                    if IsSpellKnown(spellID) then
                        table.insert(utilitySpells, spellID)
                        break
                    end
                end
            else
                if IsSpellKnown(utility) then
                    table.insert(utilitySpells, utility)
                end
            end
        end
    end
    return utilitySpells
end

function ProfessionUtil.GetKnownPassives(skillID)
    local info = PROFESSION_INFO[skillID]
    local passives = {}
    if info.Passives then
        for _, passive in ipairs(info.Passives) do
            if type(passive) == "table" then
                for _, spellID in ipairs(passive) do
                    -- this table needs to be sorted highest rank -> lowest rank.
                    -- only add the first known spell if any
                    if IsSpellKnown(spellID) then
                        table.insert(passives, spellID)
                        break
                    end
                end
            else
                if IsSpellKnown(passive) then
                    table.insert(passives, passive)
                end
            end
        end
    end
    return passives
end

function ProfessionUtil.GetNumProfessions()
    local numProfessions = 0
    for _, skillID in pairs(PRIMARY_PROFESSIONS) do
        local _, _, _, skillMaxRank = GetSkillInfo(skillID)
        if skillMaxRank and skillMaxRank > 0 then
            numProfessions = numProfessions + 1
        end
    end
    return numProfessions
end

function ProfessionUtil.GetProfessionType(skillID)
    for _, secondarySkillID in ipairs(SECONDARY_PROFESSIONS) do
        if skillID == secondarySkillID then
            return "secondary"
        end
    end
    
    return "primary"
end



-- 
-- Icon <string>
-- Name <string>
-- Ranks <table [maxRank]=spellID>
-- Specializations <table spellIDs or nil>
-- UtilitySpells <table spellIDs or nil>
-- -- can include tables of spellIDs for ranks, only the first known spell will be returned by functions
-- Passives <table spellIDs or nil>
-- -- can include tables of spellIDs for ranks, only the first known spell will be returned by functions
-- NoCraftingSpell <true or nil>
-- CraftingSpell <spellID or nil>
--
PROFESSION_INFO[Enum.Profession.Blacksmithing] = {
    Icon = "Interface\\Icons\\Trade_Blacksmithing",
    Name = GetSpellInfo(2018),
    Ranks = {
        [75] = 2018,
        [150] = 3100,
        [225] = 3538,
        [300] = 9785,
        [375] = 29844,
        [450] = 51300,
    },
    Specializations = {
        9788, -- Armorsmith
        17039, -- Master Swordsmith
        17040, -- Master Hammersmith
        17041, -- Master Axesmith
        9787, -- Weaponsmith
    }
}

PROFESSION_INFO[Enum.Profession.Alchemy] = {
    Icon = "Interface\\Icons\\Trade_Alchemy",
    Name = GetSpellInfo(2259),
    Ranks = {
        [75] = 2259,
        [150] = 3101,
        [225] = 3464,
        [300] = 11611,
        [375] = 28596,
        [450] = 51304,
    },
    Specializations = {
        28677, -- Elixir Master
        28675, -- Potion Master
        28672, -- Transmutation Master
    }
}
PROFESSION_INFO[Enum.Profession.Enchanting] = {
    Icon = "Interface\\Icons\\Trade_Engraving",
    Name = GetSpellInfo(7411),
    Ranks = {
        [75] = 7411,
        [150] = 7412,
        [225] = 7413,
        [300] = 13920,
        [375] = 28029,
        [450] = 51313,
    },
    UtilitySpells = {
        13262, -- Disenchanting
    }
}
PROFESSION_INFO[Enum.Profession.Engineering] = {
    Icon = "Interface\\Icons\\Trade_Engineering",
    Name = GetSpellInfo(4036),
    Ranks = {
        [75] = 4036,
        [150] = 4037,
        [225] = 4038,
        [300] = 12656,
        [375] = 30350,
        [450] = 51306,
    },
    Specializations = {
        20219, -- Gnomish Engineer
        20222, -- Goblin Engineer
    }
}
PROFESSION_INFO[Enum.Profession.Jewelcrafting] = {
    Icon = "Interface\\Icons\\INV_Misc_Gem_01",
    Name = GetSpellInfo(25229),
    Ranks = {
        [75] = 25229,
        [150] = 25230,
        [225] = 28894,
        [300] = 28895,
        [375] = 28897,
        [450] = 51311,
    },
    UtilitySpells = {
        31252, -- Prospecting
    },
    Passives = {
        55534, -- Gem Perfection
    }
}
PROFESSION_INFO[Enum.Profession.Inscription] = {
    Icon = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    Name = GetSpellInfo(45357),
    Ranks = {
        [75] = 45357,
        [150] = 45358,
        [225] = 45359,
        [300] = 45360,
        [375] = 45361,
        [450] = 45363,
    },
    UtilitySpells = {
        51005, -- Milling
        52175, -- Decipher
    }
}
PROFESSION_INFO[Enum.Profession.Leatherworking] = {
    Icon = "Interface\\Icons\\inv_misc_armorkit_17",
    Name = GetSpellInfo(2108),
    Ranks = {
        [75] = 2108,
        [150] = 3104,
        [225] = 3811,
        [300] = 10662,
        [375] = 32549,
        [450] = 51302,
    },
    Specializations = {
        10656, -- Dragonscale Leatherworking
        10658, -- Elemental Leatherworking
        10660, -- Tribal Leatherworking
    }
}
PROFESSION_INFO[Enum.Profession.Tailoring] = {
    Icon = "Interface\\Icons\\Trade_Tailoring",
    Name = GetSpellInfo(3908),
    Ranks = {
        [75] = 3908,
        [150] = 3909,
        [225] = 3910,
        [300] = 12180,
        [375] = 26790,
        [450] = 51309,
    },
    Specializations = {
        26798, -- Mooncloth Tailoring
        26801, -- Shadoweave Tailoring
        26797, -- Spellfire Tailoring
    },
    Passives = {
        59390, -- Cloth Scavenging
    }
}
PROFESSION_INFO[Enum.Profession.Herbalism] = {
    Icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow",
    Name = GetSpellInfo(2366),
    NoCraftingSpell = true,
    Ranks = {
        [75] = 2366,
        [150] = 2368,
        [225] = 3570,
        [300] = 11993,
        [375] = 28695,
        [450] = 50300,
    },
    UtilitySpells = {
        2383, -- Find Herbs
        { -- lifeblood
            55503, -- Lifeblood Rank 6
            55502, -- Lifeblood Rank 5
            55501, -- Lifeblood Rank 4
            55500, -- Lifeblood Rank 3
            55480, -- Lifeblood Rank 2
            55428, -- Lifeblood Rank 1
        },
    }
}
PROFESSION_INFO[Enum.Profession.Mining] = {
    Icon = "Interface\\Icons\\Trade_Mining",
    Name = GetSpellInfo(2575),
    CraftingSpell = 2656, -- Smelting
    Ranks = {
        [75] = 2575,
        [150] = 2576,
        [225] = 3564,
        [300] = 10248,
        [375] = 29354,
        [450] = 50310,
    },
    UtilitySpells = {
        2580, -- Find Minerals
    },
    Passives = {
        { -- Toughness
            53040, -- Toughness Rank 6
            53124, -- Toughness Rank 5
            53123, -- Toughness Rank 4
            53122, -- Toughness Rank 3
            53121, -- Toughness Rank 2
            53120, -- Toughness Rank 1
        }
    }
}
PROFESSION_INFO[Enum.Profession.Skinning] = {
    Icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    Name = GetSpellInfo(8613),
    NoCraftingSpell = true,
    Ranks = {
        [75] = 8613,
        [150] = 8617,
        [225] = 8618,
        [300] = 10768,
        [375] = 32678,
        [450] = 50305,
    },
    Passives = {
        { -- Master of Anatomy
            53666, -- Master of Anatomy Rank 6
            53665, -- Master of Anatomy Rank 5
            53664, -- Master of Anatomy Rank 4
            53663, -- Master of Anatomy Rank 3
            53662, -- Master of Anatomy Rank 2
            53125, -- Master of Anatomy Rank 1
        }
    }
}
PROFESSION_INFO[Enum.Profession.Cooking] = {
    Icon = "Interface\\Icons\\INV_Misc_Food_15",
    Name = GetSpellInfo(2550),
    Ranks = {
        [75] = 2550,
        [150] = 3102,
        [225] = 3413,
        [300] = 18260,
        [375] = 33359,
        [450] = 51296,
    },
    UtilitySpells = {
        818, -- Basic Campfire
    }
}
PROFESSION_INFO[Enum.Profession.FirstAid] = {
    Icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    Name = GetSpellInfo(3273),
    Ranks = {
        [75] = 3273,
        [150] = 3274,
        [225] = 7924,
        [300] = 10846,
        [375] = 27028,
        [450] = 45542,
    }
}
PROFESSION_INFO[Enum.Profession.Fishing] = {
    Icon = "Interface\\Icons\\Trade_Fishing",
    Name = GetSpellInfo(7620),
    NoCraftingSpell = true,
    Ranks = {
        [75] = 7620,
        [150] = 7731,
        [225] = 7732,
        [300] = 18248,
        [375] = 33095,
        [450] = 51294,
    },
}
PROFESSION_INFO[Enum.Profession.Bushcraft] = {
    Icon = select(3, GetSpellInfo(800267)),
    Name = GetSpellInfo(800267),
    Ranks = {
        [300] = 573523,
    },
    CraftingSpell = 800267,
}
PROFESSION_INFO[Enum.Profession.Woodcutting] = {
    Icon = "Interface\\Icons\\INV_TradeSkillItem_02",
    Name = GetSpellInfo(1366),
    Ranks = {
        [75] = 13977859,
        [150] = 13977882,
        [225] = 13977883,
        [300] = 13977884,
    },
    CraftingSpell = 13977860, -- Woodcutting
}
PROFESSION_INFO[Enum.Profession.Woodworking] = {
    Icon = "Interface\\Icons\\inv_archaeology_70_tauren_stonewoodbow",
    Name = GetSpellInfo(1005008),
    Ranks = {
        [75] = 1005008,
        [150] = 1005009,
        [225] = 1005010,
        [300] = 1005011,
    },
}