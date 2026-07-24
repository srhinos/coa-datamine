function DevConsoleMixin:RegisterCommand(command, about, func, ...)
	local closure = GenerateClosure(func, ...)
	if type(command) == "table" then
		local commands = command
		local parentTbl
		for _, command in ipairs(commands) do
			local commandTbl = { func = closure }

			if not parentTbl then
				commandTbl.about = about
				parentTbl = commandTbl
			else
				parentTbl.aliases = (parentTbl.aliases or "") .. format(" `%s` ", command:lower())
			end
			self.Commands[command:lower()] = commandTbl
		end
	else
		self.Commands[command:lower()] = {
			func = closure,
			about = about,
		}
	end
end

function DevConsoleMixin:UnregisterCommand(command)
	self.Commands[command:lower()] = nil
end

function DevConsoleMixin:RegisterAlias(alias, about, func)
	self.Aliases[alias:lower()] = {
		func = "return function(input) " .. func .. " end",
		about = about,
	}
end

function DevConsoleMixin:UnregisterAlias(alias)
	self.Aliases[alias:lower()] = nil
end

function DevConsoleMixin:RegisterDefaultCommands()
	self:RegisterCommand({ "reloadui", "rl" }, "Reloads the UI", ReloadUI)
	self:RegisterCommand({ "atlasbrowser", "ab", "av" }, "Open the Atlas Browser", ShowUIPanel, "AtlasBrowser")
	self:RegisterCommand({ "tinspect", "tdump", "ti", "tableinspector" }, "Open the Table Inspector", ShowUIPanel, "TableInspectorFrame")
	self:RegisterCommand({ "errors", "showerrors" }, "Open the UI Error Window", ShowUIPanel, "ErrorHandler")
	self:RegisterCommand("exit", "Close the console", self.Close, self)
	self:RegisterCommand("clear", "Clear the console", self.ClearConsole, self)
end