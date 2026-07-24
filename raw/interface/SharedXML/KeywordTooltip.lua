local keywordTooltipPool = CreateFramePool("Frame", UIParent, "KeywordTooltipTemplate")
--
-- Keyword Tooltip System
--
KeywordTooltip = {}

KeywordTooltip.TooltipType = {
    Hover = 1,
    Movable = 2,
}

local shownKeywords = {
    [KeywordTooltip.TooltipType.Hover] = {},
    [KeywordTooltip.TooltipType.Movable] = {},
}

function KeywordTooltip:Create(keyword, tooltipType, frameLevel)
    keyword = tonumber(keyword) or keyword
    if type(keyword) == "string" then
        keyword = C_Tutorial.GetKeywordID(keyword)
    end
    if not keyword or shownKeywords[tooltipType][keyword] then
        return false
    end

    local tooltip = keywordTooltipPool:Acquire()
    frameLevel = frameLevel or (keywordTooltipPool:GetNumActive() * 2)

    if tooltipType == KeywordTooltip.TooltipType.Hover then
        frameLevel = frameLevel + 50
    end

    local x, y = GetCursorPosition()
    x = (x - (GetScreenWidth() - UIParent:GetWidth()) / 2) / UIParent:GetEffectiveScale()
    y = (y - (GetScreenHeight() - UIParent:GetHeight()) / 2) / UIParent:GetEffectiveScale()
    tooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x+5, y-8)
    tooltip:SetFrameLevel(frameLevel + 1)

    tooltip:SetTooltipType(tooltipType)
    tooltip:SetKeyword(keyword)

    return true
end

function KeywordTooltip:IsMouseOverHoverTooltip(frameLevel)
    for tooltip in keywordTooltipPool:EnumerateActive() do
        if tooltip:IsMouseOver() then
            if tooltip.tooltipType == KeywordTooltip.TooltipType.Hover and tooltip:GetFrameLevel() >= frameLevel then
                return true
            end
        end
    end
    return false
end

function KeywordTooltip:ReleaseNested(tooltipType, frameLevel)
    local found
    if not tooltipType then
        found = keywordTooltipPool:GetNumActive() > 0
        keywordTooltipPool:ReleaseAll()
    else
        local toRemove = {}
        for tooltip in keywordTooltipPool:EnumerateActive() do
            if tooltip.tooltipType == tooltipType then
                if not frameLevel or tooltip:GetFrameLevel() >= frameLevel then
                    table.insert(toRemove, tooltip)
                    found = true
                end
            end
        end
        for _, tooltip in ipairs(toRemove) do
            keywordTooltipPool:Release(tooltip)
        end
    end

    return found
end

--
-- Keyword Tooltip Mixin
--
KeywordTooltipMixin = CreateFromMixins("BackdropTemplateMixin")

function KeywordTooltipMixin:OnLoad()
    self.TextPool = CreateFramePool("SimpleHTML", self, "KeywordTextTemplate")
    self.ImagePool = CreateTexturePool(self, "OVERLAY")
    self:RegisterForDrag("LeftButton")
    self:SetBackdrop(BACKDROP_TOOLTIP_8_8_1111)
    self.tooltipType = KeywordTooltip.TooltipType.Hover
end

function KeywordTooltipMixin:OnShow()
    self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR:GetRGBA())
    self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR:GetRGBA())
    self:UpdateType()
end

function KeywordTooltipMixin:OnHide()
    if self.keyword then
        shownKeywords[self.tooltipType][self.keyword] = nil
    end
    self.keyword = nil
    self.TextPool:ReleaseAll()
    self.ImagePool:ReleaseAll()
    self.Title:SetText("")
    self:SetHeight(58)
end


function KeywordTooltipMixin:AddImage(tag, parent)
    if tag:len() > 0 then
        local filePath, imageWidth, imageHeight, left, right, top, bottom = TextureUtil.ResolveCustomTextureTag(tag)
        local width = self:GetWidth()-24
        local image = self.ImagePool:Acquire()

        imageWidth = imageWidth or width
        imageHeight = imageHeight or imageWidth

        imageWidth, imageHeight = TextureUtil.FitTextureToWidth(width, imageHeight, imageWidth, imageHeight)
        image:SetSize(imageWidth, imageHeight)
        image:SetTexture(filePath)
        image:SetTexCoord(left, right, top, bottom)
        if parent then
            image:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -2)
        end
        image:Show()
        return image, image:GetHeight() + 10
    end

    return nil, 0
end

function KeywordTooltipMixin:AddLine(text, parent, r, g, b, a)
    text = text:gsub("^\n", ""):gsub("\n$", ""):trim()
    if text:len() == 0 then
        return nil, 0
    end

    local line = self.TextPool:Acquire()
    line:SetWidth(self:GetWidth()-24)
    line:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -2)
    local height = line:SetDynamicText(text)
    line:SetTextColor(r, g, b, a)
    line:Show()
    return line, height
end

function KeywordTooltipMixin:FormatLine(text)
    local lastSection = self.Title
    local section, sectionHeight
    local height = 28
    local imageStart = string.find(text, "{", 1, true)
    local imageEnd = string.find(text, "}", 1, true)
    if imageStart then
        -- we have image(s) in the description
        while text:len() > 0 do
            -- text before image tag
            section, sectionHeight = self:AddLine(string.sub(text, 1, imageStart-1), lastSection, 1, 0.82, 0)
            height = height + sectionHeight
            lastSection = section or lastSection
            lastSection.tooltipType = self.tooltipType

            -- image tag
            local image = string.sub(text, imageStart, imageEnd)
            section, sectionHeight = self:AddImage(image, lastSection)
            height = height + sectionHeight
            lastSection = section or lastSection
            lastSection.tooltipType = self.tooltipType

            -- text after image tag
            text = string.sub(text, imageEnd+1)

            -- check if the rest is just text
            imageStart = string.find(text, "{", 1, true)
            imageEnd = string.find(text, "}", 1, true)
            if not imageStart then
                section, sectionHeight = self:AddLine(text, lastSection, 1, 0.82, 0)
                height = height + sectionHeight
                lastSection = section or lastSection
                lastSection.tooltipType = self.tooltipType
                break
            end
        end
    else
        section, sectionHeight = self:AddLine(text, lastSection, 1, 0.82, 0)
        height = height + sectionHeight
        section.tooltipType = self.tooltipType
    end
    
    self:SetHeight(self:GetHeight()+height)
end

function KeywordTooltipMixin:SetKeyword(keyword)
    self.keyword = keyword
    shownKeywords[self.tooltipType][keyword] = true

    local keywordName, keywordTooltip = C_Tutorial.GetKeywordInfo(keyword)
    self.Title:SetText(keywordName)
    self.Title:SetTextColor(1, 1, 1)
    self:FormatLine(keywordTooltip)
    self:Show()
end

function KeywordTooltipMixin:Close()
    keywordTooltipPool:Release(self)
end

function KeywordTooltipMixin:ViewAppendix()
    OpenPathToAscensionAppendix(self.keyword)
    if self.tooltipType == KeywordTooltip.TooltipType.Hover then
        self:Close()
    end
end

function KeywordTooltipMixin:UpdateType()
    if self.tooltipType == KeywordTooltip.TooltipType.Hover then
        self.CloseButton:Hide()
        self:SetScript("OnLeave", self.OnLeave)
        self:SetScript("OnDragStart", nil)
        self:SetScript("OnDragStop", nil)
    elseif self.tooltipType == KeywordTooltip.TooltipType.Movable then
        self.CloseButton:Show()
        self:SetScript("OnLeave", nil)
        self:SetScript("OnDragStart", self.OnDragStart)
        self:SetScript("OnDragStop", self.OnDragStop)
    end
end

function KeywordTooltipMixin:OnDragStart()
    self:StartMoving()
end

function KeywordTooltipMixin:OnDragStop()
    self:StopMovingOrSizing()
end

function KeywordTooltipMixin:OnLeave()
    if not KeywordTooltip:IsMouseOverHoverTooltip(self:GetFrameLevel()) then
        KeywordTooltip:ReleaseNested(KeywordTooltip.TooltipType.Hover, self:GetFrameLevel())
    end
end

function KeywordTooltipMixin:SetTooltipType(tooltipType)
    self.tooltipType = tooltipType
    self:UpdateType()
end