C_CVar = C_CVar or {}

C_CVar.Minimums = {
    nameplateDistance = 5,
    nameplateVerticalOffset = -0.25,
    nameplateAngle = 0,
    lootToastMaximum = 1,
    tabTargetRange = 5,
}

C_CVar.Maximums = {
nameplateDistance = 60,
nameplateVerticalOffset = 1.25,
nameplateAngle = 3.1415,
lootToastMaximum = 6,
tabTargetRange = 100,
}

if InGlue() then
    function GetCVarInfo(cvar)
        local ok, defaultValue = pcall(GetCVarDefault, cvar)
        if ok then
            return cvar, defaultValue
        end
    end
end

function C_CVar.RegisterSavedCVar(cvar, defaultValue, minValue, maxValue)
    if minValue then
        C_CVar.Minimums[cvar] = minValue
    end
    if maxValue then
        C_CVar.Maximums[cvar] = maxValue
    end
    if not GetCVarInfo(cvar) then
        if type(defaultValue) == "boolean" then
            defaultValue = defaultValue and "1" or "0"
        end
        RegisterSavedCVar(cvar, defaultValue)
    end
end

function C_CVar.RegisterSavedCharacterCVar(cvar, defaultValue, minValue, maxValue)
    if minValue then
        C_CVar.Minimums[cvar] = minValue
    end
    if maxValue then
        C_CVar.Maximums[cvar] = maxValue
    end
    if not GetCVarInfo(cvar) then
        if type(defaultValue) == "boolean" then
            defaultValue = defaultValue and "1" or "0"
        end
        RegisterSavedCVar(cvar, defaultValue, true)
    end
end

local _GetCVarMax = GetCVarMax
local _GetCVarMin = GetCVarMin

function C_CVar.GetDefault(cvar)
    return GetCVarDefault(cvar)
end

function C_CVar.GetDefaultNumber(cvar)
    return tonumber(GetCVarDefault(cvar))
end

function C_CVar.GetDefaultBool(cvar)
    return toboolean(GetCVarDefault(cvar))
end

function C_CVar.GetDefaultBitfield(cvar, index)
    local cvarValue = GetCVarDefault(cvar)
    if cvarValue then
        local length = string.len(cvarValue)
        if index > length then
            return false
        end
        
        return cvarValue:sub(index, index) == "1"
    end

    return false
end

function C_CVar.ResetToDefault(cvar)
    C_CVar.Set(cvar, C_CVar.GetDefault(cvar))
end

function C_CVar.GetMin(cvar)
    return C_CVar.Minimums[cvar] or _GetCVarMin(cvar)
end

function C_CVar.GetMax(cvar)
    return C_CVar.Maximums[cvar] or _GetCVarMax(cvar)
end

function GetCVarMin(cvar) 
    return C_CVar.GetMin(cvar)
end

function GetCVarMax(cvar)
    return C_CVar.GetMax(cvar)
end

function C_CVar.Get(cvar)
    return GetCVar(cvar)
end

function C_CVar.GetNumber(cvar)
    return tonumber(GetCVar(cvar))
end

function C_CVar.GetBool(cvar)
    return toboolean(GetCVar(cvar))
end

function C_CVar.Set(cvar, value, triggerEvent)
    if tonumber(value) and C_CVar.Minimums[cvar] and tonumber(value) < C_CVar.Minimums[cvar] then
        value = C_CVar.Minimums[cvar]
    end
    
    if tonumber(value) and C_CVar.Maximums[cvar] and tonumber(value) > C_CVar.Maximums[cvar] then
        value = C_CVar.Maximums[cvar]
    end

    if type(value) == "boolean" then
        value = value and "1" or "0"
    end
    SetCVar(cvar, value, triggerEvent and cvar)
end

function C_CVar.GetBitfield(cvar, index)
    local cvarValue = GetCVar(cvar)
    if cvarValue then
        local length = string.len(cvarValue)
        if index > length then
            return false
        end
        
        return cvarValue:sub(index, index) == "1"
    end

    return false
end

function C_CVar.SetBitfield(cvar, index, value, triggerEvent)
    if index > 240 then
        return C_Logger.Error("C_CVar.SetBitfield", "index > 220. Make a new cvar", index, value)
    end
    local cvarValue = GetCVar(cvar)
    if cvarValue then
        local length = cvarValue:len()

        if length < index then
            local padding = string.rep("0", index - length)
            cvarValue = cvarValue .. padding
        end

        cvarValue = cvarValue:sub(1, index - 1) .. (value and "1" or "0") .. cvarValue:sub(index + 1)
        C_CVar.Set(cvar, cvarValue, triggerEvent)
    end
end

function C_CVar.SetFlag(cvar, flag, value)
    if not cvar or not flag then return end
    local cvarValue = C_CVar.GetNumber(cvar) or 0
    cvarValue = value and bit.bor(cvarValue, flag) or bit.band(cvarValue, bit.bnot(flag))
    C_CVar.Set(cvar, cvarValue)
end

function C_CVar.GetFlag(cvar, flag)
    if not cvar or not flag then return false end
    return bit.contains(C_CVar.GetNumber(cvar) or 0, flag)
end

function C_CVar.GetByteString(cvar)
local value = GetCVar(cvar)
    local str = ""
    if value then
        for i = 1, #value do
            local char = value:sub(i, i)
            local byte = char:byte()
            local byteStr = tostring(byte)
            if byteStr:len() < 3 then
                byteStr = string.rep("0", 3-byteStr:len()) .. byteStr
            end
            
            str = str .. "\\" .. byteStr
        end
    end
    
    return str
end

function C_CVar.Exists(cvar)
    return GetCVarInfo(cvar) ~= nil
end 