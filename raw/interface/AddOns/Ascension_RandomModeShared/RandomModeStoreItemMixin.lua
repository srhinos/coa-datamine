RandomModeStoreItemMixin = CreateFromMixins("CustomVendorItemMixin")


function RandomModeStoreItemMixin:OnLoad()
    CustomVendorItemMixin.OnLoad(self)
    self:RegisterCallback("OnItemChanged", self.OnItemChanged, self)
    self.CostFrames = CreateFramePool("Frame", self.Cost, "CustomVendorItemCostTemplate")
    self.Icon:SetBorderSize(38, 38)
    self.Icon:SetOverlaySize(38, 38)
    self.Icon:SetOverlayBlendMode("ADD")
end

function RandomModeStoreItemMixin:OnItemChanged()
    local itemID = self:GetItemID()
    local itemName = GetItemName(itemID)

    local cardID, cardRank = C_SkillCard.GetCardID(itemID)
    if cardID then
        local spellID = C_SkillCard.GetCardSpellID(cardID, cardRank)
        if spellID then
            itemName = GetSpellInfo(spellID)
        end
    end
    self:SetText(itemName)
    self.Icon:SetIcon("Interface\\Icons\\"..GetItemIconInstant(itemID))

    local borderAtlas = QUICKSLOT_QUALITY_BORDER_ATLAS[GetItemQuality(itemID)]
    self.Icon:SetBorderAtlas(borderAtlas)
    self.Icon:SetOverlayAtlas(borderAtlas)


    self.CostFrames:ReleaseAll()

    local moneyCost, requiredItems = self:GetCost()
    local index = 1
    if moneyCost > 0 then
        local costFrame = self.CostFrames:Acquire()
        costFrame:SetMoney(moneyCost)
        costFrame.layoutIndex = index
        costFrame:Show()
        index = index + 1
    end

    for _, requiredItem in ipairs(requiredItems) do
        local costFrame = self.CostFrames:Acquire()
        costFrame:SetItem(requiredItem.item, requiredItem.cost)
        costFrame.layoutIndex = index
        costFrame:Show()
        index = index + 1
    end

    self.Cost:MarkDirty()

    if GameTooltip:IsOwned(self) then
        self:OnEnter()
    end
end

function RandomModeStoreItemMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetHyperlink("item:"..self.itemID)
end

function RandomModeStoreItemMixin:OnLeave()
    GameTooltip:Hide()
end