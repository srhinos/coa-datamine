CustomTrialExtendedInfoMixin = CreateFromMixins(ChallengeExtendedInfoMixin)

function CustomTrialExtendedInfoMixin:ShowChallengesTab(challenges)
	self:ReleasePools()
	self:SetSubText(CHALLENGES)
	self.data = challenges
	self.type = "challenges"
	self:ShowInfoScroll()
	self:RefreshScroll()
end

function CustomTrialExtendedInfoMixin:SetChallengeScrollItem(data, scrollItem)
	local challenge = C_Challenge.GetChallengeInfo(data.ChallengeId)
	if challenge then
		scrollItem:SetFormattedText("%s (%s)", challenge.Name, data.Level)
		scrollItem.tooltipTitle = format("%s (%s)", challenge.Name, data.Level)
		scrollItem.tooltipText = challenge.Description
	else
		scrollItem:SetText(data.ChallengeId)
		scrollItem.tooltipTitle = data.ChallengeId
		scrollItem.tooltipText = UNKNOWN
	end

	scrollItem:GetFontString():SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
end

function CustomTrialExtendedInfoMixin:SetScrollItem(index, scrollItem)
	if not ChallengeExtendedInfoMixin.SetScrollItem(self, index, scrollItem) then
		local data = self.data[index]
		if self.type == "challenges" then
			self:SetChallengeScrollItem(data, scrollItem)
			return true
		end
	end
end