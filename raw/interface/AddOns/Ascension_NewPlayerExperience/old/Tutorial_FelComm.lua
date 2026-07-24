local T = {
    name = "FelCommutation",
    cvar = "npeFelCommTutorial",
    classless = true,

    quests = {
        1903514
    },

    sequences = {
        ["QUEST_ACCEPTED"] = {
            "FEL_COMM1",
            "FEL_COMM2",
            "FEL_COMM3",
            "FEL_COMM4",
        }
    }
}

NPE:RegisterTutorial(T)

NPEPopups["FEL_COMM1"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = 0,
    offsetY = 250,
    minWidth = 512,
    point = "BOTTOM",
}

NPEPopups["FEL_COMM2"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -100,
    offsetY = 50,
    point = "RIGHT",
    image1 = {
        atlas = "npe-ui-felcomm-portal",
    },
    event = "ASCENSION_FEL_COMMUTATION_WINDOW_VISIBILITY_CHANGED",
}

NPEPopups["FEL_COMM3"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -200,
    offsetY = 50,
    point = "RIGHT",
    image1 = {
        atlas = "npe-ui-felcomm-ui",
    },
    event = "ASCENSION_FEL_COMMUTATION_CHANGED",
}

NPEPopups["FEL_COMM4"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -150,
    offsetY = 0,
    point = "RIGHT",
}

