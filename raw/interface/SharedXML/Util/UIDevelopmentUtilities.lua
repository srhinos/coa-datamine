UIDevUtil = {}

local function GetFunctionToHook(str)
    local t = string.SplitToTable(str, ".")
    if not t or #t == 0 then
        return
    end

    local obj = _G
    for i = 1, #t - 1 do
        obj = obj[t[i]]
        if not obj then
            return
        end
    end

    local func = t[#t]
    
    return obj, func
end

function UIDevUtil.FormatLocals(locals)
    if string.isNilOrEmpty(locals) then
        return locals
    end
    -- remove (*temporary) = nil
    locals = locals:gsub("%(%*temporary%) = nil\n%s*", ""):gsub("\n%(%*temporary%) = nil", "")

    -- remove function definitions
    locals = locals:gsub("%S- = <function>.-[\n]%s*", ""):gsub("\n%S- = <function>.-$", "")

    -- remove userdatas
    locals = locals:gsub("%S- = <userdata>.-[\n]%s*", "")

    -- empty tables 1 line
    locals = locals:gsub("{%s*\n%s*}", "{}")
    return locals
end

function UIDevUtil.LogFunctionCalls(name, expandTableArgs)
    local obj, func = GetFunctionToHook(name)
    if not obj or not func then
        return
    end

    hooksecurefunc(obj, func, function(...)
        if expandTableArgs then
            local args = { ... }
            for i = 1, #args do
                if type(args[i]) == "table" then
                    if args[i].GetName then
                        args[i] = "|cffffff99"..(args[i]:GetName() or tostring(args[i])).."|r|cff1aff1a"
                    else
                        args[i] = "|cffffff99{|r" .. TableUtil.PrettyPrint(args[i]) .. "|cffffff99}|cff1aff1a"
                    end
                end
            end
            print(format("|cffFFCC44[%s]|r|cff00d1ff%s|r(", SecondsToClock(GetTime()), name) .. TableUtil.PrettyPrint(args) .. ")")
        else
            print(format("|cffFFCC44[%s]|r|cff00d1ff%s|r(", SecondsToClock(GetTime()), name) .. TableUtil.PrettyPrint(...) .. ")")
        end
    end)
end
dfunc = UIDevUtil.LogFunctionCalls

function UIDevUtil.TraceFunctionCalls(name, expandTableArgs)
    local obj, func = GetFunctionToHook(name)
    if not obj or not func then
        return
    end

    hooksecurefunc(obj, func, function(...)
        local loaded = false
        if IsAddOnLoaded("Ascension_UIDevelopmentTools") then
            loaded = true
        else
            loaded = LoadAddOn("Ascension_UIDevelopmentTools")
        end

        if loaded and DevConsole then
            local stack = debugstack(2, 8, 2)
            DevConsole:Print(format("|cff00d1ffTrace [%s]|r", name))
            local stackTbl = string.SplitToTable(stack, "\n")
            if #stackTbl > 1 then
                for i = 1, #stackTbl do
                    DevConsole:Print(stackTbl[i])
                end
            else
                DevConsole:Print(stack)
            end

            local locals = UIDevUtil.FormatLocals(debuglocals(3))
            
            DevConsole:Print(format("|cff00d1ffLocals [%s]|r", name))
            local localsTbl = string.SplitToTable(locals, "\n")
            if #localsTbl > 1 then
                for i = 1, #localsTbl do
                    DevConsole:Print(localsTbl[i])
                end
            else
                DevConsole:Print(locals)
            end
        else
            print(format("|cff00d1ffTrace [%s]|r", name) .. "\n" .. debugstack(2, 8, 2))
            print("|cff00d1ffEnable UI Development Tools AddOn for Easier Reading & Locals.|r")
        end

        if expandTableArgs then
            local args = { ... }
            for i = 1, #args do
                if type(args[i]) == "table" then
                    if args[i].GetName then
                        args[i] = "|cffffff99"..(args[i]:GetName() or tostring(args[i])).."|r|cff1aff1a"
                    else
                        args[i] = "|cffffff99{|r" .. TableUtil.PrettyPrint(args[i]) .. "|cffffff99}|cff1aff1a"
                    end
                end
            end
            if loaded then
                print(format("|cffFFCC44[%s]|r|cff00d1ff%s|r(", SecondsToClock(GetTime()), name) .. TableUtil.PrettyPrint(args) .. ") |cffffcc44Trace logged to /luaconsole|r")
            else
                print(format("|cffFFCC44[%s]|r|cff00d1ff%s|r(", SecondsToClock(GetTime()), name) .. TableUtil.PrettyPrint(args) .. ")")
            end
        else
            if loaded then
                print(format("|cffFFCC44[%s]|r|cff00d1ff%s|r(", SecondsToClock(GetTime()), name) .. TableUtil.PrettyPrint(...) .. ")  |cffffcc44Trace logged to /luaconsole|r")
            else
                print(format("|cffFFCC44[%s]|r|cff00d1ff%s|r(", SecondsToClock(GetTime()), name) .. TableUtil.PrettyPrint(...) .. ")")
            end
        end
    end)
end
tfunc = UIDevUtil.TraceFunctionCalls