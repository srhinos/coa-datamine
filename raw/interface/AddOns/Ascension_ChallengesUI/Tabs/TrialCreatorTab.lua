TrialCreatorTabMixin = {}

function TrialCreatorTabMixin:OnShow()
	local savedTrial = ChallengesUISavedTrial
	if savedTrial then
		self.Editor:LoadTrial(savedTrial)
	end
	self:SetScript("OnShow", nil)
end

function TrialCreatorTabMixin:OpenTrial(trial, trialID)
	self.Editor:LoadTrial(trial, trialID)
end

function TrialCreatorTabMixin:OnHide()
	ChallengesUISavedTrial = self.Editor:ToTable()
end