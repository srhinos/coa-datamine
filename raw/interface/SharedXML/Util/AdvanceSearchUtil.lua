-- Adds the base for creating an advance search handler
-- All filters are converted to lowercase.
-- Returns: searchText (text following all filters), filters
-- filters table = [key(lowercase)] = { param = param or true, operation = Enum.Comparisons or nil }
--
-- Usage:
-- local mySearchFilter = CreateFromMixinsAndLoad("AdvanceSearchMixin")
-- mySearchFilter:AddFilter("ae", tonumber)
-- -- type in search "[AE<=2] spell name"
-- local text, filters = mySearchFilter:Search(searchBox:GetText())
-- filters == [ae] { param == 2, operation == Enum.Comparisons.EqualOrLessThan }
--
AdvanceSearchMixin = {}

function AdvanceSearchMixin:OnLoad()
    self.Filters = {}
    self.KeyFormatters = {}
end


---Add a filter with an optional formatting function.
---@param key string
---@param formatter function
function AdvanceSearchMixin:AddFilter(key, formatter)
    assert(type(key) == "string", "Usage: AdvanceSearchMixin:AddFilter(string)")
    self.Filters[key:lower()] = formatter or true
end

function AdvanceSearchMixin:RemoveFilter(key)
    if not key or type(key) ~= "string" then return end
    self.Filters[key:lower()] = nil
end

function AdvanceSearchMixin:AddKeyFormatter(name, func)
    assert(type(func) == "function" and type(name) == "string", "Usage: AdvanceSearchMixin:AddKeyFormatter(string, function)")
    self.KeyFormatters[name] = func
end

function AdvanceSearchMixin:RemoveKeyFormatter(name)
    self.KeyFormatters[name] = nil
end

function AdvanceSearchMixin:Search(text)
    if not text then return end
    text = text:sanitize([[%\.*+-^$(){}]])
    local filters = {}
    local lowerText = text:lower()
    local hasKeys = false
    -- start with [
    -- Capture Key: matches %w, %s and _ any amount until operation or ending ]
    -- Capture Operation: matches (< > = ! or :) 0 to 2 times
    -- Capture Parameter: Anything following operation until ending ]
    -- Default return for param is true
    -- Cannot have operation without param.
    -- Can have key without operation or param. (In this case will return true for param and nil for operation
    for key, operation, param in lowerText:gmatch("%[([%w%s_]*)([<>=!:]?[<>=!:]?)([%w%d%s_]*)%]") do
        hasKeys = true
        for _, func in pairs(self.KeyFormatters) do
            local didReplace, newKey, newOperation, newParam = func(key, operation, param)
            if didReplace then
                key = newKey
                operation = newOperation
                param = newParam
                break
            end
        end
        
        if self.Filters[key] then
            if param == "" then
                param = nil
            elseif type(self.Filters[key]) == "function" then
                param = self.Filters[key](param)
            end
            if operation == "" then operation = nil end
            if operation then
                if operation == "<" then operation = Enum.Comparisons.LessThan
                elseif operation == ">" then operation = Enum.Comparisons.GreaterThan
                elseif operation == "!=" or operation == "=!" or operation == "~=" or operation == "=~" then operation = Enum.Comparisons.NotEqual
                elseif operation == "<=" or operation == "=<" then operation = Enum.Comparisons.EqualOrLessThan
                elseif operation == ">=" or operation == "=>" then operation = Enum.Comparisons.EqualOrGreaterThan
                else operation = Enum.Comparisons.Equal
                end
            end
            
            filters[key] = { param = param or true, operation = operation }
        end
    end
    
    local search = hasKeys and text:match("%[.*%] *(.*)") or text or ""
    
    return search, filters
end