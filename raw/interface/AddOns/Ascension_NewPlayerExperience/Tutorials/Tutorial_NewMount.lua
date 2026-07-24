local _, NPE = ...

-------
-- How to call mount tutorial
-------
local useMountTutorial = NPE:NewItemTutorial(NPE.Const.Tutorials.USE_MOUNT_TUTORIAL)
useMountTutorial:SetMinMaxLevel(1, 80)
useMountTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

useMountTutorial:RegisterCallback("TutorialStarted", function()
    NPE:CompleteTutorial(NPE.Const.Tutorials.LOOT_WINDOW_TUTORIAL) -- both tutorials teach to open bags
    NPE:CompleteTutorial(NPE.Const.Tutorials.EQUIP_ITEMS_TUTORIAL)

    dprint(useMountTutorial:GetName().." TutorialStarted!")
end)

useMountTutorial:RegisterCallback("TutorialCompleted", function()
    dprint(useMountTutorial:GetName().." TutorialCompleted!")

    if not NPE:IsTutorialComplete(NPE.Const.Tutorials.MOUNT_CHARACTER_PANEL_TUTORIAL) and not NPE:IsTutorialActive(NPE.Const.Tutorials.MOUNT_CHARACTER_PANEL_TUTORIAL) then
        NPE:StartTutorial(NPE.Const.Tutorials.MOUNT_CHARACTER_PANEL_TUTORIAL)
    end
end)

function useMountTutorial:ValidateItems(...)
    dprint(self:GetName()..":ValidateItems")
    local bag, slot, id, count = ...

    if id then
        local itemType = select(7, GetItemInfo(id))

        if itemType and (itemType == MOUNT) then
            return self:GetItemAvailableForUse(bag, slot), bag, slot
        end
    end

    return false
end

-- step 1: Show bag help tip
local step1 = useMountTutorial:AddStep()
step1:SetShouldSaveProgress(false)

step1:RegisterCallback("StepStarted", function()
    local helpTipInfo = {
        parent = function() return _G[useMountTutorial:GetBagParent()] end,
        text = NPE_NEW_MOUNT_FIRST_MOUNT or "You obtained your first Mount! Click here or press |cffFFFF00(B)|r to open your |cffFFFF00bags|r",
        targetPoint = HelpTip.Point.TopEdgeCenter,
        animatePointer = true,
        highlightTarget = HelpTip.TargetType.Box,
    }

    if useMountTutorial:GetBagParent() then
        step1:AddHelpTip(helpTipInfo, NPE.Const.Tutorials.USE_MOUNT_TUTORIAL)
    else
        dprint(" no get bag parentt")
        NPE:CompleteTutorial(NPE.Const.Tutorials.USE_MOUNT_TUTORIAL) -- safe exit if we reloaded UI before the tutorial is complete
    end
end)

step1:SetCompletionCondition(function()
    local bag = useMountTutorial:GetValidItemPosition()

    if IsAddOnLoaded("AdiBags") then
        return bag and NewItemTutorialMixin:IsAnyBagOpen()
    else
        return bag and IsBagOpen(bag)
    end
end)

-- step 2:Highlight proper item and ask to click it. Make tutorial complete even if you just close the bags
local step2 = useMountTutorial:AddStep()
step2:SetShouldSaveProgress(false)

step2:AddHelpTip({
    parent = function() return _G[useMountTutorial:DefineContainerItemByItemPos()] end,
    text = NPE_NEW_MOUNT_ADD_TO_COLLECTION or "|cffFFFF00Right Click|r mount to add it to your |cffFFFF00Collection|r",
    targetPoint = HelpTip.Point.LeftEdgeCenter,
    animatePointer = true,
    highlightTarget = HelpTip.TargetType.Box,
}, NPE.Const.Tutorials.USE_MOUNT_TUTORIAL)

step2:SetCompletionEvent("COMPANION_LEARNED")

NPE:AddTutorial(useMountTutorial)

-------
-- Character Panel Tutorial
-------
local characterPanelMountTutorial = NPE:NewTutorial(NPE.Const.Tutorials.MOUNT_CHARACTER_PANEL_TUTORIAL)
characterPanelMountTutorial:SetMinMaxLevel(1, 80)
characterPanelMountTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

characterPanelMountTutorial:RegisterCallback("TutorialCompleted", function()
    dprint(characterPanelMountTutorial:GetName().." TutorialCompleted!")
end)

characterPanelMountTutorial:RegisterCallback("TutorialStarted", function()
    dprint(characterPanelMountTutorial:GetName().." TutorialStarted!")
end)

-- step1: wait for character panel to open
local step1 = characterPanelMountTutorial:AddStep()

step1:AddHelpTip({
    text = NPE_NEW_MOUNT_CHARACTER_INFO or "You obtained a new mount! Check |cffFFFF00Character Info|r |cffFFFF00(C)|r",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    parent = CharacterMicroButton,
    highlightTarget = HelpTip.TargetType.Box,
    animatePointer = true,
    system            = "micromenu",
    systemPriority    = 100,
}, NPE.Const.Tutorials.MOUNT_CHARACTER_PANEL_TUTORIAL)

step1:SetShouldSaveProgress(false)
step1:SetCompletionCondition(function()
    return AscensionCharacterFrame and AscensionCharacterFrame:IsVisible()
end)

-- go to pets
local step2 = characterPanelMountTutorial:AddStep()

step2:AddHelpTip({
    text = NPE_NEW_MOUNT_GO_TO_PETS or "Go to |cffFFFF00Pets|r tab",
    targetPoint = HelpTip.Point.BottomEdgeCenter,
    parent = function() return AscensionCharacterFrame:GetTabByID(AscensionCharacterFrame.Tabs.Pets) end,
    highlightTarget = HelpTip.TargetType.Box,
    animatePointer = true,
}, NPE.Const.Tutorials.MOUNT_CHARACTER_PANEL_TUTORIAL)

step2:SetShouldSaveProgress(false)
step2:SetCompletionCondition(function()
    return AscensionPetPaperDollPanel and AscensionPetPaperDollPanel:IsVisible()
end)

-- go to mounts
local step3 = characterPanelMountTutorial:AddStep()

step3:AddHelpTip({
    text = NPE_NEW_MOUNT_GO_TO_MOUNTS or "Go to |cffFFFF00Mounts|r tab",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    parent = function() return AscensionPetPaperDollPanel:GetTabByID(3) end,
    highlightTarget = HelpTip.TargetType.Box,
    animatePointer = true,
}, NPE.Const.Tutorials.MOUNT_CHARACTER_PANEL_TUTORIAL)

step3:SetShouldSaveProgress(false)
step3:SetCompletionCondition(function()
    return AscensionPetPaperDollPanel and (AscensionPetPaperDollPanel:GetCurrentTabID() == 3)
end)

-- click summon button
local step4 = characterPanelMountTutorial:AddStep()

step4:AddHelpTip({
    text = NPE_NEW_MOUNT_SUMMON_MOUNT or "Summon your mount",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    parent = function() return AscensionPetPaperDollPanelCompanionTabCompanionModelOverlaySummonButton end,
    highlightTarget = HelpTip.TargetType.Box,
    animatePointer = true,
}, NPE.Const.Tutorials.MOUNT_CHARACTER_PANEL_TUTORIAL)

step4:SetShouldSaveProgress(false)
step4:SetCompletionEvent("COMPANION_UPDATE", "MOUNT")

-- teach how to drag
local step5 = characterPanelMountTutorial:AddStep()

step5:AddHelpTip({
    text = NPE_NEW_MOUNT_DRAG_MOUNT or "|cffFFFF00Hold left click|r to |cffFFFF00drag|r Mount to your Action Bars",
    targetPoint = HelpTip.Point.RightEdgeCenter,
    parent = function() return _G["AscensionCharacterCompanionPanelScrollFrameScrollUpButton"] end,
    --highlightTarget = HelpTip.TargetType.Box,
    animatePointer = true,
    offsetX = -16,
    offsetY = -4,
}, NPE.Const.Tutorials.MOUNT_CHARACTER_PANEL_TUTORIAL)

step5:SetShouldSaveProgress(false)
step5:SetCompletionCondition(function()
    local _, _, isMount = GetCursorInfo()

    if isMount and (isMount == "MOUNT") then
        return true
    end
end)

NPE:AddTutorial(characterPanelMountTutorial)