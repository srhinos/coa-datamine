local _, NPE = ...

local HelpTipQuestDestination = {
    parent = nil,
    text = NPE_CLICK_TO_TRACK or "|cffFFFF00Click|r to track the destination of this Quest",
    targetPoint = HelpTip.Point.LeftEdgeCenter,
    animatePointer = true,
    offsetX = -8,
    highlightTarget = HelpTip.TargetType.Circle,
}

--[[local HelpTipQuestPoi = {
    parent = nil,
    text = "|cffffd100Go Here|r to do Quest Objectives.|n|cffffd100Press (M)|r to close the |cffffd100World Map|r",
    targetPoint = HelpTip.Point.RightEdgeCenter,
    animatePointer = true,
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    onHideCallback = function() NPE:CompleteTutorial(NPE.Const.Tutorials.WORLD_MAP_TUTORIAL) end,
}]]--

local worldMapHelpTipTutorialSystem = "worldMapHelpTipTutorialSystem"

--
-- WorldMap Quest Tutorial
--
do
    local tutorialWorldMap = NPE:NewQuestTutorial(NPE.Const.Tutorials.WORLD_MAP_TUTORIAL, NPE.Const.WorldMapTutorialQuests)
    tutorialWorldMap:SetMinMaxLevel(1, 10)
    tutorialWorldMap:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

    tutorialWorldMap:RegisterCallback("TutorialStarted", function()
        dprint(tutorialWorldMap:GetName().." started!")
    end)

    tutorialWorldMap:RegisterCallback("TutorialCompleted", function()
        dprint(tutorialWorldMap:GetName().." Complete!")
    end)

    tutorialWorldMap:RegisterCallback("TutorialFinished", function()
        dprint(tutorialWorldMap:GetName().." Finished!")
        NPE:ClearAllHelpTipsForSystem(worldMapHelpTipTutorialSystem)
    end)

    tutorialWorldMap:RegisterCallback("QuestAbandoned", function()
        dprint(tutorialWorldMap:GetName().." Quest Abandoned!")
    end)

    -- step 1: wait for line poi to exist
    local step1 = tutorialWorldMap:AddStep()
    step1:SetShouldSaveProgress(false)
    step1:SetCompletionCondition(function()
        return tutorialWorldMap:GetWatchFrameLinePOI() ~= nil
    end)

    -- step 2: Open Map
    local step2 = tutorialWorldMap:AddStep()
    step2:SetShouldSaveProgress(false)

    HelpTipQuestDestination.parent = GenerateClosure(tutorialWorldMap.GetWatchFrameLinePOI, tutorialWorldMap)

    step2:AddHelpTip(HelpTipQuestDestination, worldMapHelpTipTutorialSystem)

    step2:SetCompletionEvent("SUPER_TRACKING_CHANGED")

    --[[step2:SetCompletionCondition(function()
        return WorldMapFrame:IsShown() and (tutorialWorldMap:GetWorldMapPOI() ~= nil)
    end)]]--

    --[[ step 3: Close map
    local step3 = tutorialWorldMap:AddStep()
    step3:SetShouldSaveProgress(false)

    HelpTipQuestPoi.parent = GenerateClosure(tutorialWorldMap.GetWorldMapPOI, tutorialWorldMap)
    step3:AddHelpTip(HelpTipQuestPoi, worldMapHelpTipTutorialSystem)

    step3:SetCompletionCondition(function()
        return not WorldMapFrame:IsShown()
    end)]]--

    NPE:AddTutorial(tutorialWorldMap)
end