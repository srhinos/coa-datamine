local frameObjects = {}
 table.insert(frameObjects, GetFrameMetatable().__index)
 table.insert(frameObjects, GetButtonMetatable().__index)
 table.insert(frameObjects, GetSliderMetatable().__index)
 table.insert(frameObjects, GetStatusBarMetatable().__index)
 table.insert(frameObjects, GetSimpleHTMLMetatable().__index)
 table.insert(frameObjects, GetScrollFrameMetatable().__index)
 table.insert(frameObjects, GetCheckButtonMetatable().__index)
 table.insert(frameObjects, GetModelMetatable().__index)
 table.insert(frameObjects, GetEditBoxMetatable().__index)
 table.insert(frameObjects, GetScrollingMessageFrameMetatable().__index)
 table.insert(frameObjects, GetMessageFrameMetatable().__index)

if WorldFrame then
    table.insert(frameObjects, GetDressUpModelMetatable().__index)
    table.insert(frameObjects, GetGameTooltipMetatable().__index)
    table.insert(frameObjects, GetPlayerModelMetatable().__index)
    table.insert(frameObjects, GetTabardModelMetatable().__index)
    table.insert(frameObjects, GetCooldownMetatable().__index)
end

local Frame = {}
function Frame:CallScript(script, ...)
    assert(type(script) == "string", "Frame:CallScript(script): script must be a string")
    local func = self.GetScript and self:GetScript(script)

    if func then
        return func(self, ...)
    end
end

function Frame:SetResizeBounds(minX, minY, maxX, maxY)
    self:SetMinResize(minX, minY)
    if maxX and maxY then
        self:SetMaxResize(maxX, maxY)
    end
end

function Frame:CreateLine(name, layer)
    local line = DrawUtil.CreateLine(self, name, layer)
    return line
end

Frame.RegisterUnitEvent = "RegisterEvent"

for _, frame in ipairs(frameObjects) do
    for method, func in pairs(Frame) do
        if type(func) == "string" then
            frame[method] = frame[func]
        else
            frame[method] = func
        end
    end
end