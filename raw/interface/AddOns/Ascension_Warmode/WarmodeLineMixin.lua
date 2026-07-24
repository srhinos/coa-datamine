WarmodeLineMixin = {}

function WarmodeLineMixin:OnLoad()
    self.TextBackground:SetAtlas("spellbook-text-background", Const.TextureKit.UseAtlasSize)
end

function WarmodeLineMixin:SetText(text)
    self.Text:SetText(text)
    self:SetHeight(math.max(self.Text:GetHeight() + 10, 32))
end 

function WarmodeLineMixin:SetIcon(icon)
    if icon then
        self.Icon:Show()
        self.Text:SetWidth(178)
        self.Text:SetPoint("TOPLEFT", self.Icon, "TOPRIGHT", 4, 0)
        self:SetHeight(math.max(self.Text:GetHeight() + 10, 32))
        self.Icon:SetTexture(icon)
    else
        self.Icon:Hide()
        self.Text:SetWidth(214)
        self.Text:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    end
end 