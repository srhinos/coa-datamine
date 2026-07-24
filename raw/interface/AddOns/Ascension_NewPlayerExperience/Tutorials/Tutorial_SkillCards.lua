local _, NPE = ...

TUTORIAL_TIP_WC_ROLLED_CARD = TUTORIAL_TIP_WC_ROLLED_CARD or "You just rolled your Starter |cffFFFF00Skill Card|r. You can open Skill Cards to remove that skill card and pick a different one!|r"
TUTORIAL_TIP_WC_REMOVE_BLOCKED_STARTER = TUTORIAL_TIP_WC_REMOVE_BLOCKED_STARTER or "You can |cffFFFF00remove Starter Skill Card|r you just rolled to |cffFFFF00replace|r it with a different |cffFFFF00Skill Card.|r"
TUTORIAL_TIP_WC_SIDEBAR_HELP = TUTORIAL_TIP_WC_SIDEBAR_HELP or "You can allocate more |cffFFFF00Skill Cards.|r"

TUTORIAL_TIP_WC_USE_SKILL_CARDS = TUTORIAL_TIP_WC_USE_SKILL_CARDS or "To roll desired |cffFFFF00starting abilities|r, you could use |cffFFFF00Skill Cards|r."
TUTORIAL_TIP_WC_STARTER_CARDS = TUTORIAL_TIP_WC_STARTER_CARDS or "You can filter list of known Skill Cards to display |cffFFFF00Starter Skill Cards|r only."

local HelpTipMicroButton = {
    parent = "TalentMicroButton",
    text = TUTORIAL_TIP_WC_USE_SKILL_CARDS,
    targetPoint = HelpTip.Point.TopEdgeCenter,
    strata = "TOOLTIP",
    offsetX = 0,
    system            = "micromenu", -- to properly work with other tips, HelpTips.lua
    systemPriority    = 101,
    animatePointer = true,
}

local HelpTipCollections = {
    parent = function() return Collections:GetTabForPanel("SkillCardsFrame") end,
    text = TUTORIAL_TIP_WC_USE_SKILL_CARDS,
    targetPoint = HelpTip.Point.TopEdgeCenter,
    strata = "TOOLTIP",
    --offsetY = 16,
    animatePointer = true,
}

local HelpTipMicroButton2 = {
    parent = "TalentMicroButton",
    text = TUTORIAL_TIP_WC_ROLLED_CARD,
    targetPoint = HelpTip.Point.TopEdgeCenter,
    strata = "TOOLTIP",
    offsetX = 0,
    system            = "micromenu", -- to properly work with other tips, HelpTips.lua
    systemPriority    = 102,
    animatePointer = true,
}

local HelpTipCollections2 = {
    parent = function() return Collections:GetTabForPanel("SkillCardsFrame") end,
    text = TUTORIAL_TIP_WC_ROLLED_CARD,
    targetPoint = HelpTip.Point.TopEdgeCenter,
    strata = "TOOLTIP",
    --offsetY = 16,
    animatePointer = true,
}

local HelpTipFilter = {
    parent = function() return SkillCardsFrame.Filter end,
    text = TUTORIAL_TIP_WC_STARTER_CARDS,
    targetPoint = HelpTip.Point.LeftEdgeCenter,
    strata = "TOOLTIP",
    offsetX = 0,
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    animatePointer = true,
}

local HelpTipCloseCard = {
    --parent = function() return SkillCardsFrame.ScrollListHelperFrame end,
    text = TUTORIAL_TIP_WC_REMOVE_BLOCKED_STARTER,
    targetPoint = HelpTip.Point.RightEdgeCenter,
    strata = "TOOLTIP",
    offsetX = 0,
    animatePointer = true,
}

local HelpTipSideBar = {
    parent = function() return SkillCardsFrame.ScrollListHelperFrame end,
    text = TUTORIAL_TIP_WC_SIDEBAR_HELP,
    targetPoint = HelpTip.Point.LeftEdgeCenter,
    strata = "TOOLTIP",
    offsetX = 0,
    buttonStyle = HelpTip.ButtonStyle.GotIt,
}

local tutorial = NPE:NewEventTutorial(NPE.Const.Tutorials.SKILL_CARD_TUTORIAL, "WildCard.OnSetSoFRoll", function() 
	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) and (UnitLevel("player") >= 10) and (WildCard:GetAESpent() <= 8) and (C_CharacterAdvancement.GetLearnedTE() == 0) then
		return true 
	end 
end)

tutorial:RegisterCallback("TutorialStarted", function()
    dprint(tutorial:GetName().." TutorialStarted!")
end)

tutorial:RegisterCallback("TutorialCompleted", function()
    dprint(tutorial:GetName().." TutorialCompleted!")
end)

tutorial:SetMinMaxLevel(1, 80)
tutorial:SetMinTutorialExperience(Enum.TutorialExperience.NoTutorials)

-- step 1, wait to open CA
local step1 = tutorial:AddStep()
step1:SetCompletionCondition(function(self)
    return Collections and Collections:IsVisible()
end)
step1:SetShouldSaveProgress(false)
step1:AddHelpTip(HelpTipMicroButton)

-- step 2, wait to open Skill Cards
local step2 = tutorial:AddStep()
step2:SetCompletionCondition(function(self)
    return (SkillCardsFrame and SkillCardsFrame:IsVisible()) or not(Collections:IsVisible())
end)
step2:SetShouldSaveProgress(false)
step2:AddHelpTip(HelpTipCollections)

-- step 3, use filter
local step3 = tutorial:AddStep()
step3:SetCompletionCondition(function(self)
    return self.complete or not(Collections:IsVisible())
end)
step3:SetCompletionEvent("SkillCardsFrameMixin.GenerateFilterDropdown")
step3:SetShouldSaveProgress(false)
HelpTipFilter.onHideCallback = function() step3.complete = true end,
step3:AddHelpTip(HelpTipFilter)

NPE:AddTutorial(tutorial)

-- 
-- tutorial explaining that you can roll after using a card
--
local savedCardType, savedCardIndex, skillCardVisible

local function GetProperCardForTutorial()
    if (SkillCardsFrame.TabInsetFrame.cardTypeNormal == savedCardType) then
        skillCardVisible = SkillCardsFrame.TabInsetFrame.cardIDToButtonNormal[savedCardIndex]
        return true
    end

    if (SkillCardsFrame.TabInsetFrame.cardTypeGolden == savedCardType) then
        skillCardVisible = SkillCardsFrame.TabInsetFrame.cardIDToButtonGolden[savedCardIndex]
        return true
    end
end

tutorial = NPE:NewEventTutorial(NPE.Const.Tutorials.SKILL_CARD_TUTORIAL_CLEAR_START, "SKILL_CARD_BLOCKED", function(...)
    local _, cardType, cardIndex = ...

    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) and (UnitLevel("player") >= 10) and (WildCard:GetAESpent() <= 8) and (C_CharacterAdvancement.GetLearnedTE() == 0) then
        savedCardType = cardType
        savedCardIndex = cardIndex
        return true
    end 
end) 

tutorial:RegisterCallback("TutorialStarted", function()
    NPE:CompleteTutorial(NPE.Const.Tutorials.SKILL_CARD_TUTORIAL)
end)

tutorial:RegisterCallback("TutorialCompleted", function()
    dprint(tutorial:GetName().." TutorialCompleted!")
end)

-- step 1, wait to open CA
step1 = tutorial:AddStep()
step1:SetCompletionCondition(function(self)
    return Collections and Collections:IsVisible() or not(savedCardType)
end)
step1:SetShouldSaveProgress(false)
step1:AddHelpTip(HelpTipMicroButton2)

-- step 2, wait to open Skill Cards
step2 = tutorial:AddStep()
step2:SetCompletionCondition(function(self)
    GetProperCardForTutorial()

    return (SkillCardsFrame and SkillCardsFrame:IsVisible() and skillCardVisible and skillCardVisible:IsVisible()) or not(Collections:IsVisible()) or not(savedCardType)
end)
step2:SetShouldSaveProgress(false)
step2:AddHelpTip(HelpTipCollections2)

-- step 3, navigate user to remove blocked card
step3 = tutorial:AddStep()
step3:RegisterCallback("StepStarted", function()
    HelpTipCloseCard.parent = function() return skillCardVisible.KnownCard.RemoveButton end
    step3:AddHelpTip(HelpTipCloseCard)
end)

step3:SetCompletionEvent("SKILL_CARD_UNBLOCKED")
step3:SetCompletionCondition(function(self)
    return not(Collections:IsVisible()) or not(skillCardVisible)
end)
step3:SetShouldSaveProgress(false)

-- step 4, use filter
step4 = tutorial:AddStep()
step4:SetCompletionCondition(function(self)
    return self.complete or not(Collections:IsVisible())
end)
step4:SetShouldSaveProgress(false)
HelpTipSideBar.onHideCallback = function() step4.complete = true end,
step4:AddHelpTip(HelpTipSideBar)

NPE:AddTutorial(tutorial)