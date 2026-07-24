function string.SplitToTable(string, separator, formatter)
    if formatter then
        assert(type(formatter) == "function", "string.SplitToTable() formatter must be a function")
    end

    if not string:find(separator) then
        if formatter then
            string = formatter(string)
        end
        return { string }
    end

    local out = {}

    if formatter then
        assert(type(formatter) == "function", "string.SplitToTable() formatter must be a function")
    end

    for str in string:gmatch("([^"..separator.."]+)") do
        if formatter then
            str = formatter(str)
        end

        tinsert(out, str)
    end

    return out
end

local truestrings = {
    ["true"] = true,
    [1] = true,
    ["1"] = true,
    ["on"] = true,
    ["t"] = true,
}
function string.toboolean(str)
    if not str then
        return false
    end

    if type(str) == "boolean" then
        return str
    end

    str = tostring(str)

    if str == "" then
        return false
    end

    str = str:lower()

    return truestrings[str] or false
end
toboolean = string.toboolean

local defaultSanitize = [[%.^$\+*-?(){}]].."[]"
function string.sanitize(str, characterSet)
    if not characterSet then characterSet = defaultSanitize end
    for char in characterSet:gmatch("(.)") do
        str = str:gsub("%"..char, "%%%"..char)
    end
    return str
end
strsanitize = string.sanitize

local LOCAL_ToStringAllTemp = {}
local function tostringall(...)
    local n = select('#', ...);
    -- Simple versions for common argument counts
    if (n == 1) then
        return tostring(...);
    elseif (n == 2) then
        local a, b = ...;
        return tostring(a), tostring(b);
    elseif (n == 3) then
        local a, b, c = ...;
        return tostring(a), tostring(b), tostring(c);
    elseif (n == 0) then
        return;
    end

    local needfix;
    for i = 1, n do
        local v = select(i, ...);
        if (type(v) ~= "string") then
            needfix = i;
            break;
        end
    end
    if (not needfix) then return ...; end

    wipe(LOCAL_ToStringAllTemp);
    for i = 1, needfix - 1 do
        LOCAL_ToStringAllTemp[i] = select(i, ...);
    end
    for i = needfix, n do
        LOCAL_ToStringAllTemp[i] = tostring(select(i, ...));
    end
    return unpack(LOCAL_ToStringAllTemp);
end

function makeprintable(...)
    return string.join(" ", tostringall(...))
end
tosinglestring = makeprintable

function string.startswith(str, other, caseSensitive)
    local sub = str:sub(1, strlen(other))
    if caseSensitive then
        return sub == other
    else
        return sub:lower() == other:lower()
    end
end

function string.endswith(str, other, caseSensitive)
    local len = strlen(str)
    
    local start = len + 1 - strlen(other)
    
    if start <= 0 then return false end

    local sub = str:sub(start, len)

    if caseSensitive then
        return sub == other
    else
        return sub:lower() == other:lower()
    end
end

function string.firstUpper(str)
    return str:sub(1,1):upper() .. str:sub(2):lower()
end

function string.isNilOrEmpty(str)
    return str == nil or str == ""
end 

function string.contains(str, strToFind)
    return str:find(strToFind, 1, true) ~= nil
end 
strcontains = string.contains

function string.sanitizeHTML(str)
    return str and str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("\n", "<br/>")
end