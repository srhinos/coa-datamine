local _, NPE = ...
--[[
local HelpTipXP = {
    parent = "MainMenuExpBar",
    text = "You've gained |cffFFFF00experience|r! You'll |cffFFFF00level up|r when this bar is filled",
    targetPoint = HelpTip.Point.TopEdgeLeft,
    lifetime = 10,
    strata = "TOOLTIP",
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    offsetX = 128,
}

local tutorial = NPE:NewEventTutorial(NPE.Const.Tutorials.XP_TUTORIAL, "PLAYER_XP_UPDATE", "player", function() if UnitXP("player") > 180 then return true end end)
tutorial:SetMinMaxLevel(1, 5)
tutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

-- step 1, wait for user to kill the creature
local step1 = tutorial:AddStep()

HelpTipXP.onHideCallback = function() step1.complete = true end,

step1:SetCompletionCondition(function(self)
    return self.complete
end)

step1:AddHelpTip(HelpTipXP)

NPE:AddTutorial(tutorial)
]]--