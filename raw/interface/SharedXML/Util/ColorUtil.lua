function WrapInColorCode(text, color)
    if not color then return text end
    return format("|c%s%s|r", color, text)
end

ColorPrototype = {}
ColorMT = { __index = ColorPrototype }

function CreateColor(r, g, b, a)
    local color = {}
    setmetatable(color, ColorMT)
    color:OnLoad(r, g, b, a)
    return color
end

function CreateColorFromCode(colorCode)
    local a, r, g, b = colorCode:match("|c(%x%x)(%x%x)(%x%x)(%x%x)")

    if not a then
        a, r, g, b = colorCode:match("(%x%x)(%x%x)(%x%x)(%x%x)")
    end
    
    a = tonumber("0x"..a)
    r = tonumber("0x"..r)
    g = tonumber("0x"..g)
    b = tonumber("0x"..b)
    
    return CreateColor(r, g, b, a)
end
function ColorPrototype:OnLoad(r, g, b, a)
    self:SetRGBA(r, g, b, a)
end

function ColorPrototype:Normalize()
    if self.r > 1 or self.g > 1 or self.b > 1 or self.a > 1 then
        self.r = self.r / 255
        self.g = self.g / 255
        self.b = self.b / 255
        self.a = self.a / 255
    end
end

function ColorPrototype:GetRGB()
    return self.r, self.g, self.b
end

function ColorPrototype:GetRGBA()
    return self.r, self.g, self.b, self.a
end

function ColorPrototype:SetRGBA(r, g, b, a)
    a = a or 1
    self.r, self.g, self.b, self.a = r, g, b, a
    self:Normalize()
    self.colorStr = nil
    self.colorStr = self:GetHex()
    self.hex = "|c"..self.colorStr
    self[1] = r
    self[2] = g
    self[3] = b
    self[4] = a
    
    self.h = nil
    self.s = nil
    self.v = nil
end

function ColorPrototype:SetRGB(r, g, b)
    self:SetRGBA(r, g, b, 1)
end

local function Round(val)
    return math.floor(val+0.5)
end

function ColorPrototype:GetRGBABytes()
    return Round(self.r * 255), Round(self.g * 255), Round(self.b * 255), Round(self.a * 255)
end

function ColorPrototype:GetHex()
    if self.colorStr then
        return self.colorStr
    end
    local r, g, b, a = self:GetRGBABytes()
    return format("%.2x%.2x%.2x%.2x", a, r, g, b)
end

function ColorPrototype:WrapText(text)
    return format("|c%s%s|r", self:GetHex(), text)
end

function ColorPrototype:GetHSV()
    if not self.h or not self.s or not self.v then
        self.h, self.s, self.v = ColorUtil:RGBToHSV(self:GetRGB())
    end
    return self.h, self.s, self.v
end

function ColorPrototype:SetHSV(h, s, v, a)
    local r, g, b = ColorUtil:HSVToRGB(h, s, v)
    self:SetRGBA(r, g, b, a or self.a or 1)
    self.h, self.s, self.v = h, s, v
end

function ColorPrototype:Clone()
    local color = CreateColor(self.r, self.g, self.b, self.a)
    color.h = self.h
    color.s = self.s
    color.v = self.v
    return color
end

function ColorPrototype:SetSaturation(saturation)
    local h, s, v = self:GetHSV()
    s = saturation
    self:SetHSV(h, s, v)
    
    return self
end

function ColorPrototype:SetBrightness(brightness)
    local h, s, v = self:GetHSV()
    v = brightness
    self:SetHSV(h, s, v)
    
    return self
end

ColorUtil = {}

-- https://stackoverflow.com/questions/3018313/algorithm-to-convert-rgb-to-hsv-and-hsv-to-rgb-in-range-0-255-for-both
function ColorUtil:HSVToRGB(h, s, v)
    local r, g, b
    
    if s <= 0 then
        return v, v, v
    end

    local hh = h
    if hh >= 360 then
        hh = 0
    end

    hh = hh / 60

    local i = floor(hh)

    local ff = hh - i
    local p = v * (1 - s)
    local q = v * (1 - (s * ff))
    local t = v * (1 - (s * (1 - ff)))

    if i == 0 then
        r = v
        g = t
        b = p
    elseif i == 1 then
        r = q
        g = v
        b = p
    elseif i == 2 then
        r = p
        g = v
        b = t
    elseif i == 3 then
        r = p
        g = q
        b = v
    elseif i == 4 then
        r = t
        g = p
        b = v
    else
        r = v
        g = p
        b = q
    end
    
    return r, g, b
end

function ColorUtil:RGBToHSV(r, g, b)
    local h, s, v
    local minc = min(min(r, g), b)
    local maxc = max(max(r, g), b)

    v = maxc
    local delta = maxc - minc

    if delta < 0.00001 then
        h = 0
        s = 0
        return h, s, v
    end

    if maxc > 0 then
        s = delta / maxc
    else
        s = 0
        h = 0
        return h, s, v
    end

    if r >= maxc then
        h = (g - b) / delta
    elseif g >= maxc then
        h = 2 + (b - r) / delta
    else
        h = 4 + (r - g) / delta
    end

    h = h * 60

    if h < 0 then
        h = h + 360
    end

    return h, s, v
end

function ColorUtil:Lerp(colorA, colorB, a, colorObject)
    if not colorA.GetHSV or not colorB.GetHSV then return 0, 0, 0 end 
    local hA, sA, vA = colorA:GetHSV()
    local hB, sB, vB = colorB:GetHSV()

    local h = math.lerp(hA, hB, a)
    local s = math.lerp(sA, sB, a)
    local v = math.lerp(vA, vB, a)
    local alpha = math.lerp(colorA.a, colorB.a, a)

    local r, g, b = self:HSVToRGB(h, s, v)

    if colorObject then
        colorObject:SetRGBA(r, g, b, alpha)
        return colorObject
    else
        return CreateColor(r, g, b, alpha)
    end
end

function ColorUtil.MakeColorCode(r, g, b, a)
    return format("|c%.2x%.2x%.2x%.2x", a or 1, r, g, b)
end

function ColorUtil.WrapText(text, r, g, b)
    return format("|c%.2x%.2x%.2x%.2x%s|r", 1, r, g, b, text)
end

function ColorUtil.WrapTextInColorCode(text, colorCode)
    return format("|c%s%s|r", colorCode, text)
end
WrapTextInColorCode = ColorUtil.WrapTextInColorCode