TicketMessageMixin = CreateFromMixins("ResizeLayoutMixin", "NineSlicePanelMixin")
TicketMessageMixin.OnEvent = OnEventToMethod

local PARAGRAPH_FORMAT = [[<p align="left">%s</p>]]

function TicketMessageMixin:OnLoad()
    self.minMessageWidth = 260
    self.maxMessageWidth = 492
    self.Message.leftPadding = 12
    self.Message.topPadding = 12
    self.Message.rightPadding = 12
    self.Message.bottomPadding = 48
    ResizeLayoutMixin.OnLoad(self)
    NineSlicePanelMixin.OnLoad(self)
    self:SetNineSliceIgnoreInLayout(true)
end 

function TicketMessageMixin:Clear()
    self:UnregisterEvent("SEND_GM_TICKET_MESSAGE_RESULT")
    self:UnregisterEvent("SEND_PLAYER_TICKET_MESSAGE_RESULT")
    self.Author:SetText("")
    self.Message:SetDynamicText("")
    self.Timestamp:SetText("")
    self.align = nil
    self.layoutIndex = nil
    self.message = nil
end

function TicketMessageMixin:OnShow()
    if GameTooltip:IsOwned(self) then
        self:OnEnter()
    else
        self:OnLeave()
    end
end

function TicketMessageMixin:SetMyMessage()
    self.Timestamp:ClearAndSetPoint("TOPRIGHT", self.Message, "BOTTOMRIGHT", 0, -24)
    self.Timestamp:SetJustifyH("RIGHT")

    self.Author:ClearAndSetPoint("TOPLEFT", self.Message, "BOTTOMLEFT", 0, -24)
    self.Author:SetJustifyH("LEFT")


    self.Message:ClearAndSetPoint("TOPRIGHT", -12, -12)
    self.Message:SetJustifyH("LEFT")
    self.Message.HiddenText:SetJustifyH("LEFT")

    self.CopyButton:ClearAndSetPoint("TOPRIGHT", self, "TOPLEFT", 2, -2)
    
    self:SetBorderColor(0, 0.82, 1)
    self:SetCenterColor(0, 0.82, 1)
    self.align = "right"
end

function TicketMessageMixin:SetGMNoteMessage()
    self.Timestamp:ClearAndSetPoint("TOPRIGHT", self.Message, "BOTTOMRIGHT", 0, -24)
    self.Timestamp:SetJustifyH("RIGHT")

    self.Author:ClearAndSetPoint("TOPLEFT", self.Message, "BOTTOMLEFT", 0, -24)
    self.Author:SetJustifyH("LEFT")


    self.Message:ClearAndSetPoint("TOP", 0, -12)
    self.Message:SetJustifyH("LEFT")
    self.Message.HiddenText:SetJustifyH("LEFT")

    self.CopyButton:ClearAndSetPoint("TOPRIGHT", self, "TOPLEFT", 2, -2)

    self:SetBorderColor(1, 0.82, 0)
    self:SetCenterColor(1, 0.82, 0)
    self.align = "center"
end

function TicketMessageMixin:SetOtherMessage()
    self.Timestamp:ClearAndSetPoint("TOPLEFT", self.Message, "BOTTOMLEFT", 0, -24)
    self.Timestamp:SetJustifyH("LEFT")

    self.Author:ClearAndSetPoint("TOPRIGHT", self.Message, "BOTTOMRIGHT", 0, -24)
    self.Author:SetJustifyH("RIGHT")

    self.Message:ClearAndSetPoint("TOPLEFT", 12, -12)
    self.Message:SetJustifyH("LEFT")
    self.Message.HiddenText:SetJustifyH("LEFT")
    
    self.CopyButton:ClearAndSetPoint("TOPLEFT", self, "TOPRIGHT", -2, -2)

    self:SetBorderColor(0.99, 0.54, 0)
    self:SetCenterColor(0.99, 0.54, 0)
    self.align = "left"
end

function TicketMessageMixin:SetMessagePending()
    self.Author:SetTextColor(0.5, 0.5, 0.5)
    self.Message:SetTextColor("p", 0.5, 0.5, 0.5)
    self.Timestamp:SetTextColor(0.5, 0.5, 0.5)
    self:RegisterEvent("SEND_PLAYER_TICKET_MESSAGE_RESULT")
    self:RegisterEvent("SEND_GM_TICKET_MESSAGE_RESULT")
end

function TicketMessageMixin:SetMessageFailed()
    self.Author:SetTextColor(1, 0, 0)
    self.Message:SetTextColor("p", 1, 0, 0)
    self.Timestamp:SetTextColor(1, 0, 0)
end

function TicketMessageMixin:SetMessageNormal()
    self.Author:SetTextColor(1, 1, 1)
    self.Message:SetTextColor("p", 1, 1, 1)
    self.Timestamp:SetTextColor(1, 1, 1)
end

function TicketMessageMixin:SetMessageGMNote()
    self.Author:SetTextColor(1, 0.82, 0)
    self.Message:SetTextColor("p", 1, 0.82, 0)
    self.Timestamp:SetTextColor(1, 0.82, 0)
end

function TicketMessageMixin:SetMessage(ticketID, message)
    self.message = message
    self.ticketID = ticketID
    if message.IsFromGM then
        self.Author:SetText("|TInterface\\ChatFrame\\UI-ChatIcon-Blizz.blp:18:45:0:-2|t" .. message.Sender)
    else
        self.Author:SetText(message.Sender)
    end
    
    local sanitizedMessage = message.Message and string.sanitizeHTML(message.Message)
    self.Message.HiddenText:SetWidth(self.maxMessageWidth)
    self.Message.HiddenText:SetHeight(0)
    self.Message.HiddenText:SetText(message.Message)
    self.Message:SetWidth(math.clamp(self.Message.HiddenText:GetStringWidth(), self.minMessageWidth, self.maxMessageWidth))
    self.Message:SetHeight(self.Message.HiddenText:GetStringHeight())
    self.Message:SetText(HTML_TAG_WRAPPER:format(PARAGRAPH_FORMAT:format(sanitizedMessage)))
    self.Message.HiddenText:Hide()
    local timeSince = time() - message.Timestamp
    local timeSinceMessage
    if timeSince >= 86400 then
        timeSinceMessage = date("%I:%M%p - %x", message.Timestamp)
        self.Timestamp:SetFormattedText("%s", timeSinceMessage)
    else
        timeSinceMessage = SecondsToTime(time() - message.Timestamp, timeSince > 60, false)
        self.Timestamp:SetFormattedText("%s - "..TIME_S_AGO, date("%I:%M%p", message.Timestamp), timeSinceMessage)
    end
    
    self:UpdateSeen()
end 

function TicketMessageMixin:UpdateSeen()
    if self:GetID() ~= 0 and not C_PlayerTicket.IsResponseSeen(self:GetID()) then
        C_PlayerTicket.MarkResponseSeen(nil, self:GetID())
    end
end

function TicketMessageMixin:OnEnter()
    self.CopyButton:Show()
end

function TicketMessageMixin:OnLeave()
    if self.CopyButton:IsMouseOver() then
        return
    end
    
    self.CopyButton:Hide()
end

local function FormatHyperlink(linkType, id, label)
    if id and not string.isNilOrEmpty(id) and linkType and not string.isNilOrEmpty(linkType) then
        return format("%s (%s: %s)", label, linkType, id)
    end

    return label
end

function TicketMessageMixin:CopyMessage()
    local text = self.message.Message
    local name = self.message.Sender

    text = text:gsub("|H([^:|]+):?([^:|]*)[^|]*|h([^|]+)|h", FormatHyperlink)
    text = text:gsub("|c%x%x%x%x%x%x%x%x([^|]+)|r", "%1") -- strip color tags
    
    local message
    if name == "AI" then
        message = text
    else
        message = format("[%s]: %s", name, text)
    end
    Internal_CopyToClipboard(message)
    SendSystemMessage(S_COPIED_TO_CLIPBOARD:format(message))
end

function TicketMessageMixin:SEND_PLAYER_TICKET_MESSAGE_RESULT(result, index)
    if index == self:GetID() then
        self:UnregisterEvent("SEND_GM_TICKET_MESSAGE_RESULT")
        self:UnregisterEvent("SEND_PLAYER_TICKET_MESSAGE_RESULT")
        if not result:endswith("_OK") then
            self:SetMessageFailed()
        end
    end
end

function TicketMessageMixin:SEND_GM_TICKET_MESSAGE_RESULT(result, index)
    if index == self:GetID() then
        self:UnregisterEvent("SEND_GM_TICKET_MESSAGE_RESULT")
        self:UnregisterEvent("SEND_PLAYER_TICKET_MESSAGE_RESULT")
        if not result:endswith("_OK") then
            self:SetMessageFailed()
        end
    end
end