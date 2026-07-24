local FontString = GetFontStringMetatable().__index
local EditBox = GetEditBoxMetatable().__index
local ScrollingMessageFrame = GetScrollingMessageFrameMetatable().__index
local MessageFrame = GetMessageFrameMetatable().__index

local function SetFontSize(self, value)
    local fontName, _, fontFlags = self:GetFont()

    self:SetFont(fontName, value, fontFlags)
end
FontString.SetFontSize = SetFontSize
EditBox.SetFontSize = SetFontSize
ScrollingMessageFrame.SetFontSize = SetFontSize
MessageFrame.SetFontSize = SetFontSize

local function SetFontFlags(self, value)
    local fontName, size = self:GetFont()

    self:SetFont(fontName, size, value)
end
FontString.SetFontFlags = SetFontFlags
EditBox.SetFontFlags = SetFontFlags
ScrollingMessageFrame.SetFontFlags = SetFontFlags
MessageFrame.SetFontFlags = SetFontFlags

function FontString:SetAttribute(key, value)
    self[key] = value
end

function FontString:GetAttribute(key)
    return self[key]
end

function FontString:FitToWidth(idealSize, width)
    width = (width or self:GetWidth()) - idealSize -- subtract idealSize because GetStringWidth cuts short
    if width <= 0 then
        return
    end
    local font, _, flags = self:GetFont()
    self:SetFont(font, math.max(idealSize, 1), flags)
    while self:GetStringWidth() > width and idealSize > 1 do
        idealSize = idealSize - 1
        self:SetFont(font, idealSize, flags)
    end
end

do
    -- these are registered backwards in client
    local getIndentedWordWrap = FontString.GetIndentedWordWrap
    local setIndentedWordWrap = FontString.SetIndentedWordWrap

    FontString.GetIndentedWordWrap = setIndentedWordWrap
    FontString.SetIndentedWordWrap = getIndentedWordWrap
end