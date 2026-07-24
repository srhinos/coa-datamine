HeirloomStoreMixin = CreateFromMixins("CustomVendorMixin")
HeirloomStoreMixin.OnEvent = OnEventToMethod

local ITEM_WIDTH, ITEM_HEIGHT = 144, 48
local X_OFFSET, Y_OFFSET = 18, -62
local NUM_COLUMNS = 4
function HeirloomStoreMixin:OnLoad()
    tinsert(UISpecialFrames, self:GetName())
    CustomVendorMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self:RegisterCallback("OnStoreReady", self.OnStoreReady, self)
    self:RegisterCallback("OnStoreFailed", self.OnStoreFailed, self)
    self:RegisterCallback("OnPurchaseSuccess", self.OnPurchaseSuccess, self)
    self:RegisterCallback("OnPurchaseFailed", self.OnPurchaseFailed, self)
    self:RegisterCallback("OnStoreUpdate", self.OnStoreUpdate, self)
    self:RegisterCallback("OnPageChanged", self.UpdatePage, self)
    self:SetStoreID(Enum.CustomStores.HeirloomWeapons)
    self:SetItemsPerPage(24)
    self:SetSearch(self.SearchBox)
    self:SetFilter(self.Filter)

    self.Currency:SetItem(ItemData.HEIRLOOM_WEAPON_TOKEN, true)
    
    self.ErrorFrame:SetFrameLevel(self:GetFrameLevel() + 20)
    self.LoadingFrame:SetFrameLevel(self:GetFrameLevel() + 20)

    for i = 1, 24 do
        local item = CreateFrame("Button", "$parentItem"..i, self, "HeirloomStoreItemTemplate")
        item:SetPoint(GetGridPoint(i, self, ITEM_WIDTH, ITEM_HEIGHT, NUM_COLUMNS, X_OFFSET, Y_OFFSET))
        self:AddItemButton(item)
    end

    PortraitFrame_SetIcon(self, "Interface\\Icons\\mail_gmicon")

    self:RegisterEvent("ITEM_USED")
end

function HeirloomStoreMixin:ITEM_USED(itemID)
    if itemID == ItemData.HEIRLOOM_WEAPON_TOKEN and not self:IsShown() then
        self:Show()
    end
end

function HeirloomStoreMixin:UpdatePage()
    self.PageText:SetText(self.page .. "/" .. self:GetMaxPages())
    self.PreviousPageButton:SetEnabled(self:HasPreviousPage())
    self.NextPageButton:SetEnabled(self:HasNextPage())
end

function HeirloomStoreMixin:OnShow()
    CustomVendorMixin.OnShow(self)
    self.Currency:UpdateDisplay()
    self:RegisterEvent("BAG_UPDATE")
end

function HeirloomStoreMixin:BAG_UPDATE()
    self.Currency:UpdateDisplay()
end

function HeirloomStoreMixin:OnHide()
    self:UnregisterEvent("BAG_UPDATE")
    CustomVendorMixin.OnHide(self)
end

function HeirloomStoreMixin:OnStoreReady()
    self.LoadingFrame:Hide()
    PortraitFrame_SetTitle(self, C_CustomStore.GetCustomStoreTypeInfo(self.storeID))
    self:UpdatePage()
end

function HeirloomStoreMixin:OnStoreFailed(result)
    self.ErrorFrame:SetText(CUSTOM_STORE_FAILED, _G[result] or result)
    self.ErrorFrame:Show()
end

function HeirloomStoreMixin:OnPurchaseSuccess()
end

function HeirloomStoreMixin:OnPurchaseFailed(result)
    self.ErrorFrame:SetText(PURCHASE_FAILED, _G[result] or result)
    self.ErrorFrame:Show()
end

function HeirloomStoreMixin:OnStoreUpdate()
    self.LoadingFrame:Hide()
    self:UpdatePage()
end

function HeirloomStoreMixin:OnDragStart()
    self:StartMoving()
end

function HeirloomStoreMixin:OnDragStop()
    self:StopMovingOrSizing()
end

--
-- item
--
HeirloomStoreItemMixin = CreateFromMixins("CustomVendorItemMixin")

function HeirloomStoreItemMixin:OnLoad()
    CustomVendorItemMixin.OnLoad(self)
    self.Icon:SetBorderSize(32, 32)
    self.Icon:SetOverlaySize(26, 32)
    self:RegisterCallback("OnItemChanged", self.OnItemChanged, self)
end

function HeirloomStoreItemMixin:OnItemChanged()
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

function HeirloomStoreItemMixin:OnEnter()
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

function HeirloomStoreItemMixin:OnLeave()
    GameTooltip:Hide()
end


--
-- rpg item store
--
RPGItemStoreMixin = CreateFromMixins("HeirloomStoreMixin")

function RPGItemStoreMixin:OnLoad()
    HeirloomStoreMixin.OnLoad(self)
    self:UnregisterEvent("ITEM_USED")
    self:SetStoreID(Enum.CustomStores.RPGWeaponStore)
    self.Currency:SetItem(ItemData.MARK_OF_ASCENSION, true)
    self:RegisterEvent("OPEN_CUSTOM_STORE")
end

function RPGItemStoreMixin:OPEN_CUSTOM_STORE(storeID)
    if storeID == Enum.CustomStores.RPGWeaponStore then
        self:SetStoreID(Enum.CustomStores.RPGWeaponStore)
        CloseGossip()
        self:Show()
    elseif storeID == Enum.CustomStores.RPGArmorStore then
        self:SetStoreID(Enum.CustomStores.RPGArmorStore)
        CloseGossip()
        self:Show()
    end
end

function RPGItemStoreMixin:SetupFilterDropDown()
    local filter = self.filter
    if not filter then
        return
    end

    if self.filterSetupFunc and self:filterSetupFunc(filter) then
        return
    end

    -- afford filters
    filter:AddFilterOption("FILTER_CAN_AFFORD", filter:CreateFilterInfo(FILTER_CAN_AFFORD))
    filter:AddFilterOption("FILTER_CANNOT_AFFORD", filter:CreateFilterInfo(FILTER_CANNOT_AFFORD))
end