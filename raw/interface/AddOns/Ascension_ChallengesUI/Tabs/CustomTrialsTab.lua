local ChallengesUI = select(2, ...)

CustomTrialsTabMixin = CreateFromMixins(ChallengesTabMixin)

function CustomTrialsTabMixin:OnLoad()
	self.template = "CustomTrialItemTemplate"
	ChallengesTabMixin.OnLoad(self)
	self:RegisterEvent("TRIAL_QUERY_RESULT")
	self.Challenges:SetGetNumResultsFunction(C_TrialCreator.GetNumTrials)
end

function CustomTrialsTabMixin:OnShow()
	self.Search:SetText("")
	self:ClearFilters()
	self:UpdateChallengeList()
end

function CustomTrialsTabMixin:TRIAL_QUERY_RESULT()
	self:UpdateFilteredChallenges()
end

function CustomTrialsTabMixin:UpdateChallengeList()
	C_TrialCreator.QueryTrials()
end

function CustomTrialsTabMixin:CanActivateChallenge(trialID)
	return C_TrialCreator.CanActivateTrial(trialID)
end

function CustomTrialsTabMixin:UpdateFilteredChallenges()
	self:SetFilter(Enum.ChallengeFilter.Trial, nil)
	self:SetFilter(Enum.ChallengeFilter.DungeonTrial, nil)
	self:SetFilter(Enum.ChallengeFilter.Challenge, nil)
	local searchText = self.Search:GetText():trim()
	C_TrialCreator.SetTrialFilter(searchText, self.filters)
	self.Challenges:RefreshScrollFrame()
end

function CustomTrialsTabMixin:GetChallengeInfoByIndex(index, isExpanded)
	return C_TrialCreator.GetTrialAtIndex(index, isExpanded)
end

function CustomTrialsTabMixin:GetChallengeIDByIndex(index)
	return C_TrialCreator.GetTrialIDByIndex(index)
end