TicketStatusFrameMixin = CreateFromMixins("ResizeLayoutMixin", "BackdropTemplateMixin")
TicketStatusFrameMixin.OnEvent = OnEventToMethod

function TicketStatusFrameMixin:OnLoad()
    self.Text.leftPadding = 10
    self.Text.topPadding = 8
    self.Text.bottomPadding = 8
    ResizeLayoutMixin.OnLoad(self)
    self:SetBackdrop(BACKDROP_TOOLTIP_8_8_1111)
    self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR:GetRGBA())
    self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR:GetRGBA())
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_TICKET_UPDATE")
    self:RegisterEvent("PLAYER_TICKET_NEW_MESSAGE")
    self:RegisterEvent("CLOSE_PLAYER_TICKET_RESULT")
end

function TicketStatusFrameMixin:UpdateVisible()
    local ticket = C_PlayerTicket.GetCurrentTicket()
    local hasTicket = ticket ~= nil

    if hasTicket then
        self:Show()
        self:UpdateStatusText()
        return true
    else
        self:Hide()
        return false
    end
end

function TicketStatusFrameMixin:OnShow()
    ConsolidatedBuffs:SetPoint("TOPRIGHT", self:GetParent(), "TOPRIGHT", -205, (-self:GetHeight()))
end

function TicketStatusFrameMixin:OnHide()
    if( not GMChatStatusFrame or not GMChatStatusFrame:IsShown() ) then
        ConsolidatedBuffs:SetPoint("TOPRIGHT", "UIParent", "TOPRIGHT", -180, -13);
    end
    self:StopFlashing()
end

function TicketStatusFrameMixin:StartFlashing()
    if not self.Glow.Anim:IsPlaying() then
        self.Glow.Anim:Play()
    end
end

function TicketStatusFrameMixin:StopFlashing()
    self.Glow.Anim:Stop()
end

function TicketStatusFrameMixin:UpdateStatusText()
    local text
    local ticket = C_PlayerTicket.GetCurrentTicket()
    if not ticket then
        return
    end
    
    self.hasPendingMessage = ticket.IsLastMessageUnseen

    if TicketFrame and TicketFrame:IsShown() then
        self.hasPendingMessage = false
    end

    if ticket.Status == "CLOSED" then
        text = VIEW_RESOLVED_TICKET
        if self.hasPendingMessage then
            self:StartFlashing()
        else
            self:StopFlashing()
        end
    elseif self.hasPendingMessage then
        text = VIEW_TICKET_NEW_GM_MESSAGE
        self:StartFlashing()
    else
        text = VIEW_TICKET_AWAITING_RESPONSE
        self:StopFlashing()
    end

    self.Text:SetWidth(0)
    self.Text:SetText(text)
    local stringWidth = self.Text:GetStringWidth()
    self.Text:SetWidth(math.min(stringWidth, 198))
    self:Layout()
end

function TicketStatusFrameMixin:OnClick()
    ToggleTicketUI()

    if TicketFrame and TicketFrame:IsShown() then
        self.hasPendingMessage = false
        self:UpdateStatusText()
    end
end

function TicketStatusFrameMixin:PLAYER_ENTERING_WORLD()
    self:UpdateVisible()
end

function TicketStatusFrameMixin:PLAYER_TICKET_UPDATE()
    self:UpdateVisible()
end

function TicketStatusFrameMixin:PLAYER_TICKET_NEW_MESSAGE()
    self:UpdateStatusText()
end 

function TicketStatusFrameMixin:CLOSE_PLAYER_TICKET_RESULT()
    self:UpdateVisible()
end 