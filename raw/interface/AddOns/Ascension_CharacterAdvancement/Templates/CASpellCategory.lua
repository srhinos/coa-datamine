CASpellCategoryMixin = CreateFromMixins(ThreeSliceMixin)

function CASpellCategoryMixin:OnLoad()
    ThreeSliceMixin.OnLoad(self)

    self.Highlight:SetAtlas("search-highlight", Const.TextureKit.IgnoreAtlasSize)
end