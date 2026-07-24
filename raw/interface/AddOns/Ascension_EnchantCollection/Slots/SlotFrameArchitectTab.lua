ECArchitectTabMixin = {}

function ECArchitectTabMixin:OnLoad()
    self.ScrollList = CreateFrame("Frame", "$parentScrollList", self, "StandardProportionalScrollListTemplate")
    self.ScrollList:SetSize(348, 480)
    self.ScrollList:SetPoint("TOPLEFT", 8, -8)
    self.ScrollList:SetPoint("BOTTOMRIGHT", -24, 8)
    
    self.ScrollList:SetGetNumResultsFunction(function()
        return #C_BuildEditor.GetPendingBuild().RandomEnchants
    end)
    self.ScrollList:SetCanSelect(false)

    self.Background = self:CreateTexture(nil, "BACKGROUND")
    self.Background:SetAtlas("Enchant-Slot-Frame-Background", Const.TextureKit.UseAtlasSize)
    self.Background:SetPoint("CENTER", -2, -22)
end 

function ECArchitectTabMixin:OnShow()
    if not self.init then
        self.init = true
        -- size will be broken if we dont do this.
        RunNextFrame(function()
            self.ScrollList:SetTemplate("MysticEnchantArchitectTabItemTemplate")
            self:Update()
        end)
        
        return
    end
    self:Update()
end

function ECArchitectTabMixin:Update()
    EnchantCollection.NoAltarFrame:Hide()
    self.ScrollList:RefreshScrollFrame()
end

ECArchitectTabItemMixin = CreateFromMixins("ScrollListItemBaseMixin")

function ECArchitectTabItemMixin:OnLoad()
    self:SetHighlightAtlas("EnchantSlotBorderHighlight", true)
    self:SetNormalAtlas("UI-Character-Info-ItemLevel-Bounce")
    self:GetNormalTexture():SetVertexColor(0.5, 0.5, 1)
    self:GetNormalTexture():SetDrawLayer("BACKGROUND")
end

function ECArchitectTabItemMixin:Update()
    local buildEnchantInfo = C_BuildEditor.GetPendingBuild().RandomEnchants[self.index]
    self.spellID = buildEnchantInfo.Enchant
    local stacks = buildEnchantInfo.Stacks
    self.stacks = stacks

    local enchantInfo = C_MysticEnchant.GetEnchantInfoBySpell(self.spellID)
    local quality = EnchantCollectionUtil:GetQualityFromQualityName(enchantInfo.Quality)

    self:GetNormalTexture():SetAlpha(self.index % 2 == 0 and 1 or 0.4)

    local name, _, icon = GetSpellInfo(self.spellID)
    self:SetText(ITEM_QUALITY_COLORS[quality]:WrapText(name))
    self.Count:SetFormattedText("x%d", stacks)
    if stacks < enchantInfo.MaxStacks then
        self.Count:SetTextColor(GREEN_FONT_COLOR:GetRGB())
    else
        self.Count:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end
    
    self.Icon:SetSize(32, 32)
    self.Icon:SetPortraitTexture(icon)
    self.QualityBorder:SetAtlas(Enum.ECSlotBorderStylesKnown[quality], Const.TextureKit.UseAtlasSize)
    
    self.AddStacksButton:SetShown(stacks < enchantInfo.MaxStacks)
    self.RemoveStacksButton:SetShown(stacks > 1)
end

function ECArchitectTabItemMixin:OnEnter()
    self:LockHighlight()
    self.RemoveButton:SetAlpha(1)
    self.AddStacksButton:SetAlpha(1)
    self.RemoveStacksButton:SetAlpha(1)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.spellID)
    GameTooltip:Show()
end

function ECArchitectTabItemMixin:OnLeave()
    if self:IsMouseOver() then return end
    self:UnlockHighlight()
    self.RemoveButton:SetAlpha(0.4)
    self.AddStacksButton:SetAlpha(0.4)
    self.RemoveStacksButton:SetAlpha(0.4)
    GameTooltip:Hide()
end

function ECArchitectTabItemMixin:Remove()
    C_BuildEditor.RemoveRandomEnchant(self.spellID)
    self:GetScrollList():RefreshScrollFrame()
end 

function ECArchitectTabItemMixin:AddStacks()
    C_BuildEditor.SetEnchantStacks(self.spellID, self.stacks + 1)
    self:GetScrollList():RefreshScrollFrame()
end 

function ECArchitectTabItemMixin:RemoveStacks()
    C_BuildEditor.SetEnchantStacks(self.spellID, self.stacks - 1)
    self:GetScrollList():RefreshScrollFrame()
end