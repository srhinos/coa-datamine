local Texture = GetTextureMetatable().__index

function Texture:SetAtlas(atlas, useAtlasSize)
    if not atlas then
        self:SetTexture(nil)
        return
    end

    self.atlas = atlas
    local origWidth, origHeight = self:GetSize()
    local tex, width, height, left, right, top, bottom, horizTile, vertTile = AtlasUtil:Unpack(atlas)
    self:SetTexture(tex, true)

    self:SetTexCoord(left, right, top, bottom)

    -- The texture must be 0-1 in the direction it tiles.
    -- Change vertTile / horizTile on the atlas to fix or left/right // top/bottom to be correct.
    self:SetHorizTile(horizTile)
    self:SetVertTile(vertTile)

    if useAtlasSize then
        self:SetWidth(width)
        self:SetHeight(height)
    else
        self:SetWidth(origWidth)
        self:SetHeight(origHeight)
    end
end

function Texture:GetAtlas()
    return self.atlas
end

function Texture:SetPortraitTexture(texture)
    self.atlas = nil
    self:SetTexCoord(0, 1, 0, 1)
    SetPortraitToTexture(self, texture)
end

function Texture:SetPortraitUnit(unit)
    self.atlas = nil
    self:SetTexCoord(0, 1, 0, 1)
    SetPortraitTexture(self, unit)
end

-- scale currently set tex coord by the new value
-- ex SetTexCoord(0, 0.5, 0, 0.5); ScaleTexCoord(0, 2, 0, 2)
-- >> 0, 1, 0, 1
function Texture:ScaleTexCoord(left, right, top, bottom)
    local ULx, ULy, _, LLy, URx = self:GetTexCoord()

    local oLeft, oRight, oTop, oBottom = ULx, URx, ULy, LLy

    left = math.RemapToRange(left, 0, 1, oLeft, oRight)
    right = math.RemapToRange(right, 0, 1, oLeft, oRight)
    top = math.RemapToRange(top, 0, 1, oTop, oBottom)
    bottom = math.RemapToRange(bottom, 0, 1, oTop, oBottom)

    self:SetTexCoord(left, right, top, bottom)
end

function Texture:FlipX()
    local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = self:GetTexCoord()
    self:SetTexCoord(URx, URy, LRx, LRy, ULx, ULy, LLx, LLy)
end

function Texture:FlipY()
    local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = self:GetTexCoord()
    self:SetTexCoord(LLx, LLy, ULx, ULy, LRx, LRy, URx, URy)
end

local origSetGradientAlpha = Texture.SetGradientAlpha
function Texture:SetGradientAlpha(orientation, minR, minG, minB, minA, maxR, maxG, maxB, maxA)
    if type(minR) == "table" then
        local minColor = minR
        local maxColor = minG
        minR, minG, minB, minA = minColor:GetRGBA()
        maxR, maxG, maxB, maxA = maxColor:GetRGBA()
    end

    if orientation == "VERTICAL" or orientation == "VERTICALDOWN" then
        return origSetGradientAlpha(self,"VERTICAL", minR, minG, minB, minA, maxR, maxG, maxB, maxA)
    end

    if orientation == "VERTICALUP" then
        return origSetGradientAlpha(self, "VERTICAL", maxR, maxG, maxB, maxA, minR, minG, minB, minA)
    end

    if orientation == "HORIZONTAL" or orientation == "HORIZONTALLEFT" then
        return origSetGradientAlpha(self, "HORIZONTAL", minR, minG, minB, minA, maxR, maxG, maxB, maxA)
    end

    if orientation == "HORIZONTALRIGHT" then
        return origSetGradientAlpha(self, "HORIZONTAL", maxR, maxG, maxB, maxA, minR, minG, minB, minA)
    end

    return origSetGradientAlpha(self, orientation, minR, minG, minB, minA, maxR, maxG, maxB, maxA)
end

function Texture:SetAttribute(key, value)
    self[key] = value
end

function Texture:GetAttribute(key)
    return self[key]
end

Texture.SetColorTexture = Texture.SetTexture

function Texture:SetMaskedTexture(texture, mask, size)
    if mask == TextureUtil.DefaultMask then
        SetPortraitToTexture(self, texture)
        return
    end

    if not size then
        size = TextureUtil.MaskSize.Small
    end

    if not mask:find(".", 1, true) then
        mask = mask .. ".blp"
    end

    SetMaskTexture(size, mask)
    SetPortraitToTexture(self, texture)
    SetMaskTexture(64, "Interface\\CharacterFrame\\TempPortraitAlphaMaskSmall.blp")
end 