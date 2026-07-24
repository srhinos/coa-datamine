WarmodeTierMixin = {
    HighlightAtlas = {
        "Garr_LevelBadgeGlow",
        "Garr_LevelBadgeGlow_Yellow",
        "Garr_LevelBadgeGlow_Red",
    }
}

function WarmodeTierMixin:OnLoad()
    self.Icon:SetAtlas("Garr_LevelBadge_"..self:GetID(), Const.TextureKit.UseAtlasSize)
    self.Highlight:SetAtlas(self.HighlightAtlas[self:GetID()], Const.TextureKit.UseAtlasSize)
    SetParentArray(self, "Buttons", self:GetID())
end

function WarmodeTierMixin:OnEnter()
    self:GetParent().MouseoverInfo = true
    self:GetParent():SetActive(self:GetID())

    local map = GetMapInfo()
    if not map then return end
    self:GetParent():HighlightTierZones(map, self:GetID())
end

function WarmodeTierMixin:OnLeave()
    self:GetParent().MouseoverInfo = false
    self:GetParent():HideInfo()
end