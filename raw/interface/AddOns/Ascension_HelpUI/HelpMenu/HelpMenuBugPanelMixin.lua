HelpMenuBugPanelMixin = CreateFromMixins(HelpMenuPanelMixin)

local function OpenBugReport()
	HideUIPanel(HelpMenuFrame)
	BugReportFrame:Show()
end

function HelpMenuBugPanelMixin:OnLoad()
	HelpMenuPanelMixin.OnLoad(self)
	self:SetGeneratorFunction(self.GenerateLayout)
end

function HelpMenuBugPanelMixin:GenerateLayout()
	local element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(BUG_REPORT, "PTFontHighlightEnormous", "LEFT", "TOP", ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_BUG_REPORT_TEXT, nil, "LEFT")

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_BUG_REPORT_OPTION1_HEADER, "PTFontHighlightHuge", "LEFT", nil, ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_BUG_REPORT_OPTION1, nil, "LEFT")

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_BUG_REPORT_OPTION2_HEADER, "PTFontHighlightHuge", "LEFT", nil, ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_BUG_REPORT_OPTION2, nil, "LEFT")

	self:AddSpacer(24)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_BUG_REPORT_OPTION3_HEADER, "PTFontHighlightHuge", "LEFT", nil, ASCENSION_SECONDARY_COLOR:GetRGB())

	self:AddSpacer(4)

	element = self:AddElement(HelpMenuPanelMixin.Element.Text)
	element:SetText(HELPFRAME_BUG_REPORT_OPTION3, nil, "LEFT")

	self:AddSpacer(24)
	
	element = self:AddElement(HelpMenuPanelMixin.Element.Button)
	element:SetText(BUG_REPORT)
	element:SetIconAtlas("helpicon-bug-red")
	element:SetFunction(OpenBugReport)
end