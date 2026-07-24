local _, NPE = ...

local function IsUnitContainGreyedExclamationMark()
    local questStatus = C_QuestLog.GetUnitQuestInfo("target")

    if questStatus and (questStatus == "unavailable") then
        return true
    end

    return false
end

local function IsUnitContainGreyedQuestionMark()
    local questStatus = C_QuestLog.GetUnitQuestInfo("target")

    if questStatus and (questStatus == "incomplete") then
        return true
    end

    return false
end

local PopupQuestMark = {
    iconAtlas = "NPE_ExclamationPoint",
    iconDesaturated = true,
    okButton = true,
    priority = NPE.Const.PopupPriority.HIGH,
}

--
-- exclamation mark tut
--
local exclamationMarkTutorial = NPE:NewEventTutorial(NPE.Const.Tutorials.GREYED_EXCLAMATION_TUTORIAL, "GOSSIP_SHOW", IsUnitContainGreyedExclamationMark)
exclamationMarkTutorial:SetMinMaxLevel(1, 40)
exclamationMarkTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

exclamationMarkTutorial:RegisterCallback("TutorialCompleted", function() 
    dprint(exclamationMarkTutorial:GetName().." completed") 

    PopupQuestMark.iconAtlas = "callboard-exclamationMark"
    PopupQuestMark.iconWidth = 24
    PopupQuestMark.iconHeight = 66
    PopupQuestMark.text = NPE_DISABLED_QUEST_1 or "|cffFFFF00Grey exclamation mark|r means your |cffFFFF00level is too low|r for the quest. Come back to that unit later!"
    PopupQuestMark.fontSize = 14

    NPE:ShowDialogPopup(PopupQuestMark)
end)

NPE:AddTutorial(exclamationMarkTutorial)

--
-- question mark tut
--
local questionMarkTutorial = NPE:NewEventTutorial(NPE.Const.Tutorials.GREYED_QUESTION_TUTORIAL, "GOSSIP_SHOW", IsUnitContainGreyedQuestionMark)
questionMarkTutorial:SetMinMaxLevel(1, 40)
questionMarkTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

questionMarkTutorial:RegisterCallback("TutorialCompleted", function() 
    dprint(questionMarkTutorial:GetName().." completed") 

    PopupQuestMark.iconAtlas = "callboard-questmark"
    PopupQuestMark.iconWidth = 39
    PopupQuestMark.iconHeight = 66
    PopupQuestMark.text = NPE_DISABLED_QUEST_2 or "|cffFFFF00Grey question mark|r means you have not yet achieved quest goals. Come back to that unit when you |cffFFFF00complete quest objectives|r!"
    PopupQuestMark.fontSize = 12

    NPE:ShowDialogPopup(PopupQuestMark)
end)

NPE:AddTutorial(questionMarkTutorial)