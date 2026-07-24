TrialsTabMixin = CreateFromMixins(ChallengesTabMixin)

function TrialsTabMixin:UpdateFilteredChallenges()
	self:SetFilter(Enum.ChallengeFilter.Trial, true)
	self:SetFilter(Enum.ChallengeFilter.DungeonTrial, true)
	self:SetFilter(Enum.ChallengeFilter.Challenge, nil)
	local searchText = self.Search:GetText():trim()
	C_Challenge.SetChallengeFilter(searchText, self.filters)
	self.Challenges:RefreshScrollFrame()
end