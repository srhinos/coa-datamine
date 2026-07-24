local ChallengesUI = select(2, ...)

EditableTrialMixin = {}

function EditableTrialMixin:OnLoad()
	self.challenges = {}
	self.Icon:SetBorderAtlas("item-border-gold")
	self.Icon:SetBorderSize(78, 78)
	
	self.Icon.IconSelector:RegisterCallback("IconSelected", function(_, icon)
		self.Icon:SetIcon(icon)
		self:UpdatePublishButton()
	end)

	self.Challenges:SetTemplate("ChallengeItemTemplate")
	self.Challenges:SetGetNumResultsFunction(function() return #self.challenges end)
	self.Challenges.Divider:SetAtlas("activities-divider", Const.TextureKit.IgnoreAtlasSize)
	local highlight = self.Challenges:GetSelectedHighlight()
	highlight:SetTexture() -- disable

	self.AddChallengeButton:SetFrameLevel(self.Challenges:GetFrameLevel() + 1)
	
	self.Challenges:SetRefreshCallback(function()
		if #self.challenges == 0 then
			self.Challenges.NoChallenges:Show()
			self.AddChallengeButton:ClearAndSetPoint("TOP", self.Challenges.NoChallenges, "BOTTOM", 0, -10)
		else
			self.Challenges.NoChallenges:Hide()
			self.AddChallengeButton:ClearAndSetPoint("RIGHT", self, "RIGHT", -12, 34)
		end
		self.AddChallengeButton:SetEnabled(not self.trialID or self.trialID == "")
		self:UpdatePublishButton()
	end)
	
	self:Reset()
end

function EditableTrialMixin:Reset()
	wipe(self.challenges)
	self.trialID = nil
	self:HideEditElement()
	self.Icon:SetIcon("Interface\\Icons\\INV_Misc_QuestionMark")
	self.Title:SetText(NEW_CUSTOM_TRIAL)
	self.About:SetText(CLICK_TO_SET_DESCRIPTION)
	self.Challenges:RefreshScrollFrame()
	self:UpdatePublishButton()
end

function EditableTrialMixin:Publish()
	--Script::ExtractInput(L, id, title, description, icon, challenges, challengeDescriptions)
	local trial = self:ToTable()
	local function PublishTrial()
		local challengeIDs = {}
		local challengeLevels = {}
		local challengeDescriptions = {}

		for _, challengeInfo in ipairs(trial.challenges) do
			tinsert(challengeIDs, challengeInfo[1])
			tinsert(challengeLevels, challengeInfo[2])
			tinsert(challengeDescriptions, challengeInfo[3] or "")
		end
		C_TrialCreator.SaveTrial(self.trialID or "", trial.title, trial.about, trial.icon, challengeIDs, challengeLevels, challengeDescriptions)
		ChallengesUISavedTrial = nil
		self:Reset()
	end
	StaticPopup_Show("CHALLENGES_EDITOR_PUBLISH_CONFIRM", trial.title, nil, PublishTrial)
end

function EditableTrialMixin:CanSaveTrial()
	local trial = self:ToTable()
	local challengeIDs = {}
	local challengeLevels = {}
	local challengeDescriptions = {}

	for _, challengeInfo in ipairs(trial.challenges) do
		tinsert(challengeIDs, challengeInfo[1])
		tinsert(challengeLevels, challengeInfo[2])
		tinsert(challengeDescriptions, challengeInfo[3] or "")
	end

	return C_TrialCreator.CanSaveTrial(self.trialID or "", trial.title, trial.about, trial.icon, challengeIDs, challengeLevels, challengeDescriptions)
end

function EditableTrialMixin:UpdatePublishButton()
	if #self.challenges == 0 then
		self.PublishButton:Disable()
		self.PublishButton.disabledReason = "CHALLENGES_EDITOR_NO_CHALLENGES"
		return
	end

	local titleText = self.Title:GetText()

	if titleText == NEW_CUSTOM_TRIAL then
		self.PublishButton:Disable()
		self.PublishButton.disabledReason = "CHALLENGES_EDITOR_TITLE_NO_TITLE"
		return
	end

	local titleLen = titleText:len()

	if titleLen > 64 then
		self.PublishButton:Disable()
		self.PublishButton.disabledReason = "CHALLENGES_EDITOR_TITLE_TOO_LONG"
		return
	end

	if titleLen < 3 then
		self.PublishButton:Disable()
		self.PublishButton.disabledReason = "CHALLENGES_EDITOR_TITLE_TOO_SHORT"
		return
	end

	local aboutText = self.About:GetText()

	if aboutText == CLICK_TO_SET_DESCRIPTION then
		self.PublishButton:Disable()
		self.PublishButton.disabledReason = "CHALLENGES_EDITOR_TITLE_NO_ABOUT"
		return
	end

	local aboutLen = aboutText:len()
	if aboutLen > 1024 then
		self.PublishButton:Disable()
		self.PublishButton.disabledReason = "CHALLENGES_EDITOR_ABOUT_TOO_LONG"
		return
	end

	if aboutLen < 3 then
		self.PublishButton:Disable()
		self.PublishButton.disabledReason = "CHALLENGES_EDITOR_ABOUT_TOO_SHORT"
		return
	end

	if self.Icon:GetIcon():lower() == "interface\\icons\\inv_misc_questionmark" then
		self.PublishButton:Disable()
		self.PublishButton.disabledReason = "CHALLENGES_EDITOR_NO_ICON"
		return
	end
	
	local canSave, reason = self:CanSaveTrial()

	if not canSave then
		self.PublishButton:Disable()
		self.PublishButton.disabledReason = reason
		return
	end
	
	self.PublishButton:Enable()
	self.PublishButton.disabledReason = nil
end

function EditableTrialMixin:LoadTrial(trial, trialID)
	self:Reset()
	self.trialID = trialID
	self.Title:SetText(trial.title)
	self.About:SetText(trial.about)
	self.Icon:SetIcon(trial.icon)
	for _, savedChallenge in ipairs(trial.challenges) do
		local challenge = C_Challenge.GetChallengeInfo(savedChallenge[1])
		if challenge then
			challenge.desiredLevel = savedChallenge[2]
			tinsert(self.challenges, challenge)
		end
	end
	
	self.Challenges:RefreshScrollFrame()
end

function EditableTrialMixin:ToTable()
	local challenges = {}
	for _, challenge in ipairs(self.challenges) do
		tinsert(challenges, {challenge.ID, challenge.desiredLevel})
	end
	return {
		title = self.Title:GetText(),
		about = self.About:GetText(),
		icon = self.Icon:GetIcon(),
		challenges = challenges,
	}
end

function EditableTrialMixin:OnShow()
	self.Challenges:RefreshScrollFrame()
end

function EditableTrialMixin:GetChallengeInfoByIndex(index)
	return self.challenges[index]
end

function EditableTrialMixin:IsChallengeExclusiveGroupTaken()
	return false
end

function EditableTrialMixin:IsPartOfCustomChallenge()
	return true
end

function EditableTrialMixin:CanRemoveFromCustomChallenge()
	return self.trialID == nil or self.trialID == ""
end

function EditableTrialMixin:OnHide()
	self:HideEditElement()
end

function EditableTrialMixin:SetEditElement(element)
	if self.editElement then
		self.editElement:HideEditMode()
	end
	
	self.editElement = element
	self.editElement:ShowEditMode()
	self.editElement:HideOverlay()
end

function EditableTrialMixin:HideEditModeIfElement(element)
	if self.editElement == element then
		self.editElement:HideEditMode()
		self.editElement = nil
		self:UpdatePublishButton()
	end
end

function EditableTrialMixin:HideEditElement()
	if self.editElement then
		self.editElement:HideEditMode()
		self.editElement = nil
		self:UpdatePublishButton()
	end
end 

function EditableTrialMixin:StartSelectingChallenge()
	ChallengesUI.SelectingChallenge = self
	ChallengesFrame:OpenTab(3)
	ChallengesFrame.ChallengesTab:ClearFilters()
end

function EditableTrialMixin:StopSelectingChallenge()
	ChallengesUI.SelectingChallenge = nil
end

function EditableTrialMixin:AddChallenge(challengeItem)
	local challenge = C_Challenge.GetChallengeInfo(challengeItem.challenge.ID)
	if not challenge then return end
	challenge.desiredLevel = challengeItem:GetSelectedLevel()
	tinsert(self.challenges, challenge)
	if self:IsShown() then
		self.Challenges:RefreshScrollFrame()
	end
end

function EditableTrialMixin:RemoveChallenge(challenge)
	table.RemoveItem(self.challenges, challenge)
	if self:IsShown() then
		self.Challenges:RefreshScrollFrame()
	end
end

function ChallengesUI:EditModeChallengeSelected(challengeItem)
	if ChallengesUI.SelectingChallenge then
		ChallengesUI.SelectingChallenge:AddChallenge(challengeItem)
		ChallengesUI.SelectingChallenge:StopSelectingChallenge()
		ChallengesFrame:OpenTab(4)
	end
end

function ChallengesUI:IsSelectingChallenge()
	return ChallengesUI.SelectingChallenge ~= nil
end

function ChallengesUI:ClearEditModeChallengeSelection()
	if ChallengesUI.SelectingChallenge then
		ChallengesUI.SelectingChallenge:StopSelectingChallenge()
	end
end

function ChallengesUI:CheckEditModeChallengeExclusiveGroup(otherChallenge)
	if not ChallengesUI.SelectingChallenge then return false end
	
	for _, challenge in ipairs(ChallengesUI.SelectingChallenge.challenges) do
		if challenge.ID == otherChallenge.ID or otherChallenge.ExclusiveGroup ~= 0 and challenge.ExclusiveGroup == otherChallenge.ExclusiveGroup then
			return challenge.ID
		end
	end
	
	return false
end