AtlasBrowserListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function AtlasBrowserListItemMixin:OnLoad()
    self:SetNormalAtlas("PetList-ButtonBackground")
    self:SetHighlightAtlas("PetList-ButtonHighlight")
end

function AtlasBrowserListItemMixin:Update()
    self.texture = AtlasBrowser:GetTextureAtIndex(self.index)
    self.textureName = self.texture:match("\\([^\\]*)$")
    self:SetText(self.textureName)
    self:UpdateText()
end

function AtlasBrowserListItemMixin:UpdateText()
    if AtlasBrowser:HasSearch() then
        if AtlasBrowser:MatchesSearch(self.textureName or "") then
            self.Text:SetTextColor(1, 1, 1)
        else
            for _, atlas in ipairs(AtlasBrowser:GetAtlasesForTexture(self.texture)) do
                if AtlasBrowser:MatchesSearch(atlas) then
                    self.Text:SetTextColor(YELLOW_FONT_COLOR:GetRGB())
                    return
                end
            end
            self.Text:SetTextColor(0.4, 0.4, 0.4)
        end
    else
        self.Text:SetTextColor(1, 1, 1)
    end
end

function AtlasBrowserListItemMixin:OnSelected()
    AtlasBrowser:SelectTextureIndex(self.index)
end