local _, NPE = ...

local changedSlotVariable = nil

local HelpTipCharacterPanelMicroButton = {
    text = NPE_CHAR_PANEL_ITEMS_CHANGED or "Your items had been changed! Check |cffFFFF00Character Info|r |cffFFFF00(C)|r",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    parent = CharacterMicroButton,
    highlightTarget = HelpTip.TargetType.Box,
    system            = "micromenu",
    systemPriority    = 71,
    animatePointer = true,
}

local HelpTipEquippedSlot = {
    text =  NPE_CHAR_PANEL_ITEM_EQUIPPED or "Your item has been equipped!",
    targetPoint = HelpTip.Point.RightEdgeCenter,
    parent = function() return _G[changedSlotVariable] end, -- set up properly
    highlightTarget = HelpTip.TargetType.Box,
    animatePointer = true,
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    onHideCallback = function() NPE:CompleteTutorial(NPE.Const.Tutorials.CHARACTER_PANEL_TUTORIAL) end,
}

local CharacterPanelOnEquipmentChange = function(self, ...)
    local slot, hasCurrent = ...
    if (NPE.Const.CharacterPanelSlots[slot] and hasCurrent) then
        changedSlotVariable = "Ascension"..NPE.Const.CharacterPanelSlots[slot]
    end
end

-------
-- Character Panel Tutorial
-------
do
    local characterPanelTutorial = NPE:NewTutorial(NPE.Const.Tutorials.CHARACTER_PANEL_TUTORIAL)
    characterPanelTutorial:SetAutoStart(true)
    characterPanelTutorial:SetMinMaxLevel(2, 5)
    characterPanelTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

    characterPanelTutorial:RegisterCallback("TutorialCompleted", function()
        dprint(characterPanelTutorial:GetName().." completed!")
    end)

    characterPanelTutorial:RegisterCallback("TutorialStarted", function()
        dprint(characterPanelTutorial:GetName().." Sterted!")

        if not characterPanelTutorial.eventHandle then
            characterPanelTutorial.eventHandle = characterPanelTutorial:RegisterEventCallbackWithHandle("PLAYER_EQUIPMENT_CHANGED", CharacterPanelOnEquipmentChange, characterPanelTutorial)
        end
    end)

    -- step1: wait for equipment to change
    local step1 = characterPanelTutorial:AddStep()
    step1:SetShouldSaveProgress(false)

    step1:SetCompletionCondition(function()
        return changedSlotVariable
    end)

    step1:RegisterCallback("StepFinished", function()
        if characterPanelTutorial.eventHandle then
            characterPanelTutorial.eventHandle:Unregister()
            characterPanelTutorial.eventHandle = nil
        end
    end)

    -- step2: ask to open character panel
    local step2 = characterPanelTutorial:AddStep()
    step2:SetShouldSaveProgress(false)

    step2:SetCompletionCondition(function()
       return changedSlotVariable and AscensionCharacterFrame and AscensionCharacterFrame:IsVisible()
    end)

    step2:AddHelpTip(HelpTipCharacterPanelMicroButton)

    -- step3: show what changed
    local step3 = characterPanelTutorial:AddStep()

    step3:SetCompletionCondition(function()
       return AscensionCharacterFrame and not(AscensionCharacterFrame:IsVisible())
    end)

    step3:AddHelpTip(HelpTipEquippedSlot)

    NPE:AddTutorial(characterPanelTutorial)
end