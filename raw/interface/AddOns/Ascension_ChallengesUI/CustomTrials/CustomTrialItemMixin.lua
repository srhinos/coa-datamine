CustomTrialItemMixin = CreateFromMixins(ChallengeItemMixin)

function CustomTrialItemMixin:GetChallengeLevels()
	return 0, 0, 0
end

function CustomTrialItemMixin:GetChallengeInfoByLevel()
	return self.challenge
end

function CustomTrialItemMixin:CanActivateChallenge()
	return C_TrialCreator.CanActivateTrial(self.challenge.ID)
end

function CustomTrialItemMixin:CanDeactivateChallenge()
	return C_TrialCreator.CanDeactivateTrial()
end

function CustomTrialItemMixin:IsChallengeActive()
	return C_TrialCreator.GetActiveTrial() == self.challenge.ID
end

function CustomTrialItemMixin:StartChallenge()
	return C_TrialCreator.ActivateTrial(self.challenge.ID)
end

function CustomTrialItemMixin:StopChallenge()
	return C_TrialCreator.DeactivateTrial()
end

function CustomTrialItemMixin:ShowLevelSelection()
	return false
end

function CustomTrialItemMixin:IsPlayerMade()
	return true
end

function CustomTrialItemMixin:EditTrial()
	local challenges = {}

	for _, challenge in ipairs(self.challenge.Challenges) do
		tinsert(challenges, {challenge.ChallengeId, challenge.Level})
	end

	local trialInfo = C_TrialCreator.GetTrialInfo(self.challenge.ID)
	if not trialInfo then return end

	local trial = {
		title = trialInfo.Title,
		about = trialInfo.Description,
		icon = trialInfo.Icon,
		challenges = challenges,
	}

	ChallengesFrame:OpenTab(4)
	ChallengesFrame.TrialEditorTab:OpenTrial(trial, self.challenge.ID)
end

function CustomTrialItemMixin:DeleteTrial()
	local function deleteTrial()
		C_TrialCreator.DeleteTrial(self.challenge.ID)
		C_TrialCreator.QueryTrials()
	end
	StaticPopup_Show("DELETE_CUSTOM_TRIAL_CONFIRM", self.challenge.Name, nil, deleteTrial)
end

function CustomTrialItemMixin:UpdateScore()
	-- update score info
	local trial = C_TrialCreator.GetTrialInfo(self.challenge.ID)
	self.challenge.Upvoted = trial.Upvoted
	self.challenge.Downvoted = trial.Downvoted
	self.challenge.Score = trial.Score

	self.ExtendedInfo.TabContent.UpvoteButton:SetChecked(self.challenge.Upvoted)
	self.ExtendedInfo.TabContent.DownvoteButton:SetChecked(self.challenge.Downvoted)
	self.ExtendedInfo.TabContent.Score:SetFormattedText(CUSTOM_TRIAL_RATING, self.challenge.Score)
end

function CustomTrialItemMixin:UpdateExtendedTab()
	local tabContent = self.ExtendedInfo.TabContent
	self:UpdateScore()
	for i = 1, 5 do
		local tab = self.ExtendedInfo["Tab"..i]
		if i == self.challenge.extendedTab then
			tab:LockHighlight()
			tab:SetButtonState("PUSHED", 1)
		else
			tab:UnlockHighlight()
			tab:SetButtonState("NORMAL")
		end
	end

	local canEdit = C_TrialCreator.CanEditTrial(self.challenge.ID)
	local canDelete = canEdit or C_Player:IsGM()

	self.ExtendedInfo.EditButton:SetShown(canEdit)

	self.ExtendedInfo.DeleteButton:SetShown(canDelete)
	tabContent.UpvoteButton:SetShown(not canDelete)
	tabContent.DownvoteButton:SetShown(not canDelete)
	if canDelete then
		tabContent.Score:SetPointOffset(0, -10)
	else
		tabContent.Score:ResetPointsOffset()
	end

	if C_Player:IsGM() and not canEdit then
		self.ExtendedInfo.DeleteButton:SetText("(GM)"..DELETE_TRIAL)
	else
		self.ExtendedInfo.DeleteButton:SetText(DELETE_TRIAL)
	end

	if self:GetExpandedTab() == 1 then
		return tabContent:ShowAboutTab(self.description)
	elseif self:GetExpandedTab() == 2 then
		return tabContent:ShowLeaderboard(self.challenge.ID)
	elseif self:GetExpandedTab() == 3 then
		return tabContent:ShowAurasTab(self.detailedChallenge.Spells, self.detailedChallenge.Modifiers)
	elseif self:GetExpandedTab() == 4 then
		return tabContent:ShowRestrictionsTab(self.detailedChallenge.Rules)
	elseif self:GetExpandedTab() == 5 then
		return tabContent:ShowRequirementsTab(self.detailedChallenge.Conditions)
	elseif self:GetExpandedTab() == 6 then
		return tabContent:ShowChallengesTab(self.challenge.Challenges)
	end
end

function CustomTrialItemMixin:Upvote(upvote)
	upvote = toboolean(upvote)
	C_TrialCreator.RateTrial(self.challenge.ID, upvote, false)
	self:UpdateScore()
end

function CustomTrialItemMixin:Downvote(downvote)
	downvote = toboolean(downvote)
	C_TrialCreator.RateTrial(self.challenge.ID, false, downvote)
	self:UpdateScore()
end