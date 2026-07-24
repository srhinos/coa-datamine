local function PrintDFuncHelp()
    DevConsole:Print("Usage: dfunc <|cff00DDFFfunction|r>")
    DevConsole:Print("Example: dfunc GetItemInfo")
    DevConsole:Print("-- This will print every call of GetItemInfo with the args passed.")
    DevConsole:Print("Example: dfunc C_CharacterAdvancement.LearnID")
    DevConsole:Print("-- This will print every call of C_CharacterAdvancement.LearnID with the args passed.")
end

local function ConsoleDFunc(text)
    local func = text:match("([^%s]+)")
    if string.isNilOrEmpty(func) or func == "help" then
        PrintDFuncHelp()
        return
    end
    
    dfunc(func)
end

local function PrintTFuncHelp()
    DevConsole:Print("Usage: tfunc <|cff00DDFFfunction|r>")
    DevConsole:Print("|cff00DDFFExample:|r tfunc GetItemInfo")
    DevConsole:Print("-- This will print the callstack and locals of every GetItemInfo call, with the args passed.")
    DevConsole:Print("|cff00DDFFExample:|r tfunc C_CharacterAdvancement.LearnID")
    DevConsole:Print("-- This will print the callstack and locals of every C_CharacterAdvancement.LearnID call, with the args passed.")
end

local function ConsoleTFunc(text)
    local func = text:match("([^%s]+)")
    if string.isNilOrEmpty(func) or func == "help" then
        PrintTFuncHelp()
        return
    end

    tfunc(func)
end

DevConsole:RegisterCommand({ "dfunc" }, "Hooks a function to print the args used when the function is called.", ConsoleDFunc)
DevConsole:RegisterCommand({ "tfunc" }, "Hooks a function to print the callstack and locals, as well as the args used when the function is called.", ConsoleTFunc)