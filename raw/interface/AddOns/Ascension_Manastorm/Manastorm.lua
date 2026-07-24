ManastormObjectiveTrackerMixin = CreateFromMixins(BossObjectiveTrackerMixin)

function ManastormObjectiveTrackerMixin:OnLoad()
    BossObjectiveTrackerMixin.OnLoad(self)
    
    self:CreateChaoticLinkIcon()
    self:CreateBonusChestIcon()
    
    self:SetTitle(THE_MANASTORM)
    self:SetBackgroundAtlas("manastorm-tracker-bg")
    self:SetGetEncounterFunction(C_Manastorm.GetBoss)
    self:RegisterEvent("ACTIVE_MANASTORM_UPDATED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:Update()
end

function ManastormObjectiveTrackerMixin:OnShow()
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self:RegisterEvent("MANASTORM_CHAOTIC_LINK_UPDATED")
    self:RegisterEvent("MANASTORM_LEVEL_COMPLETED")
    self:RegisterEvent(ManastormUtil.RewardVisibilityUpdatedEvent)
end

function ManastormObjectiveTrackerMixin:OnHide()
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("MANASTORM_CHAOTIC_LINK_UPDATED")
    self:UnregisterEvent("MANASTORM_LEVEL_COMPLETED")
    self:UnregisterEvent(ManastormUtil.RewardVisibilityUpdatedEvent)
    StaticPopup_Hide("LEAVE_THE_MANASTORM_CONFIRM")
    StaticPopup_Hide("LEAVE_THE_MANASTORM_CHECKPOINT_CONFIRM")
end

function ManastormObjectiveTrackerMixin:UpdateChaoticLink()
   local stacks = select(2, C_Manastorm.GetBoss())
    if stacks and stacks > 0 then
        self.ChaoticLink.Text:SetText(stacks)
    else
        self.ChaoticLink.Text:SetText(0)
    end
end

function ManastormObjectiveTrackerMixin:UpdateBonusChest()
    local numCaches, additionalCacheChance, itemID = C_Manastorm.GetManastormCacheInfo()
    local context = ManastormUtil.GetRewardVisibilityContext()
    local action, remainingSeconds = ManastormUtil.GetRewardVisibilityAction(context, itemID)
    local earnedQuantity, maxQuantity = ManastormUtil.GetRewardLimitProgress(context, itemID)
    local locked = action == ManastormUtil.RewardDisplayAction.LockedRateLimitExhausted

    self.BonusChest.itemID = itemID
    self.BonusChest.locked = locked
    self.BonusChest.remainingSeconds = remainingSeconds
    self.BonusChest.earnedQuantity = earnedQuantity
    self.BonusChest.maxQuantity = maxQuantity

    if locked then
        self.BonusChest.Text:SetText(LOCKED)
    elseif numCaches and numCaches > 0 then
        self.BonusChest.Text:SetText(numCaches)
    else
        self.BonusChest.Text:SetFormattedText("%s%%", math.round(additionalCacheChance))
    end

    if earnedQuantity and maxQuantity and maxQuantity > 0 then
        self.BonusChest.ProgressText:SetFormattedText("%d/%d", earnedQuantity, maxQuantity)
        self.BonusChest.ProgressText:Show()
    else
        self.BonusChest.ProgressText:Hide()
    end

    self.BonusChest.Icon:SetDesaturated(locked)
    self.BonusChest.IconBorder:SetDesaturated(locked)
    if locked then
        self.BonusChest.LockedOverlay:Show()
        self.BonusChest.LockedIcon:Show()
    else
        self.BonusChest.LockedOverlay:Hide()
        self.BonusChest.LockedIcon:Hide()
    end
end

function ManastormObjectiveTrackerMixin:Update()
    if not C_Manastorm.IsInManastorm() then
        self:Hide()
        return
    elseif not self:IsShown() then
        self:Show()
    end

    self:SetHeaderText(GetRealZoneText())
    local currentLevel = C_Manastorm.GetActiveLevel()
    self:SetSubText(format(UNIT_LEVEL_TEMPLATE, currentLevel))
    
    -- bottom right text 
    -- reward multi & group size multi
    local bottomRightText
    
    -- reward multi
    local manastormID = C_Manastorm.GetActiveManastormID()
    if not manastormID then
        return C_Logger.Error("ManastormObjectiveTrackerMixin:Update() - manastormID is nil")
    end
    
    local endReward, encounterReward, groupEndReward, groupEncounterReward = C_Manastorm.GetRewardModifier(manastormID)
    local rewardMulti = math.max(endReward or 1, encounterReward or 1)
    if rewardMulti and rewardMulti > 0 then
        rewardMulti = rewardMulti * 100
        if bottomRightText then
            bottomRightText = bottomRightText.."\n"
        else
            bottomRightText = ""
        end
        bottomRightText = bottomRightText..format("|cffffffff%d%%|r "..MANASTORM_REWARD_MULTIPLIER, math.round(rewardMulti))
    end

    local groupRewardMulti = math.max(groupEndReward or 1, groupEncounterReward or 1)
    if groupRewardMulti and groupRewardMulti > 1 then
        groupRewardMulti = (groupRewardMulti - 1) * 100
        if bottomRightText then
            bottomRightText = bottomRightText.."\n"
        else
            bottomRightText = ""
        end
        bottomRightText = bottomRightText..format("|cffffffff%d%%|r "..MANASTORM_GROUP_REWARD_MULTIPLIER, math.round(groupRewardMulti))
    end
    
    self:SetBottomRightText(bottomRightText or "")


    -- bottom left text
    -- xp 
    local bottomLeftText
    local isEndGameLevel = C_Player:GetLevel() >= ManastormUtil.GetEndGamePlayerLevel()
    if not isEndGameLevel then
        local maxLevelInGroup = false
        local endGamePlayerLevel = ManastormUtil.GetEndGamePlayerLevel()
        for unit in GroupUtil.EnumerateGroupMembers() do
            if UnitLevel(unit) >= endGamePlayerLevel then
                maxLevelInGroup = true
                break
            end
        end
        local expModifier = C_Manastorm.GetStageBonusExperience()

        if expModifier then
            expModifier = (expModifier - 1) * 100
            if bottomLeftText then
                bottomLeftText = bottomLeftText.."\n"
            else
                bottomLeftText = ""
            end
            bottomLeftText = format("|cffffffff+%.1f%%|r "..XP, expModifier)
        end
    end
    
    local groupType = C_Manastorm.GetActiveManastormType()
    groupType = groupType and _G[groupType] or groupType
    if bottomLeftText then
        bottomLeftText = bottomLeftText.."\n"
    else
        bottomLeftText = ""
    end
    bottomLeftText = bottomLeftText..groupType
    self:SetBottomLeftText(bottomLeftText)
    
    self:UpdateObjectives()
end

function ManastormObjectiveTrackerMixin:UpdateObjectives()
    BossObjectiveTrackerMixin.UpdateObjectives(self)
    self:UpdateChaoticLink()
    self:UpdateBonusChest()
end

function ManastormObjectiveTrackerMixin:ACTIVE_MANASTORM_UPDATED()
    self:Update()
end

function ManastormObjectiveTrackerMixin:PLAYER_ENTERING_WORLD()
    self:Update()
end

function ManastormObjectiveTrackerMixin:ZONE_CHANGED_NEW_AREA()
    self:SetHeaderText(GetRealZoneText())
end

function ManastormObjectiveTrackerMixin:MANASTORM_CHAOTIC_LINK_UPDATED(oldValue, newValue)
    self:UpdateChaoticLink()
end

function ManastormObjectiveTrackerMixin:MANASTORM_CACHE_INFO_UPDATED(numCaches, chanceForAdditionalCache, itemEntry)
    self:UpdateBonusChest()
end

function ManastormObjectiveTrackerMixin:MANASTORM_LEVEL_COMPLETED()
    self.bossDefeated = true
    self:UpdateObjectives()
end

function ManastormObjectiveTrackerMixin:MANASTORM_REWARD_VISIBILITY_UPDATED()
    self:UpdateBonusChest()
end

function ManastormObjectiveTrackerMixin:CreateChaoticLinkIcon()
    -- create chaotic link indicator
    self.ChaoticLink = CreateFrame("Frame", "$parentChaoticLinkIcon", self.MainBlock)
    self.ChaoticLink:SetSize(16, 16)
    self.ChaoticLink:SetPoint("TOPRIGHT", -14, -8)
    self.ChaoticLink:EnableMouse(true)

    -- chaotic link text
    self.ChaoticLink.Text = self.ChaoticLink:CreateFontString("$parentText", "OVERLAY", "GameFontHighlight")
    self.ChaoticLink.Text:SetPoint("RIGHT", self.ChaoticLink, "LEFT", -4, -1)
    self.ChaoticLink.Text:SetJustifyH("RIGHT")

    -- chaotic link icon
    self.ChaoticLink.Icon = self.ChaoticLink:CreateTexture("$parentIcon", "ARTWORK")
    self.ChaoticLink.Icon:SetSize(12, 12)
    self.ChaoticLink.Icon:SetPoint("CENTER")
    self.ChaoticLink.Icon:SetPortraitTexture("Interface\\icons\\nhi_manaempower_Border")

    self.ChaoticLink.IconBorder = self.ChaoticLink:CreateTexture("$parentIconBorder", "OVERLAY")
    self.ChaoticLink.IconBorder:SetSize(24, 24)
    self.ChaoticLink.IconBorder:SetPoint("CENTER", 0, -2)
    self.ChaoticLink.IconBorder:SetAtlas("honorsystem-bar-rewardborder-circle", Const.TextureKit.IgnoreAtlasSize)

    self.ChaoticLink:SetScript("OnEnter", function(self)
        local encounterID, stacks, healthPct, dmgPct = C_Manastorm.GetBoss()
        local bossName = GetEncounterInfo(encounterID) or "Unknown Encounter"
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(format(MANASTORM_CHAOTIC_LINK, stacks), 1, 1, 1, 1, 1)
        if stacks and stacks > 0 then
            GameTooltip:AddLine(format(MANASTORM_CHAOTIC_LINK_TOOLTIP, bossName, healthPct, dmgPct), 1, 0.82, 0, true)
        else
            GameTooltip:AddLine(format(MANASTORM_CHAOTIC_LINK_NONE_TOOLTIP, bossName), 1, 0.82, 0, true)
        end
        GameTooltip:Show()
    end)

    self.ChaoticLink:SetScript("OnLeave", GameTooltip_Hide)
end

function ManastormObjectiveTrackerMixin:CreateBonusChestIcon()
    -- create chaotic link indicator
    self.BonusChest = CreateFrame("Frame", "$parentBonusChestIcon", self.MainBlock)
    self.BonusChest:SetSize(16, 16)
    self.BonusChest:SetPoint("TOPRIGHT", self.ChaoticLink, "BOTTOMRIGHT", 0, -6)
    self.BonusChest:EnableMouse(true)

    -- chaotic link text
    self.BonusChest.Text = self.BonusChest:CreateFontString("$parentText", "OVERLAY", "GameFontHighlight")
    self.BonusChest.Text:SetPoint("BOTTOMRIGHT", self.BonusChest, "LEFT", -4, -1)
    self.BonusChest.Text:SetJustifyH("RIGHT")

    self.BonusChest.ProgressText = self.BonusChest:CreateFontString("$parentProgressText", "OVERLAY", "GameFontHighlightSmall")
    self.BonusChest.ProgressText:SetPoint("TOPRIGHT", self.BonusChest.Text, "BOTTOMRIGHT", 0, 1)
    self.BonusChest.ProgressText:SetJustifyH("RIGHT")
    self.BonusChest.ProgressText:Hide()

    -- chaotic link icon
    self.BonusChest.Icon = self.BonusChest:CreateTexture("$parentIcon", "ARTWORK")
    self.BonusChest.Icon:SetSize(12, 12)
    self.BonusChest.Icon:SetPoint("CENTER")
    self.BonusChest.Icon:SetPortraitTexture("Interface\\icons\\inv_legion_chest_courtoffarnodis")
    
    self.BonusChest.IconBorder = self.BonusChest:CreateTexture("$parentIconBorder", "OVERLAY")
    self.BonusChest.IconBorder:SetSize(24, 24)
    self.BonusChest.IconBorder:SetPoint("CENTER", 0, -2)
    self.BonusChest.IconBorder:SetAtlas("honorsystem-bar-rewardborder-circle", Const.TextureKit.IgnoreAtlasSize)

    self.BonusChest.LockedOverlay = self.BonusChest:CreateTexture("$parentLockedOverlay", "OVERLAY")
    self.BonusChest.LockedOverlay:SetAllPoints(self.BonusChest.Icon)
    self.BonusChest.LockedOverlay:SetColorTexture(0, 0, 0, 0.55)
    self.BonusChest.LockedOverlay:Hide()

    self.BonusChest.LockedIcon = self.BonusChest:CreateTexture("$parentLockedIcon", "OVERLAY")
    self.BonusChest.LockedIcon:SetSize(14, 14)
    self.BonusChest.LockedIcon:SetPoint("CENTER", self.BonusChest.Icon, "CENTER")
    self.BonusChest.LockedIcon:SetAtlas("Garr_LockedBuilding", Const.TextureKit.IgnoreAtlasSize)
    self.BonusChest.LockedIcon:Hide()

    self.BonusChest:SetScript("OnEnter", function(self)
        local numCaches, additionalCacheChance, itemID = C_Manastorm.GetManastormCacheInfo()
        local item = Item:CreateFromID(itemID)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(MANASTORM_BONUS_CHEST, 1, 1, 1, 1, 1)

        local context = ManastormUtil.GetRewardVisibilityContext()
        local action, remainingSeconds = ManastormUtil.GetRewardVisibilityAction(context, itemID)
        local earnedQuantity, maxQuantity = ManastormUtil.GetRewardLimitProgress(context, itemID)
        if earnedQuantity and maxQuantity and maxQuantity > 0 then
            GameTooltip:AddLine(format("%d/%d", earnedQuantity, maxQuantity), 1, 1, 1, true)
        end

        if action == ManastormUtil.RewardDisplayAction.LockedRateLimitExhausted then
            GameTooltip:AddLine(LOCKED, 1, 0.1, 0.1, true)
            if remainingSeconds and remainingSeconds > 0 then
                GameTooltip:AddLine(COOLDOWN_REMAINING.." "..SecondsToTime(remainingSeconds, false, true, 2), 1, 1, 1, true)
            end
        elseif numCaches and numCaches > 0 then
            GameTooltip:AddLine(format(MANASTORM_BONUS_CHEST_GUARANTEED_TOOLTIP, numCaches, item:GetLink(), math.round(additionalCacheChance)), 1, 0.82, 0, true)
        else
            GameTooltip:AddLine(format(MANASTORM_BONUS_CHEST_TOOLTIP, math.round(additionalCacheChance), item:GetLink()), 1, 0.82, 0, true)
        end
        GameTooltip:Show()
    end)

    self.BonusChest:SetScript("OnLeave", GameTooltip_Hide)
end

--
-- Leave Button
--
ManastormLeaveMixin = {}

function ManastormLeaveMixin:OnLoad()
    self:RegisterEvent("ACTIVE_MANASTORM_UPDATED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_DEAD")
    self:RegisterEvent("PLAYER_ALIVE")
    self:RegisterForDrag("LeftButton")

    self.Background:SetTexture("Interface\\LFGFRAME\\UI-LFG-BACKGROUND-MANASTORM")
    self.Background:SetVertexColor(0.75, 0.75, 0.75, 1)
    self.Text:SetText(MANASTORM_COMPLETE)
    self.LeaveButton:SetText(LEAVE_THE_MANASTORM)
end

function ManastormLeaveMixin:OnHide()
    StaticPopup_Hide("LEAVE_THE_MANASTORM_CONFIRM")
    StaticPopup_Hide("LEAVE_THE_MANASTORM_CHECKPOINT_CONFIRM")
end

function ManastormLeaveMixin:ShouldShow()
    return C_Manastorm.IsInManastorm() and C_Manastorm.GetActiveManastormType() == "SOLO" and C_Player:IsDead()
end

function ManastormLeaveMixin:Update()
    self:SetShown(self:ShouldShow())
end

function ManastormLeaveMixin:ACTIVE_MANASTORM_UPDATED()
    self:Update()
end


function ManastormLeaveMixin:PLAYER_ENTERING_WORLD()
    self:Update()
end

function ManastormLeaveMixin:PLAYER_DEAD()
    self:Update()
end

function ManastormLeaveMixin:OnClick()
    ManastormUtil.ShowLeaveManastormDialog()
end
