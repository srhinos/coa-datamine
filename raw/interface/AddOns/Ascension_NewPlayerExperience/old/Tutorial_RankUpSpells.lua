local T = {
    name = "RankUpSpells",
    cvar = "npeRankUpSpellsTutorial",
    classless = true,
    priority = 100,
    maxLevel = 20,

    events = {
        "SPELL_RANK_AVAILABLE"
    },

    sequences = {
        ["SPELL_RANK_AVAILABLE"] = {
            "GENERIC_RANK_UP_SPELLS1",
            "GENERIC_RANK_UP_SPELLS2",
            "GENERIC_RANK_UP_SPELLS3",
            "GENERIC_RANK_UP_SPELLS4",
            "GENERIC_RANK_UP_SPELLS5",
            "GENERIC_RANK_UP_SPELLS6",
        }
    }
}

NPE:RegisterTutorial(T)

NPEPopups["GENERIC_RANK_UP_SPELLS1"] = {
    cvar = T.cvar,
    cvarBit = 1,
    textSize = 18,
    offsetX = 400,
    offsetY = 0,
    onShow = function()
        C_Quest:AddAutoQuestPopUp(Enum.Quests.PTAscension.RankUpYourSpells)
    end,
}

NPEPopups["GENERIC_RANK_UP_SPELLS2"] = {
    cvar = T.cvar,
    cvarBit = 2,
    textSize = 18,
    offsetX = -200,
    offsetY = -50,
    point = "RIGHT",
    creature = 75118,
    buff = "Spotlight",
}

NPEPopups["GENERIC_RANK_UP_SPELLS3"] = {
    cvar = T.cvar,
    cvarBit = 3,
    textSize = 18,
    offsetX = 400,
    offsetY = 100,
    creature = 75118,
    buff = "Spotlight",
}

NPEPopups["GENERIC_RANK_UP_SPELLS4"] = {
    cvar = T.cvar,
    cvarBit = 4,
    textSize = 18,
    offsetX = -200,
    offsetY = 0,
    point = "RIGHT",
    creature = 75118,
    buff = "Spotlight",
    -- minLevel = 6,
    -- questAccept = 1903520,
}

NPEPopups["GENERIC_RANK_UP_SPELLS5"] = {
    cvar = T.cvar,
    cvarBit = 5,
    textSize = 18,
    offsetX = -150,
    offsetY = -100,
    point = "RIGHT",
    creature = 75118,
    buff = "Spotlight",
}

NPEPopups["GENERIC_RANK_UP_SPELLS6"] = {
    cvar = T.cvar,
    cvarBit = 6,
    textSize = 18,
    offsetX = 400,
    offsetY = 100,
}
