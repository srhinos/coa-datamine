CustomVendorMixin = CreateFromMixins("CallbackRegistryMixin")
CustomVendorMixin.OnEvent = OnEventToMethod

function CustomVendorMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    self:EnableMouseWheel(true)
    self:GenerateCallbackEvents({
        "OnStoreReady",
        "OnStoreFailed",
        "OnPurchaseSuccess",
        "OnPurchaseFailed",
        "OnStoreUpdate",
        "OnPageChanged",
    })
    self.page = 1
    self.itemsPerPage = 18
    self.items = {}
end

function CustomVendorMixin:SetScrollList(scrollList)
    self.scrollList = scrollList
    if scrollList then
        scrollList:SetGetNumResultsFunction(GenerateClosure(self.GetNumStoreItems, self))
        self.itemsPerPage = -1
    end
end

function CustomVendorMixin:OnShow()
    self:RegisterEvent("QUERY_CUSTOM_STORE_RESULT")
    self:RegisterEvent("PURCHASE_CUSTOM_STORE_ITEM_RESULT")
    if self.storeID then
        self:QueryStore()
    end
end

function CustomVendorMixin:OnHide()
    self:UnregisterEvent("QUERY_CUSTOM_STORE_RESULT")
    self:UnregisterEvent("PURCHASE_CUSTOM_STORE_ITEM_RESULT")
end

function CustomVendorMixin:SetStoreID(storeID)
    self:ClearSearch()
    self:ClearFilter()
    self.storeID = storeID
    if self:IsShown() then
        self:QueryStore()
    end
end

function CustomVendorMixin:GetStoreID()
    return self.storeID
end

function CustomVendorMixin:GetStoreName()
    if self.storeID then
        return C_CustomStore.GetCustomStoreTypeInfo(self.storeID)
    else 
        return ""
    end
end

function CustomVendorMixin:SetItemsPerPage(itemsPerPage)
    self.itemsPerPage = itemsPerPage
end

function CustomVendorMixin:QueryStore()
    assert(self.storeID, "Must have a storeID to query store. see SetStoreID(storeID)")
    C_CustomStore.QueryCustomStore(self.storeID)
end

function CustomVendorMixin:SetFilterSetupFunc(func)
    self.filterSetupFunc = func
end

function CustomVendorMixin:SetFilter(filter)
    self.filter = filter
    filter:RegisterCallback("OnFilterChanged", GenerateClosure(self.OnFilterChanged, self))
end

function CustomVendorMixin:SetupFilterDropDown()
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

    -- vanity owned/unowned filters
    filter:AddOptionSpacer()
    filter:AddFilterOption("FILTER_VANITY_OWNED", filter:CreateFilterInfo(FILTER_VANITY_OWNED))
    filter:AddFilterOption("FILTER_VANITY_UNOWNED", filter:CreateFilterInfo(FILTER_VANITY_UNOWNED))
    
    --quality filters
    filter:AddOptionSpacer()
    filter:AddCategoryOption("QUALITY", QUALITY)
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_NORMAL", filter:CreateFilterInfo("ITEM_QUALITY1_DESC", ITEM_QUALITY_COLORS[1]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_UNCOMMON", filter:CreateFilterInfo("ITEM_QUALITY2_DESC", ITEM_QUALITY_COLORS[2]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_RARE", filter:CreateFilterInfo("ITEM_QUALITY3_DESC", ITEM_QUALITY_COLORS[3]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_EPIC", filter:CreateFilterInfo("ITEM_QUALITY4_DESC", ITEM_QUALITY_COLORS[4]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_LEGENDARY", filter:CreateFilterInfo("ITEM_QUALITY5_DESC", ITEM_QUALITY_COLORS[5]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_ARTIFACT", filter:CreateFilterInfo("ITEM_QUALITY6_DESC", ITEM_QUALITY_COLORS[6]))
    filter:AddSubFilterOption("QUALITY", "FILTER_QUALITY_HEIRLOOM", filter:CreateFilterInfo("ITEM_QUALITY7_DESC", ITEM_QUALITY_COLORS[7]))
end

function CustomVendorMixin:OnFilterChanged()
    self:ResetToFirstPage()
    self:MarkDirty()
end

function CustomVendorMixin:GetFilter()
    return self.filter and self.filter:GetFilter() or table.empty
end

function CustomVendorMixin:ClearFilter()
    if self.filter then
        self.filter:ClearFilters()
    end
end

function CustomVendorMixin:SetSort(sorting)
    self.sorting = sorting
    self:ResetToFirstPage()
    self:MarkDirty()
end

function CustomVendorMixin:SetSearch(search)
    self.search = search
    search:SetScript("OnTextChanged", function(searchBox)
        SearchBoxTemplate_OnTextChanged(searchBox)
        self:OnSearchChanged()
    end)
end

function CustomVendorMixin:OnSearchChanged()
    self:ResetToFirstPage()
    self:MarkDirty()
end

function CustomVendorMixin:ClearSearch()
    if self.search then
        self.search:SetText("")
    end
end

function CustomVendorMixin:GetSearch()
    return self.search and self.search:GetText() or ""
end

function CustomVendorMixin:ResetToFirstPage()
    self.page = 1
    self:TriggerEvent("OnPageChanged", self.page)
end

function CustomVendorMixin:RefreshStore()
    C_CustomStore.ApplyCustomStoreFilter(self:GetSearch(), self:GetFilter(), self.sorting or table.empty, self.itemsPerPage or 18)
    if self:GetMaxPages() < self.page then
        self:ResetToFirstPage()
    end
    self:UpdateItems()
    self:TriggerEvent("OnStoreUpdate")
end

function CustomVendorMixin:UpdateItems()
    if self.scrollList then
        self.scrollList:RefreshScrollFrame()
    else
        for _, item in ipairs(self.items) do
            item:MarkDirty()
        end
    end
end

function CustomVendorMixin:MarkDirty()
    self:SetScript("OnUpdate", function()
        self:SetScript("OnUpdate", nil)
        self:RefreshStore()
    end)
end

function CustomVendorMixin:GetNumStoreItems()
    return #C_CustomStore.GetCustomStoreData(self.page)
end

function CustomVendorMixin:GetStoreItemAtIndex(index)
    return C_CustomStore.GetCustomStoreData(self.page)[index]
end

function CustomVendorMixin:NextPage()
    self:SetPage(self.page + 1)
end

function CustomVendorMixin:PreviousPage()
    self:SetPage(self.page - 1)
end

function CustomVendorMixin:SetPage(page)
    local maxPages = self:GetMaxPages()
    self.page = math.clamp(page, 1, maxPages)
    self:TriggerEvent("OnPageChanged", self.page)
    self:MarkDirty()
end

function CustomVendorMixin:HasPreviousPage()
    return self.page > 1
end

function CustomVendorMixin:HasNextPage()
    return self.page < self:GetMaxPages()
end

function CustomVendorMixin:GetMaxPages()
    return C_CustomStore.GetCustomStoreMaxPages()
end

function CustomVendorMixin:AddItemButton(itemButton)
    table.insert(self.items, itemButton)
    itemButton:SetStore(self)
    itemButton:SetIndex(#self.items)
end

function CustomVendorMixin:QUERY_CUSTOM_STORE_RESULT(result)
    if self.filter then
        self.filter:ClearFilters()
        self.filter:ClearDropDown()
        self:SetupFilterDropDown()
    end
    if result == "QUERY_CUSTOM_STORE_OK" then
        self:TriggerEvent("OnStoreReady")
        self:RefreshStore()
    else
        self:TriggerEvent("OnStoreFailed", result)
    end
end

function CustomVendorMixin:PURCHASE_CUSTOM_STORE_ITEM_RESULT(result)
    if result == "PURCHASE_CUSTOM_STORE_ITEM_OK" then
        -- refreshes filter
        C_CustomStore.ApplyCustomStoreFilter("", table.empty, table.empty, self.itemsPerPage or 18)
        self:RefreshStore()
        self:TriggerEvent("OnPurchaseSuccess")
    else
        self:TriggerEvent("OnPurchaseFailed", result)
    end
end

function CustomVendorMixin:OnMouseWheel(delta)
    if delta > 0 then
        self:PreviousPage()
    else
        self:NextPage()
    end
end

--
-- Custom Vendor Item Mixin
--

CustomVendorItemMixin = CreateFromMixins("CallbackRegistryMixin")

function CustomVendorItemMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    self:EnableMouseWheel(true)
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self:GenerateCallbackEvents({
        "OnItemChanged",
    })
end

function CustomVendorItemMixin:SetIndex(index)
    self.index = index
end

function CustomVendorItemMixin:SetStore(customStore)
    self.customStore = customStore
end

function CustomVendorItemMixin:GetStore()
    return self.customStore
end

function CustomVendorItemMixin:OnShow()
    self:RegisterEvent("PLAYER_MONEY")
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:RegisterEvent("BAG_UPDATE")
end

function CustomVendorItemMixin:OnHide()
    self:UnregisterEvent("PLAYER_MONEY")
    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:UnregisterEvent("BAG_UPDATE")
end

function CustomVendorItemMixin:OnEvent()
    self:MarkDirty()
end

function CustomVendorItemMixin:MarkDirty()
    self:Update()
end

function CustomVendorItemMixin:GetRequiredGameEvent()
    if self.requiredGameEvent then
        return C_CustomStore.IsItemLockedDueToGameEvent(self.customStore:GetStoreItemAtIndex(self:GetIndex())), self.requiredGameEvent
    end
end

function CustomVendorItemMixin:GetRequiredAchievement()
    if self.requiredAchievement then
        return C_CustomStore.IsItemLockedDueToAchievement(self.customStore:GetStoreItemAtIndex(self:GetIndex())), self.requiredAchievement
    end
end

function CustomVendorItemMixin:GetIndex()
    return self.index or self:GetID()
end

function CustomVendorItemMixin:Update()
    local itemID, moneyCost, requiredItems, requiredItemCosts, requiredGameEvent, requiredAchievement = C_CustomStore.GetCustomStoreItemInfo(self.customStore:GetStoreItemAtIndex(self:GetIndex()))
    if itemID then
        self:Show()
        self.itemID = itemID
        self.item = Item:CreateFromID(itemID)
        self.moneyCost = moneyCost
        self.requiredItems = self.requiredItems or {}
        self.requiredGameEvent = requiredGameEvent
        self.requiredAchievement = requiredAchievement
        wipe(self.requiredItems)

        for i, requiredItem in ipairs(requiredItems) do
            self.requiredItems[i] = { item = Item:CreateFromID(requiredItem), cost = requiredItemCosts[i] or 1 }
        end
        self:TriggerEvent("OnItemChanged")
    else
        self:Hide()
    end
end

function CustomVendorItemMixin:GetItemID()
    return self.itemID
end

function CustomVendorItemMixin:GetMoneyCost()
    return self.moneyCost
end

function CustomVendorItemMixin:GetItemCost()
    return self.requiredItems
end

function CustomVendorItemMixin:GetCostString()
    local costString
    if self.moneyCost > 0 then
        local moneyString = GetMoneyString(self.moneyCost)
        if GetMoney() < self.moneyCost then
            moneyString = RED_FONT_COLOR:WrapText(moneyString)
        end
        costString = (costString or " ") .. moneyString .. " "
    end

    for _, requiredItem in ipairs(self.requiredItems) do
        local itemIcon = requiredItem.item:GetIconTextureMarkup(0, 0, -2)
        if itemIcon then
            local itemCount = requiredItem.cost
            if GetItemCount(requiredItem.item:GetItemID()) < requiredItem.cost then
                itemCount = RED_FONT_COLOR:WrapText(itemCount)
            end
            -- have to do 2 separate links because it just breaks with icon + text
            local itemString = "|Hitem:" .. requiredItem.item:GetItemID() .. "|h" .. itemCount .. "|h"
            itemString = itemString .. " |Hitem:" .. requiredItem.item:GetItemID() .. "|h" .. itemIcon .. "|h" 
            if GetItemCount(requiredItem.item:GetItemID()) < requiredItem.cost then
                itemString = RED_FONT_COLOR:WrapText(itemString)
            end
            costString = (costString or " ") .. itemString
        end
    end

    return costString or ""
end

function CustomVendorItemMixin:GetCost()
    return self.moneyCost, self.requiredItems
end

function CustomVendorItemMixin:OnClick(button)
    if IsModifiedClick("DRESSUP") then
        DressUpItemLink(self.item:GetLink())
        return
    end

    if IsModifiedClick("CHATLINK") then
        ChatEdit_InsertLink(self.item:GetLink())
        return
    end

    if self:IsEnabled() and self:IsShown() and self.index then
        StaticPopup_Show("CONFIRM_CUSTOM_STORE_PURCHASE", nil, nil, {
            itemIndex = self.customStore:GetStoreItemAtIndex(self.index or self:GetID()),
            quantity = 1,
            itemLink = self.item:GetLink(),
            costString = self:GetCostString()
        })
    end
end 

function CustomVendorItemMixin:OnMouseWheel(delta)
    self.customStore:OnMouseWheel(delta)
end

--
-- Custom Vendor Item Cost Mixin
-- 

CustomVendorItemCostMixin = {}

function CustomVendorItemCostMixin:OnLoad()
    self:EnableMouseWheel(true)
end

function CustomVendorItemCostMixin:Clear()
    self.item = nil
    self.token = nil
    self.money = nil
end

function CustomVendorItemCostMixin:CheckTooltip()
    if GameTooltip:IsOwned(self) then
        self:OnEnter()
    end
end

function CustomVendorItemCostMixin:SetItem(item, amount)
    if type(item) == "number" then
        item = Item:CreateFromID(item)
    end

    if type(item) ~= "table" then
        C_Logger.Error("CustomVendorItemCostMixin:SetItem expected item to be a ItemMixin or itemID, got %s", type(item))
        return
    end
    self:Clear()

    self.item = item
    self.Icon:SetSize(self:GetHeight(), self:GetHeight())
    self.Count:SetText(BreakUpLargeNumbers(amount))
    self.Icon:SetTexture(item:GetIcon())

    if GetItemCount(item:GetItemID()) < amount then
        self.Count:SetTextColor(RED_FONT_COLOR:GetRGB())
    else
        self.Count:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end

    self:SetWidth(self.Icon:GetWidth() + self.Count:GetStringWidth() + 6)
    self:CheckTooltip()
end

function CustomVendorItemCostMixin:SetToken(tokenID, amount)
    local name, _, _, icon = C_Token.GetTokenInfo(tokenID)
    if not name then
        C_Logger.Error("CustomVendorItemCostMixin:SetToken: Invalid tokenID %s", tokenID)
        return
    end
    
    self:Clear()

    self.token = tokenID
    self.Icon:SetSize(self:GetHeight(), self:GetHeight())
    self.Icon:SetTexture(icon)
    self.Count:SetText(BreakUpLargeNumbers(amount))

    if TokenUtil.GetTokenCount(tokenID) < amount then
        self.Count:SetTextColor(RED_FONT_COLOR:GetRGB())
    else
        self.Count:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end

    self:SetWidth(self.Icon:GetWidth() + self.Count:GetStringWidth() + 6)
    self:CheckTooltip()
end

function CustomVendorItemCostMixin:SetMoney(copperAmount)
    self:Clear()

    self.money = copperAmount
    self.Icon:SetSize(1, self:GetHeight())
    self.Icon:SetTexture(nil)
    self.Count:SetText(GetCoinTextureString(copperAmount))

    if GetMoney() < copperAmount then
        self.Count:SetTextColor(RED_FONT_COLOR:GetRGB())
    else
        self.Count:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end

    self:SetWidth(self.Icon:GetWidth() + self.Count:GetStringWidth() + 6)
    self:CheckTooltip()
end

function CustomVendorItemCostMixin:OnEnter()
    if not self.item and not self.token then
        GameTooltip:Hide()
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if self.item then
        GameTooltip:SetHyperlink(self.item:GetLink())
    elseif self.token then
        GameTooltip:SetToken(self.token)
    end
    GameTooltip:Show()
end

function CustomVendorItemCostMixin:OnLeave()
    GameTooltip:Hide()
end

function CustomVendorItemCostMixin:OnMouseWheel(delta)
    local parent = self:GetParent()
    if not parent.OnMouseWheel then
        parent = parent:GetParent()
    end

    if parent.OnMouseWheel then
        parent:OnMouseWheel(delta)
    end
end


