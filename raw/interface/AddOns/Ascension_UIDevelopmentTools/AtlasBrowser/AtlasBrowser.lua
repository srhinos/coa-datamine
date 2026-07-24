AtlasBrowserMixin = CreateFromMixins(CallbackRegistryMixin)

function AtlasBrowserMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    BasicFrame_SetTitle(self, "Ascension Atlas Browser")
    self.atlasTextures = {}
    self.atlasesByTexture = {}
    self.filteredAtlasTextures = {}
    self.AtlasImage = CreateFrame("Frame", "$parentAtlasImage", self, "AtlasBrowserImageTemplate")
    self.AtlasImage:SetSize(self.RightInset.PanZoom:GetSize())
    self.AtlasImage.PanZoom = self.RightInset.PanZoom
    self.RightInset.PanZoom:SetContent(self.AtlasImage)
    self.LeftInset.ScrollList:SetGetNumResultsFunction(function() return #self.filteredAtlasTextures end)
    self.LeftInset.ScrollList:SetTemplate("AtlasBrowserListItemTemplate")
    self.LeftInset.ScrollList:GetSelectedHighlight():SetAtlas("PetList-ButtonSelect", Const.TextureKit.IgnoreAtlasSize)
    
    self:GenerateCallbackEvents({
        "SearchTextChanged",
    })
    
    self:RegisterForDrag("LeftButton")
end

function AtlasBrowserMixin:OnShow()
    if self.Initialize then
        self:Initialize()
    end
    
    self:ClearSearch()
    self.LeftInset.ScrollList:RefreshScrollFrame()
end

function AtlasBrowserMixin:Initialize()
    for atlas, info in pairs(AtlasInfo) do
        local texture = info[1]
        if not self.atlasesByTexture[texture] then
            self.atlasesByTexture[texture] = {}
            tinsert(self.atlasTextures, texture)
        end
        
        tinsert(self.atlasesByTexture[texture], atlas)
    end
    
    self.Initialize = nil
end

function AtlasBrowserMixin:GetTextureAtIndex(index)
    return self.filteredAtlasTextures[index]
end

function AtlasBrowserMixin:GetAtlasesForTexture(texture)
    return self.atlasesByTexture[texture]
end

function AtlasBrowserMixin:SelectTextureIndex(index)
    local texture = self:GetTextureAtIndex(index)
    local atlases = self:GetAtlasesForTexture(texture)
    self.AtlasImage:SetTextureInfo(texture, atlases)
end 

function AtlasBrowserMixin:UpdateSearch()
    self.searchText = self.LeftInset.Search:GetText():lower()
    
    wipe(self.filteredAtlasTextures)
    
    for _, texture in ipairs(self.atlasTextures) do
        if not self:HasSearch() or self:MatchesSearch(texture:match("\\([^\\]*)$")) then
            tinsert(self.filteredAtlasTextures, texture)
        else
            for _, atlas in ipairs(self:GetAtlasesForTexture(texture)) do
                if self:MatchesSearch(atlas) then
                    tinsert(self.filteredAtlasTextures, texture)
                    break
                end
            end
        end
    end
    
    self.LeftInset.ScrollList:RefreshScrollFrame()
    self:TriggerEvent("SearchTextChanged")
end

function AtlasBrowserMixin:HasSearch()
    return not string.isNilOrEmpty(self.searchText)
end

function AtlasBrowserMixin:MatchesSearch(text)
    return text:lower():find(self.searchText, 1, true)
end 

function AtlasBrowserMixin:ClearSearch()
    self.LeftInset.Search:SetText("")
    self:UpdateSearch()
end 

function AtlasBrowserMixin:OnDragStart()
    self:StartMoving()
end 

function AtlasBrowserMixin:OnDragStop()
    self:StopMovingOrSizing()
end