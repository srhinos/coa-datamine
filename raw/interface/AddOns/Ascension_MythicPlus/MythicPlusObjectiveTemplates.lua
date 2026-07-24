--
-- Base Text Objective
--
MythicPlusObjectiveMixin = CreateFromMixins(ScenarioObjectiveMixin)

function MythicPlusObjectiveMixin:SetLabel(label)
	self.Label = label
	if self.CompletedTime then
		self.Text:SetFormattedText("%s (%s)", label, self.CompletedTime)
	else
		self.Text:SetText(label)
	end
end

function MythicPlusObjectiveMixin:SetProgress(progress)
	if ScenarioObjectiveMixin.SetProgress(self, progress) then
		self.progress = progress
		if self.progressMax then
			if self.progress >= self.progressMax then
				local timeLeft, totalTime = C_MythicPlus.GetActiveKeystoneTime()
				self.CompletedTime = SecondsToClock(totalTime - timeLeft)
			end
		else
			self.CompletedTime = nil
		end
	end
end

--
-- Status Bar Objective
--
MythicPlusStatusBarObjectiveMixin = CreateFromMixins(ScenarioStatusBarObjectiveMixin)

function MythicPlusStatusBarObjectiveMixin:SetProgress(progress)
	if ScenarioStatusBarObjectiveMixin.SetProgress(self, progress) then
		self.progress = progress
		if self.progressMax then
			if self.progress >= self.progressMax then
				local timeLeft, totalTime = C_MythicPlus.GetActiveKeystoneTime()
				self.CompletedTime = SecondsToClock(totalTime - timeLeft)
			end
		else
			self.CompletedTime = nil
		end
	end
end

--
-- Expandable Objective
--
MythicPlusExpandableObjectiveMixin = CreateFromMixins(ScenarioExpandableObjectiveMixin)