local ITEMS_PER_PAGE = 21

local ITEM_WIDTH, ITEM_HEIGHT = 190, 48
local X_OFFSET, Y_OFFSET = 44, -88
local NUM_COLUMNS = 3

ChallengesStoreTabMixin = CreateFromMixins("CustomVendorMixin")

function ChallengesStoreTabMixin:OnLoad()
    CustomVendorMixin.OnLoad(self)
    self:RegisterCallback("OnStoreReady", self.OnStoreReady, self)
    self:RegisterCallback("OnStoreFailed", self.OnStoreFailed, self)
    self:RegisterCallback("OnPurchaseSuccess", self.OnPurchaseSuccess, self)
    self:RegisterCallback("OnPurchaseFailed", self.OnPurchaseFailed, self)
    self:RegisterCallback("OnStoreUpdate", self.OnStoreUpdate, self)
    self:RegisterCallback("OnPageChanged", self.UpdatePage, self)
    self:SetStoreID(Enum.CustomStores.TrialMasters)
    self:SetItemsPerPage(ITEMS_PER_PAGE)
    self:SetSearch(self.SearchBox)
    self:SetFilter(self.Filter)

    for i = 1, ITEMS_PER_PAGE do
        local item = CreateFrame("Button", "$parentSlot"..i, self, "ChallengeStoreItemSlotTemplate")
        item:SetPoint(GetGridPoint(i, self, ITEM_WIDTH, ITEM_HEIGHT, NUM_COLUMNS, X_OFFSET, Y_OFFSET))
        self:AddItemButton(item)
    end
    
    local frameLevel = self:GetFrameLevel()
    self.ErrorFrame:SetFrameLevel(frameLevel + 15)
    self.LoadingFrame:SetFrameLevel(frameLevel + 15)
    
    local trialMasterStoreName = C_CustomStore.GetCustomStoreTypeInfo(Enum.CustomStores.TrialMasters)
    self.StoreButtonLayout.TrialMasterButton:SetText(trialMasterStoreName)
    local buildMasterStoreName = C_CustomStore.GetCustomStoreTypeInfo(Enum.CustomStores.BuildMasters)
    self.StoreButtonLayout.BuildMasterButton:SetText(buildMasterStoreName)

    if not C_Player:IsHero() then
        self.StoreButtonLayout.BuildMasterButton:Hide()
    end
end

function ChallengesStoreTabMixin:UpdatePage()
    if self:GetStoreID() == Enum.CustomStores.TrialMasters then
        self.StoreButtonLayout.TrialMasterButton:LockHighlight()
        self.StoreButtonLayout.BuildMasterButton:UnlockHighlight()
    elseif self:GetStoreID() == Enum.CustomStores.BuildMasters then
        self.StoreButtonLayout.TrialMasterButton:UnlockHighlight()
        self.StoreButtonLayout.BuildMasterButton:LockHighlight()
    else
        self.StoreButtonLayout.TrialMasterButton:UnlockHighlight()
        self.StoreButtonLayout.BuildMasterButton:UnlockHighlight()
    end

    self.PageText:SetText(self.page .. " / " .. self:GetMaxPages())
    self.PreviousPageButton:SetEnabled(self:HasPreviousPage())
    self.NextPageButton:SetEnabled(self:HasNextPage())
end

function ChallengesStoreTabMixin:SetStoreID(storeID)
    self.LoadingFrame:Show()
    if storeID == Enum.CustomStores.TrialMasters then
        self.Currency:SetItem(ItemData.TRIAL_MASTER_TROPHY, true)
    elseif storeID == Enum.CustomStores.BuildMasters then
        self.Currency:SetItem(ItemData.BUILD_MASTERS_TROPHY, true)
    end
    self.Currency:UpdateDisplay()
    CustomVendorMixin.SetStoreID(self, storeID)
end

function ChallengesStoreTabMixin:OnShow()
    CustomVendorMixin.OnShow(self)
    self.Currency:UpdateDisplay()
    self:RegisterEvent("BAG_UPDATE")
end

function ChallengesStoreTabMixin:BAG_UPDATE()
    self.Currency:UpdateDisplay()
end

function ChallengesStoreTabMixin:OnHide()
    self:UnregisterEvent("BAG_UPDATE")
    CustomVendorMixin.OnHide(self)
end

function ChallengesStoreTabMixin:OnStoreReady()
    self.LoadingFrame:Hide()
    self:UpdatePage()
end

function ChallengesStoreTabMixin:OnStoreFailed(result)
    self.ErrorFrame:SetText(CUSTOM_STORE_FAILED, _G[result] or result)
    self.ErrorFrame:Show()
end

function ChallengesStoreTabMixin:OnPurchaseSuccess()
end

function ChallengesStoreTabMixin:OnPurchaseFailed(result)
    self.ErrorFrame:SetText(PURCHASE_FAILED, _G[result] or result)
    self.ErrorFrame:Show()
end

function ChallengesStoreTabMixin:OnStoreUpdate()
    self.LoadingFrame:Hide()
    self:UpdatePage()
end

--
-- item
--
ChallengesStoreItemMixin = CreateFromMixins("CustomVendorItemMixin")

function ChallengesStoreItemMixin:OnLoad()
    CustomVendorItemMixin.OnLoad(self)
    self:RegisterCallback("OnItemChanged", self.OnItemChanged, self)
end

function ChallengesStoreItemMixin:OnItemChanged()
    local itemID = self:GetItemID()
    self:SetText(ITEM_QUALITY_COLORS[GetItemQuality(itemID)]:WrapText(GetItemName(itemID)))
    self.Icon:SetTexture("Interface\\Icons\\"..GetItemIconInstant(itemID))

    self.Cost:SetText(self:GetCostString())
end

function ChallengesStoreItemMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetHyperlink("item:"..self.itemID)
end

function ChallengesStoreItemMixin:OnLeave()
    GameTooltip:Hide()
end
