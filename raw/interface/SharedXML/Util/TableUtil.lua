TableUtil = {}

local ArgumentColors =
{
    ["string"] = GREEN_FONT_COLOR,
    ["number"] = ORANGE_FONT_COLOR,
    ["boolean"] = BRIGHTBLUE_FONT_COLOR,
    ["table"] = LIGHTYELLOW_FONT_COLOR,
    ["nil"] = GRAY_FONT_COLOR,
}

local function GetArgumentColor(arg)
    return ArgumentColors[type(arg)] or HIGHLIGHT_FONT_COLOR
end

local function FormatArgument(arg)
    local color = GetArgumentColor(arg)
    local t = type(arg)
    if t == "string" then
        return color:WrapText(string.format('"%s"', arg))
    elseif t == "nil" then
        return color:WrapText(t)
    end
    return color:WrapText(tostring(arg))
end

function TableUtil.PrettyPrint(...)
    local words = {};
    local tbl = ...
    if type(tbl) == "table" then -- table passed
        for _, value in ipairs(tbl) do
            table.insert(words, FormatArgument(value))
        end
        return table.concat(words, ", ");
    else -- list of args
        local count = select("#", ...);
        for index = 1, count do
            local arg = select(index, ...);
            table.insert(words, FormatArgument(arg));
        end

        local wordCount = #words;
        if wordCount == 0 then
            return "";
        elseif wordCount == 1 then
            return words[1];
        end
        return table.concat(words, ", ");
    end
end

function TableUtil.Prettify(tbl)
    local out = {}
    for key, value in pairs(tbl) do
        out[key] = FormatArgument(value);
    end
    return out
end

function TableUtil.PrettifyArg(arg)
    return FormatArgument(arg)
end

function TableUtil.GetArgColor(arg)
    return GetArgumentColor(arg)
end


function tDeleteItem(tbl, item)
    local size = #tbl;
    local index = size;
    while index > 0 do
        if item == tbl[index] then
            tremove(tbl, index);
        end
        index = index - 1;
    end
    return size - #tbl;
end

function SafePack(...)
    local tbl = { ... }
    tbl.n = select("#", ...)
    return tbl
end

function SafeUnpack(tbl)
    return unpack(tbl, 1, tbl.n)
end

function GetOrCreateTableEntryByCallback(table, key, callback)
    local currentValue = table[key]
    local isNewValue = (currentValue == nil)
    if isNewValue then
        currentValue = callback(key)
        table[key] = currentValue
    end

    return currentValue, isNewValue
end