local _, NPE = ...

local LOOT_CORPSE_POPUP_KEY = "PopupLootCorpse"

local PopupLootCorpse = {
    key = LOOT_CORPSE_POPUP_KEY,
    text = NPE_LOOT_SPARKLING_CORPSES or "|cffFFFF00Sparkling corpses contain loot!|r |cffFFFF00Left click|r to see what they have and click the loot to claim it.",
    --iconAtlas = "newplayertutorial-icon-mouse-rightbutton",
    icon = "interface\\tutorials\\sparklestut",
    iconWidth = 96,
    iconHeight = 96,
    okButton = true,
    priority = NPE.Const.PopupPriority.HIGH,
    fontSize = 14,
}

local HelpTipLootWindowClickItem = {
    text = NPE_LOOT_CLICK_TO_ADD_TO_BAG or "Click to add item to your |cffFFFF00bag|r",
    targetPoint = HelpTip.Point.LeftEdgeCenter,
    parent = LootButton1,
    highlightTarget = HelpTip.TargetType.Box,
    animatePointer = true,
}

local HelpTipLootWindowOpenBags = {
    text =  NPE_LOOT_CLICK_TO_OPEN_BAGS or "Click here or press |cffFFFF00(B)|r to see contents or your |cffFFFF00bags|r",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    parent = MainMenuBarBackpackButton,
    highlightTarget = HelpTip.TargetType.Box,
    animatePointer = true,
}

local helpTipSystemLoot = "helpTipSystemLoot"
-------
-- Kill-Loot Tutorial functions
-------
local LootTutorialComplete = function()
    NPE:CompleteTutorial(NPE.Const.Tutorials.LOOT_CORPSE_TUTORIAL)

    NPE:SetPopupComplete(LOOT_CORPSE_POPUP_KEY)
    Timer.After(0.5, function()
        NPE:ClearDialogPopup(LOOT_CORPSE_POPUP_KEY)
    end)
end

local LootTutorialOnCombatLogEvent = function(self, ...)
    local event_subType = select(2, ...)
    local attackerName = select(4, ...)
    local destGUID = select(6, ...)
    local destName = select(7, ...)
    local ID = GetCreatureIDFromGUID(destGUID)

    if attackerName and (attackerName ~= UnitName("player")) then
        return
    end
    
    if event_subType and ID and NPE.Const.StartingAreaCreatures[ID] then
        if  (event_subType == "SPELL_DAMAGE") or (event_subType == "SWING_DAMAGE")  then
            if not(self.damageTargets) then
                self.damageTargets = {}
            end
            self.damageTargets[destGUID] = true
        elseif (event_subType == "PARTY_KILL") then
            self.damageTargets = {}
            self.hasCorpse = true
            return
        elseif (event_subType == "UNIT_DIED") then
            if next(self.damageTargets) and self.damageTargets[destGUID] then
                self.damageTargets = {}
                self.hasCorpse = true
                return
            end
        end
    end
end

-------
-- Kill-Loot Tutorial
-------
do
    local lootTutorial = NPE:NewTutorial(NPE.Const.Tutorials.LOOT_CORPSE_TUTORIAL)
    lootTutorial.damageTargets = {}
    lootTutorial.hasCorpse = false

    lootTutorial:SetAutoStart(true)
    lootTutorial:SetMinMaxLevel(1, 5)
    lootTutorial:RegisterCallback("TutorialCompleted", LootTutorialComplete)
    lootTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)
    --lootTutorial:RegisterCallback("TutorialStopped", TutorialComplete) -- ?

    lootTutorial:RegisterCallback("TutorialStarted", function()
        dprint(lootTutorial:GetName().." Sterted!")

        if not lootTutorial.eventHandle then
            lootTutorial.eventHandle = lootTutorial:RegisterEventCallbackWithHandle("COMBAT_LOG_EVENT_UNFILTERED", LootTutorialOnCombatLogEvent, lootTutorial)
        end
    end)

    -- step 1, wait for user to kill the creature
    local step1 = lootTutorial:AddStep()
    step1:SetCompletionCondition(function()
        return lootTutorial.hasCorpse
    end)

    step1:RegisterCallback("StepFinished", function()
        if lootTutorial.eventHandle then
            lootTutorial.eventHandle:Unregister()
            lootTutorial.eventHandle = nil
        end
    end)

    -- step 2, wait for user to reveal loot UI
    local step2 = lootTutorial:AddStep()
    step2:SetCompletionEvent("LOOT_OPENED")
    step2:RegisterCallback("StepStarted", function()
        NPE:ShowDialogPopup(PopupLootCorpse)
    end)

    NPE:AddTutorial(lootTutorial)
end

-------
-- Loot window tutorial
-------
do 
    local lootWindowTutorial = NPE:NewTutorial(NPE.Const.Tutorials.LOOT_WINDOW_TUTORIAL)
    lootWindowTutorial:SetAutoStart(true)
    lootWindowTutorial:SetMinMaxLevel(1, 5)
    lootWindowTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

    lootWindowTutorial:RegisterCallback("TutorialFinished", function()
        dprint(lootWindowTutorial:GetName().." Finished!")
        NPE:ClearAllHelpTipsForSystem(helpTipSystemLoot)
    end)

    -- wait for loot window to appear
    local step1 = lootWindowTutorial:AddStep()
    step1:SetCompletionEvent("LOOT_OPENED")

    -- step 2, wait for user to loot item
    local step2 = lootWindowTutorial:AddStep()

    step2:SetCompletionEvent("LOOT_SLOT_CLEARED")
    step2:AddHelpTip(HelpTipLootWindowClickItem, helpTipSystemLoot)
    
    -- step 3, wait for to open bags
    local step3 = lootWindowTutorial:AddStep()

    step3:SetCompletionCondition(function()
        return NewItemTutorialMixin:IsAnyBagOpen()
    end)
    step3:AddHelpTip(HelpTipLootWindowOpenBags, helpTipSystemLoot)

    NPE:AddTutorial(lootWindowTutorial)
end