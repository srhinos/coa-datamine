local T = {
    name = "Professions",
    cvar = "npeprofessionsTutorial",
    classless = true,

    quests = {
        1903542
    },

    sequences = {
        ["QUEST_ACCEPTED"] = {
            "PROFESSIONS1",
            "PROFESSIONS2",
            "PROFESSIONS3",
        }
    }
}

NPE:RegisterTutorial(T)

NPEPopups["PROFESSIONS1"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -50,
    offsetY = 50,
    creature = 57524,
    buff = "Spotlight",
    point = "RIGHT",
    relativeTo="WatchFrame",
    relativePoint="LEFT",
    event = "GOSSIP_SHOW",
}

NPEPopups["PROFESSIONS2"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -50,
    offsetY = 0,
    creature = 57524,
    buff = "Spotlight",
    point = "RIGHT",
    relativeTo="WatchFrame",
    relativePoint="LEFT",
    questFinish = 1903542
}

NPEPopups["PROFESSIONS3"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -25,
    offsetY = 50,
    creature = 75118,
    buff = "Spotlight",
    point = "RIGHT",
    relativeTo="WatchFrame",
    relativePoint="LEFT",
    questTurnIn = 1903542
}