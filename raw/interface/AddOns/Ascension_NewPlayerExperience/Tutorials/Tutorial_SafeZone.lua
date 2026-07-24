local _, NPE = ...

local HelpTipRes = {
    parent = "ClosestResFrame",
    text = NPE_SAFE_ZONE_RESURRECT or "Use this option to resurrect in a Safe Zone and avoid death penalties.",
    targetPoint = HelpTip.Point.RightEdgeCenter,
    lifetime = 10,
    strata = "TOOLTIP",
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    offsetX = 0,
}

local tutorial = NPE:NewEventTutorial(NPE.Const.Tutorials.RES_SAFE_ZONE_TUTORIAL, "PLAYER_FLAGS_CHANGED", "player", function() 
	if UnitIsGhost("player") and (UnitIsGhost("player") == 1) then 
		return true 
	end 
end)

tutorial:SetMinMaxLevel(1, 20)
tutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToAscension)

-- step 1, wait for user to kill the creature
local step1 = tutorial:AddStep()

HelpTipRes.onHideCallback = function() step1.complete = true end,

step1:SetCompletionCondition(function(self)
    return self.complete
end)

step1:AddHelpTip(HelpTipRes)

NPE:AddTutorial(tutorial)