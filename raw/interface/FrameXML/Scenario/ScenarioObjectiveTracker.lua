ObjectiveTrackerBaseMixin = CreateFromMixins(CallbackRegistryMixin)

function ObjectiveTrackerBaseMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    local name = self:GetName()
    self:RegisterEvent("VARIABLES_LOADED")
    SCENARIO_TRACKER_POSITION = SCENARIO_TRACKER_POSITION or {}
    RegisterForSave("SCENARIO_TRACKER_POSITION")
    self.Header:SetAtlas("Objective-Header", Const.TextureKit.UseAtlasSize)
    self:GenerateCallbackEvents({
        "OnCollapse",
        "OnExpand"
    })
    
    self:RestoreSavedPosition()
end

function ObjectiveTrackerBaseMixin:RestoreSavedPosition()
    if SCENARIO_TRACKER_POSITION and next(SCENARIO_TRACKER_POSITION) then
        self:ClearAllPoints()
        for _, point in ipairs(SCENARIO_TRACKER_POSITION) do
            self:SetPoint(unpack(point))
        end
    end
end

function ObjectiveTrackerBaseMixin:SavePosition()
    local pos = {}
    for i = 1, self:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = self:GetPoint(i)
        tinsert(pos, {point, relativeTo, relativePoint, x, y})
    end
    SCENARIO_TRACKER_POSITION = pos
end

function ObjectiveTrackerBaseMixin:SetHeaderText(headerText)
    self.HeaderText:SetText(headerText)
end

function ObjectiveTrackerBaseMixin:GetDesiredHeight()
    local height = self.Header:GetHeight()
    return height
end

function ObjectiveTrackerBaseMixin:UpdateHeight()
    -- sizing is broken if done same frame other things change
    RunNextFrame(function() self:SetHeight(self:GetDesiredHeight()) end)
end

function ObjectiveTrackerBaseMixin:ToggleCollapsed()
    self.collapsed = not self.collapsed

    if self.collapsed then
        local texture = self.CollapseExpandButton:GetNormalTexture()
        texture:SetTexCoord(0, 0.5, 0, 0.5)
        texture = self.CollapseExpandButton:GetPushedTexture()
        texture:SetTexCoord(0.5, 1, 0, 0.5)

        self:TriggerEvent("OnCollapse")
        PlaySound(SOUNDKIT.MINI_MAP_CLOSE_70)
    else
        local texture = self.CollapseExpandButton:GetNormalTexture()
        texture:SetTexCoord(0, 0.5, 0.5, 1)
        texture = self.CollapseExpandButton:GetPushedTexture()
        texture:SetTexCoord(0.5, 1, 0.5, 1)

        self:TriggerEvent("OnExpand")
        PlaySound(SOUNDKIT.MINI_MAP_OPEN_70)
    end
end

function ObjectiveTrackerBaseMixin:OnDragStart()
    self:StartMoving()
end

function ObjectiveTrackerBaseMixin:OnDragStop()
    self:StopMovingOrSizing()
    self:SavePosition()
end

function ObjectiveTrackerBaseMixin:VARIABLES_LOADED()
    self:RestoreSavedPosition()
end

ObjectiveTrackerMixin = CreateFromMixins(ObjectiveTrackerBaseMixin)

function ObjectiveTrackerMixin:OnLoad()
    ObjectiveTrackerBaseMixin.OnLoad(self)
    self.ObjectivePool = CreateFramePoolCollection()
    self.objectives = {}
    self:RegisterCallback("OnCollapse", GenerateClosure(self.OnCollapse, self))
    self:RegisterCallback("OnExpand", GenerateClosure(self.OnExpand, self))
end

function ObjectiveTrackerMixin:SetBackgroundAtlas(atlas)
    self.MainBlock.Background:SetAtlas(atlas)
end 

function ObjectiveTrackerMixin:SetTitle(title)
    self.MainBlock.Title:SetText(title)
end 

function ObjectiveTrackerMixin:SetSubText(subText)
    self.MainBlock.SubText:SetText(subText)
end

function ObjectiveTrackerMixin:SetBottomLeftText(bottomLeftText)
    self.MainBlock.BottomLeftText:SetText(bottomLeftText)
end

function ObjectiveTrackerMixin:SetBottomRightText(bottomRightText)
    self.MainBlock.BottomRightText:SetText(bottomRightText)
end

function ObjectiveTrackerMixin:GetDesiredHeight()
    local height = ObjectiveTrackerBaseMixin.GetDesiredHeight(self)
    if not self.collapsed then
        height = height + self.MainBlock:GetHeight() + self.ObjectiveBlock:GetHeight()
    end
    return height
end

function ObjectiveTrackerMixin:OnCollapse()
    self.MainBlock:Hide()
    self.ObjectiveBlock:Hide()
end

function ObjectiveTrackerMixin:OnExpand()
    self.MainBlock:Show()
    self.ObjectiveBlock:Show()
end

function ObjectiveTrackerMixin:ClearObjectives()
    self.ObjectivePool:ReleaseAll()
    wipe(self.objectives)
end

function ObjectiveTrackerMixin:CreateObjective(objectiveType, updateFunc)
    local pool
    if objectiveType == "fill" then
        pool = self.ObjectivePool:GetOrCreatePool("Frame", self.ObjectiveBlock, "ScenarioStatusBarObjectiveTemplate")
    else
        pool = self.ObjectivePool:GetOrCreatePool("Frame", self.ObjectiveBlock, "ScenarioTextObjectiveTemplate")
    end
    
    local objective = pool:Acquire()

    local lastObjective = self.objectives[#self.objectives]
    if lastObjective then
        objective:SetPoint("TOP", lastObjective, "BOTTOM", 0, -4)
    else
        objective:SetPoint("TOP", self.ObjectiveBlock, "TOP", 0, -2)
    end
    
    objective.updateFunc = updateFunc

    tinsert(self.objectives, objective)
    objective:Show()
    return objective
end

function ObjectiveTrackerMixin:UpdateObjectives()
    for _, objective in ipairs(self.objectives) do
        if objective.updateFunc then
            objective:updateFunc()
        end
    end
end

BossObjectiveTrackerMixin = CreateFromMixins(ObjectiveTrackerMixin)

function BossObjectiveTrackerMixin:OnLoad()
    ObjectiveTrackerMixin.OnLoad(self)
    self:CreateObjective("oneline", GenerateClosure(self.UpdateBossObjective, self))
end

function BossObjectiveTrackerMixin:OnShow()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function BossObjectiveTrackerMixin:OnHide()
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function BossObjectiveTrackerMixin:COMBAT_LOG_EVENT_UNFILTERED(_, event, _, _, _, _, unitName)
    if event == "UNIT_DIED" and unitName == self.bossName then
        self.bossDefeated = true
        self:UpdateObjectives()
    end
end

function BossObjectiveTrackerMixin:UpdateBossObjective(objective)
    local encounterID = self.getEncounterID()
    local bossName = GetEncounterInfo(encounterID)
    if self.bossName ~= bossName then
        self.bossDefeated = false
    end

    self.bossName = bossName
    objective:SetObjective(DEFEAT_S:format(bossName or UNKNOWNOBJECT), self.bossDefeated and 1 or 0, 1)
end

function BossObjectiveTrackerMixin:SetGetEncounterFunction(getEncounterFunc)
    self.getEncounterID = getEncounterFunc
end

LFGObjectiveTrackerMixin = CreateFromMixins(BossObjectiveTrackerMixin)

function LFGObjectiveTrackerMixin:OnLoad()
    BossObjectiveTrackerMixin.OnLoad(self)
    self:SetBackgroundAtlas("ScenarioTrackerToast")
    self:SetGetEncounterFunction(GetLFGBoss)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("CURRENT_LFG_DUNGEON_ID_CHANGED")
end

function LFGObjectiveTrackerMixin:Update()
    if C_Instance.IsInDungeon() and IsPartyLFG() then
        self:Show()
    else
        self:Hide()
        return
    end
 
    local instance, _, difficulty = GetInstanceInfo()

    local header = LFG_TYPE_DUNGEON
    if difficulty == 2 then
        header = LFG_TYPE_HEROIC_DUNGEON
    elseif difficulty == 3 then
        header = LFG_TYPE_MYTHIC_DUNGEON
    end
    self:SetHeaderText(LFG_TYPE_DUNGEON)

    self:SetTitle(instance)
    self:UpdateObjectives()
end

function LFGObjectiveTrackerMixin:PLAYER_ENTERING_WORLD()
    self:Update()
end

function LFGObjectiveTrackerMixin:CURRENT_LFG_DUNGEON_ID_CHANGED()
    self:Update()
end

ScenarioObjectiveTrackerMixin = CreateFromMixins(ObjectiveTrackerMixin)

function ScenarioObjectiveTrackerMixin:OnLoad()
    ObjectiveTrackerMixin.OnLoad(self)
    self:RegisterEvent("SCENARIO_OBJECTIVE_UPDATE")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end 

function ScenarioObjectiveTrackerMixin:SCENARIO_OBJECTIVE_UPDATE()
    self:Update()
end

function ScenarioObjectiveTrackerMixin:PLAYER_ENTERING_WORLD()
    self:Update()
end

function ScenarioObjectiveTrackerMixin:Update()
    if not C_Scenario.IsInScenario() then
        return self:Hide()
    elseif not self:IsShown() then
        self:Show()
    end

    local name, trackerAtlas, numStages = C_Scenario.GetScenarioInfo()
    self:SetHeaderText(SCENARIO)
    self:SetTitle(name)
    self:SetBackgroundAtlas(trackerAtlas)
    local stageNumber, stageName = C_Scenario.GetActiveStage()
    self:SetSubText(stageName)
    
    self:ClearObjectives()
    for i = 1, C_Scenario.GetNumEncounters() do
        local encounterInfo = C_Scenario.GetEncounterAtIndex(i)
        local objective = self:CreateObjective(encounterInfo.Display, GenerateClosure(self.UpdateEncounterObjective, self))
        objective:SetID(i)
    end
    
    self.FinalStageFiligree:SetShown(stageNumber == numStages)
end 

function ScenarioObjectiveTrackerMixin:UpdateObjective(objective)
    local encounterInfo = C_Scenario.GetEncounterAtIndex(self:GetID())
    objective:SetObjective(encounterInfo.Name, encounterInfo.Count, encounterInfo.Required)
end