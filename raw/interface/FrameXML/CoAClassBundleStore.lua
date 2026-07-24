CoAClassBundleStoreMixin = CreateFromMixins("CustomVendorMixin")
CoAClassBundleStoreMixin.OnEvent = OnEventToMethod

local ITEM_WIDTH, ITEM_HEIGHT = 144, 48
local X_OFFSET, Y_OFFSET = 18, -62
local NUM_COLUMNS = 4
function CoAClassBundleStoreMixin:OnLoad()
    tinsert(UISpecialFrames, self:GetName())
    CustomVendorMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self:RegisterCallback("OnStoreReady", self.OnStoreReady, self)
    self:RegisterCallback("OnStoreFailed", self.OnStoreFailed, self)
    self:RegisterCallback("OnPurchaseSuccess", self.OnPurchaseSuccess, self)
    self:RegisterCallback("OnPurchaseFailed", self.OnPurchaseFailed, self)
    self:RegisterCallback("OnStoreUpdate", self.OnStoreUpdate, self)
    self:RegisterCallback("OnPageChanged", self.UpdatePage, self)

    self.currencyItemID = self.currencyItemID or ItemData.ITEM_COA_STORE_ITEM_1
    self.customStoreID = self.customStoreID or Enum.CustomStores.CoAClassBundleStore

    self:SetStoreID(self.customStoreID)
    self:SetItemsPerPage(24)
    self:SetSearch(self.SearchBox)
    self:SetFilter(self.Filter)

    self.Currency:SetItem(self.currencyItemID, true)
    
    self.ErrorFrame:SetFrameLevel(self:GetFrameLevel() + 20)
    self.LoadingFrame:SetFrameLevel(self:GetFrameLevel() + 20)

    for i = 1, 24 do
        local item = CreateFrame("Button", "$parentItem"..i, self, "CoAClassBundleStoreItemTemplate")
        item:SetPoint(GetGridPoint(i, self, ITEM_WIDTH, ITEM_HEIGHT, NUM_COLUMNS, X_OFFSET, Y_OFFSET))
        self:AddItemButton(item)
    end

    PortraitFrame_SetIcon(self, "Interface\\Icons\\mail_gmicon")

    self:RegisterEvent("ITEM_USED")
end

function CoAClassBundleStoreMixin:ITEM_USED(itemID)
    if itemID == self.currencyItemID and not self:IsShown() then
        self:Show()
    end
end

function CoAClassBundleStoreMixin:UpdatePage()
    self.PageText:SetText(self.page .. "/" .. self:GetMaxPages())
    self.PreviousPageButton:SetEnabled(self:HasPreviousPage())
    self.NextPageButton:SetEnabled(self:HasNextPage())
end

function CoAClassBundleStoreMixin:OnShow()
    CustomVendorMixin.OnShow(self)
    self.Currency:UpdateDisplay()
    self:RegisterEvent("BAG_UPDATE")
end

function CoAClassBundleStoreMixin:BAG_UPDATE()
    self.Currency:UpdateDisplay()
end

function CoAClassBundleStoreMixin:OnHide()
    self:UnregisterEvent("BAG_UPDATE")
    CustomVendorMixin.OnHide(self)
end

function CoAClassBundleStoreMixin:OnStoreReady()
    self.LoadingFrame:Hide()
    PortraitFrame_SetTitle(self, C_CustomStore.GetCustomStoreTypeInfo(self.storeID))
    self:UpdatePage()
end

function CoAClassBundleStoreMixin:OnStoreFailed(result)
    self.ErrorFrame:SetText(CUSTOM_STORE_FAILED, _G[result] or result)
    self.ErrorFrame:Show()
end

function CoAClassBundleStoreMixin:OnPurchaseSuccess()
end

function CoAClassBundleStoreMixin:OnPurchaseFailed(result)
    self.ErrorFrame:SetText(PURCHASE_FAILED, _G[result] or result)
    self.ErrorFrame:Show()
end

function CoAClassBundleStoreMixin:OnStoreUpdate()
    self.LoadingFrame:Hide()
    self:UpdatePage()
end

function CoAClassBundleStoreMixin:OnDragStart()
    self:StartMoving()
end

function CoAClassBundleStoreMixin:OnDragStop()
    self:StopMovingOrSizing()
end

CoAClassBundleStore2Mixin = CreateFromMixins("CoAClassBundleStoreMixin")

function CoAClassBundleStore2Mixin:OnLoad()
    self.currencyItemID = ItemData.ITEM_COA_STORE_ITEM_2
    self.customStoreID = Enum.CustomStores.CoAClassBundleStore2
    CoAClassBundleStoreMixin.OnLoad(self)
end

--
-- item
--
CoAClassBundleStoreItemMixin = CreateFromMixins("CustomVendorItemMixin")

function CoAClassBundleStoreItemMixin:OnLoad()
    CustomVendorItemMixin.OnLoad(self)
    self.Icon:SetBorderSize(32, 32)
    self.Icon:SetOverlaySize(26, 32)
    self:RegisterCallback("OnItemChanged", self.OnItemChanged, self)
end

function CoAClassBundleStoreItemMixin:OnItemChanged()
    local itemID = self:GetItemID()
    local quality = GetItemQuality(itemID)
    self.Icon:SetBorderAtlas(QUICKSLOT_QUALITY_BORDER_ATLAS[quality])
    self.Icon:SetItem(itemID)

    self.Cost:SetText(self:GetCostString())
    
    local requiresAchievement = self:GetRequiredAchievement()
    if requiresAchievement then
        self.Icon:SetOverlayAtlas("Garr_LockedBuilding")
        self.Icon:SetDesaturated(true)
        self:SetText(DISABLED_FONT_COLOR:WrapText(GetItemName(itemID)))
        self.Cost:SetTextColor(DISABLED_FONT_COLOR:GetRGBA())
        self:Disable()
    else
        self.Icon:SetOverlayTexture(nil)
        self.Icon:SetDesaturated(false)
        self:SetText(ITEM_QUALITY_COLORS[quality]:WrapText(GetItemName(itemID)))
        self.Cost:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGBA())
        self:Enable()
    end
end

function CoAClassBundleStoreItemMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetHyperlink("item:"..self.itemID)
    local requiresAchievement, requiredAchievement = self:GetRequiredAchievement()

    if requiresAchievement then
        local _, achievementName = GetAchievementInfo(requiredAchievement)
        GameTooltip_AddSpacer(GameTooltip)
        GameTooltip:AddLine(CUSTOM_STORE_ACHIEVEMENT_REQUIRED_S:format(achievementName), RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
        GameTooltip:Show()
    end
end

function CoAClassBundleStoreItemMixin:OnLeave()
    GameTooltip:Hide()
end

