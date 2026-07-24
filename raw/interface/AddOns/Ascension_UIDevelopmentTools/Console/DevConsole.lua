DevConsoleMixin = {
	Commands = {},
	Aliases = {},
	nextLineNumber = 1,
	lines = {}
}

local function FormatTimestamp(seconds, lineNumber)
	seconds = tonumber(seconds)
	local timestamp = SecondsToClock(seconds, false, false)
	return "|Hcopy:"..lineNumber.."|h" .. timestamp
end

function DevConsoleMixin:OnLoad()
	self.start = TimeSince:Now()

	local _print = print

	print = function(...)
		self:Print(...)
		if _print then
			_print(...)
		end
	end

	if dprint and C_Realm.IsDevelopment() then
		dprint = function(...)
			if self:IsShown() then
				self:Print("|cff22FF22[DEV]:|r", ...)
			else
				print("|cff22FF22[DEV]:|r", ...)
			end
		end
	end

	function message(...)
		self:Print(...)
		if _print then
			_print(...)
		end
	end
	
	if InGlue() then
		C_Hook:RegisterAllEvents(self, "OnEvent")
	end

	self:RegisterDefaultCommands()
	self:Print("|cff00DDFFConsole Loaded|r")
end

function DevConsoleMixin:OnShow()
	self.AnimIn:Play()
	if not self.Initialized then
		self.Initialized = true
		if DevConsoleHistory then
			for _, line in ipairs(DevConsoleHistory) do
				self.EditBox:AddHistoryLine(line)
			end
		end

		if DevConsoleAliases then
			for alias, func in pairs(DevConsoleAliases) do
				if not self.Commands[alias:lower()] then
					DevConsole:RegisterAlias(alias, "alias for " .. func, func)
				end
			end
		end
		
		if self.Commands["help"] then
			self.Commands["help"].func()
		end
	end
end

function DevConsoleMixin:OnHide()
end

function DevConsoleMixin:Close()
	self.AnimIn:Stop()
	self.AnimOut:Play()
	if ToggleDevConsoleButton then
		ToggleDevConsoleButton.Icon:FlipY()
		ToggleDevConsoleButton:SetPoint("TOPLEFT")
	end
end

function DevConsoleMixin:ErrorHandler(message)
	DevConsole:Print("|cffFF0000"..message.."|r", "\n"..debugstack(2, 8, 2))
	return message
end

function DevConsoleMixin:ClearConsole()
	wipe(self.lines)
	self.nextLineNumber = 1
	self:Clear()
end

function DevConsoleMixin:Print(...)
	local str = "|cFFFFD100[" .. FormatTimestamp(self.start:elapsed(), self.nextLineNumber) .. "s]|r "
	local text = makeprintable(...)
	str = str .. text
	if strlen(str) > 1024 then
		str = str:sub(1, 1024) .. "..."
	end
	
	self.lines[self.nextLineNumber] = text
	self:AddMessage(str)
	self.nextLineNumber = self.nextLineNumber + 1
end

function DevConsoleMixin:PrintError(...)
	local color = RED_FONT_COLOR.hex
	local firstLine = ...
	
	return self:Print(color..firstLine, select(2, ...))
end

function DevConsoleMixin:OnEvent(event, ...)
	if event == "UPDATE_STATUS_DIALOG" and (not ... or ... == "") then
		return
	end

	local s = TableUtil.PrettyPrint(...) or ""

	self:Print("[|cffFFD100" .. event .. "|r]: " .. s)
end

local NoHistoryLines = {
	["exit"] = true,
	["reloadui"] = true,
	["rl"] = true,
	["clear"] = true,
}

function DevConsoleMixin:SendInput(editBox)
	local text = editBox:GetText()
	if strlen(text) == 0 then return end
	self:ScrollToBottom()
	self:Print("|cff888888--> ", text)

	local commandText = text:lower():match("(%w*)[$%s]*")
	local command = commandText and self.Commands[commandText]
	local alias = commandText and self.Aliases[commandText]
	if command then
		local input = text:match(commandText .. "[$%s]*(.*)")
		command.func(input)
	elseif alias then
		local input = text:match(commandText .. "[$%s]*(.*)")
		local func = assert(loadstring(alias.func)())
		func(input)
	else
		local func = assert(loadstring(text))
		func()
	end

	editBox:AddHistoryLine(text)
	if not DevConsoleHistory then
		DevConsoleHistory = {}
	end
	
	local isNewLine = true
	for _, line in ipairs(DevConsoleHistory) do
		if line == text then
			isNewLine = false
			break
		end
	end

	if isNewLine and not NoHistoryLines[text:lower():trim()] then
		table.insert(DevConsoleHistory, text)

		while #DevConsoleHistory > 20  do
			table.remove(DevConsoleHistory, 1)
		end
	end
	editBox:SetText("")
end

function DevConsoleMixin:OnHyperlinkClick(link)
	local hyperlink = LinkUtil:CreateHyperlink(link)
	if hyperlink:GetType() == "copy" then
		local lineNum = tonumber(hyperlink:GetArg(1))
		local line = self.lines[lineNum]
		if line then
			if not IsShiftKeyDown() then
				line = line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
			end
			Internal_CopyToClipboard(line)
			return self:Print("|cff00FF00Copied line:|r "..lineNum)
		else
			return self:PrintError("Could not copy line "..lineNum)
		end
	end
end 

function DevConsoleMixin:OnHyperlinkEnter(link, text)
	local tooltip = GameTooltip or GlueTooltip
	tooltip:SetOwner(self, "ANCHOR_CURSOR")
	tooltip:SetText("Click to copy this line")
	tooltip:AddLine("Shift-Click to copy this line with color formatting strings")
	tooltip:Show()
end

function DevConsoleMixin:OnHyperlinkLeave(link, text)
	local tooltip = GameTooltip or GlueTooltip
	if tooltip:IsOwned(self) then
		tooltip:Hide()
	end
end 