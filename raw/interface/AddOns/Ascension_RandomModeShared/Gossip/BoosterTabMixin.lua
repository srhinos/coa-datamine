BoosterTabMixin = {}

function BoosterTabMixin:OnLoad()
    self.ErrorFrame:SetFrameLevel(self:GetFrameLevel() + 20)
    self.Rewards.Reward1:SetItem(ItemData.GOLDEN_ABILITY_SEALED_CARD_PACK)
    self.Rewards.Reward2:SetItem(ItemData.GOLDEN_TALENT_SEALED_CARD_PACK)
    self.Rewards.Reward1:Show()
    self.Rewards.Reward2:Show()
    self.Rewards:Show()
    self.Rewards:MarkDirty()
    
    self.claimAmount = 1
end

function BoosterTabMixin:OnShow()
    self:RegisterEvent("PURCHASE_SEALED_CARD_BOOSTER_PACK_RESULT")
    self.claimAmount = 1
    self:UpdateCount()
end

function BoosterTabMixin:OnHide()
    self:UnregisterEvent("PURCHASE_SEALED_CARD_BOOSTER_PACK_RESULT")
    StaticPopup_Hide("CONFIRM_PURCHASE_SKILL_CARD_BOOSTER")
end

function BoosterTabMixin:OnEvent(event, ...)
    if event == "PURCHASE_SEALED_CARD_BOOSTER_PACK_RESULT" then
        local result = ...
        if result ~= "PURCHASE_SEALED_CARD_BOOSTER_PACK_OK" then
            self.ErrorFrame:SetText(UNABLE_TO_PURCHASE_BOOSTER, RED_FONT_COLOR:WrapText(_G[result] or result))
            self.ErrorFrame:Show()
        end
        self.claimAmount = 1
        self:UpdateCount()
    end
end

function BoosterTabMixin:OnPurchaseBooster()
    StaticPopup_Show("CONFIRM_PURCHASE_SKILL_CARD_BOOSTER", self.claimAmount, self.Rewards.Reward1.item:GetLink(), function()
        self.PurchaseButton:Disable()
        C_SkillCardCollection.PurchaseSealedCardBoosterPack(self.claimAmount)
    end)
end

function BoosterTabMixin:UpdateCount()
    local cost = C_SkillCardCollection.GetSealedCardBoosterPackCost(self.claimAmount)
    local costString = HIGHLIGHT_FONT_COLOR:WrapText(BreakUpLargeMoneyString(cost))
    self.PurchaseButton:SetFormattedText(CLAIM_GOLDEN_SKILL_CARDS_FOR_S, costString)
    local canPurchase, errors = C_SkillCardCollection.CanPurchaseSealedCardBoosterPack(self.claimAmount)
    self.PurchaseButton:SetEnabled(canPurchase)
    if errors then
        self.PurchaseButton.ErrorText:SetText(_G[errors[1]] or errors[1])
    end
    self.PurchaseButton.ErrorText:SetShown(not canPurchase)

    self.PurchaseButton.UpButton:SetEnabled(self.claimAmount < C_SkillCardCollection.GetMaxNumPurchasableSealedCardBoosterPacks())
    self.PurchaseButton.DownButton:SetEnabled(self.claimAmount > 1)

    self.Rewards.Reward1:SetItem(ItemData.GOLDEN_ABILITY_SEALED_CARD_PACK, self.claimAmount)
    self.Rewards.Reward2:SetItem(ItemData.GOLDEN_TALENT_SEALED_CARD_PACK, self.claimAmount)
end

function BoosterTabMixin:ChangeClaimAmount(amount)
    local maximumClaim = C_SkillCardCollection.GetMaxNumPurchasableSealedCardBoosterPacks()
    self.claimAmount = math.clamp(self.claimAmount + amount, 1, maximumClaim)
    self:UpdateCount()
end