RestartTimerMixin = {}
RestartTimerMixin.OnEvent = OnEventToMethod

function RestartTimerMixin:OnLoad()
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:SetFontObject("GameFontHighlightOutline")
    self.Text:SetFontSize(10)
    self.Overlay:SetAtlas("challenges-timerborder", Const.TextureKit.IgnoreAtlasSize)
    self.Text:SetPointOffset(0, -1)
end

function RestartTimerMixin:CHAT_MSG_SYSTEM(message)
    local isRestart = message:startswith("[SERVER] Restart")
    local isShutdown = message:startswith("[SERVER] Shutdown")
    self.isShutdown = isShutdown
    if isRestart or isShutdown then
        local minutes = tonumber(message:match("(%d+) Minute") or 0)
        local seconds = tonumber(message:match("(%d+) Second") or 0)

        if minutes > 0 or seconds > 0 then
            if self.disable then
                return
            end
            seconds = seconds + minutes * 60
            if not self:IsShown() then
                self:SetMinMaxValues(0, seconds)
                self:Show()
            end
            self.seconds = seconds
        elseif message:lower():find("restart cancelled") or message:lower():find("shutdown cancelled") then
            self:Hide()
            self.disable = nil
        end
    end
end

function RestartTimerMixin:OnUpdate(elapsed)
    if self.seconds then
        self.seconds = self.seconds - elapsed
        self:SetValue(self.seconds)
        if self.isShutdown then
            self:SetFormattedText("Server Shutdown - %s", SecondsToClock(math.ceil(self.seconds, false, false)))
        else
            self:SetFormattedText("Server Restart - %s", SecondsToClock(math.ceil(self.seconds, false, false)))
        end
    end
end 

function RestartTimerMixin:OnMouseDown()
    self:Hide()
    self.disable = true
end 