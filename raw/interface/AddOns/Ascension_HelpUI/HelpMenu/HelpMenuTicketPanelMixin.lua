HelpMenuTicketPanelMixin = CreateFromMixins(HelpMenuPanelMixin)

function HelpMenuTicketPanelMixin:OnLoad()
	HelpMenuPanelMixin.OnLoad(self)
	self:RegisterEvent("UPDATE_GM_STATUS")
	self:RegisterEvent("UPDATE_TICKET")
	self:RegisterEvent("GMRESPONSE_RECEIVED")
	self.TicketsEnabled = C_Config.GetBoolConfig("CONFIG_ALLOW_TICKETS")
	self:SetGeneratorFunction(self.GeneratePreTicketLayout)
end

--
-- Pre Ticket Message Layout
--
function HelpMenuTicketPanelMixin:GeneratePreTicketLayout()
	local element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_GMTALK_TITLE, "PTFontHighlightEnormous", "LEFT", "TOP", ASCENSION_SECONDARY_COLOR:GetRGB())
	
	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_GMTALK_TEXT1, nil, "LEFT")

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_GMTALK_ISSUE1_HEADER, "PTFontHighlightHuge", "LEFT", nil, ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_GMTALK_ISSUE1, nil, "LEFT")
	
	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_GMTALK_ISSUE2_HEADER, "PTFontHighlightHuge", "LEFT", nil, ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_GMTALK_ISSUE2, nil, "LEFT")

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_GMTALK_ISSUE3_HEADER, "PTFontHighlightHuge", "LEFT", nil, ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_GMTALK_ISSUE3, nil, "LEFT")

	self:AddSpacer(12)
	
	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText("https://discord.gg/customwow", "PTFontHighlightHuge", nil, nil, NORMAL_FONT_COLOR:GetRGB())

	self:AddSpacer(12)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_GMTALK_TEXT2, nil, "LEFT")

	self:AddSpacer(24)

	if not self.TicketsEnabled then
		element = self:AddElement(HelpMenuPanelMixin.Element.Text)
		element:SetText(GM_TICKET_UNAVAILABLE_ON_REALM, nil, nil, nil, RED_FONT_COLOR:GetRGB())

		self:AddSpacer(12)
	end

	element = self:AddElement(HelpMenuPanelMixin.Element.Button)
	element:SetText(HELP_TICKET_OPEN)
	element:SetIconAtlas("helpicon-chat")
	element:SetFunction(function()
		HideUIPanel(HelpMenuFrame)
		OpenTicketUI()
	end)
	
	element:SetEnabled(self.TicketsEnabled)
end 
--
-- events
--
function HelpMenuTicketPanelMixin:UPDATE_GM_STATUS(status)
	self.TicketsEnabled = status == Enum.TicketQueueStatus.Enabled
	if not self.TicketsEnabled then
		StaticPopup_Show("HELP_TICKET_QUEUE_DISABLED")
	end
	self:RegenerateLayout()
end

function HelpMenuTicketPanelMixin:UPDATE_TICKET(hasTicket, ticketDescription)
	self.ticketDescription = ticketDescription
	self.ticketResponse = nil
	if not hasTicket then
		-- no args = no ticket
		self:SetGeneratorFunction(self.GeneratePreTicketLayout)
		self:RegenerateLayout()
		return
	end
	
	self:SetGeneratorFunction(self.GenerateEditTicketLayout)
	self:RegenerateLayout()
end

function HelpMenuTicketPanelMixin:GMRESPONSE_RECEIVED(ticketDescription, response)
	self.ticketDescription = ticketDescription
	self.ticketResponse = response
	self:SetGeneratorFunction(self.GenerateResponseTicketLayout)
	self:RegenerateLayout()
end 