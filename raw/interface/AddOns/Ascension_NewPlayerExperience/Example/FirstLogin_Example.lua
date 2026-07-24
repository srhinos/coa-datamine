local _, NPE = ...

local FirstQuestIDs = { 783, 4641 }

-- use /measure to get the distance between two points
-- use /run local x,y,_,m = GetCurrentPlayerPosition() Internal_CopyToClipboard(format("%.4f, %.4f, %s", x, y, m))
-- [questID] = { x, y, map, radius }
local FirstQuestIDAreas = {
    [783] = {-8949.1113, -128.6298, 0, 400 },
    [4641] = { -609.6086, -4253.5493, 1, 560 },
}
local FirstQuestNPC = {
    [783] = 823,
    [4641] = 10176,
}
local FirstQuestNPCName = {
    [783] = "Deputy Willem",
    [4641] = "Kaltunk",
}
local FirstQuestTurnIn = {
    [783] = 197,
    [4641] = 3143,
}
local FirstQuestTurnInName = {
    [783] = "Marshal McBride",
    [4641] = "Gornek",
}

local TURN_IN_FIRST_QUEST = "TurnInFirstQuest"

-- objectives
-- Inside Area (Northshire Area Tutorial)
-- Create initial quest tutorial
    --> Talk to Deputy Willem
    --> Accepts Quest starting TURN_IN_FIRST_QUEST tutorial
    --> Start step to open map
    --> click to open map
    --> map opens show tip 
    --> directs you to turn in quest npc

-- area setup
local TalkToNPCDialog = {
    key = "TalkToNPC",
    input = "RightButton",
}

local TutorialStarted = function(questID)
    TalkToNPCDialog.text = "|cffffd100Talk|r to " .. FirstQuestNPCName[questID]
    TalkToNPCDialog.unit = FirstQuestNPC[questID]
    NPE:ShowDialogPopup(TalkToNPCDialog)
end

local TutorialStopped = function()
    NPE:CompleteTutorial(TURN_IN_FIRST_QUEST)
    NPE:ClearDialogPopup("TalkToNPC")
end

local tutorialComplete = function()
    NPE:CompleteTutorial(TURN_IN_FIRST_QUEST)
    NPE:ClearDialogPopup("TalkToNPC")
end

for questID, area in pairs(FirstQuestIDAreas) do
    local areaTutorial = NPE:NewAreaTutorial("NorthshireTutorial", unpack(area))
    areaTutorial:SetMinMaxLevel(1, 10)
    areaTutorial:RegisterCallback("TutorialStarted", GenerateClosure(TutorialStarted, questID))
    areaTutorial:RegisterCallback("TutorialCompleted", tutorialComplete)
    areaTutorial:RegisterCallback("TutorialStopped", TutorialStopped)
    NPE:AddTutorial(areaTutorial)
end

--
-- Turn in quest tutorial, handles all first quests
--
local tutorial = NPE:NewQuestTutorial(TURN_IN_FIRST_QUEST, FirstQuestIDs)
tutorial:SetMinMaxLevel(1, 10)
tutorial:RegisterCallback("TutorialStarted", function()
    NPE:ClearDialogPopup("TalkToNPC")
end)

tutorial:RegisterCallback("TutorialComplete", function()
    NPE:ClearDialogPopup("TalkToNPC")
end)

tutorial:RegisterCallback("TutorialFinished", function()
    NPE:ClearAllHelpTipsForSystem("FirstQuest")
end)

tutorial:RegisterCallback("QuestAbandoned", function()
    NPE:ShowDialogPopup(TalkToNPCDialog)
end)

-- step 1: wait for line poi to exist
local step = tutorial:AddStep()
step:SetCompletionCondition(function()
    return tutorial:GetWatchFrameLinePOI() ~= nil
end)

-- step 2: Open Map
step = tutorial:AddStep()
step:SetShouldSaveProgress(false) -- this step will probably error on login restore
local openMapTipInfo = {
    text = "|cffffd100Click|r to find where to go for your quest",
    targetPoint = HelpTip.Point.LeftEdgeCenter,
    parent = GenerateClosure(tutorial.GetWatchFrameLinePOI, tutorial),
    highlightTarget = HelpTip.TargetType.Circle,
}
step:AddHelpTip(openMapTipInfo, "FirstQuest")

-- backup incase they click wrong
local openMapTipInfo2 = {
    text = "|cffffd100Click|r to open the |cffffd100World Map|r or press |cffffd100(M)|r on the keyboard.",
    targetPoint = HelpTip.Point.RightEdgeCenter,
    parent = QuestLogFrameShowMapButton,
    highlightTarget = HelpTip.TargetType.Box,
}
step:AddHelpTip(openMapTipInfo2, "FirstQuest")

step:SetCompletionCondition(function()
    return WorldMapFrame:IsShown() and tutorial:GetWorldMapPOI() ~= nil
end)

-- step 3: Close map
step = tutorial:AddStep()
step:SetShouldSaveProgress(false) -- this step will just instantly complete if we restore here
local closeMapTipInfo = {
    text = "|cffffd100Go Here|r to complete your quest.|n|cffffd100Press (M)|r to close the |cffffd100World Map|r",
    targetPoint = HelpTip.Point.BottomEdgeCenter,
    textJustifyH = "CENTER",
    parent = GenerateClosure(tutorial.GetWorldMapPOI, tutorial),
    highlightTarget = HelpTip.TargetType.Circle,
}
step:AddHelpTip(closeMapTipInfo, "FirstQuest")

step:SetCompletionCondition(function()
    return not WorldMapFrame:IsShown()
end)

-- step 3: wait for turn in
step = tutorial:AddStep()

step:RegisterCallback("StepStarted", function()
    local TurnInPopup = {
        key = "TalkToNPC",
        text = "|cffffd100Talk|r to " .. FirstQuestTurnInName[tutorial:GetQuestID()],
        input = "RightButton",
        unit = FirstQuestTurnIn[tutorial:GetQuestID()],
    }

    NPE:ShowDialogPopup(TurnInPopup)

    local selectQuestInfo = {
        text = "|cffffd100Click|r your completed quest.",
        targetPoint = HelpTip.Point.BottomEdgeCenter,
        parent = GossipTitleButton1,
        highlightTarget = HelpTip.TargetType.Box,
    }
    step.selectQuest = NPE:CreateHelpTip(selectQuestInfo, "FirstQuest")

    local completeQuestInfo = {
        text = "|cffffd100Click|r to complete your quest.",
        targetPoint = HelpTip.Point.TopEdgeCenter,
        alignment = HelpTip.Alignment.Left,
        parent = QuestFrameCompleteQuestButton,
        highlightTarget = HelpTip.TargetType.Box,
    }
    step:AddHelpTip(completeQuestInfo, "FirstQuest")

    EventRegistry:RegisterFrameEventAndCallbackWithHandle("GOSSIP_SHOW", function()
        if GetCreatureIDFromGUID(UnitGUID("npc")) == FirstQuestTurnIn[tutorial:GetQuestID()] then
            step.selectQuest:Show()
        else
            step.selectQuest:Hide()
        end
    end)
end)
step:RegisterCallback("StepFinished", function()
    step.selectQuest:Hide()
end)

NPE:AddTutorial(tutorial)


