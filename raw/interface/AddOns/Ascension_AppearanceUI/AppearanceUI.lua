local _, UI = ...

AppearanceUI = UI

MixinAndLoad(AppearanceUI, "CallbackRegistryMixin")

AppearanceUI:GenerateCallbackEvents({
    "OnAppearanceTypeSelected",
    "OnCategorySelected",
})

function AppearanceUI.OpenCategory(appearanceType, categoryID)
    AppearanceUI:TriggerEvent("OnAppearanceTypeSelected", appearanceType)
    AppearanceUI:TriggerEvent("OnCategorySelected", categoryID)
end

function AppearanceUI.OpenToTryOn(appearanceType, categoryID, appearanceID, itemName)
    AppearanceUI:TriggerEvent("OnAppearanceTypeSelected", appearanceType)
    AppearanceUI:TriggerEvent("OnCategorySelected", categoryID)
    AppearanceWardrobeFrame.Collection.SearchBox:SetText(itemName)
    C_Appearance.SetPendingAppearance(categoryID, appearanceID)
end

function AppearanceUI.OpenToItemSet(itemSetName)
    local categoryIDs = C_AppearanceCollection.GetCategoriesForType("APPEARANCE_TYPE_ITEM_SET")
    local categoryID = categoryIDs and categoryIDs[1]
    if not categoryID then
        return
    end

    if type(itemSetName) == "number" then
        itemSetName = C_ItemSet.GetItemSetName(itemSetName)
    end

    AppearanceUI.OpenCategory("APPEARANCE_TYPE_ITEM_SET", categoryID)
    AppearanceWardrobeFrame.Collection.SearchBox:SetText(itemSetName)
end

function AppearanceUI.OpenToOutfits()
    local categoryIDs = C_AppearanceCollection.GetCategoriesForType("APPEARANCE_TYPE_OUTFIT")
    local categoryID = categoryIDs and categoryIDs[1]
    if not categoryID then
        return
    end

    AppearanceUI.OpenCategory("APPEARANCE_TYPE_OUTFIT", categoryID)
end

