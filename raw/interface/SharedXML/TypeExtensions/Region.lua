local ExtendedTypes = {}
ExtendedTypes["Frame"] = CreateFrame("Frame")
ExtendedTypes["Button"] = CreateFrame("Button")
ExtendedTypes["Slider"] = CreateFrame("Slider")
ExtendedTypes["StatusBar"] = CreateFrame("StatusBar")
ExtendedTypes["SimpleHTML"] = CreateFrame("SimpleHTML")
ExtendedTypes["ScrollFrame"] = CreateFrame("ScrollFrame")
ExtendedTypes["CheckButton"] = CreateFrame("CheckButton")
ExtendedTypes["Model"] = CreateFrame("Model")
ExtendedTypes["EditBox"] = CreateFrame("EditBox")
ExtendedTypes["ScrollingMessageFrame"] = CreateFrame("ScrollingMessageFrame")
ExtendedTypes["MessageFrame"] = CreateFrame("MessageFrame")

ExtendedTypes["Texture"] = ExtendedTypes.Frame:CreateTexture()
ExtendedTypes["FontString"] = ExtendedTypes.Frame:CreateFontString()

if WorldFrame then
    ExtendedTypes["DressUpModel"] = CreateFrame("DressUpModel")
    ExtendedTypes["GameTooltip"] = CreateFrame("GameTooltip")
    ExtendedTypes["PlayerModel"] = CreateFrame("PlayerModel")
    ExtendedTypes["TabardModel"] = CreateFrame("TabardModel")
    ExtendedTypes["Cooldown"] = CreateFrame("Cooldown")
end

-- Region
-- these apply to everything
local Region = {}
function Region:SetShown(show)
    if show then
        self:Show()
    else
        self:Hide()
    end
end

function Region:ClearAndSetPoint(...)
    self:ClearAllPoints()
    self:SetPoint(...)
end

function Region:HookEvent(event, callback)
    C_Hook:Register(self, event, callback)
end

function Region:UnhookEvent(event)
    C_Hook:Unregister(self, event)
end

function Region:UnhookAllEvents()
    C_Hook:Unregister(self)
end

function Region:HookBucketEvent(event, period, callback)
    C_Hook:RegisterBucket(self, event, period, callback)
end

function Region:FrameFadeIn(duration)
    if not self:IsVisible() then
        self:Show()
    end

    local fadeInfo = {}
    fadeInfo.mode = "IN"
    fadeInfo.timeToFade = duration or 0.5
    fadeInfo.startAlpha = 0
    fadeInfo.endAlpha = 1
    UIFrameFade(self, fadeInfo)
end

function Region:FrameFadeOut(duration)
    if not self:IsVisible() then
        self:Show()
    end
    local fadeInfo = {}
    fadeInfo.mode = "OUT"
    fadeInfo.timeToFade = duration or 0.5
    fadeInfo.startAlpha = 1
    fadeInfo.endAlpha = 0
    fadeInfo.finishedFunc = function() self:Hide() end
    UIFrameFade(self, fadeInfo)
end

function Region:GetPointByName(p)
    for i = 1, self:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = self:GetPoint(i)
        if point == p then
            relativeTo = relativeTo or self:GetParent()
            relativePoint = relativePoint or point
            x = x or 0
            y = y or 0
            return point, relativeTo, relativePoint, x, y
        end
    end
end

function Region:GetPointOffset()
    if not self.pointOffsets then return 0, 0 end
    return self.pointOffsets.x, self.pointOffsets.y
end

function Region:AdjustPointOffset(x, y)
    self.pointOffsets = self.pointOffsets or Vector2D(0, 0)

    self.pointOffsets:SetXY(self.pointOffsets.x + x, self.pointOffsets.y + y)

    for i = 1, self:GetNumPoints() do
        local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint(i)
        self:SetPoint(point, relativeTo, relativePoint, offsetX + self.pointOffsets.x, offsetY + self.pointOffsets.y)
    end
end

function Region:SetPointOffset(x, y)
    self:ResetPointsOffset()
    self.pointOffsets = self.pointOffsets or Vector2D(0, 0)

    self.pointOffsets:SetXY(x, y)

    for i = 1, self:GetNumPoints() do
        local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint(i)
        self:SetPoint(point, relativeTo, relativePoint, offsetX + self.pointOffsets.x, offsetY + self.pointOffsets.y)
    end
end

function Region:ResetPointsOffset()
    if not self.pointOffsets then return end

    for i = 1, self:GetNumPoints() do
        local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint(i)
        self:SetPoint(point, relativeTo, relativePoint, offsetX - self.pointOffsets.x, offsetY - self.pointOffsets.y)
    end

    self.pointOffsets:SetXY(0, 0)
end

function Region:GetScaledRect()
    local frameLeft, frameBottom, frameWidth, frameHeight = self:GetRect()
    local scale = self.GetEffectiveScale and self:GetEffectiveScale() or 1
    scale = scale / GetUIScale()
    if frameLeft then
        return frameLeft * scale, frameBottom * scale, frameWidth * scale, frameHeight * scale
    end
    return frameLeft, frameBottom, frameWidth, frameHeight
end

function Region:SetIgnoreParentAlpha(ignore)
    return
end

function Region:GetDebugName()
    local name
    if self.GetName then
        name = self:GetName()
    end

    if not name then
        name = tostring(self) or "<unknown>"
    end
    
    return name
end

for frameType, frame in pairs(ExtendedTypes) do
    frame:Hide()
    _G["Get"..frameType.."Metatable"] = function()
        return getmetatable(frame)
    end
    
    local metatable = getmetatable(frame)
    for method, func in pairs(Region) do
        metatable.__index[method] = func
    end
end

ExtendedTypes = nil