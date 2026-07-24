local function PrintHelp()
	DevConsole:Print("Usage: alias <|cff00DDFFalias|r> <|cff00DDFFscript|r>")
	DevConsole:Print("Example: alias test print('hello world')")
	DevConsole:Print("-- Typing |cff00DDFFtest|r into the console will print |cff00DDFFhello world|r")
	DevConsole:Print("Example: alias test2 print(input)")
	DevConsole:Print("-- Typing |cff00DDFFtest2 hello world|r into the console will print |cff00DDFFhello world|r")
	DevConsole:Print("Example: alias test |cff00DDFF--removes the alias|r")
end

local function Alias(script)
	if script == "help" then
		return PrintHelp()
	end

	if script == "list" then
		DevConsole:Print("Listing all aliases:")
		for alias, func in pairs(DevConsoleAliases) do
			DevConsole:Print("|cff00DDFF" .. alias .. "|r", "for", func)
		end
		return
	end
	
	local alias, func = script:match("([^%s]+)%s*(.*)")

	if not alias then
		return PrintHelp()
	end

	if not DevConsoleAliases then
		DevConsoleAliases = {}
	end
	
	if DevConsole.Commands[alias:lower()] then
		return DevConsole:PrintError("Cannot modify alias", alias, "because it is a baseline command!")
	end
	
	
	if not func or func == "" then
		DevConsoleAliases[alias] = nil
		DevConsole:UnregisterAlias(alias)
		DevConsole:Print("Removed alias", alias)
	else
		DevConsoleAliases[alias] = func
		DevConsole:RegisterAlias(alias, "alias for " .. func, func)
		DevConsole:Print("Created alias", alias, "for", func)
	end
end

DevConsole:RegisterCommand("alias", "create a function alias saved by the console", Alias)