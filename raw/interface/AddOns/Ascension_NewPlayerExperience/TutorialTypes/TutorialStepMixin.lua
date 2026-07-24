local _, NPE = ...
NPETutorialStepMixin = CreateFromMixins(CallbackRegistryMixin)

function NPE:NewTutorialStep(name)
    local step = CreateFromMixins(NPETutorialStepMixin)
    CallbackRegistryMixin.OnLoad(step)
    step:Initialize(name)
    return step
end

function NPETutorialStepMixin:Initialize(name)
    self.name = name
    self.isActive = false
    self.paused = false
    self.savesProgress = true
    self.helpTips = {}
    
    self:GenerateCallbackEvents({
        "StepStarted",
        "StepPaused",
        "StepResumed",
        "StepCompleted",
        "StepFinished",
    })
end

function NPETutorialStepMixin:GetName()
    return self.name
end

function NPETutorialStepMixin:IsActive()
    return self.isActive
end

function NPETutorialStepMixin:IsPaused()
    return self.paused
end

function NPETutorialStepMixin:GetTutorial()
    return self.tutorial
end

function NPETutorialStepMixin:Start()
    if self:IsActive() then return end
    self.isActive = true
    self:TriggerEvent("StepStarted")
    for _, helpTip in ipairs(self.helpTips) do
        helpTip:Show()
    end
    self:StartCompletionEventHandle()
end

function NPETutorialStepMixin:Stop()
    if not self:IsActive() then
        return
    end
    self.isActive = false
    self:TriggerEvent("StepFinished")
    for _, helpTip in ipairs(self.helpTips) do
        helpTip:Hide()
    end
    self:StopCompletionEventHandle()
end

function NPETutorialStepMixin:Complete()
    if not self:IsActive() then return end
    self.isActive = false
    self:TriggerEvent("StepCompleted")
    self:TriggerEvent("StepFinished")
    for _, helpTip in ipairs(self.helpTips) do
        helpTip:Hide()
    end
    self:StopCompletionEventHandle()
end

function NPETutorialStepMixin:Pause()
    if self:IsPaused() then return end
    self.paused = false
    self:TriggerEvent("StepPaused")
    for _, helpTip in ipairs(self.helpTips) do
        helpTip:Hide()
    end
    self:StopCompletionEventHandle()
end

function NPETutorialStepMixin:Resume()
    if not self:IsPaused() then return end
    self.paused = false
    self:TriggerEvent("StepResumed")
    for _, helpTip in ipairs(self.helpTips) do
        helpTip:Show()
    end
    self:StartCompletionEventHandle()
end

function NPETutorialStepMixin:SetCompletionCondition(callback)
    self.completionCondition = callback
end

function NPETutorialStepMixin:StopCompletionEventHandle()
    if self.startEventHandle then
        self.startEventHandle:Unregister()
        self.startEventHandle = nil
    end
end

function NPETutorialStepMixin:StartCompletionEventHandle()
    self:StopCompletionEventHandle()
    if self.completionEvent then
        self.startEventHandle = self:GetTutorial():RegisterEventCallbackWithHandle(self.completionEvent, function(_, ...)
            if #self.completionEventArgs > 0 then
                for i = 1, select("#", ...) do
                    local arg = self.completionEventArgs[i]
                    if type(arg) == "table" then
                        if not arg[select(i, ...)] then
                            return
                        end
                    elseif type(arg) == "function" then
                        if not arg(select(i, ...)) then
                            return
                        end
                    else
                        if select(i, ...) ~= self.completionEventArgs[i] then
                            return
                        end
                    end
                end
            end
            self.eventCompleted = true
            self.startEventHandle:Unregister()
        end)
    end
end

-- Completes this step when the specified event fires, optionally with specified arguments
function NPETutorialStepMixin:SetCompletionEvent(event, ...)
    self.completionEvent = event
    self.completionEventArgs = {...}
    self.eventCompleted = false

    if self:IsActive() then
        self:StartCompletionEventHandle()
    end
end

function NPETutorialStepMixin:CheckCompletion()
    if self.completionEvent then
        if self.eventCompleted then
            return true
        end
    end
    if self.completionCondition then
        return self:completionCondition()
    end
end

function NPETutorialStepMixin:AddHelpTip(helpTipInfo, system)
    local helpTip = NPE:CreateHelpTip(helpTipInfo, system)
    tinsert(self.helpTips, helpTip)

    if self:IsActive() then
        helpTip:Show()
    end
end

function NPETutorialStepMixin:ShouldSaveProgress()
    return self.savesProgress
end

function NPETutorialStepMixin:SetShouldSaveProgress(savesProgress)
    self.savesProgress = savesProgress
end

