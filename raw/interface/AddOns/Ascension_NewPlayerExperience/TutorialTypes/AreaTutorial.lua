local _, NPE = ...

NPEAreaTutorialMixin = CreateFromMixins(NPETutorialMixin)

-- use /measure to get the distance between two points
-- use /run local x,y,_,m = GetCurrentPlayerPosition() Internal_CopyToClipboard(format("%.4f, %.4f, %s", x, y, m))

function NPE:NewAreaTutorial(name, x, y, map, radius)
    local tutorial = CreateFromMixins(NPEAreaTutorialMixin)
    CallbackRegistryMixin.OnLoad(tutorial)
    tutorial:Initialize(name, x, y, map, radius)
    return tutorial
end

function NPEAreaTutorialMixin:Initialize(name, x, y, map, radius)
    NPETutorialMixin.Initialize(self, name)
    self:SetFinalStepCompletes(false)
    self.x = x
    self.y = y
    self.map = map
    self.radius = radius
end

function NPEAreaTutorialMixin:ListenForEnter()
    self.enterTicker = Timer.NewTicker(0.5, function()
        if self:IsInArea() then
            self:Start()
        end
    end)
end
-- 
function NPEAreaTutorialMixin:IsInArea()
    if self.x and self.y and self.map and self.radius then
        local playerX, playerY, _, playerMap = GetCurrentPlayerPosition()
        if playerMap == self.map then
            -- get distance
            local distance = sqrt((playerX - self.x) ^ 2 + (playerY - self.y) ^ 2)
            if distance <= self.radius then
                return true
            end
        end
    end

    return false
end

function NPEAreaTutorialMixin:CanAutoStart()
    return false
end

function NPEAreaTutorialMixin:Setup()
    if not self:IsSetup() then
        NPETutorialMixin.Setup(self)
        self:ListenForEnter()
    end
end

function NPEAreaTutorialMixin:CanAutoStart()
    return false
end

function NPEAreaTutorialMixin:OnTick()
    if not self:IsInArea() then
        self:Stop()
    end
end

function NPEAreaTutorialMixin:Start(jumpToStep)
    if self.enterTicker then
        self.enterTicker:Cancel()
        self.enterTicker = nil
    end
    NPETutorialMixin.Start(self, jumpToStep)
end

function NPEAreaTutorialMixin:Destroy()
    NPETutorialMixin.Destroy(self)
    if self.enterTicker then
        self.enterTicker:Cancel()
        self.enterTicker = nil
    end
end

function NPEAreaTutorialMixin:Stop()
    NPETutorialMixin.Stop(self)
    self:ListenForEnter()
end
