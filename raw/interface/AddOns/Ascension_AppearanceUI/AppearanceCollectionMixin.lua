AppearanceCollectionMixin = CreateFromMixins("NineSlicePanelMixin", "TabSystemMixin")

-- see bottom of file
local CATEGORY_TAB_LAYOUT_FUNC -- custom layout functions per appearance type
local CATEGORY_TAB_LAYOUT_WIDTH -- extra width from custom layout functions so tabs stay centered

local DefaultFilter = {}
local DefaultSorting = {}

local HideCategories = {
    ["APPEARANCE_TYPE_ITEM_SET"] = true,
    ["APPEARANCE_TYPE_OUTFIT"] = true,
    ["APPEARANCE_TYPE_MOUNT"] = true,
    ["APPEARANCE_TYPE_COMPANION"] = true,
    ["APPEARANCE_TYPE_TOY"] = true,
}

local function IsWeaponCategory(self)
    return self.categoryID == 13 or self.categoryID == 14
end

local function IsMainHandCategory(self)
    return self.categoryID == 13
end

local function IsOffHandCategory(self)
    return self.categoryID == 14
end

local function IsArmorCategory(self)
    local categoryID = self.categoryID or 0
    return categoryID < 12 and categoryID > 0
end

local function IsRangedCategory(self)
    return self.categoryID == 12
end

local function IsNotItemSets(self)
    return self.appearanceType ~= "APPEARANCE_TYPE_ITEM_SET"
end

local function CanShowThrown(self)
    return IsRangedCategory(self) and C_Config.GetBoolConfig("CONFIG_THROWN_WEAPON_APPEARANCES_ENABLED")
end

local function GetCategoryState(self, categoryID)
    local previousCategoryID = self.categoryID
    self.categoryID = categoryID

    local state = {
        isWeaponCategory = IsWeaponCategory(self),
        isMainHandCategory = IsMainHandCategory(self),
        isOffHandCategory = IsOffHandCategory(self),
        isArmorCategory = IsArmorCategory(self),
        isRangedCategory = IsRangedCategory(self),
        isNotItemSets = IsNotItemSets(self),
        canShowThrown = CanShowThrown(self),
    }

    self.categoryID = previousCategoryID
    return state
end

local function HasCategoryStateChanged(previousState, newState)
    if not previousState then
        return true
    end

    for key, value in pairs(newState) do
        if previousState[key] ~= value then
            return true
        end
    end

    return false
end

function AppearanceCollectionMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    NineSlicePanelMixin.OnLoad(self)
    TabSystemMixin.OnLoad(self)
    self:EnableMouseWheel(true)
    self:CreateAppearanceTypeTabs()
    self:CreateCategoryTabs()
    self:CreateFilters()
    self.page = 1
    self.maxPages = 1
    
    AppearanceUI:RegisterCallback("OnAppearanceTypeSelected", self.SetAppearanceType, self)
    AppearanceUI:RegisterCallback("OnCategorySelected", self.SetCategory, self)
end 

function AppearanceCollectionMixin:CreateAppearanceTypeTabs()
    self:SetTabTemplate("AppearanceTypeTabTemplate")
    self:SetTabSelectedSound(SOUNDKIT.CHARACTER_SHEET_TAB)
    self:SetTabPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -2)
    local tab
    for index, appearanceType in ipairs(C_AppearanceCollection.GetAppearanceTypes()) do
        if appearanceType ~= "APPEARANCE_TYPE_NONE" and appearanceType ~= "APPEARANCE_TYPE_ILLUSION" then
            tab = self:AddTab(_G[appearanceType] or appearanceType)
            tab.appearanceType = appearanceType
        end
    end
    
    self:RegisterCallback("OnTabSelected", self.OnAppearanceTypeSelected, self)
end

function AppearanceCollectionMixin:CreateCategoryTabs()
    MixinAndLoadScripts(self.Categories, "TabSystemMixin")
    self.Categories:SetTabTemplate("AppearanceCategoryTabTemplate")
    self.Categories:SetTabSelectedSound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    self.Categories:SetTabPadding(4, 0)
    self.Categories:RegisterCallback("OnTabSelected", self.OnCategorySelected, self)
end

function AppearanceCollectionMixin:CreateFilters()
    local filter = self.Filter
    filter:RegisterCallback("OnFilterChanged", GenerateClosure(self.RefreshCategory, self))

    local isWeaponCategory = GenerateClosure(IsWeaponCategory, self)
    local isMainHandCategory = GenerateClosure(IsMainHandCategory, self)
    local isOffHandCategory = GenerateClosure(IsOffHandCategory, self)
    local isArmorCategory = GenerateClosure(IsArmorCategory, self)
    local isRangedCategory = GenerateClosure(IsRangedCategory, self)
    local isNotItemSets = GenerateClosure(IsNotItemSets, self)
    local canShowThrown = GenerateClosure(CanShowThrown, self)

    filter:AddFilterOption("FILTER_COLLECTED", filter:CreateFilterInfo(TRANSMOG_COLLECTED))
    filter:AddFilterOption("FILTER_UNCOLLECTED", filter:CreateFilterInfo(TRANSMOG_NOT_COLLECTED))

    filter:AddOptionSpacer()

    filter:AddFilterOption("FILTER_AVAILABLE_ON_THE_WEB_STORE", filter:CreateFilterInfo(TRANSMOG_AVAILABLE_ON_WEB))
    filter:AddFilterOption("FILTER_AVAILABLE_ON_THE_ETHEREAL_BAZAAR", filter:CreateFilterInfo(TRANSMOG_AVAILABLE_ON_BAZAAR))

    filter:AddOptionSpacer()
    filter:AddCategoryOption("QUALITY", QUALITY)
    filter:AddSubFilterOption("QUALITY", "FILTER_ITEM_QUALITY_POOR", filter:CreateFilterInfo("ITEM_QUALITY0_DESC", ITEM_QUALITY_COLORS[0]))
    filter:AddSubFilterOption("QUALITY", "FILTER_ITEM_QUALITY_NORMAL", filter:CreateFilterInfo("ITEM_QUALITY1_DESC", ITEM_QUALITY_COLORS[1]))
    filter:AddSubFilterOption("QUALITY", "FILTER_ITEM_QUALITY_UNCOMMON", filter:CreateFilterInfo("ITEM_QUALITY2_DESC", ITEM_QUALITY_COLORS[2]))
    filter:AddSubFilterOption("QUALITY", "FILTER_ITEM_QUALITY_RARE", filter:CreateFilterInfo("ITEM_QUALITY3_DESC", ITEM_QUALITY_COLORS[3]))
    filter:AddSubFilterOption("QUALITY", "FILTER_ITEM_QUALITY_EPIC", filter:CreateFilterInfo("ITEM_QUALITY4_DESC", ITEM_QUALITY_COLORS[4]))
    filter:AddSubFilterOption("QUALITY", "FILTER_ITEM_QUALITY_LEGENDARY", filter:CreateFilterInfo("ITEM_QUALITY5_DESC", ITEM_QUALITY_COLORS[5]))
    filter:AddSubFilterOption("QUALITY", "FILTER_ITEM_QUALITY_ARTIFACT", filter:CreateFilterInfo("ITEM_QUALITY6_DESC", ITEM_QUALITY_COLORS[6]))
    filter:AddSubFilterOption("QUALITY", "FILTER_ITEM_QUALITY_HEIRLOOM", filter:CreateFilterInfo("ITEM_QUALITY7_DESC", ITEM_QUALITY_COLORS[7]))
    filter:AddOptionSpacer()

    filter:AddFilterOption("FILTER_INVTYPE_MAINHAND", filter:CreateFilterInfo(INVTYPE_WEAPONMAINHAND, nil, nil, isMainHandCategory))
    filter:AddFilterOption("FILTER_INVTYPE_OFFHAND", filter:CreateFilterInfo(INVTYPE_WEAPONOFFHAND, nil, nil, isOffHandCategory))
    filter:AddFilterOption("FILTER_WEAPON_AXE", filter:CreateFilterInfo(ITEM_SUBCLASS_2_0, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_AXE2", filter:CreateFilterInfo(ITEM_SUBCLASS_2_1, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_BOW", filter:CreateFilterInfo(ITEM_SUBCLASS_2_2, nil, nil, isRangedCategory))
    filter:AddFilterOption("FILTER_WEAPON_GUN", filter:CreateFilterInfo(ITEM_SUBCLASS_2_3, nil, nil, isRangedCategory))
    filter:AddFilterOption("FILTER_WEAPON_MACE", filter:CreateFilterInfo(ITEM_SUBCLASS_2_4, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_MACE2", filter:CreateFilterInfo(ITEM_SUBCLASS_2_5, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_POLEARM", filter:CreateFilterInfo(ITEM_SUBCLASS_2_6, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_SWORD", filter:CreateFilterInfo(ITEM_SUBCLASS_2_7, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_SWORD2", filter:CreateFilterInfo(ITEM_SUBCLASS_2_8, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_STAFF", filter:CreateFilterInfo(ITEM_SUBCLASS_2_10, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_FIST", filter:CreateFilterInfo(ITEM_SUBCLASS_2_13, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_DAGGER", filter:CreateFilterInfo(ITEM_SUBCLASS_2_15, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_SPEAR", filter:CreateFilterInfo(ITEM_SUBCLASS_2_17, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_WEAPON_CROSSBOW", filter:CreateFilterInfo(ITEM_SUBCLASS_2_18, nil, nil, isRangedCategory))
    filter:AddFilterOption("FILTER_WEAPON_WAND", filter:CreateFilterInfo(ITEM_SUBCLASS_2_19, nil, nil, isRangedCategory))
    filter:AddFilterOption("FILTER_WEAPON_FISHING_POLE", filter:CreateFilterInfo(ITEM_SUBCLASS_2_20, nil, nil, isWeaponCategory))
    filter:AddFilterOption("FILTER_ARMOR_CLOTH", filter:CreateFilterInfo(ITEM_SUBCLASS_4_1, nil, nil, isArmorCategory))
    filter:AddFilterOption("FILTER_ARMOR_LEATHER", filter:CreateFilterInfo(ITEM_SUBCLASS_4_2, nil, nil, isArmorCategory))
    filter:AddFilterOption("FILTER_ARMOR_MAIL", filter:CreateFilterInfo(ITEM_SUBCLASS_4_3, nil, nil, isArmorCategory))
    filter:AddFilterOption("FILTER_ARMOR_PLATE", filter:CreateFilterInfo(ITEM_SUBCLASS_4_4, nil, nil, isArmorCategory))
    filter:AddFilterOption("FILTER_ARMOR_SHIELD", filter:CreateFilterInfo(ITEM_SUBCLASS_4_6, nil, nil, isOffHandCategory))
    filter:AddFilterOption("FILTER_INVTYPE_HOLDABLE", filter:CreateFilterInfo(ITEM_SUBCLASS_2_14, nil, nil, isOffHandCategory))
    filter:AddFilterOption("FILTER_WEAPON_THROWN", filter:CreateFilterInfo(ITEM_SUBCLASS_2_16, nil, nil, canShowThrown))

    local sortOrder = self.Sorting
    sortOrder:RegisterCallback("OnFilterChanged", GenerateClosure(self.RefreshCategory, self))
    sortOrder:SetSingleOptionMode(true)

    
    sortOrder:AddFilterOption("SORT_RECENTLY_COLLECTED_DESC", filter:CreateFilterInfo(ORDER_BY_RECENT_COLLECTION, nil, nil, isNotItemSets))
    sortOrder:AddFilterOption("SORT_RECENTLY_COLLECTED_ASC", filter:CreateFilterInfo(ORDER_BY_OLDEST_COLLECTION, nil, nil, isNotItemSets))

    sortOrder:AddOptionSpacer(isNotItemSets)

    sortOrder:AddFilterOption("SORT_ALPHABETICAL_ASC", filter:CreateFilterInfo(ORDER_BY_ALPHABETICAL_AZ))
    sortOrder:AddFilterOption("SORT_ALPHABETICAL_DESC", filter:CreateFilterInfo(ORDER_BY_ALPHABETICAL_ZA))

    sortOrder:AddOptionSpacer()

    sortOrder:AddFilterOption("SORT_ID_ASC", filter:CreateFilterInfo(ORDER_BY_APPEARANCE_ID_ASC))
    sortOrder:AddFilterOption("SORT_ID_DESC", filter:CreateFilterInfo(ORDER_BY_APPEARANCE_ID_DESC))
end

function AppearanceCollectionMixin:OnAppearanceTypeSelected(tabID, tab)
    local appearanceType = tab.appearanceType
    AppearanceUI:TriggerEvent("OnAppearanceTypeSelected", appearanceType)
end

function AppearanceCollectionMixin:SetAppearanceType(appearanceType)
    self.appearanceType = appearanceType

    for _, tab in self:EnumerateTabs() do
        tab:SetTabSelected(tab.appearanceType == appearanceType)
    end

    if appearanceType == "APPEARANCE_TYPE_OUTFIT" then
        self.Filter:Hide()
        self.Sorting:Hide()
        self.SearchBox:SetPoint("TOP", self, "TOP", 0, -6)
    else
        self.Filter:Show()
        self.Sorting:Show()
        self.SearchBox:SetPoint("TOP", self, "TOP", -88, -6)
    end

    self.SearchBox:SetText("")

    self:UpdateCategories()
    self.Categories:SelectFirstEnabledTab()
end

function AppearanceCollectionMixin:UpdateCategories()
    self.Categories:RemoveAllTabs()
    local categories
    if self.appearanceType == "APPEARANCE_TYPE_ILLUSION" then
        categories = C_AppearanceCollection.GetCategoriesForType("APPEARANCE_TYPE_ITEM")
    else
        categories = C_AppearanceCollection.GetCategoriesForType(self.appearanceType)
    end

    if CATEGORY_TAB_LAYOUT_FUNC[self.appearanceType] then
        self.Categories:SetTabLayout(CATEGORY_TAB_LAYOUT_FUNC[self.appearanceType])
    else
        self.Categories:SetTabLayout("HORIZONTAL")
    end

    -- item sets and outfits have 1 category, so we hide the category tabs
    local IsHiddenCategories = HideCategories[self.appearanceType]
    
    for _, categoryID in ipairs(categories) do
        local name, icon = C_AppearanceCollection.GetCategoryInfo(categoryID)
        local tab = self.Categories:AddTab(name)
        tab:SetCategory(categoryID, icon)
        tab:SetTooltip(name or "")
        tab:SetFrameLevel(self.Categories:GetFrameLevel() + 1)
        tab:SetScale(1)
        tab.isIllusionTab = nil
        tab.parent = nil
        tab:SetShown(not IsHiddenCategories)

        local illusionCategory = AppearanceUtil.GetCategoryIllusionCategoryID(categoryID)
        if illusionCategory then
            local illusionName, illusionIcon = C_AppearanceCollection.GetCategoryInfo(illusionCategory)
            local illusionTab = self.Categories:AddTab(illusionName)
            illusionTab.isIllusionTab = true
            illusionTab.parent = tab
            illusionTab:SetScale(0.6)
            illusionTab:SetCategory(illusionCategory, illusionIcon)
            illusionTab:SetTooltip(illusionName)
            illusionTab:SetFrameLevel(tab:GetFrameLevel() + 5)
        end
    end
    
    local extraWidth = CATEGORY_TAB_LAYOUT_WIDTH[self.appearanceType] or 0
    self.Categories:SetTabPoint("TOP", self.Categories, "TOP", -((((#categories - 1) * ( self.Categories:GetTabPadding() + 32)) - extraWidth) / 2), -38)
    self.Categories:UpdateTabLayout()
end

function AppearanceCollectionMixin:OnCategorySelected(tabID, tab)
    AppearanceUI:TriggerEvent("OnCategorySelected", tab:GetCategory())
end

function AppearanceCollectionMixin:RefreshCategory()
    local filter = self.Filter:HasAnyFilters() and self.Filter:GetFilter() or DefaultFilter
    local sorting = self.Sorting:HasAnyFilters() and self.Sorting:GetFilter() or DefaultSorting
    C_AppearanceCollection.ApplyCategoryFilter(self.categoryID, self.SearchBox:GetText():trim(), filter, sorting)
    local collected, numAppearances = C_AppearanceCollection.GetCollectedCount(self.categoryID)

    self.Progress:SetMinMaxValues(0, numAppearances)
    self.Progress:SetValue(collected)
    self.Progress:SetText(TRANSMOG_COLLECTED .. " " .. collected .. " / " .. numAppearances)

    self.page = 1
    self.maxPages = C_AppearanceCollection.GetCategoryMaxPages()

    self:UpdatePage()
end

function AppearanceCollectionMixin:SetCategory(categoryID)
    local previousCategoryState = self.categoryState
    local newCategoryState = GetCategoryState(self, categoryID)
    local hasCategoryStateChanged = HasCategoryStateChanged(previousCategoryState, newCategoryState)

    self.categoryState = newCategoryState
    self.categoryID = categoryID

    for _, tab in self.Categories:EnumerateTabs() do
        tab:SetTabSelected(tab:GetCategory() == categoryID)
    end
    
    CloseDropDownMenus()
    if hasCategoryStateChanged then
        self.Filter:ClearFilterExcept("FILTER_COLLECTED", "FILTER_UNCOLLECTED") -- this will update filter, which will trigger RefreshCategory
    else
        self:RefreshCategory()
    end
end

function AppearanceCollectionMixin:UpdatePage()
    self.PageText:SetFormattedText("Page %s / %s", self.page, self.maxPages)
    self:UpdateAppearances()
end

function AppearanceCollectionMixin:OnMouseWheel(delta)
    if delta < 0 then
        self.PageRightButton:Click()
    else
        self.PageLeftButton:Click()
    end
end 

function AppearanceCollectionMixin:OnShow()
    self:RegisterEvent("APPEARANCE_COLLECTED")
    self:RegisterEvent("APPEARANCE_UNCOLLECTED")
    self:RegisterEvent("VIEWABLE_APPEARANCES_RESET")
    if not self:GetCurrentTabID() then
        self:SelectFirstEnabledTab()
    elseif not self.Categories:GetCurrentTabID() then
        self.Categories:SelectFirstEnabledTab()
    else
        self:UpdatePage()
    end
end

function AppearanceCollectionMixin:OnHide()
    self:UnregisterEvent("APPEARANCE_COLLECTED")
    self:UnregisterEvent("APPEARANCE_UNCOLLECTED")
    self:UnregisterEvent("VIEWABLE_APPEARANCES_RESET")
end

function AppearanceCollectionMixin:VIEWABLE_APPEARANCES_RESET()
    AppearanceUI:TriggerEvent("OnAppearanceTypeSelected", "APPEARANCE_TYPE_ITEM")
end

function AppearanceCollectionMixin:APPEARANCE_COLLECTED()
    PlaySound(SOUNDKIT.UI_VOIDSTORAGE_UNLOCK)
    self:RefreshCategory()
end

function AppearanceCollectionMixin:APPEARANCE_UNCOLLECTED()
    PlaySound(SOUNDKIT.UI_VOIDSTORAGE_DEPOSIT)
    self:RefreshCategory()
end

function AppearanceCollectionMixin:InternalUpdateAppearances(dt)
    self.updateDelay = self.updateDelay - dt
    if self.updateDelay > 0 then
        return
    end

    if self.pendingUpdate then
        local data = tremove(self.pendingUpdate, 1)
        if not data then
            self.pendingUpdate = nil
            self:SetScript("OnUpdate", nil)
            return
        end
        self.updateDelay = 0.01
        local model, appearanceID, isLargerDisplay, setPoint = unpack(data)
        if isLargerDisplay then
            model:SetScale(1.2)
            if setPoint then
                local x = -((5 * ( 16 + 78)) / 2)
                local y = -38
                model:ClearAndSetPoint("TOP", x, y)
            end
            if self.appearanceType == "APPEARANCE_TYPE_ITEM_SET" then
                model:SetAppearanceID(appearanceID, self.categoryID)
            else
                model:SetOutfitDisplay(appearanceID, self.categoryID)
            end
        else
            model:SetScale(1)
            if setPoint then
                local x = -((5 * ( 16 + 78)) / 2)
                local y = -112
                model:ClearAndSetPoint("TOP", x, y)
            end
            model:SetAppearanceID(appearanceID, self.categoryID)
        end

    else
        self.pendingUpdate = {}
        
        local isLargerDisplay = self.appearanceType == "APPEARANCE_TYPE_ITEM_SET" or self.appearanceType == "APPEARANCE_TYPE_OUTFIT"
        self.Progress:SetShown(not isLargerDisplay)

        local appearanceIDs = C_AppearanceCollection.GetCategoryAppearances(self.page)
        for i, model in ipairs(self.Models) do
            tinsert(self.pendingUpdate, { model, appearanceIDs[i], isLargerDisplay, i == 1 })
        end
    end
end

function AppearanceCollectionMixin:UpdateAppearances()
    self:MarkDirty()
end

function AppearanceCollectionMixin:MarkDirty()
    self.updateDelay = (self.appearanceType == "APPEARANCE_TYPE_ITEM_SET" or self.appearanceType == "APPEARANCE_TYPE_OUTFIT") and 0.1 or 0
    self.pendingUpdate = nil
    self:SetScript("OnUpdate", AppearanceCollectionMixin.InternalUpdateAppearances)
end

function AppearanceCollectionMixin:NextPage()
    self.page = self.page + 1
    if self.page > self.maxPages then
        self.page = 1
    end
    self:UpdatePage()
end 

function AppearanceCollectionMixin:PreviousPage()
    self.page = self.page - 1
    if self.page < 1 then
        self.page = self.maxPages
    end
    self:UpdatePage()
end 

function AppearanceCollectionMixin:UpdateSearch()
    self:RefreshCategory()
end

local function ItemCategoryLayout(tabIndex, tab, previousTab)
    if tab.isIllusionTab then
        tab:ClearAndSetPoint("CENTER", previousTab, "TOPRIGHT", 0, 0)
    else
        local xOffset = 4
        if tabIndex == 8 then -- wrist (section split)
            xOffset = 16
        elseif tabIndex == 12 then -- ranged (section split)
            xOffset = 16
        elseif tabIndex == 15 then -- off-hand (space for mh illusion)
            xOffset = 12
        end
        tab:ClearAndSetPoint("LEFT", previousTab.parent or previousTab, "RIGHT", xOffset, 0)
    end
end

local function IncarnationTabLayout(tabIndex, tab, previousTab)
    local xOffset = 4
    if tabIndex == 9 then
        xOffset = 16
    end
    tab:ClearAndSetPoint("LEFT", previousTab, "RIGHT", xOffset, 0)
end

CATEGORY_TAB_LAYOUT_FUNC = {
    ["APPEARANCE_TYPE_ITEM"] = ItemCategoryLayout,
    ["APPEARANCE_TYPE_INCARNATION"] = IncarnationTabLayout,
    ["APPEARANCE_TYPE_ILLUSION"] = ItemCategoryLayout,
}

CATEGORY_TAB_LAYOUT_WIDTH = {
    ["APPEARANCE_TYPE_INCARNATION"] = 16,
}
