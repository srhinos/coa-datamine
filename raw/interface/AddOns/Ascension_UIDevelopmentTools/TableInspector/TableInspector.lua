TableInspector = {}

TableInspector.TypeSort = {
    ["boolean"] = 1,
    ["string"] = 2,
    ["number"] = 3,
    ["table"] = 4,
    ["function"] = 5,
    ["nil"] = 6,
}

TableInspector.SkippedType = {
    ["userdata"] = true,
    ["thread"] = true,
}

function TableInspector.SortInspectedTable(left, right)
    local leftKey, leftValue = unpack(left)
    local rightKey, rightValue = unpack(right)

    if leftKey == "_INSPECTPARENT_" and rightKey ~= "_INSPECTPARENT_" then
        return true
    elseif leftKey ~= "_INSPECTPARENT_" and rightKey == "_INSPECTPARENT_" then
        return false
    end
    
    local leftKeyType = type(leftKey)
    local rightKeyType = type(rightKey)

    -- sort index numbers to top
    if leftKeyType == "number" and rightKeyType ~= "number" then
        return true
    elseif leftKeyType ~= "number" and rightKeyType == "number" then
        return false
    elseif leftKeyType == "number" and rightKeyType == "number" then
        -- if indexed just sort by number not value type
        return leftKey < rightKey
    end

    local leftValueType = type(leftValue)
    local rightValueType = type(rightValue)
    -- sort by value type
    if leftValueType ~= rightValueType then
        return TableInspector.TypeSort[leftValueType] < TableInspector.TypeSort[rightValueType]
    end

    if leftValueType == "table" and rightValueType == "table" then
        -- put region tables below regular tables
        if leftValue.GetObjectType and not rightValue.GetObjectType then
            return false
        elseif not leftValue.GetObjectType and rightValue.GetObjectType then
            return true
        end
    end
    
    -- sort by key name
    return tostring(leftKey) < tostring(rightKey)
end

TableInspectorMixin = {}
TableInspectorMixin.OnEvent = OnEventToMethod

function TableInspectorMixin:OnLoad()
    self.Background:SetAtlas("auctionhouse-background-buy-noncommodities-market", Const.TextureKit.IgnoreAtlasSize)
    self:RegisterForDrag("LeftButton")
    self.inspectDepth = 0
    self.tableDepth = {}
    self.inspectedTable = {}
    self.tableLength = 0
    
    self.InspectedTableList:SetTemplate("TableInspectorLineTemplate")
    self.InspectedTableList:SetGetNumResultsFunction(function() return self.tableLength end)
    self.InspectedTableList:SetSelectedHighlightTexture()
end

function TableInspectorMixin:OnShow()
    self.GoBackButton:SetEnabled(self:CanGoBack())
    self.InspectedTableList:SetShown(self.targetObject ~= nil)
    self.Instruction:SetShown(self.targetObject == nil)
end

function TableInspectorMixin:SearchObject(objectName)
    self.filterText = nil
    self.FilterSearch:SetText("")
    local object = not string.isNilOrEmpty(objectName) and StringToGlobalTableEntry(objectName)
    if object and type(object) == "table" then
        self:SetObject(object)
        return
    elseif not string.isNilOrEmpty(objectName) then
        -- maybe its a function?
        local func = loadstring("return "..objectName)
        if func and type(func) == "function" then
            -- safely call function
            local result = { pcall(func) }
            local ok = result[1]
            if ok then
                -- we only have a table to show
                if #result == 2 then
                    if  type(result[2]) == "table" then
                        result = result[2]
                    else
                        table.remove(result, 1)
                    end
                end
                self:SetObject(result)
                return
            end
        end
    end

    self:ClearObject()
end 

function TableInspectorMixin:FilterObject(text)
    self.filterText = text and text:lower():trim()
    self:Refresh()
end

function TableInspectorMixin:SetObject(object)
    wipe(self.tableDepth)
    self.Instruction:Hide()
    self.InspectedTableList:Show()
    self:InspectTable(object)
end

function TableInspectorMixin:ClearObject()
    BasicFrame_SetTitle(self, "Table Inspector")
    self.targetObject = nil
    self.isRegion = nil
    self.filterText = nil
    self.FilterSearch:SetText("")
    self.Search:SetText("")
    self.InspectedTableList:Hide()
    self.Instruction:Show()
end

function TableInspectorMixin:InspectTable(tbl)
    if type(tbl) ~= "table" then
        self:ClearObject()
        return
    end
    self.targetObject = tbl
    self.isRegion = tbl.GetObjectType ~= nil
    BasicFrame_SetTitle(self, "Inspect: " .. (self.isRegion and tbl:GetDebugName() or tostring(tbl)))

    self.tableDepth[#self.tableDepth + 1] = tbl
    self:Refresh()
end

function TableInspectorMixin:Refresh()
    local tbl = self.targetObject
    wipe(self.inspectedTable)
    self.tableLength = 0

    if tbl.GetParent then
        local parent = tbl:GetParent()
        if parent then
            tinsert(self.inspectedTable, { "_INSPECTPARENT_", parent })
            self.tableLength = self.tableLength + 1
        end
    end

    for key, value in pairs(tbl) do
        if not TableInspector.SkippedType[type(value)] then
            if type(value) == "table" and value.shitFrameCache then
                value = "UIFrameCache"
            end
            local pass
            if self.filterText then
                pass = false
                if tostring(key):lower():find(self.filterText, 1, true) then
                    pass = true
                elseif tostring(value):lower():find(self.filterText, 1, true) then
                    pass = true
                elseif type(value) == "table" then
                    if value.GetDebugName and tostring(value:GetDebugName()):lower():find(self.filterText, 1, true) then
                        pass = true
                    elseif value.GetObjectType and tostring(value:GetObjectType()):lower():find(self.filterText, 1, true) then
                        pass = true
                    end
                end
            else
               pass = true
            end
            if pass then
                tinsert(self.inspectedTable, { key, value })
                self.tableLength = self.tableLength + 1
            end
        end
    end

    table.sort(self.inspectedTable, TableInspector.SortInspectedTable)

    self.InspectedTableList:RefreshScrollFrame()
    self.GoBackButton:SetEnabled(self:CanGoBack())
end

function TableInspectorMixin:GetTableValueAtIndex(index)
    return unpack(self.inspectedTable[index])
end

function TableInspectorMixin:InspectIndex(index)
    local key, value = unpack(self.inspectedTable[index])
    if type(value) == "table" then
        self:InspectTable(value)
    end
end

function TableInspectorMixin:CanGoBack()
    return #self.tableDepth > 1
end

function TableInspectorMixin:GoBack()
    local depth = #self.tableDepth
    local backIndex = depth - 1
    if not self.tableDepth[backIndex] then
        return
    end
    table.remove(self.tableDepth, depth) -- remove current table

    local tbl = self.tableDepth[backIndex]
    table.remove(self.tableDepth, backIndex) -- inspect table will append to end of table depth again
    self:InspectTable(tbl)
end 

function TableInspectorMixin:OnDragStart()
    self:StartMoving()
end 

function TableInspectorMixin:OnDragStop()
    self:StopMovingOrSizing()
end 

function TableInspectorMixin:TargetFrame()
    self:RegisterEvent("GLOBAL_MOUSE_UP")
    self:Hide()
    TableInspectSelectFrame:Show()
end 

function TableInspectorMixin:GLOBAL_MOUSE_UP(mouseButton)
    self:UnregisterEvent("GLOBAL_MOUSE_UP")
    self:Show()
    TableInspectSelectFrame:Hide()
    if mouseButton == Enum.MouseButton.Left then
        local target = GetMouseFocus()
        self.Search:SetText(target:GetDebugName())
        self:SetObject(target)
    end
end 

function TableInspectorMixin:CopyEntireTable()
    local str = "Dump: " .. (self.targetObject.GetDebugName and self.targetObject:GetDebugName() or tostring(self.targetObject))
    for _, entry in pairs(self.inspectedTable) do
        local key, value = unpack(entry)
        if key == "_INSPECTPARENT_" then
            key = "Parent"
        end

        if type(value) == "table" then
            if value.GetDebugName then
                value = value:GetDebugName()
            end
        end
        local copy = tostring(key) .. ": " .. tostring(value)
        str = str .. "\n" .. copy
    end
    
    Internal_CopyToClipboard("```\n"..str.."\n```")
    SendSystemMessage("Table Copied to Clipboard!")
end 