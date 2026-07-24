local _, NPE = ...

NPEQuestTutorialMixin = CreateFromMixins(NPETutorialMixin)

function NPE:NewQuestTutorial(name, questID)
    local tutorial = CreateFromMixins(NPEQuestTutorialMixin)
    CallbackRegistryMixin.OnLoad(tutorial)
    tutorial:Initialize(name, questID)
    return tutorial
end

function NPEQuestTutorialMixin:Initialize(name, questID)
    NPETutorialMixin.Initialize(self, name)
    self:GenerateCallbackEvents({
        "QuestAccepted",
        "QuestAbandoned",
        "QuestProgress",
        "QuestCompleted",
        "QuestsQueried",
    })

    if type(questID) == "string" then
        questID = tonumber(questID)
    end
    
    if type(questID) ~= "table" then
        questID = { questID }
    end

    self.questIDs = questID

    self:ListenForQuestQueryLoaded()
end

function NPEQuestTutorialMixin:CanSetup()
    local canSetup = self:IsAppropriateLevel()
    if self.questIDs then
        for _, questID in ipairs(self.questIDs) do
            if IsQuestComplete(questID) then
                canSetup = false
                break
            end
        end
    else
        canSetup = false
    end
    
    return canSetup
end

function NPEQuestTutorialMixin:Setup()
    NPETutorialMixin.Setup(self)

    if self:GetQuestLogIndex() then
        self:Start()
    else
        self:ListenForQuestAccept()
    end
end

function NPEQuestTutorialMixin:CanAutoStart()
    -- Setup will always handle starting 
    return false
end

function NPEQuestTutorialMixin:Destroy()
    NPETutorialMixin.Destroy(self)
    self.questAbandonHandle = nil
    self.questAcceptHandle = nil
    self.questCompleteHandle = nil
end

function NPEQuestTutorialMixin:Start(jumpToStep)
    NPETutorialMixin.Start(self, jumpToStep)
    self:UnregisterEventHandle(self.questAcceptHandle)
    self.questAcceptHandle = nil
    self:ListenForQuestAbandon()
    self:ListenForQuestComplete()
    self:ListenForQuestChanges()
end

function NPEQuestTutorialMixin:Stop()
    NPETutorialMixin.Stop(self)
    self:UnregisterEventHandle(self.questAbandonHandle)
    self.questAbandonHandle = nil
    self:UnregisterEventHandle(self.questCompleteHandle)
    self.questCompleteHandle = nil
    self:UnregisterEventHandle(self.questWatchUpdateHandle)
    self.questWatchUpdateHandle = nil
    -- restart waiting for quest accept
    self:ListenForQuestAccept()
end

function NPEQuestTutorialMixin:ListenForQuestAccept()
    self.questAcceptHandle = self:RegisterEventCallbackWithHandle("QUEST_ACCEPTED", self.OnQuestAccepted, self)
end

function NPEQuestTutorialMixin:ListenForQuestQueryLoaded()
    self.questsQueryLoadedHandle = self:RegisterEventCallbackWithHandle("Quest.OnQuestQueryComplete", self.OnQuestQueryLoaded, self)
end

function NPEQuestTutorialMixin:OnQuestQueryLoaded()
    self.questsQueryLoadedHandle:Unregister()
    self.questsQueryLoadedHandle = nil
    self:TriggerEvent("QuestsQueried")
end

function NPEQuestTutorialMixin:OnQuestAccepted(questIndex)
    local questID = select(9, GetQuestLogTitle(questIndex))
    if table.Contains(self.questIDs, questID) then
        self:TriggerEvent("QuestAccepted")
        self:Start(0) -- explicitly start at step 0
        return
    end
end

function NPEQuestTutorialMixin:ListenForQuestAbandon()
    self.questAbandonHandle = self:RegisterEventCallbackWithHandle("QUEST_REMOVED", self.OnQuestAbandon, self)
end 

function NPEQuestTutorialMixin:OnQuestAbandon(questID)
    if table.Contains(self.questIDs, questID) then
        self:TriggerEvent("QuestAbandoned", questID)
        self:Stop()
        self:UnregisterEventHandle(self.questAbandonHandle)
        self.questAbandonHandle = nil
        return
    end
end

function NPEQuestTutorialMixin:ListenForQuestComplete()
    self.questCompleteHandle = self:RegisterEventCallbackWithHandle("QUEST_TURNED_IN", self.OnQuestComplete, self)
end 

function NPEQuestTutorialMixin:OnQuestComplete(questID)
    if table.Contains(self.questIDs, questID) then
        self:TriggerEvent("QuestCompleted")
        self:Complete()
        return
    end
end

function NPEQuestTutorialMixin:ListenForQuestChanges()
    self.questWatchUpdateHandle = self:RegisterEventCallbackWithHandle("QUEST_WATCH_UPDATE", self.OnQuestLogUpdate, self)
end

function NPEQuestTutorialMixin:OnQuestLogUpdate(questIndex)
    local questID = select(9, GetQuestLogTitle(questIndex))
    if table.Contains(self.questIDs, questID) then
        self:TriggerEvent("QuestProgress")
    end
end

function NPEQuestTutorialMixin:GetQuestLogIndex()
    for _, questID in ipairs(self.questIDs) do
        local questIndex = GetQuestLogIndexByID(questID)
        if questIndex and questIndex ~= 0 then
            return questIndex, questID
        end
    end
end

function NPEQuestTutorialMixin:OpenMapToQuest()
    local questIndex, questID = self:GetQuestLogIndex()
    if questIndex then
        SelectQuestLogEntry(questIndex)
        WorldMap_OpenToQuest(questID)
        return
    end
end

function NPEQuestTutorialMixin:IsQuestVisibleOnMap()
    local questIndex, questID = self:GetQuestLogIndex()
    if questIndex then
        return WorldMapFrame:IsShown() and QuestUtil.IsQuestOnCurrentMap(questID)
    end
end

function NPEQuestTutorialMixin:GetWatchFrameLinePOI()
    local questIndex, questID = self:GetQuestLogIndex()
    if questIndex then
        return QuestPOI_FindButtonByQuestId("WatchFrameLines", questID)
    end
end

function NPEQuestTutorialMixin:GetWorldMapPOI()
    local questIndex, questID = self:GetQuestLogIndex()
    if questIndex then
        local poiButton = QuestPOI_FindButtonByQuestId("WorldMapPOIFrame", questID)
        if poiButton and not poiButton:IsShown() then
            if poiWorldMapPOIFrame_Swap and  poiWorldMapPOIFrame_Swap.quest and  poiWorldMapPOIFrame_Swap.quest and  poiWorldMapPOIFrame_Swap.quest.questId == questID then
                poiButton = poiWorldMapPOIFrame_Swap
            end
        end
        return poiButton
    end
end 

function NPEQuestTutorialMixin:IsQuestReadyForTurnIn()
    local questIndex, questID = self:GetQuestLogIndex()
    if questIndex then
        return QuestUtil.IsQuestComplete(questID)
    end
end 

function NPEQuestTutorialMixin:GetQuestID()
    local questIndex, questID = self:GetQuestLogIndex()
    return questID
end

function NPEQuestTutorialMixin:AnyQuestCompleted()
    for _, questID in ipairs(self.questIDs) do
        if IsQuestComplete(questID) then
            return true
        end
    end
    return false
end 