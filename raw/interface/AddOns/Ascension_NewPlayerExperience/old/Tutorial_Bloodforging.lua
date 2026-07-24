local T = {
    name = "Bloodforging",
    cvar = "npeBloodforgeTutorial",
    classless = true,

    quests = {
        580163
    },

    sequences = {
        ["QUEST_ACCEPTED"] = {
            "BLOODFORGE1",
            "BLOODFORGE2",
            "BLOODFORGE3",
            "BLOODFORGE4",
        }
    }
}

NPE:RegisterTutorial(T)

NPEPopups["BLOODFORGE1"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -200,
    offsetY = 50,
    point = "RIGHT",
}

NPEPopups["BLOODFORGE2"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -250,
    offsetY = 0,
    creature = 9780012,
    buff = "Spotlight",
    point = "RIGHT",
    event = "ITEM_PUSH", -- lazy but the odds of someone buying something other than a blood jar here is low
}

NPEPopups["BLOODFORGE3"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = 0,
    offsetY = 250,
    minWidth = 512,
    point = "BOTTOM",
    questFinish = 580163,
}

NPEPopups["BLOODFORGE4"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -200,
    offsetY = 0,
    point = "RIGHT",
    questTurnIn = 580163,
}
