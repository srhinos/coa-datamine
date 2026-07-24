RealmInfoMixin = {}

function RealmInfoMixin:OnLoad()
    self.IconBackground:SetAtlas("realm-select-icon-bg", Const.TextureKit.IgnoreAtlasSize)
    self.IconBorder:SetAtlas("realm-select-icon-border", Const.TextureKit.IgnoreAtlasSize)
    self.IconHighlight:SetAtlas("realm-select-icon-highlight", Const.TextureKit.IgnoreAtlasSize)
end

function RealmInfoMixin:SetText(header, text)
    self.Header:SetText(header)
    if self.Text then
        self.Text:SetText(text)
    end
end

function RealmInfoMixin:SetIcon(atlas, scale, offsetY)
    if not atlas then
        self.IconBackground:SetAtlas("realm-select-icon-bg", Const.TextureKit.IgnoreAtlasSize)
        self.Icon:SetTexture(nil)
        self.HasIcon = false
        return
    end

    self.HasIcon = true
    scale = scale or 0
    scale = 1 - scale
    self.Icon:SetAtlas(atlas, Const.TextureKit.UseAtlasSize)
    self.IconBackground:SetAtlas("realm-select-icon-bg", Const.TextureKit.IgnoreAtlasSize)
    local w, h = self.Icon:GetSize()
    local bgW, bgH = self.IconBackground:GetSize()

    w = w * (bgW / (144 * scale))
    h = h * (bgH / (144 * scale))

    self.Icon:SetSize(w, h)

    if offsetY then
        self.Icon:SetPoint("CENTER", self.IconBackground, 0, offsetY)
    end
end

function RealmInfoMixin:DesaturateIcon(desaturate)
    self.Icon:SetDesaturated(desaturate)
    if not self.HasIcon then
        self.IconBackground:SetDesaturated(desaturate)
    else
        self.IconBackground:SetDesaturated(false)
    end
end

function RealmInfoMixin:SetBackground(atlas)
    self.IconBackground:SetAtlas(atlas)
end

function RealmInfoMixin:SetBadge(atlas, scale)
    scale = scale or 0
    scale = 1 - scale
    self.Badge:SetAtlas(atlas, Const.TextureKit.UseAtlasSize)
    local w, h = self.Badge:GetSize()
    local bgW, bgH = self.IconBackground:GetSize()

    w = w * (bgW / (144 * scale))
    h = h * (bgH / (144 * scale))

    self.Badge:SetSize(w, h)
end

function RealmInfoMixin:GetText()
    return self.Header:GetText(), self.Text and self.Text:GetText()
end

function RealmInfoMixin:Disable()
    self.Header:SetFontObject("GameFontDisableOutlineLarge")
    if self.Text then
        self.Text:SetFontObject("GameFontDisableOutline")
    end
end

function RealmInfoMixin:Enable()
    self.Header:SetFontObject("GameFontNormalOutlineLarge")
    if self.Text then
        self.Text:SetFontObject("GameFontHighlightOutlineLarge")
    end
end

function RealmInfoMixin:OnEnter()
    self:GetParent():LockHighlight()
    self:GetParent():OnEnter()
    if self.tooltipTitle then
        GlueTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GlueTooltip:SetText(self.tooltipTitle, 1, 1, 1, true)
        if self.tooltipText then
            GlueTooltip:AddLine(self.tooltipText, nil, nil, nil, true)
        end
        GlueTooltip:Show()
    end
end

function RealmInfoMixin:OnLeave()
    self:GetParent():UnlockHighlight()
    self:GetParent():OnLeave()
    GlueTooltip:Hide()
end 