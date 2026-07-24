local HORDE_CALLBOARD_QUEST = 1903543
local ALLIANCE_CALLBOARD_QUEST = 1903545
local T = {
    name = "CallBoards",
    cvar = "npeCallBoardsTutorial",
    classless = true,
    priority = 100,

    quests = {
        HORDE_CALLBOARD_QUEST,
        ALLIANCE_CALLBOARD_QUEST,
    },

    sequences = {
        ["QUEST_ACCEPTED"] = {
            "CALL_BOARDS1",
            "CALL_BOARDS2"
        }
    }
}

NPE:RegisterTutorial(T)

NPEPopups["CALL_BOARDS1"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -100,
    offsetY = 0,
    creature = C_Player:GetFaction() == "Horde" and 80190 or 80189,
    buff = "Spotlight",
    point = "RIGHT",
    event = "GOSSIP_SHOW",
}

NPEPopups["CALL_BOARDS2"] = {
    cvar = T.cvar,
    params = { (C_Player:GetFaction() == "Horde" and HORDE_CALLBOARD_QUEST or ALLIANCE_CALLBOARD_QUEST) },
    cvarBit = T:NextBit(),
    offsetX = -200,
    offsetY = -50,
    creature = C_Player:GetFaction() == "Horde" and 80190 or 80189,
    buff = "Spotlight",
    point = "RIGHT",
    questTurnIn = { HORDE_CALLBOARD_QUEST, ALLIANCE_CALLBOARD_QUEST }
}