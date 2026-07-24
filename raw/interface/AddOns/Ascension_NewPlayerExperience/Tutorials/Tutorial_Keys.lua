local _, NPE = ...

local function HasKeyCheck()
    return KeyRingButton and KeyRingButton:IsVisible() and HasKey()
end

-------
-- Keyring tutorial
-------

local keyTutorial = NPE:NewEventTutorial(NPE.Const.Tutorials.KEYS_TUTORIAL, "BAG_UPDATE", HasKeyCheck)
keyTutorial:SetMinMaxLevel(1, 80)
keyTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

keyTutorial:RegisterCallback("TutorialStarted", function()
    dprint(keyTutorial:GetName().." TutorialStarted!")
end)

keyTutorial:RegisterCallback("TutorialCompleted", function()
    dprint(keyTutorial:GetName().." TutorialCompleted!")
end)

-- step 1: Show bag help tip
local step1 = keyTutorial:AddStep()
step1:SetShouldSaveProgress(false)

step1:RegisterCallback("StepStarted", function()
    local helpTipInfo = {
        parent = function() return _G["KeyRingButton"] end,
        text = NPE_TUTORIAL_KEY or "You got a key! Click here to show your |cffFFFF00keyring|r",
        targetPoint = HelpTip.Point.TopEdgeCenter,
        animatePointer = true,
        highlightTarget = HelpTip.TargetType.Box,
        onAcknowledgeCallback = function() NPE:CompleteTutorial(NPE.Const.Tutorials.KEYS_TUTORIAL) end,
        buttonStyle = HelpTip.ButtonStyle.Close,
    }

    if _G["KeyRingButton"] then
        step1:AddHelpTip(helpTipInfo, NPE.Const.Tutorials.KEYS_TUTORIAL)
    else
        NPE:CompleteTutorial(NPE.Const.Tutorials.KEYS_TUTORIAL) -- safe exit if we reloaded UI before the tutorial is complete
    end
end)

step1:SetCompletionCondition(function()
    return IsBagOpen(KEYRING_CONTAINER)
end)

NPE:AddTutorial(keyTutorial)
