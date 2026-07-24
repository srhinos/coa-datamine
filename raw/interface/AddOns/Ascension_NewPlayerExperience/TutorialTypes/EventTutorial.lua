local _, NPE = ...

NPEEventTutorial = CreateFromMixins(NPETutorialMixin)

function NPE:NewEventTutorial(name, event, ...)
    local tutorial = CreateFromMixins(NPEEventTutorial)
    CallbackRegistryMixin.OnLoad(tutorial)
    tutorial:Initialize(name, event, ...)
    return tutorial
end

function NPEEventTutorial:Initialize(name, event, ...)
    NPETutorialMixin.Initialize(self, name)
    --self:SetFinalStepCompletes(false) -- why?
    self.event = event
    self.eventArgs = { ... }
end

function NPEEventTutorial:StopEventHandle()
    if self.startEventHandle then
        self.startEventHandle:Unregister()
        self.startEventHandle = nil
    end
end

function NPEEventTutorial:StartEventHandle()
    self:StopEventHandle()
    self.startEventHandle = self:RegisterEventCallbackWithHandle(self.event, function(_, ...)
        if #self.eventArgs > 0 then
            for i, arg in pairs(self.eventArgs) do
                if type(arg) == "table" then
                    if not arg[select(i, ...)] then
                        return
                    end
                elseif type(arg) == "function" then
                    if not arg(select(i, ...)) then
                        return
                    end
                else
                    if select(i, ...) ~= self.eventArgs[i] then
                        return
                    end
                end
            end
        elseif #self.eventArgs > 0  then
            return
        end
        self:Start()
    end)
end

function NPEEventTutorial:CanAutoStart()
    return false
end

function NPEEventTutorial:Setup()
    if not self:IsSetup() then
        NPETutorialMixin.Setup(self)
        self:StartEventHandle()
    end
end

function NPEEventTutorial:CanAutoStart()
    return false
end

function NPEEventTutorial:Start(jumpToStep)
    self:StopEventHandle()
    NPETutorialMixin.Start(self, jumpToStep)
end

function NPEEventTutorial:Destroy()
    NPETutorialMixin.Destroy(self)
    self:StopEventHandle()
end

function NPEEventTutorial:Stop()
    NPETutorialMixin.Stop(self)
    self:StopEventHandle()
end
