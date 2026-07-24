local _, NPE = ...

local TUTORIAL_NEXT_USABLE_BAG = nil

local function HasNoFreeSlots()

    if NPE:IsTutorialActive(NPE.Const.Tutorials.USE_MOUNT_TUTORIAL) then
        return false
    end

    local hasFreeBagSlot = false
    local hasBagInBags = false

    local freeSlots = 0
    for bag = 0, NUM_BAG_SLOTS do
        if GetContainerNumSlots(bag) == 0 then
            hasFreeBagSlot = true
        end

        for slot = 1, GetContainerNumSlots(bag) do
            local texture = GetContainerItemInfo(bag, slot)
            if not texture then
                freeSlots = freeSlots + 1
            else
                local link = select(7, GetContainerItemInfo(bag, slot))
                local equipSlot = select(9, GetItemInfo(link))

                if equipSlot and (equipSlot == "INVTYPE_BAG") then
                    hasBagInBags = {bag, slot}
                end
            end
        end
    end

    if freeSlots == 0 then

        if hasBagInBags and hasFreeBagSlot then -- ask user to equip new bag instead of basic tut
            if not NPE:IsTutorialComplete(NPE.Const.Tutorials.USE_BAGS_TUTORIAL) and not NPE:IsTutorialActive(NPE.Const.Tutorials.USE_BAGS_TUTORIAL) then
                TUTORIAL_NEXT_USABLE_BAG = {unpack(hasBagInBags)}
                NPE:StartTutorial(NPE.Const.Tutorials.USE_BAGS_TUTORIAL)
                return false
            elseif NPE:IsTutorialActive(NPE.Const.Tutorials.USE_BAGS_TUTORIAL) then
                return false
            end
        end

        return true
    end

    return false
end

local BagHelperFrame = CreateFrame("FRAME", "BagHelperFrame", MainMenuBar)
BagHelperFrame:Hide()
BagHelperFrame:SetPoint("TOPLEFT", CharacterBag3Slot, "TOPLEFT", 0, 0)
BagHelperFrame:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "BOTTOMRIGHT", 0, 0)
-------
-- No space in bags tutorial
-------
local fullBagsTutorial = NPE:NewEventTutorial(NPE.Const.Tutorials.FULL_BAGS_TUTORIAL, "BAG_UPDATE", HasNoFreeSlots)
fullBagsTutorial:SetMinMaxLevel(1, 20)
fullBagsTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

fullBagsTutorial:RegisterCallback("TutorialStarted", function()
    NPE:CompleteTutorial(NPE.Const.Tutorials.LOOT_WINDOW_TUTORIAL) -- both tutorials teach to open bags
    NPE:CompleteTutorial(NPE.Const.Tutorials.EQUIP_ITEMS_TUTORIAL)

    dprint(fullBagsTutorial:GetName().." TutorialStarted!")
end)

fullBagsTutorial:RegisterCallback("TutorialCompleted", function()
    dprint(fullBagsTutorial:GetName().." TutorialCompleted!")
end)

-- step 1: Show bag help tip
local step1 = fullBagsTutorial:AddStep()
step1:SetShouldSaveProgress(false)

step1:RegisterCallback("StepStarted", function()
    local helpTipInfo = {
        parent = function() return _G["MainMenuBarBackpackButton"] end,
        text = NPE_FULL_BAGS_PRESS_B or "Your bags are full! Click here or press |cffFFFF00(B)|r to open your |cffFFFF00bags|r",
        targetPoint = HelpTip.Point.TopEdgeCenter,
        animatePointer = true,
        highlightTarget = HelpTip.TargetType.Box,
    }

    if _G["MainMenuBarBackpackButton"] then
        step1:AddHelpTip(helpTipInfo, NPE.Const.Tutorials.FULL_BAGS_TUTORIAL)
    else
        NPE:CompleteTutorial(NPE.Const.Tutorials.FULL_BAGS_TUTORIAL) -- safe exit if we reloaded UI before the tutorial is complete
    end
end)

step1:SetCompletionCondition(function()
    return NewItemTutorialMixin:IsAnyBagOpen()
end)

-- step 2
local step2 = fullBagsTutorial:AddStep()
step2:SetShouldSaveProgress(false)

step2:AddHelpTip({
    parent = function() return NewItemTutorialMixin:GetOpenBag() end,
    text = NPE_FULL_BAGS_DELETE or "You can |cffFFFF00drag|r an item from your bags onto the ground to |cffFFFF00delete|r it. You can delete low sell price items to free up inventory space.",
    targetPoint = HelpTip.Point.LeftEdgeCenter,
    highlightTarget = HelpTip.TargetType.Box,
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    onHideCallback = function() step2.isComplete = true end,
}, NPE.Const.Tutorials.FULL_BAGS_TUTORIAL)

step2:SetCompletionCondition(function()
    return step2.isComplete or not NewItemTutorialMixin:IsAnyBagOpen()
end)

-- step 3. Minimap help
local step3 = fullBagsTutorial:AddStep()
step3:SetShouldSaveProgress(false)

step3:AddHelpTip({
    parent = function() return _G["MiniMapTrackingButton"] end,
    text = NPE_FULL_BAGS_VENDOR or "To find a vendor to sell old gear and jank items, look for |cffFFFF00Repair|r or |cffFFFF00Food & Drink|r vendor in Minimap tracking",
    targetPoint = HelpTip.Point.LeftEdgeCenter,
    animatePointer = true,
    highlightTarget = HelpTip.TargetType.Circle,
}, NPE.Const.Tutorials.FULL_BAGS_TUTORIAL)

step3:RegisterCallback("StepStarted", function()
    EventRegistry:RegisterFrameEventAndCallbackWithHandle("MiniMapTrackingDropDown_Initialize", function()
        NPE:CompleteTutorial(NPE.Const.Tutorials.FULL_BAGS_TUTORIAL)
    end)
end)

NPE:AddTutorial(fullBagsTutorial)

-------
-- Equip bag tutorial
-------
local equipBagTutorial = NPE:NewTutorial(NPE.Const.Tutorials.USE_BAGS_TUTORIAL)
equipBagTutorial:SetMinMaxLevel(1, 20)
equipBagTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

equipBagTutorial:RegisterCallback("TutorialStarted", function()
    NPE:CompleteTutorial(NPE.Const.Tutorials.LOOT_WINDOW_TUTORIAL) -- both tutorials teach to open bags
    NPE:CompleteTutorial(NPE.Const.Tutorials.EQUIP_ITEMS_TUTORIAL)

    dprint(equipBagTutorial:GetName().." TutorialStarted!")
end)

equipBagTutorial:RegisterCallback("TutorialCompleted", function()
    dprint(equipBagTutorial:GetName().." TutorialCompleted!")
    BagHelperFrame:Hide()
end)

-- step 1. Open proper bag tip
local step1 = equipBagTutorial:AddStep()
step1:SetShouldSaveProgress(false)

step1:RegisterCallback("StepStarted", function()
    local helpTipInfo = {
        text = NPE_FULL_BAGS_HAVE_MORE_BAGS or "Seems like |cffFFFF00you have one more bag you can use!|r Open this bag to find it.",
        targetPoint = HelpTip.Point.TopEdgeCenter,
        animatePointer = true,
        highlightTarget = HelpTip.TargetType.Box,
    }

    if TUTORIAL_NEXT_USABLE_BAG then
        local bag = TUTORIAL_NEXT_USABLE_BAG[1]

        helpTipInfo.parent = _G[NewItemTutorialMixin:DefineBagByItemPos(bag)]
        step1:AddHelpTip(helpTipInfo, NPE.Const.Tutorials.USE_BAGS_TUTORIAL)
    else
        dprint(equipBagTutorial:GetName().." step1: exit complete tutorial")
        NPE:CompleteTutorial(NPE.Const.Tutorials.USE_BAGS_TUTORIAL) -- safe exit if we reloaded UI before the tutorial is complete
    end
end)

step1:SetCompletionCondition(function()
    if IsAddOnLoaded("AdiBags") then
        return not(TUTORIAL_NEXT_USABLE_BAG) or (TUTORIAL_NEXT_USABLE_BAG and NewItemTutorialMixin:IsAnyBagOpen())
    else
        return not(TUTORIAL_NEXT_USABLE_BAG) or (TUTORIAL_NEXT_USABLE_BAG and IsBagOpen(TUTORIAL_NEXT_USABLE_BAG[1]))
    end
end)

-- step 2:Highlight proper item and ask to click it. Make tutorial complete even if you just close the bags
local step2 = equipBagTutorial:AddStep()
step2:SetShouldSaveProgress(false)

step2:RegisterCallback("StepStarted", function()
    local helpTipInfo = {
        text = NPE_FULL_BAGS_RIGHT_CLICK_TO_EQUIP or "|cffFFFF00Right Click|r the bag to equip it",
        targetPoint = HelpTip.Point.LeftEdgeCenter,
        animatePointer = true,
        highlightTarget = HelpTip.TargetType.Box,
    }

    helpTipInfo.parent = _G[NewItemTutorialMixin:DefineParentByItemPos(unpack(TUTORIAL_NEXT_USABLE_BAG))]

    if helpTipInfo.parent then
        step2:AddHelpTip(helpTipInfo, NPE.Const.Tutorials.USE_BAGS_TUTORIAL)
    else
        dprint(equipBagTutorial:GetName().." step2: exit complete tutorial")
        NPE:CompleteTutorial(NPE.Const.Tutorials.USE_BAGS_TUTORIAL) -- safe exit if we reloaded UI before the tutorial is complete
    end
end)

step2:SetCompletionEvent("ITEM_LOCKED")
step2:SetCompletionCondition(function()
   return not NewItemTutorialMixin:IsAnyBagOpen()
end)

local step3 = equipBagTutorial:AddStep()
step3:SetShouldSaveProgress(false)

step3:RegisterCallback("StepStarted", function()
    local helpTipInfo = {
        text = NPE_FULL_BAGS_4_BAGS or "Those are your bags. |cffFFFF00You can have up to 4 bags|r equipped at once!",
        targetPoint = HelpTip.Point.TopEdgeCenter,
        animatePointer = true,
        highlightTarget = HelpTip.TargetType.Box,
        buttonStyle = HelpTip.ButtonStyle.GotIt,
        onHideCallback = function() step3.isComplete = true end,
    }
    
    BagHelperFrame:Show()
    helpTipInfo.parent = BagHelperFrame

    if helpTipInfo.parent then
        step3:AddHelpTip(helpTipInfo, NPE.Const.Tutorials.USE_BAGS_TUTORIAL)
    else
        dprint(equipBagTutorial:GetName().." step3: exit complete tutorial")
        NPE:CompleteTutorial(NPE.Const.Tutorials.USE_BAGS_TUTORIAL) -- safe exit if we reloaded UI before the tutorial is complete
    end
end)

step3:SetCompletionCondition(function()
   return step3.isComplete 
end)

NPE:AddTutorial(equipBagTutorial)