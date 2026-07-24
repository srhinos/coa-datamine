RandomModeRewardTabMixin = {}
RandomModeRewardTabMixin.OnEvent = OnEventToMethod

function RandomModeRewardTabMixin:OnLoad()
    self.LevelingScroll.Child.Fill:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\CollectionsBarEnchants", "REPEAT", "REPEAT")
    self.LevelingScroll.Child.RewardPool = CreateFramePool("Frame", self.LevelingScroll.Child, "RandomModeLevelingRewardTemplate")
    self.MarkOfAscensionItem = Item:CreateFromID(ItemData.MARK_OF_ASCENSION)
    self.MainReward.Item.BigDigits:SetAnimated(true)
    self.ErrorFrame:SetFrameLevel(self:GetFrameLevel() + 20)
    UseParentLevel(self.Magic)
end

function RandomModeRewardTabMixin:OnShow()
    self:UpdateState()
    self.handle = self:GetParent():GetParent():RegisterCallbackWithHandle("OnSpecializationSelected", self.UpdateState, self)
    self:RegisterEvent("COLLECT_SCROLL_OF_FORTUNE_REWARDS_RESULT")
    self:RegisterEvent("COLLECT_HAND_OF_FATE_REWARDS_RESULT")
end

function RandomModeRewardTabMixin:OnHide()
    self:SetScript("OnUpdate", nil)
    self.handle:Unregister()
    self.handle = nil
    self:UnregisterEvent("COLLECT_SCROLL_OF_FORTUNE_REWARDS_RESULT")
    self:UnregisterEvent("COLLECT_HAND_OF_FATE_REWARDS_RESULT")
end

function RandomModeRewardTabMixin:COLLECT_SCROLL_OF_FORTUNE_REWARDS_RESULT(result)
    if result ~= "COLLECT_SCROLL_OF_FORTUNE_REWARDS_OK" then
        self.ErrorFrame:SetText(UNABLE_TO_CLAIM_REWARDS, RED_FONT_COLOR:WrapText(_G[result] or result))
        self.ErrorFrame:Show()
    else
        self.Magic:PlaySplash()
    end
    self:UpdateState()
end

function RandomModeRewardTabMixin:COLLECT_HAND_OF_FATE_REWARDS_RESULT(result)
    if result ~= "COLLECT_HAND_OF_FATE_REWARDS_OK" then
        self.ErrorFrame:SetText(UNABLE_TO_CLAIM_REWARDS, RED_FONT_COLOR:WrapText(_G[result] or result))
        self.ErrorFrame:Show()
    else
        self.Magic:PlaySplash()
    end
    self:UpdateState()
end

function RandomModeRewardTabMixin:UpdateGameMode()
    -- wildcard
    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        self.mode = Enum.GameMode.WildCard
        self.LevelingScroll.Label:SetText(SOF_RESETS_IN_PRESTIGE_MODE)
        self.ClaimButton:SetText(SOF_CLAIM)
        self.MainReward.Art:SetAtlas("BoosterSilasArt", Const.TextureKit.UseAtlasSize)
        self.MainReward.Art:SetPoint("CENTER", -16, 12)
        self.MainReward.Art:SetAlpha(0.9)

    -- draft
    elseif C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
        self.mode = Enum.GameMode.Draft
        self.LevelingScroll.Label:SetText(HOF_RESETS_IN_PRESTIGE_MODE)
        self.ClaimButton:SetText(HOF_CLAIM)
        self.MainReward.Art:SetTexture("Interface\\darkmoon\\HoF_Illustration") 
        self.MainReward.Art:SetSize(400, 400)
        self.MainReward.Art:SetPoint("CENTER", 0, -36)
        self.MainReward.Art:SetAlpha(1)
    end
end

function RandomModeRewardTabMixin:GetDisplayItem(specialization)
    return self.visual == "normal" and self.MainItem or self:GetMainItem(specialization)
end

function RandomModeRewardTabMixin:SetNormalModeDisplayItem(specialization, item)
    self.MainItem = item

    if self.mode == Enum.GameMode.WildCard then
        local abilityItem = CostUtil:GetScrollOfFortuneForSpec(specialization)
        local talentItem = CostUtil:GetScrollOfFortuneTalentsForSpec(specialization)
        local abilityPack = ItemData.ABILITY_SEALED_CARD_PACK
        local talentPack = ItemData.TALENT_SEALED_CARD_PACK

        if item == abilityItem then
            self.MainReward.Item.SubText:SetText(SOF_DESCRIPTION)
        elseif item == talentItem then
            self.MainReward.Item.SubText:SetText(SOF_TALENTS_DESCRIPTION)
        elseif item == abilityPack then
            self.MainReward.Item.SubText:SetText(ABILITY_PACK_DESCRIPTION)
        elseif item == talentPack then
            self.MainReward.Item.SubText:SetText(TALENT_PACK_DESCRIPTION)
        end

    elseif self.mode == Enum.GameMode.Draft then
        local abilityItem = CostUtil:GetHandOfFateForSpec(specialization)
        local abilityPack = ItemData.ABILITY_SEALED_CARD_PACK

        if item == abilityItem then
            self.MainReward.Item.SubText:SetText(HOF_DESCRIPTION)
        elseif item == abilityPack then
            self.MainReward.Item.SubText:SetText(ABILITY_PACK_DESCRIPTION)
        end
    end

    self:UpdateState()
end

function RandomModeRewardTabMixin:GetMainItem(specialization)
    if self.mode == Enum.GameMode.WildCard then
        return CostUtil:GetScrollOfFortuneForSpec(specialization)
    elseif self.mode == Enum.GameMode.Draft then
        return CostUtil:GetHandOfFateForSpec(specialization)
    end
end

function RandomModeRewardTabMixin:GetNumClaimableRewards(specialization, leveling)
    if self.mode == Enum.GameMode.WildCard then
        return C_WildcardRewards.GetNumClaimableScrollOfFortuneRewards(specialization, leveling)
    elseif self.mode == Enum.GameMode.Draft then
        return C_DraftRewards.GetNumClaimableScrollOfFortuneRewards(specialization, leveling)
    end
end

function RandomModeRewardTabMixin:GetNumClaimedRewards(specialization, leveling)
    if self.mode == Enum.GameMode.WildCard then
        return C_WildcardRewards.GetNumClaimedScrollOfFortuneRewards(specialization, leveling)
    elseif self.mode == Enum.GameMode.Draft then
        return C_DraftRewards.GetNumClaimedScrollOfFortuneRewards(specialization, leveling)
    end
end

function RandomModeRewardTabMixin:CanClaimRewards(specialization, numRewards, leveling)
    if self.mode == Enum.GameMode.WildCard then
        return C_WildcardRewards.CanClaimScrollOfFortuneRewards(specialization, numRewards, leveling)
    elseif self.mode == Enum.GameMode.Draft then
        return C_DraftRewards.CanClaimScrollOfFortuneRewards(specialization, numRewards, leveling)
    end
end

function RandomModeRewardTabMixin:ClaimReward(specialization, numRewards, leveling)
    if self.mode == Enum.GameMode.WildCard then
        C_WildcardRewards.ClaimScrollOfFortuneRewards(specialization, numRewards, leveling)
    elseif self.mode == Enum.GameMode.Draft then
        C_DraftRewards.ClaimScrollOfFortuneRewards(specialization, numRewards, leveling)
    end
end

function RandomModeRewardTabMixin:GetMarkOfAscensionCost(specialization, numRewards, leveling)
    if self.mode == Enum.GameMode.WildCard then
        return C_WildcardRewards.GetMarkOfAscensionCost(specialization, numRewards, leveling)
    elseif self.mode == Enum.GameMode.Draft then
        return C_DraftRewards.GetMarkOfAscensionCost(specialization, numRewards, leveling)
    end
end

function RandomModeRewardTabMixin:GetRewards(specialization, numRewards, leveling)
    if self.mode == Enum.GameMode.WildCard then
        return C_WildcardRewards.GetRewards(specialization, numRewards, leveling)
    elseif self.mode == Enum.GameMode.Draft then
        return C_DraftRewards.GetRewards(specialization, numRewards, leveling)
    end
end

function RandomModeRewardTabMixin:GetLevelingInfo(specialization)
    if self.mode == Enum.GameMode.WildCard then
        return C_WildcardRewards.GetLevelingInfo(specialization)
    elseif self.mode == Enum.GameMode.Draft then
        return C_DraftRewards.GetLevelingInfo(specialization)
    end
end

function RandomModeRewardTabMixin:GetReleaseInfo(specialization)
    if self.mode == Enum.GameMode.WildCard then
        return C_WildcardRewards.GetScrollOfFortuneRewardsReleaseInfo(specialization)
    elseif self.mode == Enum.GameMode.Draft then
        return C_DraftRewards.GetScrollOfFortuneRewardsReleaseInfo(specialization)
    end
end

function RandomModeRewardTabMixin:UpdateState()
    self:UpdateGameMode()
    local specialization = self:GetParent():GetParent():GetSelectedSpecialization()
    if self.specialization ~= specialization then
        self.MainItem = nil
    end

    self.specialization = specialization

    self.LevelingScroll.Child.RewardPool:ReleaseAll()
    
    local rewards =  self:GetLevelingInfo(self.specialization)
    local numRewards = #rewards
    if self:GetNumClaimedRewards(self.specialization, true) < numRewards then
        self:UpdateLevelingMode(rewards)
    else
        self.claimAmount = 1
        self:UpdateNormalMode()
    end

    local item = self:GetDisplayItem(self.specialization)
    self.MainReward.Item:SetItem(item)
    self.MainReward.Item.Title:SetText(GetItemName(item))
end 

function RandomModeRewardTabMixin:UpdateLevelingMode(rewards)
    self.visual = "leveling"
    self.ClaimButton:SetPoint("BOTTOM", 0, 140)
    self.ClaimButton.UpButton:Hide()
    self.ClaimButton.DownButton:Hide()
    self.LevelingScroll:Show()
    self.MainReward.Item.BigDigits:Hide()
    self.ClaimButton.BonusRewards:Hide()
    self.RewardProgress:Hide()
    self.NextRelease:Hide()
    self:SetScript("OnUpdate", nil)

    if self.mode == Enum.GameMode.WildCard then
        self.MainReward.Item.SubText:SetText(SOF_DESCRIPTION)
    elseif self.mode == Enum.GameMode.Draft then
        self.MainReward.Item.SubText:SetText(HOF_DESCRIPTION)
    end
    
    -- update leveling rewards
    local width = (#rewards + 1) * 100
    self.LevelingScroll.Child:SetWidth(width) -- width of RandomModeLevelingRewardTemplate
    self.numLevelingRewards = #rewards
    local lastReward
    for i = 1, self.numLevelingRewards do
        local reward = rewards[i]
        local button = self.LevelingScroll.Child.RewardPool:Acquire()
        button:SetLevel(reward.Level)
        button:SetRewards(reward.Rewards, reward.IsClaimed)
        if lastReward then
            button:SetPoint("LEFT", lastReward, "RIGHT", 0, 0)
        else
            button:SetPoint("BOTTOMLEFT", 0, 0)
        end
        lastReward = button
        button:Show()
    end

    local button = self.LevelingScroll.Child.RewardPool:Acquire()
    button:SetEndCap()
    button:SetPoint("LEFT", lastReward, "RIGHT", 0, 0)
    button:Show()
    
    -- scroll to the first unclaimed reward
    local scrollMax = width - self.LevelingScroll:GetWidth()
    local numClaimedRewards = self:GetNumClaimedRewards(self.specialization, true)
    local scrollStep = math.clamp(scrollMax / math.max(self.numLevelingRewards - 3, 1) * numClaimedRewards, 0, scrollMax)
    self.LevelingScroll:SetHorizontalScroll(scrollStep)

    self.LevelingScroll.ScrollLeftButton:SetEnabled(not math.NearlyEquals(scrollStep, 0))
    self.LevelingScroll.ScrollRightButton:SetEnabled(not math.NearlyEquals(scrollStep, scrollMax))
    
    local canClaim, reason = self:CanClaimRewards(self.specialization, 1, true)
    self.ClaimButton:SetEnabled(canClaim)
    self.ClaimButton.ErrorText:SetShown(not canClaim)
    self.ClaimButton.ErrorText:SetText(_G[reason] or reason)

    -- Calculate the fill width based on claimed rewards
    local claimRatio = numClaimedRewards / (self.numLevelingRewards + 1)
    local fillWidth = (claimRatio * width) - 50
    fillWidth = math.clamp(fillWidth, 1, width - 10)

    self.LevelingScroll.Child.Fill:SetWidth(fillWidth)
end 

function RandomModeRewardTabMixin:UpdateNormalMode()
    self.visual = "normal"
    self.LevelingScroll:Hide()
    self.ClaimButton.UpButton:Show()
    self.ClaimButton.DownButton:Show()
    self.MainReward.Item.BigDigits:Show()
    self.ClaimButton.BonusRewards:Show()
    self.NextRelease:Show()
    self.RewardProgress:Show()
    self:SetScript("OnUpdate", nil)
    
    self:UpdateCount()
end

function RandomModeRewardTabMixin:SetLevelingScrollValue(currentValue, newValue)
    self.dt = 0
    self:SetScript("OnUpdate", function(self, elapsed)
        local scrollValue = Lerp(currentValue, newValue, self.dt)
        self.dt = self.dt + (elapsed * 10)
        if math.NearlyEquals(scrollValue, newValue) then
            self.LevelingScroll:SetHorizontalScroll(newValue)
            self:SetScript("OnUpdate", nil)
        else
            self.LevelingScroll:SetHorizontalScroll(scrollValue)
        end
    end)
end 

function RandomModeRewardTabMixin:ScrollLevelingRewards(delta)
    local currentScroll = self.LevelingScroll:GetHorizontalScroll()
    local scrollValue = currentScroll
    local scrollMax = self.LevelingScroll:GetHorizontalScrollRange()
    local scrollStep = scrollMax / (self.numLevelingRewards / 4)
    if delta > 0 then
        scrollValue = math.min(scrollValue + scrollStep, scrollMax)
    else
        scrollValue = math.max(scrollValue - scrollStep, 0)
    end
    
    if not math.NearlyEquals(currentScroll, scrollValue) then
        self:SetLevelingScrollValue(currentScroll, scrollValue)
    end
    
    self.LevelingScroll.ScrollLeftButton:SetEnabled(scrollValue > 0)
    self.LevelingScroll.ScrollRightButton:SetEnabled(scrollValue < scrollMax)
end

function RandomModeRewardTabMixin:OnClaimReward()
    local numClaimableLeveling = self:GetNumClaimableRewards(self.specialization, true)
    if numClaimableLeveling > 0 then
        self:ClaimReward(self.specialization, 1, true)
    else
        self:ClaimReward(self.specialization, self.claimAmount, false)
    end
    self.ClaimButton:Disable()
end 

function RandomModeRewardTabMixin:UpdateCount()
    self.ClaimButton:SetPoint("BOTTOM", 0, 80)

    -- update claim button enabled
    local canClaim, reason = self:CanClaimRewards(self.specialization, self.claimAmount, false)
    self.ClaimButton:SetEnabled(canClaim)
    self.ClaimButton.ErrorText:SetShown(not canClaim)
    self.ClaimButton.ErrorText:SetText(_G[reason] or reason)

    -- update claim button text
    local markCost = self:GetMarkOfAscensionCost(self.specialization, self.claimAmount, false)
    markCost = self.MarkOfAscensionItem:GetIconTextureMarkup(14, 0, 0) .. " " .. BreakUpLargeNumbers(markCost) .. " " .. self.MarkOfAscensionItem:GetLink()
    self.ClaimButton:SetText(CLAIM_REWARDS_FOR_S:format(HIGHLIGHT_FONT_COLOR:WrapText(markCost)))

    -- update bonus rewards
    local i = 1
    local displayItem = self:GetDisplayItem(self.specialization)
    for item, count in pairs(self:GetRewards(self.specialization, self.claimAmount, false)) do
        local button = self.ClaimButton.BonusRewards["Reward"..i]
        button:SetItem(item, count)
        button:SetClaimed(false)
        button:Show()
        button:SetScript("OnClick", function()
            self:SetNormalModeDisplayItem(self.specialization, item)
        end)
    
        if item == displayItem then
            self.MainReward.Item.BigDigits:SetValue(count)   
        end

        i = i + 1
        if i > 4 then
            break
        end
    end

    for j = i, 4 do
        self.ClaimButton.BonusRewards["Reward"..j]:Hide()
    end

    self.ClaimButton.BonusRewards:MarkDirty()

    local numClaimed = self:GetNumClaimedRewards(self.specialization, false)
    local numClaimable = self:GetNumClaimableRewards(self.specialization, false)
    local numReleased, maximumReleases, nextReleaseTimeSeconds = self:GetReleaseInfo(self.specialization)
    local totalPendingClaim = numClaimed + self.claimAmount

    self.ClaimButton.UpButton:SetEnabled(self.claimAmount < numClaimable)
    self.ClaimButton.DownButton:SetEnabled(self.claimAmount > 1)

    self.RewardProgress:SetMinMaxValues(0, numReleased)
    self.RewardProgress:SetValue(totalPendingClaim)

    self.RewardProgress.PendingClaimProgress:SetMinMaxValues(0, numReleased)
    self.RewardProgress.PendingClaimProgress:SetValue(numClaimed)

    self.RewardProgress.PendingClaimProgress:SetFormattedText("%s (+%s) / %s", numClaimed, self.claimAmount, numReleased)

    if numReleased < maximumReleases and nextReleaseTimeSeconds and nextReleaseTimeSeconds > 0 and numClaimed >= numReleased then
        self.NextRelease:SetFormattedText(RANDOM_MODE_REWARD_RELEASES_IN_S, SecondsToTime(nextReleaseTimeSeconds))
    else
        self.NextRelease:SetText("")
    end
end

function RandomModeRewardTabMixin:ChangeClaimAmount(amount)
    local maximumClaim = self:GetNumClaimableRewards(self.specialization, false)
    self.claimAmount = math.clamp(self.claimAmount + amount, 1, maximumClaim)
    self:UpdateCount()
end
