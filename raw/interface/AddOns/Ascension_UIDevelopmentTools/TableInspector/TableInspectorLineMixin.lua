TableInspectorLineMixin = CreateFromMixins("ScrollListItemBaseMixin")

function TableInspectorLineMixin:Update()
    self.Alternative:SetShown(self.index % 2 == 0)
    local key, value = self:GetValue()

    if type(key) == "table" then
        key = key.GetDebugName and key:GetDebugName() or tostring(key)
    elseif key == "_INSPECTPARENT_" then
        key = BRIGHTBLUE_FONT_COLOR:WrapText("Parent")
    else
        key = tostring(key)
    end

    if type(value) == "table" then
        if value.GetObjectType then
            local color = TableUtil.GetArgColor(value)
            local prefix = GREEN_FONT_COLOR:WrapText(value:GetObjectType() .. ": ")
            value = prefix .. color:WrapText(value:GetDebugName())
        else
            value = TableUtil.PrettifyArg(value)
        end
    elseif value == "UIFrameCache" then
        value = DISABLED_FONT_COLOR:WrapText(value .. " (Cannot Inspect)")
    else
        value = TableUtil.PrettifyArg(value)
    end

    self.key = key
    self.value = value

    self.Key:SetText(key)
    self.Value:SetText(value)
end

function TableInspectorLineMixin:OnRightClick()
    local key, value = self:GetValue()
    if key == "_INSPECTPARENT_" then
        key = "Parent"
    end

    if type(value) == "table" then
        if value.GetDebugName then
            value = value:GetDebugName()
        end
    end
    local copy = tostring(key) .. ": " .. tostring(value)
    Internal_CopyToClipboard(copy)
    SendSystemMessage("Copied \"" .. copy .. "\" to clipboard.")
end

function TableInspectorLineMixin:OnSelected()
    self:GetScrollList():GetParent():InspectIndex(self.index)
end

function TableInspectorLineMixin:GetValue()
    return self:GetScrollList():GetParent():GetTableValueAtIndex(self.index)
end