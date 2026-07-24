local function PrintHelp()
    DevConsole:Print("Usage: cvar <|cff00DDFFcvar|r> <|cff00DDFFvalue|r>")
    DevConsole:Print("Example: cvar entityShadows 1")
    DevConsole:Print("Example: cvar entityShadows")
    DevConsole:Print("-- This will print |cff00DDFFentityShadows = 1|r")
end

local function ConsoleCVar(text)
    local cvar, value = text:match("([^%s]+)%s*(.*)")
    if not cvar then return end
    if not C_CVar.Exists(cvar) then
        if cvar == "help" then
            PrintHelp()
            return
        end
        DevConsole:PrintError("CVar:", cvar, "does not exist!")
        return
    end
    
    if value and value ~= "" then
        value = value ~= nil and toboolean(value) or tonumber(value) or value
        C_CVar.Set(cvar, value)
        DevConsole:Print("Set:", cvar, "->", value)
    else
        DevConsole:Print(cvar, "=", C_CVar.Get(cvar))
    end
end

DevConsole:RegisterCommand({ "cvar" }, "Get or set the value of the given cvar. Use |cff00DDFFcvar help|r for how to use", ConsoleCVar)