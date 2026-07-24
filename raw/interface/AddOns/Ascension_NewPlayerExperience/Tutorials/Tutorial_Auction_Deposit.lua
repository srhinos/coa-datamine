local _, NPE = ...

local HelpTipDeposit = {
    parent = "AuctionsDepositMoneyFrame",
    text = NPE_AUCTION_DEPOSIT or "The Deposit is paid upfront. If your item sells, you get the deposit back! If your item does not sell, you lose the deposit. Make sure to price your item to sell so you don't lose your deposit!",
    targetPoint = HelpTip.Point.RightEdgeCenter,
    strata = "TOOLTIP",
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    animatePointer = true,
    offsetX = 128,
}

local tutorial = NPE:NewEventTutorial(NPE.Const.Tutorials.AUCTION_HOUSE_DEPOSIT, "NEW_AUCTION_UPDATE")
tutorial:SetMinMaxLevel(1, 80)
tutorial:SetMinTutorialExperience(Enum.TutorialExperience.NoTutorials)

tutorial:RegisterCallback("TutorialStarted", function()
    dprint(tutorial:GetName().." TutorialStarted!")
end)

tutorial:RegisterCallback("TutorialCompleted", function()
    dprint(tutorial:GetName().." TutorialCompleted!")
end)

-- step 1, open tut
local step1 = tutorial:AddStep()

HelpTipDeposit.onHideCallback = function() if step1:IsActive() then step1:Complete() end  end,

step1:SetCompletionCondition(function(self)
    return not AuctionFrameAuctions or not(AuctionFrameAuctions:IsVisible())
end)

step1:AddHelpTip(HelpTipDeposit)

NPE:AddTutorial(tutorial)
