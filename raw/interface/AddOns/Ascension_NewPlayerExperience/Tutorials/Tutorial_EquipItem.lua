local _, NPE = ...

-------
-- How to equip items tutorial
-------
local equipItemsTutorial = NPE:NewItemTutorial(NPE.Const.Tutorials.EQUIP_ITEMS_TUTORIAL)
equipItemsTutorial:SetMinMaxLevel(1, 10)
equipItemsTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

equipItemsTutorial:RegisterCallback("TutorialStarted", function()
    NPE:CompleteTutorial(NPE.Const.Tutorials.LOOT_WINDOW_TUTORIAL) -- both tutorials teach to open bags
    dprint(equipItemsTutorial:GetName().." TutorialStarted!")
end)

equipItemsTutorial:RegisterCallback("TutorialCompleted", function()
    dprint(equipItemsTutorial:GetName().." TutorialCompleted!")
end)

function equipItemsTutorial:ValidateItems(...)
    local bag, slot, id, count = ...

    if id and (IsEquippableItem(id)) then

        if not C_Player:IsHero() then
            return false
        end
        
        return self:GetItemAvailableForUse(bag, slot), bag, slot
    end

    return false
end

-- step 1: Show bag help tip
local step1 = equipItemsTutorial:AddStep()
step1:SetShouldSaveProgress(false)

step1:RegisterCallback("StepStarted", function()
    local helpTipInfo = {
        parent = function() return _G[equipItemsTutorial:GetBagParent()] end,
        text = NPE_NEW_EQUIPPABLE_ITEM_BAG or "Seems like you have a new equippable item! Click here or press |cffFFFF00(B)|r to open your |cffFFFF00bags|r",
        targetPoint = HelpTip.Point.TopEdgeCenter,
        animatePointer = true,
        highlightTarget = HelpTip.TargetType.Box,
    }

    if equipItemsTutorial:GetBagParent() then
        step1:AddHelpTip(helpTipInfo, NPE.Const.Tutorials.EQUIP_ITEMS_TUTORIAL)
    else
        NPE:CompleteTutorial(NPE.Const.Tutorials.EQUIP_ITEMS_TUTORIAL) -- safe exit if we reloaded UI before the tutorial is complete
    end
end)

step1:SetCompletionCondition(function()
    local bag = equipItemsTutorial:GetValidItemPosition()
    if IsAddOnLoaded("AdiBags") then
        return bag and NewItemTutorialMixin:IsAnyBagOpen()
    else
        return bag and IsBagOpen(bag)
    end
end)

-- step 2:Highlight proper item and ask to click it. Make tutorial complete even if you just close the bags
local step2 = equipItemsTutorial:AddStep()
step2:SetShouldSaveProgress(false)

step2:AddHelpTip({
    parent = function() return _G[equipItemsTutorial:DefineContainerItemByItemPos()] end,
    text = NPE_RIGHT_CLICK_TO_EQUIP_IT or "|cffFFFF00Right Click|r new item to equip it",
    targetPoint = HelpTip.Point.LeftEdgeCenter,
    animatePointer = true,
    highlightTarget = HelpTip.TargetType.Box,
}, NPE.Const.Tutorials.EQUIP_ITEMS_TUTORIAL)

step2:SetCompletionEvent("ITEM_LOCKED")
step2:SetCompletionCondition(function()
   return not NewItemTutorialMixin:IsAnyBagOpen()
end)

NPE:AddTutorial(equipItemsTutorial)
