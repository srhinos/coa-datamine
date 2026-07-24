local function PrintHelp()
	for name, command in pairs(DevConsole.Commands) do
		if command.about then
			if command.aliases then
				DevConsole:Print(format("|cff00DDFF%s|r - %s |cff00FF00Aliases:|cff00DDFF%s|r", name, command.about,
				                  command.aliases))
			else
				DevConsole:Print(format("|cff00DDFF%s|r - %s", name, command.about))
			end
		end
	end
end

DevConsole:RegisterCommand("help", "Prints this command list", PrintHelp)