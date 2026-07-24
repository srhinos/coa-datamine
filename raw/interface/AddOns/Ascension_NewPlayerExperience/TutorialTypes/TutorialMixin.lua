local _, NPE = ...

NPETutorialMixin = CreateFromMixins(CallbackRegistryMixin)

function NPE:NewTutorial(name)
    local tutorial = CreateFromMixins(NPETutorialMixin)
    CallbackRegistryMixin.OnLoad(tutorial)
    tutorial:Initialize(name)
    return tutorial
end

function NPETutorialMixin:Initialize(name)
    self.name = name
    self.steps = {}
    self.allEventHandles = {}
    self.currentStepIndex = 0
    self.isActive = false
    self.paused = false
    self.canAutoStart = false
    self.finalStepCompletes = true
    
    self:GenerateCallbackEvents({
        "TutorialStarted",
        "TutorialFinished",
        "TutorialStopped",
        "TutorialPaused",
        "TutorialResumed",
        "TutorialCompleted",
        "TutorialSetup",
    })
end

function NPETutorialMixin:GetName()
    return self.name
end

function NPETutorialMixin:IsPaused()
    return self.paused
end

function NPETutorialMixin:IsActive()
    return self.isActive
end

function NPETutorialMixin:IsSetup()
    return self.setup
end

function NPETutorialMixin:GetCurrentStep()
    return self.currentStep
end

function NPETutorialMixin:IsAppropriateLevel(level)
    if self.minLevel then
        level = level or UnitLevel("player")
        if level < self.minLevel or level > self.maxLevel then
            return false
        end
    end
    
    return true
end

function NPETutorialMixin:CanSetup(level)
    local canSetup = self:IsAppropriateLevel(level)
    return canSetup
end

function NPETutorialMixin:CanAutoStart()
    return self.canAutoStart
end

function NPETutorialMixin:SetAutoStart(value)
    self.canAutoStart = value
end

function NPETutorialMixin:FinalStepCompletes()
    return self.finalStepCompletes
end

function NPETutorialMixin:SetFinalStepCompletes(value)
    self.finalStepCompletes = value
end

function NPETutorialMixin:Setup()
    if not self:IsSetup() then
        self.setup = true
    end
    -- implement this function to initialize event listeners etc..
    -- this is when the player meets the conditions to start the tutorial, but has not started it yet

    if self:CanAutoStart() then
        self:Start()
    end

     self:TriggerEvent("TutorialSetup")
end

function NPETutorialMixin:Destroy()
    if self:IsSetup() then
        self.setup = false
    end
    -- implement this function to clean up event listeners etc..
    -- this is when the tutorial is either completed or aborted because it is no longer valid
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end

    for _, handle in ipairs(self.allEventHandles) do
        handle:Unregister()
    end
    wipe(self.allEventHandles)
end

function NPETutorialMixin:Pause()
    if self:IsPaused() then return end
    self.paused = true
    self:TriggerEvent("TutorialPaused")

    if self:GetCurrentStep() then
        self:GetCurrentStep():Pause()
    end
end

function NPETutorialMixin:Resume()
    if not self:IsPaused() then return end
    self.paused = false
    self:TriggerEvent("TutorialResumed")
    
    if self:GetCurrentStep() then
        self:GetCurrentStep():Resume()
    end
end

function NPETutorialMixin:GetSaveState()
    return NPE:GetCharacterTutorialDB(self:GetName())
end

function NPETutorialMixin:GetGlobalSaveState()
    return NPE:GetTutorialDB(self:GetName())
end

function NPETutorialMixin:IsAppropriateTutorialExperience()
    return TutorialUtil.GetTutorialExperience() >= self:GetMinTutorialExperience()
end

function NPETutorialMixin:IsCompleted()
    if not self:IsAppropriateTutorialExperience() then
        return true
    end
    return self:GetGlobalSaveState().completed
end

function NPETutorialMixin:Start(jumpToStep)
    if self:IsActive() then return end

    if not self:IsAppropriateTutorialExperience() then
        return
    end

    self.isActive = true
    self:TriggerEvent("TutorialStarted")
    self.currentStepIndex = jumpToStep or (self:GetSaveState().currentStepIndex or 1) - 1
    self:StartNextStep()
    
    self:GetSaveState().active = true
    
    self.ticker = Timer.NewTicker(0.1, function()
        if self:IsPaused() then return end
        if self.OnTick then
            self:OnTick()
        end
        if self:GetCurrentStep() then
            if self:GetCurrentStep():CheckCompletion() then
                self:StartNextStep()
            end
        end
    end)
end

function NPETutorialMixin:Stop()
    if not self:IsActive() then return end
    self.isActive = false
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end

    self:GetSaveState().active = nil

    if self:GetCurrentStep() then
        self:GetCurrentStep():Stop()
    end
    
    self:TriggerEvent("TutorialStopped")
    self:TriggerEvent("TutorialFinished")
end

function NPETutorialMixin:Complete(ignoreActive)
    if not self:IsActive() and not(ignoreActive) then return end
    self.isActive = false
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end

    self:GetSaveState().active = nil
    self:GetGlobalSaveState().completed = true

    if self:GetCurrentStep() then
        self:GetCurrentStep():Complete()
    end


    self:TriggerEvent("TutorialCompleted")
    self:TriggerEvent("TutorialFinished")
    self:Destroy()
end

function NPETutorialMixin:AddStep(step)
    if not step then
        step = NPE:NewTutorialStep(self:GetName().."Step" .. #self.steps + 1)
    end
    step.tutorial = self
    table.insert(self.steps, step)
    return step
end

function NPETutorialMixin:StartNextStep()
    if self:IsPaused() then return end
    if not self:IsActive() then return end

    if self:GetCurrentStep() then
        self:GetCurrentStep():Complete()
    end

    self.currentStepIndex = self.currentStepIndex + 1
    local step = self.steps[self.currentStepIndex]
    if step then
        if step:ShouldSaveProgress() then
            self:GetSaveState().currentStepIndex = self.currentStepIndex
        end
        self.currentStep = step
        step:Start()
    elseif self:FinalStepCompletes() then
        self:Complete()
    end
end

function NPETutorialMixin:RegisterEventCallbackWithHandle(event, callback, ...)
    local handle
    if event:upper() == event then
        handle = EventRegistry:RegisterFrameEventAndCallbackWithHandle(event, callback, ...)
    else
        handle = EventRegistry:RegisterCallbackWithHandle(event, callback, ...)
    end
    table.insert(self.allEventHandles, handle)
    
    -- override the Unregister method to remove the handle from all event handler list
    handle.OriginalUnregister = handle.Unregister
    handle.Unregister = function()
        self:UnregisterEventHandle(handle)
    end

    return handle
end

function NPETutorialMixin:UnregisterEventHandle(handle)
    for i, h in ipairs(self.allEventHandles) do
        if h == handle then
            handle:OriginalUnregister()
            table.remove(self.allEventHandles, i)
            return
        end
    end
end

function NPETutorialMixin:SetMinMaxLevel(minLevel, maxLevel)
    if not minLevel then
        minLevel = 1
    end
    
    if not maxLevel then
        maxLevel = 80
    end
    
    self.minLevel = minLevel
    self.maxLevel = maxLevel
end

function NPETutorialMixin:SetMinTutorialExperience(minExperience)
    self.minPlayerExperience = minExperience
end

function NPETutorialMixin:GetMinTutorialExperience()
    return self.minPlayerExperience or Enum.TutorialExperience.NewToAscension
end

