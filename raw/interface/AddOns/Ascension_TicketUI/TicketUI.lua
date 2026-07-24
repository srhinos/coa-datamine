TicketFrameMixin = {}
TicketFrameMixin.OnEvent = OnEventToMethod

function TicketFrameMixin:OnLoad()
    PortraitFrame_SetIcon(self, "Interface\\Icons\\mail_gmicon")
    local level = self:GetFrameLevel()
    self.Error:SetFrameLevel(level + 20)
    self.Loading:SetFrameLevel(level + 20)
    self.Success:SetFrameLevel(level + 20)
    self:RegisterForDrag("LeftButton")
end

function TicketFrameMixin:OnDragStart()
    self:StartMoving()
end

function TicketFrameMixin:OnDragStop()
    self:StopMovingOrSizing()
end

function TicketFrameMixin:OnShow()
    self:RegisterEvent("PLAYER_TICKET_UPDATE")
    self:RegisterEvent("CREATE_PLAYER_TICKET_RESULT")
    self:RegisterEvent("CLOSE_PLAYER_TICKET_RESULT")
    self:RegisterEvent("SEND_PLAYER_TICKET_MESSAGE_RESULT")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:HideNotifications()
    self:UpdateShownPanel()
    TicketStatusFrame:UpdateStatusText()
end

function TicketFrameMixin:OnHide()
    self:UnregisterEvent("PLAYER_TICKET_UPDATE")
    self:UnregisterEvent("CREATE_PLAYER_TICKET_RESULT")
    self:UnregisterEvent("CLOSE_PLAYER_TICKET_RESULT")
    self:UnregisterEvent("SEND_PLAYER_TICKET_MESSAGE_RESULT")
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
end

function TicketFrameMixin:UpdateShownPanel()
    local hasTicket = C_PlayerTicket.GetCurrentTicket() ~= nil
    self.ViewTicketPanel:SetShown(hasTicket)
    self.CreateTicketPanel:SetShown(not hasTicket)
    self.Label:SetShown(not hasTicket)
    
    PortraitFrame_SetTitle(self, hasTicket and HELPFRAME_GMTALK_TITLE or HELP_TICKET_OPEN)
end

function TicketFrameMixin:InsertLink(link)
    if self.ViewTicketPanel.MessageInput.Text:IsVisible() and self.ViewTicketPanel.MessageInput.Text:HasFocus() then
        self.ViewTicketPanel.MessageInput.Text:Insert(link)
        return true
    end
    return false
end

function TicketFrameMixin:HideNotifications()
    self.Loading:Hide()
    self.Success:Hide()
    self.Error:Hide()
end

function TicketFrameMixin:ShowLoading()
    self:HideNotifications()
    self.Loading:Show()
end 

function TicketFrameMixin:ShowSuccess(text)
    self:HideNotifications()
    self.Success:Show()
    self.Success:SetText(PLAYER_TICKET_SUCCESS, text)
end 

function TicketFrameMixin:ShowError(text)
    self:HideNotifications()
    self.Error:Show()
    self.Error:SetText(PLAYER_TICKET_ERROR, text)
end 

function TicketFrameMixin:CREATE_PLAYER_TICKET_RESULT(result)
    if result:endswith("_OK") then
        self.CreateTicketPanel:Clear()
        self:HideNotifications()
    else
        self:ShowError(_G[result] or result)
    end

    self:UpdateShownPanel()
end 

function TicketFrameMixin:CLOSE_PLAYER_TICKET_RESULT(result)
    if result:endswith("_OK") then
        self.CreateTicketPanel:Clear()
        self:Hide()
    else
        self:ShowError(_G[result] or result)
    end
    
    self:UpdateShownPanel()
end 

function TicketFrameMixin:PLAYER_REGEN_DISABLED()
    self:Hide()
end 