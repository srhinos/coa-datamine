HelpMenuUnstuckPanelMixin = CreateFromMixins(HelpMenuPanelMixin)

local function UseUnstuck()
	Stuck()
	HideUIPanel(HelpMenuFrame)
end

function HelpMenuUnstuckPanelMixin:OnLoad()
	HelpMenuPanelMixin.OnLoad(self)
	self:SetGeneratorFunction(self.GenerateLayout)
end

function HelpMenuUnstuckPanelMixin:GenerateLayout()
	local element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_STUCK_TITLE, "PTFontHighlightEnormous", "LEFT", "TOP", ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_STUCK_TEXT1, nil, "LEFT")

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_STUCK_OPTION1_HEADER, "PTFontHighlightHuge", "LEFT", nil, ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_STUCK_OPTION1, nil, "LEFT")

	self:AddSpacer(24)
	
	element = self:AddElement(HelpMenuPanelMixin.Element.UseItem)
	element:SetItem(6948)

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_STUCK_OPTION2_HEADER, "PTFontHighlightHuge", "LEFT", nil, ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_STUCK_OPTION2, nil, "LEFT")

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Button)
	element:SetText(STUCK_BUTTON_TEXT)
	element:SetIconAtlas("helpicon-stuck")
	element:SetFunction(UseUnstuck)

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_STUCK_OPTION3_HEADER, "PTFontHighlightHuge", "LEFT", nil, ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_STUCK_OPTION3, nil, "LEFT")

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Button)
	element:SetText(HELP_TICKET_OPEN)
	element:SetIconAtlas("helpicon-chat")
	element:SetFunction(function()
		ShowTicketFrame()
	end)
end 