local HelpUI = select(2, ...)

BugReportFrameMixin = {}

local BODY_SUB_QUESTIONS = {
	{ key = "IS_GAMEBREAKING", type = "oneline" },
	{ key = "LOCATION", type = "oneline", gps = true },
	{ key = "WHAT_DOING", type = "multiline" },
	{ key = "EXPECTED_OUTCOME", type="multiline" },
	{ key = "ACTUAL_OUTCOME", type="multiline" },
	{ key = "REPRODUCTION_STEPS", type="multiline" },
}

function BugReportFrameMixin:InitializeCategoryDropDown(dropdown, level)
	local info = UIDropDownMenu_CreateInfo()
	for category, index in pairs(Enum.BugReport.Category) do
		info.text = _G["BUG_REPORT_CATEGORY_"..category:upper()] or category
		info.value = index
		info.checked = nil
		info.func = function(button)
			UIDropDownMenu_SetSelectedValue(self.CategorySelect, button.value)
			self:LoadCategory(button.value)
			self:UpdateSubmitButton()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end

local PriorityOrder = {
	"Low",
	"Medium",
	"High",
	"GameBreaking",
}
function BugReportFrameMixin:InitializePriorityDropDown(dropdown, level)
	local info = UIDropDownMenu_CreateInfo()
	for _, priority in ipairs(PriorityOrder) do
		local index = Enum.BugReport.Priority[priority]
		info.text = _G["BUG_REPORT_PRIORITY_"..priority:upper()] or priority
		info.value = index
		info.checked = nil
		info.func = function(button)
			UIDropDownMenu_SetSelectedValue(self.Priority, button.value)
			self:UpdateSubmitButton()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end

function BugReportFrameMixin:OnLoad()
	self.baseHeight = 86
	self.bottomPadding = 20
	self:RegisterEvent("CREATE_BUG_REPORT_ERROR")
	self:RegisterEvent("CREATE_BUG_REPORT_SUCCESS")

	local frameLevel = self:GetFrameLevel()
	self.PortraitFrame.portrait:SetPortraitTexture("Interface\\Icons\\custom_55_bug_border")
	self.SuccessInputBlock:SetFrameLevel(frameLevel+30)
	self.ErrorInputBlock:SetFrameLevel(frameLevel+30)
	self.SubmittingInputBlock:SetFrameLevel(frameLevel+30)
	self.OutOfDateInputBlock:SetFrameLevel(frameLevel+30)

	self.TitleText:SetText(CREATE_BUG_REPORT)
	self.TitleBg:SetAtlas("_UI-Frame-Mechagon-TitleMiddle", Const.TextureKit.IgnoreAtlasSize)
	self.Background:SetAtlas("auctionhouse-background-buy-commodities", Const.TextureKit.IgnoreAtlasSize)

	self.Fields = {}
	
	self.CategorySelect = HelpUI:GetDropDownField()
	self.CategorySelect:Show()
	self.CategorySelect:SetRequired(true)
	self.CategorySelect:SetLabel(BUG_REPORT_CATEGORY)
	self.CategorySelect:SetPoint("TOPLEFT", 7, -72)
	UIDropDownMenu_SetText(self.CategorySelect, BUG_REPORT_CATEGORY_INSTRUCTION)
	UIDropDownMenu_Initialize(self.CategorySelect, GenerateClosure(self.InitializeCategoryDropDown, self))
	self.baseHeight = self.baseHeight + self.CategorySelect:GetFieldHeight()

	self.Priority = HelpUI:GetDropDownField()
	self.Priority:Show()
	self.Priority:SetRequired(true)
	self.Priority:SetLabel(BUG_REPORT_PRIORITY)
	self.Priority:SetPoint("TOPRIGHT", -7, -72)
	UIDropDownMenu_SetText(self.Priority, BUG_REPORT_PRIORITY_INSTRUCTION)
	UIDropDownMenu_Initialize(self.Priority, GenerateClosure(self.InitializePriorityDropDown, self))
	
	self.Title = HelpUI:GetOneLineField()
	self.Title:Show()
	self.Title:SetRequired(true)
	self.Title:SetLabel(BUG_REPORT_TITLE)
	self.Title:SetInstruction(BUG_REPORT_TITLE_INSTRUCTION)
	self.Title:SetPoint("TOPLEFT", 12, -124)
	self.Title:SetPoint("RIGHT", -12, 0)
	self.baseHeight = self.baseHeight + self.Title:GetFieldHeight()

	self.Body = HelpUI:GetMultiLineField()
	self.Body:Show()
	self.Body:SetRequired(true)
	self.Body:SetLabel(BUG_REPORT_BODY)
	self.Body:SetInstruction(BUG_REPORT_BODY_INSTRUCTION)
	self.Body:AttachToField(self.Fields[#self.Fields] or self.Title)
	
	local lastField = self.Body
	for _, subQuestion in ipairs(BODY_SUB_QUESTIONS) do
		local field = HelpUI:GetFieldByType(subQuestion.type)
		self.Body:AddSubField(field)
		field:Show()
		field:InitializeFromLayout(subQuestion)
		field:AttachToField(lastField)
		lastField = field
	end
	self.baseHeight = self.baseHeight + self.Body:GetFieldHeight()
	
	self:UpdateBodyPosition()
	self:UpdateSubmitButton()
end

function BugReportFrameMixin:OnShow()
	self:RegisterEvent("UPDATE_TICKET")
	GetGMTicket()
end

function BugReportFrameMixin:OnHide()
	PlaySound(SOUNDKIT.UCHARACTERSHEETCLOSE_50)
	self.ErrorInputBlock:Hide()
	self.SuccessInputBlock:Hide()
	self.SubmittingInputBlock:Hide()
	self:UnregisterEvent("UPDATE_TICKET")
end

function BugReportFrameMixin:OnEvent(event, ...)
	if event == "CREATE_BUG_REPORT_ERROR" then
		self:ShowError(...)
	elseif event == "CREATE_BUG_REPORT_SUCCESS" then
		C_BugTracker.ClearReport()
		self:ShowSuccess(...)
	elseif event == "UPDATE_TICKET" then
		local hasTicket = ...
		if hasTicket then
			self.HasTicket = true
		else
			self.HasTicket = false
		end
		self:UpdateSubmitButton()
	end
end

function BugReportFrameMixin:ShowError(error)
	PlaySound(SOUNDKIT.ERROR)
	SendSystemMessage(BUG_REPORT_NOT_SUBMITTED)
	SendSystemMessage(error)
	self.SubmittingInputBlock:Hide()
	self.SuccessInputBlock:Hide()
	self.OutOfDateInputBlock:Hide()

	self.ErrorInputBlock:Show()
	self.ErrorInputBlock:SetText(BUG_REPORT_NOT_SUBMITTED, error)
end

function BugReportFrameMixin:ShowSuccess(reportID)
	PlaySound(SOUNDKIT.UI_QUEST_OBJECTIVECOMPLETE_01)
	SendSystemMessage(format(BUG_REPORT_SUBMITTED_S, self.Title:GetFieldValue()))
	SendSystemMessage(format("Click to View: |cffFFFFFF|Hascensionweb:bugtracker/view/%1$s|h[https://ascension.gg/bugtracker/view/%1$s]|h|r", reportID))
	self.SubmittingInputBlock:Hide()
	self.ErrorInputBlock:Hide()
	self.OutOfDateInputBlock:Hide()

	self.SuccessInputBlock.ReportID = reportID
	self.SuccessInputBlock:Show()
	self.SuccessInputBlock:SetText(BUG_REPORT_SUBMITTED, "https://ascension.gg/bugtracker/view/"..reportID)
	self:Clear()
end

function BugReportFrameMixin:UpdateBodyPosition()
	self.Body:AttachToField(self.Fields[#self.Fields] or self.Title)
	local fieldHeight = 0
	for _, field in ipairs(self.Fields) do
		fieldHeight = fieldHeight + field:GetFieldHeight()
	end
	self:SetHeight(self.baseHeight + fieldHeight + (self.bottomPadding or 0))
end

function BugReportFrameMixin:GetLayoutForCategory(category)
	return HelpUI.BugReportLayouts[category]
end

function BugReportFrameMixin:CleanupFields()
	for _, field in ipairs(self.Fields) do
		field:Release()
	end
	wipe(self.Fields)
	self:UpdateBodyPosition()
	self:UpdateSubmitButton()
end

function BugReportFrameMixin:LoadCategory(category)
	local layout = self:GetLayoutForCategory(category)
	if not layout then
		C_Logger.Error("No layout for category: "..category)
		return self:CleanupFields()
	end
	
	self:CleanupFields()
	local lastFrame = self.Title
	for i, field in ipairs(layout) do
		local frame = HelpUI:GetFieldByType(field.type)
		if not frame then
			C_Logger.Error("Invalid field type: "..field.type)
			return self:CleanupFields()
		end

		frame:Show()
		frame:AttachToField(lastFrame)
		frame:InitializeFromLayout(field)

		tinsert(self.Fields, frame)
		lastFrame = frame
	end
	self:UpdateBodyPosition()
	self:UpdateSubmitButton()
end

function BugReportFrameMixin:GetInvalidFields()
	local invalidFields = {}
	if not self.CategorySelect:IsValid() then
		tinsert(invalidFields, self.CategorySelect)
	end

	if not self.Priority:IsValid() then
		tinsert(invalidFields, self.Priority)
	end

	if not self.Title:IsValid() then
		tinsert(invalidFields, self.Title)
	end
	
	for _, field in ipairs(self.Fields) do
		if not field:IsValid() then
			tinsert(invalidFields, field)
		end
	end

	if not self.Body:IsValid() or self.Body:GetFieldValue() == DEFAULT_REPORT_TEXT then
		tinsert(invalidFields, self.Body)
	end
	return invalidFields
end

function BugReportFrameMixin:SubmitOnEnter(button)
	if button:IsEnabled() == 1 then return end

	GameTooltip:SetOwner(button, "ANCHOR_TOP")
	GameTooltip:SetText(BUG_REPORT_CANT_SUBMIT, 1, 0.82, 0, 1)

	if button == self.TalkToGMButton and not C_Config.GetBoolConfig("CONFIG_ALLOW_TICKETS") then
		GameTooltip:AddLine(GM_TICKET_UNAVAILABLE_ON_REALM, 1, 1, 1, false)
	else
		GameTooltip:AddLine(BUG_REPORT_CANT_SUBMIT_EMPTY_FIELDS, 1, 1, 1, false)
		for _, field in ipairs(self:GetInvalidFields()) do
			GameTooltip:AddLine(field.Label:GetText(), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, false)
		end
	end
	GameTooltip:Show()
end

function BugReportFrameMixin:UpdateSubmitButton()
	local invalidFields = self:GetInvalidFields()
	local allFieldsValid = #invalidFields == 0
	self.SubmitButton:SetEnabled(allFieldsValid)
	self.TalkToGMButton:SetEnabled(allFieldsValid and not self.HasTicket and C_Config.GetBoolConfig("CONFIG_ALLOW_TICKETS"))
end

function BugReportFrameMixin:Clear()
	UIDropDownMenu_SetSelectedValue(self.CategorySelect, nil)
	UIDropDownMenu_SetText(self.CategorySelect, BUG_REPORT_CATEGORY_INSTRUCTION)
	UIDropDownMenu_SetSelectedValue(self.Priority, nil)
	UIDropDownMenu_SetText(self.Priority, BUG_REPORT_PRIORITY_INSTRUCTION)
	self.Title:SetFieldValue("")
	self.Body:SetFieldValue("")
	if self.Body.SubFields then
		for _, field in ipairs(self.Body.SubFields) do
			field:SetFieldValue("")
		end
	end
	
	self:CleanupFields()
end

function BugReportFrameMixin:GetReportString(ignoreVersionCheck, markdown)
	local title = self.Title:GetFieldValue()
	local body = self.Body:GetTextBlock(markdown)
	self.Body.Text:ClearFocus()
	self.Title:ClearFocus()

	local fields = ""
	for _, field in ipairs(self.Fields) do
		if field.ClearFocus then
			field:ClearFocus()
		elseif field.Text then
			field.Text:ClearFocus()
		end
		fields = field:GetTextBlock(markdown).."\n\n"
	end
	
	if fields:len() > 0 then
		body = fields .. body
	end

	if markdown then
		local spellDBCDate, spellDBCTime, version, upToDate = GetClientVersion()

		if not upToDate and not ignoreVersionCheck then
			PlaySound(SOUNDKIT.ESCAPE_SCREEN_OPEN_50)
			self.OutOfDateInputBlock:Show()
			return
		end

		local x, y, z, m = GetCurrentPlayerPosition()
		local location = format("Location: %s %s %s %s", x or 0, y or 0, z or 0, m or -1)
        local class = select(2, UnitClass("player"))
        class = format("Class: %s", class or "UNKNOWN")
		body = body .. "\n\n" .. location .. "\n" .. class .. "\n" .. format(BUG_REPORT_VERSION, upToDate and "Yes" or "No", version, spellDBCDate, spellDBCTime)
	end

	if C_Realm.IsDevelopment() then
		title = "[IGR TEST] "..title
	end
	
	return title, body
end

function BugReportFrameMixin:SubmitReport(ignoreVersionCheck)
	local category = self.CategorySelect:GetFieldValue()
	local priority = self.Priority:GetFieldValue()
	local isPublic = self.Public:GetChecked() and true or false
	local title, body = self:GetReportString(ignoreVersionCheck, true)
	-- remove leading and trailing whitespace
	body = body:gsub("^%s*(.-)%s*$", "%1")
	
	C_BugTracker.SetReportCategory(category)
	C_BugTracker.SetReportPriority(priority)
	C_BugTracker.SetReportPublic(isPublic)
	C_BugTracker.SetReportTitle(title)
	C_BugTracker.SetReportDescription(body)

	local success = C_BugTracker.SubmitReport()
	if success then
		self.SubmittingInputBlock:Show()
	else
		self:ShowError("Client failed to submit report.")
	end
end 

function BugReportFrameMixin:SubmitReportToGM()
	local title, text = self:GetReportString(true, false)
	text = title .. "\n"..text
	-- remove leading and trailing whitespace
	text = text:gsub("^%s*(.-)%s*$", "%1")
	-- remove repeating newlines
	text = text:gsub("\n\n+", "\n")
	text = text:sub(1, 500)
	NewGMTicket(text, true)
	self:Clear()
	self:Hide()
end
