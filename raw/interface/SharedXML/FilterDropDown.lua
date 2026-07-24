FilterDropDownButtonMixin = CreateFromMixins(CallbackRegistryMixin)

function FilterDropDownButtonMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    self.singleOptionMode = false
    self.filters = {}
    self.defaults = {}
    self.dropdownInfo = {
        { text = CLOSE, func = function() CloseDropDownMenus() end, notCheckable = true }
    }
    self.menuLists = {}
    self:GenerateCallbackEvents({ "OnFilterChanged", "OnFilterCleared" })
end

function FilterDropDownButtonMixin:Initialize()
    if not self.initialized then
        self.initialized = true
        UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.GenerateDropDown, self), "MENU", 1)
    end
end

function FilterDropDownButtonMixin:SetSingleOptionMode(singleOptionMode)
    self.singleOptionMode = singleOptionMode and true or false
end

function FilterDropDownButtonMixin:GenerateDropDown(dropdown, level, menuList)
    level = level or 1
    if level == 1 then
        for _, info in ipairs(self.dropdownInfo) do
            if not info.condition or info.condition() then
                info.isRadio = info.func and self.singleOptionMode
                UIDropDownMenu_AddButton(info, level)
            end
        end
    elseif menuList and self.menuLists[menuList] then
        for _, info in ipairs(self.menuLists[menuList]) do
            if not info.condition or info.condition() then
                info.isRadio = info.func and self.singleOptionMode
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
end

function FilterDropDownButtonMixin:IsFiltered(key)
    if next(self.filters) then
        return self.filters[key]
    else
        return self.defaults[key]
    end
end 

function FilterDropDownButtonMixin:IsFilteredFind(partialKey)
    for key in pairs(self.filters) do
        if string.find(key, partialKey, 1, true) then
            return true
        end
    end
end

function FilterDropDownButtonMixin:HasAnyFilters()
    local hasFilters = false
    for k, v in pairs(self.filters) do
        if self.defaults[k] ~= v then
            hasFilters = true
            break
        end
    end
    
    return hasFilters
end

function FilterDropDownButtonMixin:GetFilter()
    if next(self.filters) then
        return self.filters
    else
        return self.defaults
    end
end

function FilterDropDownButtonMixin:GetFilterKeys()
    if next(self.filters) then
        return GetKeysArray(self.filters)
    else
        return GetKeysArray(self.defaults)
    end
end

function FilterDropDownButtonMixin:UpdateClearFilterButton()
    self.ClearFilterButton:SetShown(self:HasAnyFilters())
end

function FilterDropDownButtonMixin:SetFilterInternal(key, value)
    self.filters[key] = value and value or nil
    if self.menuLists[key] then
        for _, subInfo in ipairs(self.menuLists[key]) do
            self:SetFilterInternal(subInfo.arg1, value)
        end
    end
end

function FilterDropDownButtonMixin:SetFilter(key, value)
    self:SetFilterInternal(key, value)
    self:TriggerEvent("OnFilterChanged", key, value)
    self:UpdateClearFilterButton()
    UIDropDownMenu_RefreshChecks()
end

function FilterDropDownButtonMixin:SetToSingleFilter(key)
    wipe(self.filters)
    self:SetFilter(key, true)
end

function FilterDropDownButtonMixin:AddDefaultFilter(key)
    self.defaults[key] = true
end

function FilterDropDownButtonMixin:RemoveDefaultFilter(key)
    self.defaults[key] = nil
end

function FilterDropDownButtonMixin:ClearFilters()
    wipe(self.filters)
    self:TriggerEvent("OnFilterChanged")
    self:TriggerEvent("OnFilterCleared")
    self:UpdateClearFilterButton()
    UIDropDownMenu_RefreshChecks()
end

function FilterDropDownButtonMixin:ClearFilterExcept(...)
    local savedValues = {}
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        savedValues[key] = self.filters[key]
    end
    wipe(self.filters)
    for key, value in pairs(savedValues) do
        self.filters[key] = value
    end
    self:TriggerEvent("OnFilterChanged")
    self:TriggerEvent("OnFilterCleared")
    self:UpdateClearFilterButton()
    UIDropDownMenu_RefreshChecks()
end

function FilterDropDownButtonMixin:ClearDropDown()
    wipe(self.dropdownInfo)
    wipe(self.menuLists)

    self.filters = {}

    self.dropdownInfo = {
        { text = CLOSE, func = function() CloseDropDownMenus() end, notCheckable = true }
    }
    self.menuLists = {}
end

function FilterDropDownButtonMixin:CreateFilterInfo(text, color, icon, condition, tooltip)
    local info = UIDropDownMenu_CreateInfo()
    text = _G[text] or text
    info.text = color and color:WrapText(text) or text
    info.condition = condition
    if tooltip then
        info.tooltipTitle = info.text
        info.tooltipText = _G[tooltip] or tooltip
    end
    info.keepShownOnClick = 1
    if icon then
        if icon:find("\\") then
            info.icon = icon
        else
            info.iconAtlas = icon
        end
    end
    return info
end

function FilterDropDownButtonMixin:GetDropDownInfoByKey(key)
    for index, info in pairs(self.dropdownInfo) do
        if info.arg1 == key then
            return info
        end
        if info.menuList then
            for _, subInfo in ipairs(self.menuLists[info.menuList]) do
                if subInfo.arg1 == key then
                    return subInfo
                end
            end
        end
    end
end

function FilterDropDownButtonMixin:AddFilterOption(filterKey, info)
    info.arg1 = filterKey
    info.checked = function()
        return self:IsFiltered(filterKey)
    end
    if info.func then
        local func = info.func
        info.func = function(_, key)
            func()
            if self.singleOptionMode then
                if not self:IsFiltered(key) then
                    self:SetToSingleFilter(key)
                else
                    self:SetFilter(key, not self:IsFiltered(key))
                end
            else
                self:SetFilter(key, not self:IsFiltered(key))
            end
        end
    else
        info.func = function(_, key)
            if self.singleOptionMode then
                if not self:IsFiltered(key) then
                    self:SetToSingleFilter(key)
                else
                    self:SetFilter(key, not self:IsFiltered(key))
                end
            else
                self:SetFilter(key, not self:IsFiltered(key))
            end
        end
    end
    -- insert at end (but not +1) to keep close button at the bottom
    tinsert(self.dropdownInfo, #self.dropdownInfo, table.Copy(info))
end

function FilterDropDownButtonMixin:AddCategoryOption(filterKey, name, tooltip, icon)
    local info = UIDropDownMenu_CreateInfo()
    info.text = _G[name] or name
    info.arg1 = filterKey
    if tooltip then
        info.tooltipTitle = info.text
        info.tooltipText = _G[tooltip] or tooltip
    end
    info.tooltip = tooltip
    if icon then
        if icon:find("\\") then
            info.icon = icon
        else
            info.iconAtlas = icon
        end
    end
    -- insert at end (but not +1) to keep close button at the bottom
    tinsert(self.dropdownInfo, #self.dropdownInfo, table.Copy(info))
end

function FilterDropDownButtonMixin:AddOptionSpacer(condition)
    -- insert at end (but not +1) to keep close button at the bottom
    local info = UIDropDownMenu_CreateInfo()
    info.hasArrow = false
    info.isTitle = true
    info.notCheckable = true
    info.condition = condition
    tinsert(self.dropdownInfo, #self.dropdownInfo, table.Copy(info))
end

function FilterDropDownButtonMixin:AddHeader(text, condition)
    -- insert at end (but not +1) to keep close button at the bottom
    local info = UIDropDownMenu_CreateInfo()
    info.hasArrow = false
    info.isTitle = true
    info.notCheckable = true
    info.condition = condition
    info.text = text
    tinsert(self.dropdownInfo, #self.dropdownInfo, table.Copy(info))
end

function FilterDropDownButtonMixin:AddSubFilterOption(parentFilterKey, subMenuKey, info)
    local parentInfo = self:GetDropDownInfoByKey(parentFilterKey)
    if not parentInfo then
        return
    end
    
    parentInfo.hasArrow = true
    parentInfo.menuList = parentFilterKey
    
    if not self.menuLists[parentFilterKey] then
        self.menuLists[parentFilterKey] = {}

        -- set checked function for parent to check if any subfilter is checked
        parentInfo.checked = function()
            if self:IsFiltered(parentInfo.arg1) then
                return true
            end
            for _, subInfo in ipairs(self.menuLists[parentFilterKey]) do
                if self.menuLists[subInfo.arg1] then
                    for _, subSubInfo in ipairs(self.menuLists[subInfo.arg1]) do
                        if self:IsFiltered(subSubInfo.arg1) then
                            return true
                        end
                    end
                end
                if self:IsFiltered(subInfo.arg1) then
                    return true
                end
            end

            return false
        end
    end

    info.arg1 = subMenuKey
    info.checked = function()
        return self:IsFiltered(subMenuKey)
    end
    if info.func then
        local func = info.func
        info.func = function(_, key)
            func()
            self:SetFilter(key, not self:IsFiltered(key))
        end
    else
        info.func = function(_, key)
            self:SetFilter(key, not self:IsFiltered(key))
        end
    end
    tinsert(self.menuLists[parentFilterKey], table.Copy(info))
end 


--
-- old manual setup filter dropdown
--
FilterDropDownMenuMixin = {}

function FilterDropDownMenuMixin:Initialize(func, clearFunc)
    UIDropDownMenu_Initialize(self.DropDown, func, "MENU", 1)
    if not self.ClearFilters and clearFunc then
        self.ClearFilters = clearFunc
    end
end