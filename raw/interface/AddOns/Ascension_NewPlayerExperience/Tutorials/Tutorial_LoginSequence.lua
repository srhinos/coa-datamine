local _, NPE = ...

TALKTONPCHINT = TALKTONPCHINT or "|cffffd100Talk|r to %s"

local areaTutorialByQuestID = {
	-- structure: [questID] = areaTutorialName,
}

local killTutorialByQuestID = {
	-- structure: [questID] = areaTutorialName,
}

local TalkToNPCPopupKey = "TalkToNPCPopupKey"

local TalkToNPCDialog = {
    key = TalkToNPCPopupKey,
    input = "RightButton",
    priority = NPE.Const.PopupPriority.LOW,
}

local PopupComplete = {
    text = NPE_KEEP_DOING_QUESTS or "Keep doing quests to gain experience to |cffFFFF00level up|r!",
    iconAtlas = "NPE_ExclamationPoint",
    okButton = true,
    priority = NPE.Const.PopupPriority.MEDIUM,
}

local PopupSuperTracker = {
	key = TalkToNPCPopupKey,
    text = NPE_FOLLOW_THE_SUPERTRACKER or "Follow the |cffFFFF00Tracker|r icon on your screen to get to the area of objectives.",
    iconAtlas = "Navigation-Tracked-Icon",
    iconWidth = 23*1.6,
	iconHeight = 35*1.6,
    okButton = true,
    fontSize = 13,
    priority = NPE.Const.PopupPriority.MEDIUM,
}

local function ShowTalkToNPCPopup(text, unit, fontSize, atlas)
	NPE:ClearDialogPopup(TalkToNPCPopupKey)
	TalkToNPCDialog.text = text
	TalkToNPCDialog.unit = unit
	TalkToNPCDialog.fontSize = fontSize or 16
	NPE:ShowDialogPopup(TalkToNPCDialog)
end
--
-- Area Controller 
-- responsible for highlighting gossip buttons when out of quest
-- for npc pop ups when out of quest
--
local StartingAreaTutorialMixin = {}

function StartingAreaTutorialMixin:OnLoad()
    self:SetMinMaxLevel(1, 10)
    self:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)
    self:RegisterCallback("TutorialStarted", self.Started, self)
    self:RegisterCallback("TutorialCompleted", self.Completed, self)
    self:RegisterCallback("TutorialStopped", self.Stopped, self)
    self.additionalHooks = {}
end

function StartingAreaTutorialMixin:CheckNPCPopUps()
	-- first of all make sure we're checking up to date quests. Kinda dirty but will work
	local quest1Tutorial = NPE:GetTutorialByName(NPE.Const.Tutorials.STARTING_QUEST_1)

	if quest1Tutorial and quest1Tutorial.questsQueryLoadedHandle then -- quests are not loaded yet, hook to loading event
		quest1Tutorial:RegisterCallback("QuestsQueried", function() 
			dprint(self:GetName().." QuestsQueried triggered")
			StartingAreaTutorialMixin.CheckNPCPopUps(self)
			quest1Tutorial:UnregisterCallback("QuestsQueried", quest1Tutorial)
		end, quest1Tutorial)

		return
	end

	local questIDs = self:GetQuestIDs()

	for i = 1, #questIDs do
		local tutorial = NPE:GetTutorialByName(NPE.Const.Tutorials["STARTING_QUEST_"..i])
		local questID = questIDs[i]

		dprint("StartingAreaTutorialMixin:CheckNPCPopUps: checking starting tutorial "..i)

		if not tutorial then
			dprint("StartingAreaTutorialMixin:CheckNPCPopUps: tutorial "..i.." does not exist")
			return
		end

		if not(C_Quest:IsQuestTurnedIn(questID)) then
			dprint("StartingAreaTutorialMixin:CheckNPCPopUps: checking quest "..questID)

			local unit = NPE.Const.QuestGivers[questID]

			-- make sure previous quest is complete. For not to display "talk to questgiver 2" when quest 1 is not complete
			if i > 1 then
				if not C_Quest:IsQuestTurnedIn(questIDs[i-1]) then
					dprint("StartingAreaTutorialMixin:CheckNPCPopUps: Prev quest is not complete")
					return
				end
			end

			if tutorial.questAcceptHandle then
				ShowTalkToNPCPopup(unit.objective, unit.ID)
				return
			else
				dprint("StartingAreaTutorialMixin:CheckNPCPopUps: no quest accept handle")
			end
		end
	end
end

function StartingAreaTutorialMixin:HighlightGossipButtons(...)
	for _, questID in pairs(self:GetQuestIDs()) do
		if DecideParentForGossipHelper(questID, "GOSSIP_SHOW") then
			NPE:SetPopupComplete(TalkToNPCPopupKey, true)
			return
		end
	end
end

function StartingAreaTutorialMixin:HighlightQuestButtons(...)
	for _, questID in pairs(self:GetQuestIDs()) do
		if DecideParentForGossipHelper(questID, "QUEST_GREETING") then
			NPE:SetPopupComplete(TalkToNPCPopupKey, true)
			return
		end
	end
end

function StartingAreaTutorialMixin:HighlightAcceptButtons()
	for _, questID in pairs(self:GetQuestIDs()) do
		if DecideParentForQuestAccept(questID) then
			HelpTip:Show("QUEST_FRAME_ACCEPT")
			return
		end
	end
end

function StartingAreaTutorialMixin:OnGossipClose()
	self:CheckNPCPopUps()
end

function StartingAreaTutorialMixin:ClearHooks()
	if next(self.additionalHooks) then
		for i = #self.additionalHooks, 1, -1 do
			self.additionalHooks[i]:Unregister()
			self.additionalHooks[i] = nil
		end
	end
end

function StartingAreaTutorialMixin:Completed()
	dprint(self:GetName().." Completed")

	self:Stopped()
end

function StartingAreaTutorialMixin:Stopped()
	dprint(self:GetName().." Stopped")

	local questIDs = self:GetQuestIDs()

	for i = 1, #questIDs do
		local tutorial = NPE:GetTutorialByName(NPE.Const.Tutorials["STARTING_QUEST_"..i])
		if tutorial:IsActive() then
			tutorial:Stop()
		end
	end

	NPE:ClearDialogPopup(TalkToNPCPopupKey)

	HelpTip:Hide("GOSSIP_SELECT_HELPER")
	HelpTip:Hide("QUEST_FRAME_ACCEPT")
	HelpTip:Hide("QUEST_FRAME_COMPLETE")
	HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
	HelpTip:Hide("GOSSIP_REWARDS_HELPER")

	self:ClearHooks()
end

function StartingAreaTutorialMixin:Started()
	dprint(self:GetName().." Started")

	self:CheckNPCPopUps()

	if not(self.highlightGossipCallback) then
		self.highlightGossipCallback = self:RegisterEventCallbackWithHandle("GOSSIP_SHOW", self.HighlightGossipButtons, self)
		table.insert(self.additionalHooks, self.highlightGossipCallback)

		self.highlightGossipCallback2 = self:RegisterEventCallbackWithHandle("QUEST_GREETING", self.HighlightQuestButtons, self)
		table.insert(self.additionalHooks, self.highlightGossipCallback2
			)
		self.highlightGossipAccept = self:RegisterEventCallbackWithHandle("QUEST_DETAIL", self.HighlightAcceptButtons, self)
		table.insert(self.additionalHooks, self.highlightGossipAccept)

		self.gossipClosedHandle = self:RegisterEventCallbackWithHandle("GOSSIP_CLOSED", self.OnGossipClose, self)
		table.insert(self.additionalHooks, self.gossipClosedHandle)
	end
end

function StartingAreaTutorialMixin:GetQuestIDs()
	return self.questIDs
end

--
-- Kill Area Tutorial logic:
--
local KillAreaTutorialMixin = {}

function KillAreaTutorialMixin:OnLoad()
    self:SetMinMaxLevel(1, 10)
    self:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)
    self:RegisterCallback("TutorialStarted", self.Started, self)
    self:RegisterCallback("TutorialCompleted", self.Completed, self)
    self:RegisterCallback("TutorialStopped", self.Stopped, self)
end

function KillAreaTutorialMixin:Completed()
	dprint(self:GetName().." Completed!")
	self:Stopped()
end

function KillAreaTutorialMixin:Started()
	dprint(self:GetName().." Started!")

	self:CheckNPCPopUps()

	if not self.playerRegenHook then
		self.playerRegenHook = self:RegisterEventCallbackWithHandle("PLAYER_REGEN_DISABLED", self.Complete, self)
	end
end

function KillAreaTutorialMixin:Stopped()
	local popup = NPE:GetDialogPopup()

	if self.popup and popup and popup.info and popup.info.text == self.popup.objective then
		NPE:ClearDialogPopup(TalkToNPCPopupKey)
	end

	if self.playerRegenHook then
		self.playerRegenHook:Unregister()
		self.playerRegenHook = nil
	end
end

function KillAreaTutorialMixin:CheckNPCPopUps()
	if not self:IsActive() then
		dprint(self:GetName().." is not active")
		return
	end

	local questID = self.questID

	if self.popup and C_Quest:IsOnQuestID(questID) and not(C_Quest:IsQuestComplete(questID)) and not(C_Quest:IsQuestTurnedIn(questID)) then
		ShowTalkToNPCPopup(self.popup.objective, self.popup.ID, self.popup.fontSize)
	else
		dprint(self:GetName().." kill area tutorial failed")
	end
end

--
-- Quest tutorial logic:
--
local StartingAreaQuestTutorialMixin = {}

function StartingAreaQuestTutorialMixin:OnLoad()
	self:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

	self:RegisterCallback("TutorialStarted", function() 
		dprint(self:GetName().." started") 

		if not(self.onQuestCompleteHandle) then
			self.onQuestCompleteHandle = self:RegisterEventCallbackWithHandle("QUEST_COMPLETE", self.OnQuestCompleteShow, self)
			self.onQuestSelectRewardHandle = self:RegisterEventCallbackWithHandle("Quest.QuestRewardItemOnClick", self.OnQuestCompleteShow, self)
		end
	end)

	-- display completed tutorial when last quest is complete
	self:RegisterCallback("TutorialCompleted", function() 
		dprint(self:GetName().." completed") 
		self:OnStop()

		local questID = self:GetQuestID()

		if not(questID) then
			return
		end

		local killTutorial = NPE:GetTutorialByName(killTutorialByQuestID[questID])

		if killTutorial then
			killTutorial:Complete(true)
		end

		local areaTutorial = NPE:GetTutorialByName(areaTutorialByQuestID[questID])
		
		if not areaTutorial then
			return
		end

		local tutorialQuests = areaTutorial:GetQuestIDs()

		if tutorialQuests[#tutorialQuests] == questID then
			NPE:ShowDialogPopup(PopupComplete)
			areaTutorial:Complete(true)
		end
	end)

	self:RegisterCallback("QuestAbandoned", function(value, questID)
		 dprint(self:GetName().." quest abandoned ")
		 self.abandonedQuest = questID

		 self:RefreshKillAreaPopups()
	end)
end

function StartingAreaQuestTutorialMixin:OnStop()
	if self.abandonedQuest then
		NPE:ClearDialogPopup(TalkToNPCPopupKey)
		local areaTutorial = NPE:GetTutorialByName(areaTutorialByQuestID[self.abandonedQuest])
		
		if areaTutorial then
			areaTutorial:CheckNPCPopUps()
		end
	end

	if self.onQuestCompleteHandle then
		self.onQuestCompleteHandle:Unregister()
		self.onQuestCompleteHandle = nil

		self.onQuestSelectRewardHandle:Unregister()
		self.onQuestSelectRewardHandle = nil
	end
end

function StartingAreaQuestTutorialMixin:Stop() -- because OnFinished triggers before questsQueryLoadedHandle is registered
	NPEQuestTutorialMixin.Stop(self)
	dprint(self:GetName().." stopped") 
	self:OnStop()
end

function StartingAreaQuestTutorialMixin:RefreshKillAreaPopups()
	local questID = self:GetQuestID()

	local killTutorial = NPE:GetTutorialByName(killTutorialByQuestID[questID])
	
	if not killTutorial then
		return
	end

	killTutorial:CheckNPCPopUps()
end

function StartingAreaQuestTutorialMixin:OnQuestCompleteShow()
	dprint("StartingAreaQuestTutorialMixin:OnQuestCompleteShow")
	-- define if quest fits our quest ID
	local questID = self:GetQuestID()

	if not (questID) then
		return
	end

	-- Define if quest is our guy
	local portraitQuestID = NPE:ScanStartingQuestPortrait()

	dprint("StartingAreaQuestTutorialMixin:OnQuestCompleteShow, questID: "..(portraitQuestID or "NO QUEST ID"))

	if portraitQuestID ~= questID then
		return
	end

	NPE:SetPopupComplete(TalkToNPCPopupKey, true)

	-- no quest choices, just show completion hint
	if GetNumQuestChoices() == 0 then 
		HelpTip:Show("QUEST_FRAME_COMPLETE")
		return
	end

	-- we have quest choices, show how to select dialogue
	if QuestInfoFrame and not(QuestInfoFrame.itemChoice) or (QuestInfoFrame.itemChoice == 0) then
		HelpTip:Hide("QUEST_FRAME_COMPLETE")
		HelpTip:Show("GOSSIP_REWARDS_HELPER")
		return
	end

	HelpTip:Hide("GOSSIP_REWARDS_HELPER")
	HelpTip:Show("QUEST_FRAME_COMPLETE")
end

--
-- Quest tutorial 1:
--
local quest1Tutorial = NPE:NewQuestTutorial(NPE.Const.Tutorials.STARTING_QUEST_1, NPE.Const.StartingQuests1)
MixinAndLoad(quest1Tutorial, StartingAreaQuestTutorialMixin)

-- step 1: Wait for to complete quest objectives
quest1Tutorial.step1 = quest1Tutorial:AddStep()
quest1Tutorial.step1:SetShouldSaveProgress(false)

quest1Tutorial.step1:RegisterCallback("StepStarted", function()
	dprint("quest1Tutorial.step1")
	NPE:ClearDialogPopup(TalkToNPCPopupKey)

	local questID = quest1Tutorial:GetQuestID()
	local popupData = NPE.Const.Quest1Objectives[questID]

	if not(questID) or not(popupData) then
		dprint("no popup data for "..(questID or "NO QUEST ID"))
		NPE:ShowDialogPopup(PopupSuperTracker)
		quest1Tutorial:RefreshKillAreaPopups()
		return
	end

	ShowTalkToNPCPopup(popupData.objective, popupData.ID, popupData.fontSize)
end)

quest1Tutorial.step1:SetCompletionCondition(function()
	return quest1Tutorial:AnyQuestCompleted()
end)

-- step 2: Tell user how to complete quest
quest1Tutorial.step2 = quest1Tutorial:AddStep()
quest1Tutorial.step2:SetShouldSaveProgress(false)

quest1Tutorial.step2:RegisterCallback("StepStarted", function()
	dprint("quest1Tutorial.step2")

	NPE:SetPopupComplete(TalkToNPCPopupKey)

	Timer.After(0.5, function()
		local questID = quest1Tutorial:GetQuestID()
		local popupData = NPE.Const.Quest1Completions[questID]

		if not(popupData) then
			return
		end

		ShowTalkToNPCPopup(popupData.objective, popupData.ID, popupData.fontSize)

		if NPE.Const.Quest1MinimapCompletionHint[quest1Tutorial:GetQuestID()] then
			HelpTip:Show("MINIMAP_COMPLETE_QUEST")
		end
	end)

end)

NPE:AddTutorial(quest1Tutorial)

--
-- Quest tutorial 2:
--
local quest2Tutorial = NPE:NewQuestTutorial(NPE.Const.Tutorials.STARTING_QUEST_2, NPE.Const.StartingQuests2)
MixinAndLoad(quest2Tutorial, StartingAreaQuestTutorialMixin)

-- step 1: Wait for to complete quest objectives
quest2Tutorial.step1 = quest2Tutorial:AddStep()
quest2Tutorial.step1:SetShouldSaveProgress(false)

quest2Tutorial.step1:RegisterCallback("StepStarted", function()
	-- all 2nd quests are kill quests, just refresh kill ara pop ups
	NPE:ClearDialogPopup(TalkToNPCPopupKey)

	NPE:ShowDialogPopup(PopupSuperTracker)

	quest1Tutorial:RefreshKillAreaPopups()
end)

quest2Tutorial.step1:SetCompletionCondition(function()
	return quest2Tutorial:AnyQuestCompleted()
end)

-- step 2: Tell user how to complete quest
quest2Tutorial.step2 = quest2Tutorial:AddStep()
quest2Tutorial.step2:SetShouldSaveProgress(false)

quest2Tutorial.step2:RegisterCallback("StepStarted", function()
	dprint("quest2Tutorial.step2")
	NPE:SetPopupComplete(TalkToNPCPopupKey)

	Timer.After(0.5, function() 
		local questID = quest2Tutorial:GetQuestID()
		local popupData = NPE.Const.Quest2Completions[questID]

		if not(popupData) then
			return
		end

		ShowTalkToNPCPopup(popupData.objective, popupData.ID, popupData.fontSize)

		if NPE.Const.Quest2MinimapCompletionHint[quest2Tutorial:GetQuestID()] then
			HelpTip:Show("MINIMAP_COMPLETE_QUEST")
		end
	end)
end)

NPE:AddTutorial(quest2Tutorial)

--
-- Starting Area Tutorials:
--
for _, area in pairs(NPE.Const.StartingAreas) do
	local x, y, map, radius, questIDs = unpack(area)

	local areaTutorialName = NPE.Const.Tutorials.STARTING_AREA_CONTROLLER..questIDs[1]

    local areaTutorial = NPE:NewAreaTutorial(areaTutorialName, x, y, map, radius)
    MixinAndLoad(areaTutorial, StartingAreaTutorialMixin)
    areaTutorial.questIDs = questIDs

    for i = 1, #questIDs do
    	local questID = questIDs[i]
    	areaTutorialByQuestID[questID] = areaTutorialName
    end

    NPE:AddTutorial(areaTutorial)
end

--
-- Kill Area Tutorials:
--
for _, area in pairs(NPE.Const.KillAreas) do
	local x, y, map, radius, questID = unpack(area)
	local killAreaTutorialName = NPE.Const.Tutorials.KILL_AREA_CONTROLLER..questID

	local killAreaTutorial = NPE:NewAreaTutorial(killAreaTutorialName, x, y, map, radius)
	MixinAndLoad(killAreaTutorial, KillAreaTutorialMixin)
	killAreaTutorial.questID = questID
	killAreaTutorial.popup = NPE.Const.KillAreaObjectives[questID]

	killTutorialByQuestID[questID] = killAreaTutorialName

	NPE:AddTutorial(killAreaTutorial)
end