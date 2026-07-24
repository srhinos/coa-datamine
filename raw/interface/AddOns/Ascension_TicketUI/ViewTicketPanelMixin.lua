ViewTicketPanelMixin = {}
ViewTicketPanelMixin.OnEvent = OnEventToMethod

local function ClearTicketMessage(pool, message)
    FramePool_HideAndClearAnchors(pool, message)
    message:Clear()
end

function ViewTicketPanelMixin:OnLoad()
    self.Background:SetAtlas("ui-frame-dragonflight-backgroundtile", Const.TextureKit.UseAtlasSize)
    self.ScrollFrame.scrollToBottom = true
    self.MessageFrame = self.ScrollFrame.Child
    self.MessageFrame.ClosedTicketNotice.align = "center"
    
    self.MessagePool = CreateFramePool("FRAME", self.MessageFrame, "TicketMessageTemplate", ClearTicketMessage)

    self.ScrollFrame:SetScript("OnScrollRangeChanged", function(scrollFrame, xrange, yrange)
        ScrollFrame_OnScrollRangeChanged(scrollFrame, xrange, yrange)
        -- this might be getting called twice, but the messages will come out weird if we dont
        self.MessageFrame:Layout()
    end)

    self.MessageInput.Text:SetScript("OnEnterPressed", function(editBox)
        if IsShiftKeyDown() then
            editBox:Insert("\n")
        else
            self:SubmitMessage()
        end
    end)

    self.MessageInput.Text:SetMaxLetters(2048)
    self.nextLayoutIndex = 1
end 

function ViewTicketPanelMixin:OnShow()
    self:PLAYER_TICKET_UPDATE()
    self:RegisterEvent("PLAYER_TICKET_UPDATE")
    self:RegisterEvent("SEND_PLAYER_TICKET_MESSAGE_RESULT")
    self:RegisterEvent("PLAYER_TICKET_NEW_MESSAGE")
    self:RegisterEvent("CLOSE_PLAYER_TICKET_RESULT")
    self:RefreshMessages()
end 

function ViewTicketPanelMixin:OnHide()
    self:UnregisterEvent("PLAYER_TICKET_UPDATE")
    self:UnregisterEvent("SEND_PLAYER_TICKET_MESSAGE_RESULT")
    self:UnregisterEvent("PLAYER_TICKET_NEW_MESSAGE")
    self:UnregisterEvent("CLOSE_PLAYER_TICKET_RESULT")
end 

function ViewTicketPanelMixin:RefreshMessages()
    self.nextLayoutIndex = 1
    self.MessagePool:ReleaseAll()

    local messages = C_PlayerTicket.GetTicketMessages()

    if not messages then
        return
    end

    for i, message in ipairs(messages) do
        if message.Message then
            -- gm notes will be nil messages.
            self:AddMessage(i, message)
        end
    end

    if self.ticket.Status == "CLOSED" then
        if C_PlayerTicket.CanReopenTicket() then
            self.MessageFrame.ClosedTicketNotice.Text:SetText(PLAYER_TICKET_CLOSED_NOTICE)
        else
            self.MessageFrame.ClosedTicketNotice.Text:SetText(PLAYER_TICKET_CLOSED_NOTICE_NO_REOPEN)
        end
        self.MessageFrame.ClosedTicketNotice:Show()
        self.MessageFrame.ClosedTicketNotice.layoutIndex = self.nextLayoutIndex
        self.nextLayoutIndex = self.nextLayoutIndex + 1
    else
        self.MessageFrame.ClosedTicketNotice:Hide()
    end

    self.MessageFrame:Layout()
end

function ViewTicketPanelMixin:AddMessage(index, message)
    local messageFrame = self.MessagePool:Acquire()
    if message.GMOnly then
        messageFrame:SetGMNoteMessage()
        messageFrame:SetMessageGMNote()
    elseif message.IsFromGM then
        messageFrame:SetOtherMessage()
        messageFrame:SetMessageNormal()
    else
        messageFrame:SetMyMessage()
        if index == 0 then
            messageFrame:SetMessagePending()
        else
            messageFrame:SetMessageNormal()
        end
    end
    messageFrame:SetID(index)
    messageFrame.layoutIndex = self.nextLayoutIndex
    messageFrame:Show()
    messageFrame:SetMessage(self.ticket.TicketID, message)
    self.nextLayoutIndex = self.nextLayoutIndex + 1
end

function ViewTicketPanelMixin:ReopenTicketWithMessage()
    C_PlayerTicket.ReopenTicket()
    self:SubmitMessage(true)
end

function ViewTicketPanelMixin:SubmitMessage(ignoreStatus)
    local message = self.MessageInput.Text:GetText()
    if message:len() <= 0 then
        return
    end

    if not ignoreStatus and self.ticket.Status == "CLOSED" then
        if C_PlayerTicket.CanReopenTicket() then
            StaticPopup_Show("PLAYER_TICKET_REOPEN_WITH_MESSAGE_CONFIRM", nil, nil, GenerateClosure(self.ReopenTicketWithMessage, self))
        end
        return
    end
    
    local canSend, reason = C_PlayerTicket.CanSendTicketMessage(nil, message, false)

    if canSend then
        local msgObj = {
            IsFromGM = false,
            GMOnly = false,
            Sender = UnitName("player"),
            Message = message,
            Timestamp = time()
        }
        self:AddMessage(0, msgObj)
        self.MessageFrame:Layout()
        if C_PlayerTicket.SendTicketMessage(nil, message, false) then
            self.MessageInput.Text:ClearFocus()
            self.MessageInput.Text:SetText("")
        end
    else
        self:GetParent():ShowError(_G[reason] or reason)
    end
end

function ViewTicketPanelMixin:PLAYER_TICKET_UPDATE()
    self.ticket = C_PlayerTicket.GetCurrentTicket()
    if not self.ticket then
        return
    end

    self.Title:SetText(self.ticket.Title)
    self.TicketStatus:SetText(_G["PLAYER_TICKET_STATUS_"..self.ticket.Status] or "PLAYER_TICKET_STATUS_"..(self.ticket.Status or ""))

    self.MessageFrame.ClosedTicketNotice.ResolveButton:Enable()
    self.MessageFrame.ClosedTicketNotice.ReopenButton:Enable()
    
    local canClose, reason = C_PlayerTicket.CanCloseTicket()
    canClose = canClose and self.ticket.Status ~= "CLOSED"
    self.CancelTicketButton:SetShown(canClose)
    self.CancelTicketButton:Enable()
    if not canClose and reason then
        self.CancelTicketButton.tooltipTitle = PLAYER_TICKET_UNABLE_CLOSE
        self.CancelTicketButton.tooltipText = _G[reason] or reason
    else
        self.CancelTicketButton.tooltipTitle = nil
        self.CancelTicketButton.tooltipText = nil
    end
    
    self:RefreshMessages()
end

function ViewTicketPanelMixin:PLAYER_TICKET_NEW_MESSAGE(messageID)
    if messageID == 0 then
        return
    end
    
    self:RefreshMessages()
end 

function ViewTicketPanelMixin:CLOSE_PLAYER_TICKET_RESULT()
    self.CancelTicketButton:Enable()
    self.MessageFrame.ClosedTicketNotice.ResolveButton:Enable()
    self.MessageFrame.ClosedTicketNotice.ReopenButton:Enable()
end