RepurchaseTabMixin = {}

function RepurchaseTabMixin:OnLoad()
    self.ErrorFrame:SetFrameLevel(self:GetFrameLevel() + 20)
    self.scrollClaimAmount = 1
    self.talentScrollClaimAmount = 1
    self.ScrollReward.BigDigits:SetAnimated(true)
    self.TalentScrollReward.BigDigits:SetAnimated(true)
    self.ScrollReward.SubText:SetText(SOF_DESCRIPTION)
    self.TalentScrollReward.SubText:SetText(SOF_TALENTS_DESCRIPTION)
    self.markOfAscension = Item:CreateFromID(ItemData.MARK_OF_ASCENSION)
end

function RepurchaseTabMixin:OnShow()
    self:RegisterEvent("WILDCARD_REPURCHASE_ROLLS_RESULT")
    self:RegisterEvent("WILDCARD_REPURCHASABLE_ROLLS_CHANGED")
    self:RegisterEvent("WILDCARD_REPURCHASABLE_ABILITY_ROLLS_CHANGED")
    self:RegisterEvent("WILDCARD_REPURCHASABLE_TALENT_ROLLS_CHANGED")
    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    self:Refresh(true)
end

function RepurchaseTabMixin:OnHide()
    self:UnregisterEvent("WILDCARD_REPURCHASE_ROLLS_RESULT")
    self:UnregisterEvent("WILDCARD_REPURCHASABLE_ROLLS_CHANGED")
    self:UnregisterEvent("WILDCARD_REPURCHASABLE_ABILITY_ROLLS_CHANGED")
    self:UnregisterEvent("WILDCARD_REPURCHASABLE_TALENT_ROLLS_CHANGED")
    self:UnregisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    StaticPopup_Hide("CONFIRM_PURCHASE_NO_REFUNDS")
end

function RepurchaseTabMixin:OnEvent(event, ...)
    if event == "WILDCARD_REPURCHASE_ROLLS_RESULT" then
        local reason = ...
        if reason ~= "REPURCHASE_WILDCARD_ROLL_OK" then
            self.ErrorFrame:SetText(UNABLE_TO_REPURCHASE, _G[reason] or reason)
            self.ErrorFrame:Show()
            self:Refresh()
        else
            self:Refresh(true)
        end
    else
        self:Refresh(true)
    end
end

function RepurchaseTabMixin:Refresh(reset)
    if reset then
        self.scrollClaimAmount = 1
        self.talentScrollClaimAmount = 1
    end
    self:CheckCanUseGold()
    self:UpdateScrolls()
    self:UpdateTalentScrolls()
end

function RepurchaseTabMixin:CheckCanUseGold()
    local canUseGold = C_Config.GetBoolConfig("CONFIG_WILDCARD_ROLL_GOLD_REPURCHASING_ENABLED")
    self.UseGold:SetShown(canUseGold)
    if not canUseGold then
        self.UseGold:SetChecked(false)
    end
end

function RepurchaseTabMixin:ChangeScrollClaimAmount(amount)
    local maximumClaim = C_Wildcard.GetNumRepurchasableRolls()
    self.scrollClaimAmount = math.clamp(self.scrollClaimAmount + amount, 1, maximumClaim)
    self:UpdateScrolls()
end 

function RepurchaseTabMixin:ChangeTalentScrollClaimAmount(amount)
    local maximumClaim = C_Wildcard.GetNumRepurchasableTalentRolls()
    self.talentScrollClaimAmount = math.clamp(self.talentScrollClaimAmount + amount, 1, maximumClaim)
    self:UpdateTalentScrolls()
end 

function RepurchaseTabMixin:UpdateScrolls()
    local isUsingGold = self.UseGold:GetBoolValue()
    local cost = C_Wildcard.GetRepurchaseRollCost(self.scrollClaimAmount, isUsingGold)
    local abilityItemID = CostUtil:GetScrollOfFortuneForSpec(SpecializationUtil.GetActiveSpecialization())
    local abilityItem = Item:CreateFromID(abilityItemID)

    if isUsingGold then
        local costString = GetMoneyString(cost)
        self.PurchaseScrollsButton:SetFormattedText(CLAIM_S_FOR_S, self.scrollClaimAmount.." "..abilityItem:GetLink(), costString)
    else
        local costString = cost .. " " .. self.markOfAscension:GetIconLink()
        self.PurchaseScrollsButton:SetFormattedText(CLAIM_S_FOR_S, self.scrollClaimAmount.." "..abilityItem:GetLink(), costString)
    end

    local canPurchase, error = C_Wildcard.CanRepurchaseRolls(self.scrollClaimAmount, isUsingGold)
    self.PurchaseScrollsButton:SetEnabled(canPurchase)
    if error then
        self.PurchaseScrollsButton.ErrorText:SetText(_G[error] or error)
    end
    self.PurchaseScrollsButton.ErrorText:SetShown(not canPurchase)
    
    local numPurchasable = C_Wildcard.GetNumRepurchasableRolls()

    self.PurchaseScrollsButton.UpButton:SetEnabled(self.scrollClaimAmount < numPurchasable)
    self.PurchaseScrollsButton.DownButton:SetEnabled(self.scrollClaimAmount > 1)

    self.ScrollReward:SetItem(abilityItemID)
    self.ScrollReward.Title:SetText(GetItemName(abilityItemID))
    self.ScrollReward.BigDigits:SetValue(self.scrollClaimAmount)
    if numPurchasable > 0 then
        self.ScrollReward.Remaining:SetVertexColor(0, 1, 0, 1)
        self.ScrollReward.Remaining:SetFormattedText(REPURCHASE_REMAINING, numPurchasable - self.scrollClaimAmount)
    else
        self.ScrollReward.Remaining:SetVertexColor(0.4, 0.4, 0.4, 0.8)
        self.ScrollReward.Remaining:SetFormattedText(REPURCHASE_REMAINING, 0)
    end
end

function RepurchaseTabMixin:UpdateTalentScrolls()
    local isUsingGold = self.UseGold:GetBoolValue()
    local cost = C_Wildcard.GetRepurchaseTalentRollCost(self.talentScrollClaimAmount, isUsingGold)
    local talentItemID = CostUtil:GetScrollOfFortuneTalentsForSpec(SpecializationUtil.GetActiveSpecialization())
    local talentItem = Item:CreateFromID(talentItemID)

    if isUsingGold then
        local costString = GetMoneyString(cost)
        self.PurchaseTalentScrollsButton:SetFormattedText(CLAIM_S_FOR_S, self.talentScrollClaimAmount .. " " .. talentItem:GetLink(), costString)
    else
        local costString = cost .. " " .. self.markOfAscension:GetIconLink()
        self.PurchaseTalentScrollsButton:SetFormattedText(CLAIM_S_FOR_S, self.talentScrollClaimAmount .. " " .. talentItem:GetLink(), costString)
    end
    local canPurchase, error = C_Wildcard.CanRepurchaseTalentRolls(self.talentScrollClaimAmount, false)
    self.PurchaseTalentScrollsButton:SetEnabled(canPurchase)
    if error then
        self.PurchaseTalentScrollsButton.ErrorText:SetText(_G[error] or error)
    end
    self.PurchaseTalentScrollsButton.ErrorText:SetShown(not canPurchase)
    
    local numPurchasable = C_Wildcard.GetNumRepurchasableTalentRolls()

    self.PurchaseTalentScrollsButton.UpButton:SetEnabled(self.talentScrollClaimAmount < numPurchasable)
    self.PurchaseTalentScrollsButton.DownButton:SetEnabled(self.talentScrollClaimAmount > 1)

    self.TalentScrollReward:SetItem(talentItemID, self.talentScrollClaimAmount)
    self.TalentScrollReward.Title:SetText(GetItemName(talentItemID))
    self.TalentScrollReward.BigDigits:SetValue(self.talentScrollClaimAmount)
    if numPurchasable > 0 then
        self.TalentScrollReward.Remaining:SetVertexColor(0, 1, 0)
        self.TalentScrollReward.Remaining:SetFormattedText(REPURCHASE_REMAINING, numPurchasable - self.talentScrollClaimAmount)
    else
        self.TalentScrollReward.Remaining:SetVertexColor(0.4, 0.4, 0.4, 0.8)
        self.TalentScrollReward.Remaining:SetFormattedText(REPURCHASE_REMAINING, 0)
    end
end

function RepurchaseTabMixin:OnPurchaseScrolls()
    StaticPopup_Show("CONFIRM_PURCHASE_NO_REFUNDS", self.scrollClaimAmount, self.ScrollReward.item:GetLink(), function()
        self.PurchaseScrollsButton:Disable()
        C_Wildcard.RepurchaseRolls(self.scrollClaimAmount, self.UseGold:GetBoolValue())
    end)
end

function RepurchaseTabMixin:OnPurchaseTalentScrolls()
    StaticPopup_Show("CONFIRM_PURCHASE_NO_REFUNDS", self.talentScrollClaimAmount, self.TalentScrollReward.item:GetLink(), function()
        self.PurchaseTalentScrollsButton:Disable()
        C_Wildcard.RepurchaseTalentRolls(self.talentScrollClaimAmount, self.UseGold:GetBoolValue())
    end)
end 