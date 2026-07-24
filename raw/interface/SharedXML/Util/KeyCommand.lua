local generalMetaKeys =
{
	SHIFT = IsShiftKeyDown,
	CTRL = IsControlKeyDown,
	ALT = IsAltKeyDown,
}

local function IsSingleKeyDown(key)
	if generalMetaKeys[key] then
		return generalMetaKeys[key]()
	end

	if type(key) == "string" then
		key = Enum.Key[key:upper()]
	end
	
	if not key then return false end
	return IsKeyDown(key)
end

local function IsCommandKeyDown(key)
	for _, keyName in ipairs(key) do
		if not IsSingleKeyDown(keyName) then
			return false
		end
	end
	
	return true
end

KeyCommand =
{
	RUN_ON_UP = true,
	RUN_ON_DOWN = false,
}

function KeyCommand:OnLoad(command, runOnUp, key, pressesRequired)
	self.keyStates = {}
	self:SetCommand(command)
	self:SetKey(runOnUp, key)
	self:SetPresses(pressesRequired)
end

function KeyCommand:Update()
	local isDown = IsCommandKeyDown(self.key)

	-- Press
	if not self.isDown and isDown then
		self.isDown = true
		if not self.runOnUp then
			if self.lastPress and self.lastPress(0.2) then
				self.pressCount = 0
			end
			self.pressCount = self.pressCount + 1
			if self.pressCount == self.pressesRequired then
				self.command()
				self.pressCount = 0
			else
				if self.lastPress then
					self.lastPress:ResetToNow()
				else
					self.lastPress = TimeSince:Now()
				end
			end
			self:MarkCommandFired()
		end
	end

	-- Release
	if self.isDown and not isDown then
		self.isDown = false
		if self.runOnUp and self:CanFireCommand() then
			if self.lastPress and self.lastPress(0.2) then
				self.pressCount = 0
			end
			self.pressCount = self.pressCount + 1
			if self.pressCount == self.pressesRequired then
				self.command()
				self.pressCount = 0
			else
				if self.lastPress then
					self.lastPress:ResetToNow()
				else
					self.lastPress = TimeSince:Now()
				end
			end
		end

		self:CheckResetCommand()
	end
end

function KeyCommand:MarkCommandFired()
	for _, keyName in ipairs(self.key) do
		self.keyStates[keyName] = self
	end
end

function KeyCommand:CanFireCommand()
	for index, keyName in ipairs(self.key) do
		if self.keyStates[keyName] ~= nil then
			return false
		end
	end

	return true
end

function KeyCommand:CheckResetCommand()
	for _, keyName in ipairs(self.key) do
		if IsSingleKeyDown(keyName) then
			return
		end

		self.keyStates[keyName] = nil
	end
end

function KeyCommand:SetKey(mode, key)
	self.runOnUp = (mode == KeyCommand.RUN_ON_UP)
	self.key = key
end

function KeyCommand:SetCommand(command)
	assert(type(command) == "function")
	self.command = command
end

function KeyCommand:SetPresses(presses)
	self.pressesRequired = presses
	self.pressCount = 0
end

function KeyCommand_Create(command, runOnUp, key, pressesRequired)
	if not pressesRequired then pressesRequired = 1 end
	local keyCommand = CreateFromMixins(KeyCommand)
	keyCommand:OnLoad(command, runOnUp, key, pressesRequired)
	return keyCommand
end

function KeyCommand_CreateKey(...)
	return { ... }
end

function KeyCommand_Update(commands)
	if not IsExtensionsLoaded() then return end
	if commands.Update then
		commands:Update()
		return true 
	end

	for _, command in pairs(commands) do
		if command:Update() then
			return true
		end
	end
end

local updater

function KeyCommand_RegisterGlobal(key, commands)
	if not updater then
		updater = CreateFrame("Frame", nil, UIParent or GlueParent)
		updater.commands = {}
		updater:SetScript("OnUpdate", function(self)
			for _, keyCommands in pairs(self.commands) do
				KeyCommand_Update(keyCommands)
			end
		end)
	end
	
	updater.commands[key] = commands
end

function KeyCommand_UnregisterGlobal(key)
	if updater then
		updater.commands[key] = nil
	end
end