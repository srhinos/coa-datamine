local ChallengesUI = select(2, ...)
ChallengesUI.activeChallengesByExclusiveGroup = {}

ChallengesFrameMixin = {}

local function ChallengesEnabled()
	return C_Config.GetBoolConfig("CONFIG_CHALLENGE_ENABLED")
end

local function TrialCreatorEnabled()
	return C_Config.GetBoolConfig("CONFIG_CHALLENGE_CREATOR_ENABLED")
end

local Tabs = {
	{ key = "TrialsTab", check = ChallengesEnabled },
	{ key = "StoreTab" },
	{ key = "ChallengesTab", check = ChallengesEnabled },
	{ key = "CustomTrialsTab", check = TrialCreatorEnabled },
	{ key = "TrialEditorTab", check = TrialCreatorEnabled },
	{ key = "GamemodesTab" },
}

function ChallengesFrameMixin:OnLoad()
	PanelTemplates_SetNumTabs(self, #Tabs)
	self:RegisterForDrag("LeftButton")
	self:SetUserPlaced(false)
	self.Background:SetAtlas("services-popup-bg", Const.TextureKit.IgnoreAtlasSize)
	
	self.NineSlice:SetFrameLevel(self:GetFrameLevel() + 20)
	self.NineSlice.TitleBG:SetAtlas("UI-Frame-Mechagon-Ribbon", Const.TextureKit.IgnoreAtlasSize)
	self.NineSlice.TitleBG:SetVertexColor(0.8, 0.8, 1)
	self.NineSlice.Title:SetText(CHALLENGES)

	self.CloseButton:SetFrameLevel(self:GetFrameLevel() + 25)
	
	self.ErrorInputBlock:SetFrameLevel(self:GetFrameLevel() + 20)
	self.WarningInputBlock:SetFrameLevel(self:GetFrameLevel() + 20)
	
	self:RegisterEvent("CHALLENGE_START_RESPONSE")
	self:RegisterEvent("CHALLENGE_STOP_RESPONSE")
	self:RegisterEvent("CHALLENGE_ACTIVE_LIST_CHANGED")
	self:RegisterEvent("CHALLENGE_COMPLETED_LIST_CHANGED")
	self:RegisterEvent("TRIAL_ACTIVATE_RESULT")
	self:RegisterEvent("TRIAL_DEACTIVATE_RESULT")
	self:RegisterEvent("CHALLENGE_CRITERIA_UPDATED")
	self:RegisterEvent("TRIAL_SAVE_RESULT")
end

function ChallengesFrameMixin:OnTabClick(tabButton)
	PlaySound(SOUNDKIT.CHARACTER_SHEET_TAB)
	self:OpenTab(tabButton:GetID())
end

function ChallengesFrameMixin:OpenTab(index)
	if PanelTemplates_IsTabEnabled(self, index) then
		PanelTemplates_SetTab(self, index)
		for i, tab in ipairs(Tabs) do
			if i == index then
				self[tab.key]:Show()
				self.NineSlice.Title:SetText(self["Tab"..i]:GetText())
			else
				self[tab.key]:Hide()
			end
		end
	else
		local hasSelected = false
		for i, tab in ipairs(Tabs) do
			if PanelTemplates_IsTabEnabled(self, i) and not hasSelected then
				PanelTemplates_SetTab(self, i)
				self[tab.key]:Show()
				self.NineSlice.Title:SetText(self["Tab"..i]:GetText())
				hasSelected = true
			else
				self[tab.key]:Hide()
			end
		end
	end
end

function ChallengesFrameMixin:OnShow()
	UpdateMicroButtons()
	for i, tab in ipairs(Tabs) do
		if tab.check and not tab.check() then
			PanelTemplates_DisableTab(self, i)
		else
			PanelTemplates_EnableTab(self, i)
		end
	end
	
	if not PanelTemplates_GetSelectedTab(self) then
		self:OpenTab(1)
	end
	
	self:RefreshCurrentTab()
	PlaySound(SOUNDKIT.UCHARACTERSHEETOPEN)
end

function ChallengesFrameMixin:OnHide()
	ChallengesUI:ClearEditModeChallengeSelection()
	if self.ErrorInputBlock:IsShown() then
		self.ErrorInputBlock:Hide()
	end
	UpdateMicroButtons()
	PlaySound(SOUNDKIT.CHARACTER_SHEET_CLOSE)
	CloseGossip()
end

function ChallengesFrameMixin:RefreshCurrentTab()
	local index = PanelTemplates_GetSelectedTab(self)
	if index then
		local frame = self[Tabs[index].key]
		if frame and frame.Refresh then frame:Refresh() end
	end
end

function ChallengesFrameMixin:CHALLENGE_START_RESPONSE(challengeID, level, response)
	local responseID = Enum.ChallengeResponse[response]
	if not responseID or responseID ~= Enum.ChallengeResponse.CHALLENGE_START_OK then
		self.ErrorInputBlock:Show()
		response = S_SERVER_ERROR:format(_G[response] or response)
		self.ErrorInputBlock:SetText(CHALLENGES_CANNOT_ACTIVATE, response)
		self.ErrorInputBlock.MoreInfo:SetShown(responseID == Enum.ChallengeResponse.CHALLENGE_START_OUTSIDE_INTERACTION)
	elseif responseID then
		PlaySound(SOUNDKIT.QUEST_ACTIVATE_75, true)
	end
	self:RefreshCurrentTab()
end

function ChallengesFrameMixin:CHALLENGE_STOP_RESPONSE(challengeID, level, response)
	local responseID = Enum.ChallengeStopResponse[response]
	if not responseID or responseID ~= Enum.ChallengeStopResponse.CHALLENGE_STOP_OK then
		self.ErrorInputBlock:Show()
		response = S_SERVER_ERROR:format(_G[response] or response)
		self.ErrorInputBlock:SetText(CHALLENGES_CANNOT_ACTIVATE, response)
	elseif responseID then
		if self:IsShown() then
			PlaySound(SOUNDKIT.QUEST_UPDATE, true)
		end
	end
	self:RefreshCurrentTab()
end

function ChallengesFrameMixin:CHALLENGE_ACTIVE_LIST_CHANGED()
	self:RefreshCurrentTab()
end

function ChallengesFrameMixin:CHALLENGE_COMPLETED_LIST_CHANGED()
	self:RefreshCurrentTab()
end

function ChallengesFrameMixin:CHALLENGE_CRITERIA_UPDATED()
	self:RefreshCurrentTab()
end

function ChallengesFrameMixin:TRIAL_ACTIVATE_RESULT(trialID, response)
	local responseID = Enum.TrialActivateResponse[response]
	if responseID then
		if responseID ~= Enum.TrialActivateResponse.ACTIVATE_TRIAL_OK then
			self.ErrorInputBlock:Show()
			response = S_SERVER_ERROR:format(_G[response] or response)
			self.ErrorInputBlock:SetText(CHALLENGES_CANNOT_ACTIVATE, response)
		else
			PlaySound(SOUNDKIT.QUEST_ACTIVATE_75, true)
		end
	end
	self:RefreshCurrentTab()
end

function ChallengesFrameMixin:TRIAL_DEACTIVATE_RESULT(trialID, response)
	local responseID = Enum.TrialDeactivateResponse[response]
	if responseID then
		if responseID ~= Enum.TrialDeactivateResponse.DEACTIVATE_TRIAL_OK then
			self.ErrorInputBlock:Show()
			response = S_SERVER_ERROR:format(_G[response] or response)
			self.ErrorInputBlock:SetText(CHALLENGES_CANNOT_ACTIVATE, response)
		else
			if self:IsShown() then
				PlaySound(SOUNDKIT.QUEST_UPDATE, true)
			end
		end
	end
	self:RefreshCurrentTab()
end

function ChallengesFrameMixin:TRIAL_SAVE_RESULT(trialID, response)
	local responseID = Enum.TrialSaveResponse[response]
	if responseID then
		if responseID ~= Enum.TrialSaveResponse.SAVE_TRIAL_OK then
			self.ErrorInputBlock:Show()
			response = S_SERVER_ERROR:format(_G[response] or response)
			self.ErrorInputBlock:SetText(CHALLENGES_FAILED_TO_SAVE_TRIAL, response)
		end
	end
	self:RefreshCurrentTab()
end