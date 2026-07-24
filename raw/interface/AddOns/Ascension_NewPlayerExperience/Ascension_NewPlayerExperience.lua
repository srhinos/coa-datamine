local addonName, NPE = ...

local Addon = LibStub("AceAddon-3.0"):NewAddon(addonName)
NPE[1] = Addon

_G.NewPlayerExperience = NPE

NPE.tutorials = {}

function Addon:OnInitialize()
    local db = LibStub("AceDB-3.0"):New("Ascension_NewPlayerExperienceDB", {}, true)
    NPE.db = db.global
    NPE.cdb = db.char

    EventRegistry:RegisterCallback("TutorialSystem.ExperienceChanged", function(_, experience)
        if experience > 0 then
            NPE:Load()
        else
            NPE:Unload()
        end
    end)

    if TutorialUtil.CanShowAnyTutorials() then
        NPE:Load()
    end
end

function NPE:Load()
    if self.isActive then
        return
    end
    self.isActive = true

    for _, tutorial in ipairs(self.tutorials) do
        local tutorialWasActive = tutorial:GetSaveState().active
        if not tutorial:IsCompleted() and tutorial:CanSetup() then
            tutorial:Setup() -- setup will also auto start if it can
            if tutorialWasActive and not tutorial:IsActive() then
                tutorial:Start()
            end
        end
    end
    
    EventRegistry:RegisterFrameEventAndCallbackWithHandle("PLAYER_LEVEL_UP", function(_, level)
        for _, tutorial in ipairs(self.tutorials) do
            if not tutorial:IsActive() then
                local tutorialWasActive = tutorial:GetSaveState().active
                if not tutorial:IsCompleted() and tutorial:CanSetup(level) then
                    tutorial:Setup() -- setup will also auto start if it can
                    if tutorialWasActive then
                        tutorial:Start()
                    end
                end
            end
        end
    end)
end 

function NPE:Unload()
    if not self.isActive then
        return
    end

    for _, tutorial in ipairs(self.tutorials) do
        if tutorial:IsActive() then
            tutorial:Stop()
        end
    end
    
    NPE:ClearDialogPopup()
    NPE:ClearAllHelpTips()

    self.isActive = false
end 

function NPE:AddTutorial(tutorial)
    table.insert(self.tutorials, tutorial)
    if self.isActive then
        if not tutorial:IsActive() then
            local tutorialWasActive = tutorial:GetSaveState().active
            if not tutorial:IsCompleted() and (tutorial:CanSetup() or tutorialWasActive) then
                tutorial:Setup() -- setup will also auto start if it can
                if tutorialWasActive then
                    tutorial:Start()
                end
            end
        end
    end
end 

function NPE:StartTutorial(tutorialName, startFromStep)
    for _, tutorial in ipairs(self.tutorials) do
        if tutorial:GetName() == tutorialName then
            tutorial:Setup()
            tutorial:Start(startFromStep)
        end
    end
end 

function NPE:StopTutorial(tutorialName)
    for _, tutorial in ipairs(self.tutorials) do
        if tutorial:GetName() == tutorialName then
            if tutorial:IsActive() then
                tutorial:Stop()
            end
        end
    end
end 

function NPE:CompleteTutorial(tutorialName)
    for _, tutorial in ipairs(self.tutorials) do
        if tutorial:GetName() == tutorialName then
            if tutorial:IsActive() then
                tutorial:Complete()
            elseif tutorial:IsSetup() then
                tutorial:Destroy()
            end
        end
    end
end 

function NPE:PauseTutorial(tutorialName)
    for _, tutorial in ipairs(self.tutorials) do
        if tutorial:GetName() == tutorialName then
            tutorial:Pause()
        end
    end
end

function NPE:IsTutorialActive(tutorialName)
    for _, tutorial in ipairs(self.tutorials) do
        if tutorial:GetName() == tutorialName then
            return tutorial:IsActive()
        end
    end
end

function NPE:IsTutorialComplete(tutorialName)
    for _, tutorial in ipairs(self.tutorials) do
        if tutorial:GetName() == tutorialName then
            return tutorial:IsCompleted()
        end
    end

    return true
end

function NPE:GetTutorialByName(tutorialName)
    for _, tutorial in ipairs(self.tutorials) do
        if tutorial:GetName() == tutorialName then
            return tutorial
        end
    end
end

function NPE:UnpauseTutorial(tutorialName)
    for _, tutorial in ipairs(self.tutorials) do
        if tutorial:GetName() == tutorialName then
            tutorial:Unpause()
        end
    end
end

function NPE:GetTutorialDB(tutorialName)
    if not NPE.db[tutorialName] then
        NPE.db[tutorialName] = {}
    end
    return NPE.db[tutorialName]
end

function NPE:GetCharacterTutorialDB(tutorialName)
    if not NPE.cdb[tutorialName] then
        NPE.cdb[tutorialName] = {}
    end
    return NPE.cdb[tutorialName]
end

--/run NewPlayerExperience:ResetAll()
function NPE:ResetAll()
    wipe(NPE.db)
    wipe(NPE.cdb)
    ReloadUI()
end 

function NPE:ScanStartingQuestPortrait()
    local questTitle = GetTitleText()
    if (questTitle) then
        for _, questID in pairs(NPE.Const.StartingQuests1) do
            local name = C_Quest:GetQuestNameByID(questID)
            if name and (name == questTitle) then
                return questID
            end
        end

        for _, questID in pairs(NPE.Const.StartingQuests2) do
            local name = C_Quest:GetQuestNameByID(questID)
            if name and (name == questTitle) then
                return questID
            end
        end
    end
end

SLASH_RESETNPE1 = "/nper"
SlashCmdList["RESETNPE"] = function()
    NPE:ResetAll()
end