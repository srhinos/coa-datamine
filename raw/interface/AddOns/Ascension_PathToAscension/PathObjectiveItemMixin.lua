PathObjectiveItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function PathObjectiveItemMixin:OnLoad()
    self.Icon.MentorRequirement:SetAtlas("newplayerhelp-guide", Const.TextureKit.IgnoreAtlasSize)
    local frameLevel = self:GetFrameLevel()
    self.NewIcon:SetFrameLevel(frameLevel+4)
    
    self.Icon:SetRounded(true)
    self.Icon:SetBorderSize(95*0.7, 90*0.7)
    self.Icon:SetBorderAtlas("pta-icon-border")
    self.Icon:SetBorderOffset(-1.5, -5)
end

function PathObjectiveItemMixin:OnShow()
    self:RegisterEvent("CRITERIA_UPDATE")
    self:RegisterEvent("TUTORIAL_ENTRY_UPDATE")
    self:RegisterEvent("QUEST_LOG_UPDATE")
end

function PathObjectiveItemMixin:OnHide()
    self:UnregisterEvent("CRITERIA_UPDATE")
    self:UnregisterEvent("TUTORIAL_ENTRY_UPDATE")
    self:UnregisterEvent("QUEST_LOG_UPDATE")
end

function PathObjectiveItemMixin:OnEvent()
    self:Update()
end

function PathObjectiveItemMixin:OnMouseDown()
    self.Pushed:Show()
    self.Normal:Hide()
    self.Title:SetPoint("LEFT", 54, -1)
end

function PathObjectiveItemMixin:OnMouseUp()
    self.Pushed:Hide()
    self.Normal:Show()
    self.Title:SetPoint("LEFT", 56, 0)
end

function PathObjectiveItemMixin:Update()
    self.tutorialID, self.name, self.questID, self.suggestedLevel, self.icon, self.achievementID, self.hint = C_Tutorial.GetTutorialAtIndex(self.index)
    self.isAvailable, self.notAvailableReason = C_Tutorial.IsTutorialAvailable(self.tutorialID)
    self.isMentorTutorial = C_Tutorial.IsTutorialRequiredForMentorStatus(self.tutorialID)
    
    local isSelected = self:GetScrollList():GetSelectedIndex() == self.index

    self.Selected:SetShown(isSelected and self.isAvailable)

    if isSelected and self.isAvailable then
        self.Title:SetVertexColor(1, 1, 1, 1)
    elseif self.isAvailable then
        self.Title:SetVertexColor(1, 0.82, 0, 1)
    else
        self.Title:SetVertexColor(0.5, 0.5, 0.5, 1)
    end

    if not PTA_TUTORIALS_SEEN[self.tutorialID] and self.isAvailable then
        self.NewIcon:Show()
    else
        self.NewIcon:Hide()
    end

    if self.icon then
        self.Icon:SetIcon("Interface\\Icons\\"..self.icon)
        self.Icon:SetIconColor(1, 1, 1, 1)
        self.Icon:Show()
    else
        self.Icon:Hide()
    end

    if self.questID and self.isAvailable then
        if QuestUtil.IsOnQuestID(self.questID) then
            self.Icon.QuestIcon.Texture:SetAtlas("questturnin", Const.TextureKit.IgnoreAtlasSize)
        elseif not QuestUtil.IsQuestTurnedIn(self.questID) then
            self.Icon.QuestIcon.Texture:SetAtlas("questnormal", Const.TextureKit.IgnoreAtlasSize)
        else
            self.Icon.QuestIcon.Texture:SetTexture(nil)
        end
    else
        self.Icon.QuestIcon.Texture:SetTexture(nil)
    end
    
    self.rewards = C_Tutorial.GetRewards(self.tutorialID)

    if C_Tutorial.IsTutorialComplete(self.tutorialID) and self.isAvailable then
        self.Icon.MentorRequirement:Hide()
        self:SetComplete()
    else
        self.Icon.MentorRequirement:SetShown(self.isMentorTutorial)
        self:SetIncomplete()
    end
    
    self:UpdateTitle()

    if self.isAvailable then
        self:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
        self.Icon:SetBorderColor(1, 1, 1, 1)
        self.Icon.MentorRequirement:SetVertexColor(1, 1, 1, 1)
    else
        self:GetNormalTexture():SetVertexColor(0.5, 0.5, 0.5, 1)
        self.Icon:SetIconColor(0.5, 0.5, 0.5, 1)
        self.Icon:SetBorderColor(0.5, 0.5, 0.5, 1)
        self.Icon.MentorRequirement:SetVertexColor(0.5, 0.5, 0.5, 1)
    end

    if GameTooltip:IsOwned(self) then
        if self.isAvailable then
            self:OnEnter()
        else
            self:OnLeave()
        end
    end
end

function PathObjectiveItemMixin:SetComplete()
    --self.Level:Hide()
    self.Icon.QuestIcon:Hide()
    --self.LevelSubText:Hide()
    --self.CompleteIcon:Show()
    --self.CompleteIcon:SetDesaturated(false)
    --self.CompleteIcon:SetAlpha(1)
    --self.Background:SetVertexColor(1, 0.92, 0.4, 1)

    self.Icon:SetIconColor(0.3, 0.3, 0.3, 1)
    self.Icon.CheckedTexture:Show()

    if C_Tutorial.IsRewardCollected(self.tutorialID) then
        -- collected reward
        PTA_TUTORIALS_SEEN[self.tutorialID] = true
        self.NewIcon:Hide() -- incase they've already collected just never show this again
        self.Title:SetWidth(314)
        self.Reward:Hide()
        --self.Overlay:Show()
    else
        -- hasnt collected reward
        local hasRewards = self.rewards ~= nil
        self.Reward:SetShown(hasRewards)
        self.Reward.BgRing:Show()
        --self.Reward.ClaimIcon:Show()
        --self.Overlay:Hide()
        self.Reward:Enable()
    end
end

function PathObjectiveItemMixin:SetIncomplete()
    --self.Background:SetVertexColor(1, 1, 1, 1)

    self.Icon:SetIconColor(1, 1, 1, 1)
    self.Icon.QuestIcon:Show()
    self.Icon.CheckedTexture:Hide()

    --self.Overlay:Hide()
    --[[if self.suggestedLevel and self.suggestedLevel > 0 then
        self.Level:Show()
        self.LevelSubText:Show()
        self.CompleteIcon:Hide()
        self.Level:SetText(self.suggestedLevel)
    else
        self.Level:Hide()
        self.LevelSubText:Hide()
        self.CompleteIcon:Show()
        self.CompleteIcon:SetDesaturated(true)
        self.CompleteIcon:SetAlpha(0.2)
    end]]--

    local hasRewards = self.rewards ~= nil and self.isAvailable
    self.Reward:SetShown(hasRewards)
    self.Reward.BgRing:Hide()
    --self.Reward.ClaimIcon:Hide()
    self.Reward:Disable()
end

function PathObjectiveItemMixin:UpdateTitle()
    local hasRewards = self.rewards ~= nil
    local titleWidth = hasRewards and 192 or 128
    self.Title:SetWidth(titleWidth)
    if self.isAvailable then
        self.Title:SetText(self.name)
    else
        self.Title:SetText("????")
    end
    --self.Title:FitToWidth(16, titleWidth)
end

function PathObjectiveItemMixin:OnSelected()
    if IsControlKeyDown() and C_Player:IsGM() then
        SendChatMessage(".achievement add achievement "..UnitName("player").." "..self.achievementID)
        return
    end

    if not self.isAvailable then
        return
    end

    PTA_TUTORIALS_SEEN[self.tutorialID] = true
    self.NewIcon:Hide()
    
    self:GetScrollList():GetParent().Display:SetTutorial(self.tutorialID)
end 

function PathObjectiveItemMixin:PreClick()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
end

function PathObjectiveItemMixin:OnRewardEnter()
    if self.rewards then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(REWARDS, HIGHLIGHT_FONT_COLOR:GetRGB())
        if C_Tutorial.CanCollectReward(self.tutorialID) then
            GameTooltip:AddLine(CAN_COLLECT_REWARD, GREEN_FONT_COLOR:GetRGB())
        elseif not C_Tutorial.IsTutorialComplete(self.tutorialID) then
            GameTooltip:AddLine(COMPLETE_TUTORIAL_FOR_REWARDS, BRIGHTBLUE_FONT_COLOR:GetRGB())
        end

        for itemID, count in pairs(self.rewards) do
            local item = Item:CreateFromID(itemID)
            local link = item:GetIconLink()
            GameTooltip:AddLine(link.." x"..count, HIGHLIGHT_FONT_COLOR:GetRGB())
        end

        GameTooltip:Show()
    end
end 

function PathObjectiveItemMixin:OnEnter()
    self.Highlight:Show()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if not self.isAvailable then
        GameTooltip:SetText("????", HIGHLIGHT_FONT_COLOR:GetRGB())
    else
        GameTooltip:SetText(self.name, HIGHLIGHT_FONT_COLOR:GetRGB())
    end

    if self.hint and self.hint ~= "" then
        GameTooltip:AddLine(self.hint, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end

    if self.isMentorTutorial then
        GameTooltip:AddLine(TUTORIAL_UNLOCKS_MENTOR, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, true)
    end

    if C_Player:IsGM() then
        if not self.isAvailable then
            if self.notAvailableReason then
                GameTooltip_AddIDLine(GameTooltip, "Unavailable Reason", self.notAvailableReason)
            end
            GameTooltip_AddIDLine(GameTooltip, "Tutorial Name", self.name)
        end

        GameTooltip_AddIDLine(GameTooltip, "Tutorial ID", self.tutorialID)
        if self.questID then
            GameTooltip_AddIDLine(GameTooltip, "Quest ID", self.questID)
        end
        if self.suggestedLevel then
            GameTooltip_AddIDLine(GameTooltip, "Suggested Level", self.suggestedLevel)
        end
        if self.achievementID then
            GameTooltip_AddIDLine(GameTooltip, "Achievement ID", self.achievementID)
            local numCriteria = GetAchievementNumCriteria(self.achievementID)
            for i = 1, numCriteria do
                local name, _, _, _, _, _, _, _, _, criteriaID = GetAchievementCriteriaInfo(self.achievementID, i)
                GameTooltip_AddIDLine(GameTooltip, "  " .. i .. ". CriteriaID", criteriaID)
            end
        end
        for _, objectiveID in ipairs(C_Tutorial.GetObjectives(self.tutorialID)) do
            GameTooltip_AddIDLine(GameTooltip, "Objective ID", objectiveID)
        end
    end
    GameTooltip:Show()
end 

function PathObjectiveItemMixin:OnLeave()
    self.Highlight:Hide()
    GameTooltip:Hide()
end 

function PathObjectiveItemMixin:OnRewardClick()
    if C_Tutorial.IsRewardCollected(self.tutorialID) then
        return
    end

    if C_Tutorial.IsTutorialComplete(self.tutorialID) then
        if C_Tutorial.CanCollectReward(self.tutorialID) then
            C_Tutorial.CollectReward(self.tutorialID)
        end
        return
    end
end 