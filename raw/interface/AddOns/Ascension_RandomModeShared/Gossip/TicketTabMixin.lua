TicketTabMixin = {}

local CardSelectFormat = "|TInterface\\Icons\\INV_Misc_Ticket_Darkmoon_01:16:16:0:0|t %s"
local ITEMS_PER_PAGE = 16

-- store button positioning
local ITEM_WIDTH, ITEM_HEIGHT = 194, 62
local X_OFFSET, Y_OFFSET = 58, -126
local NUM_COLUMNS = 4

local CLASS_ORDER = {
    "DRUID",
    "HUNTER",
    "MAGE",
    "PALADIN",
    "PRIEST",
    "ROGUE",
    "SHAMAN",
    "WARLOCK",
    "WARRIOR",
    "DEATHKNIGHT",
}

function TicketTabMixin:OnLoad()
    local frameLevel = self:GetFrameLevel()
    self.ErrorFrame:SetFrameLevel(frameLevel + 20)
    self.LoadingFrame:SetFrameLevel(frameLevel + 20)

    self.Store:RegisterForDrag("LeftButton")
    self.Store:RegisterCallback("OnStoreReady", self.OnStoreReady, self)
    self.Store:RegisterCallback("OnStoreFailed", self.OnStoreFailed, self)
    self.Store:RegisterCallback("OnPurchaseSuccess", self.OnPurchaseSuccess, self)
    self.Store:RegisterCallback("OnPurchaseFailed", self.OnPurchaseFailed, self)
    self.Store:RegisterCallback("OnStoreUpdate", self.OnStoreUpdate, self)
    self.Store:RegisterCallback("OnPageChanged", self.UpdatePage, self)
    self.Store:SetItemsPerPage(ITEMS_PER_PAGE)
    self.Store:SetSearch(self.Store.SearchBox)
    self.Store:SetFilter(self.Store.Filter)
    self.Store:SetFilterSetupFunc(GenerateClosure(self.SetupStoreFilter, self))

    for i = 1, ITEMS_PER_PAGE do
        local item = CreateFrame("Button", "$parentSlot"..i, self.Store, "RandomModeStoreItemTemplate")
        item:SetPoint(GetGridPoint(i, self.Store, ITEM_WIDTH, ITEM_HEIGHT, NUM_COLUMNS, X_OFFSET, Y_OFFSET))
        self.Store:AddItemButton(item)
    end

    for index, class in ipairs(CLASS_ORDER) do
        local classButton = CreateFrame("Button", "$parentClassButton"..index, self.Store.ClassButtons, "RandomModeStoreClassButtonTemplate")
        classButton.layoutIndex = index
        classButton:SetClass(class)
        classButton:SetScript("OnClick", GenerateClosure(self.OnClassFilterClick, self))
    end

    self.Store.ClassButtons:MarkDirty()

    self.ChooseStore.SkillCards.SelectButton:SetFormattedText(CardSelectFormat, SKILL_CARDS)
    self.ChooseStore.Cosmetics.SelectButton:SetFormattedText(CardSelectFormat, DARKMOON_TICKET_PRIZES)
    self.ChooseStore.GoldenSkillCards.SelectButton:SetFormattedText(CardSelectFormat, GOLDEN_SKILL_CARDS)
end

function TicketTabMixin:OnShow()
    self.Store:Hide()
    self.ChooseStore:Show()
    self:GetParent().ArtTop:Show()
    self:GetParent().ArtBottom:Show()
end

function TicketTabMixin:OnHide()
    if self.Store:IsShown() then
        self:CloseStore()
    end
end
    
function TicketTabMixin:OpenStore(id)
    self.ErrorFrame:Hide()
    self.LoadingFrame:Show()
    self.storeID = id
    self.Store:SetStoreID(id)
    self.ChooseStore:Hide()
    self.Store:Show()
    self:GetParent().ArtTop:Hide()
    self:GetParent().ArtBottom:Hide()
end 

function TicketTabMixin:CloseStore()
    PlaySound(SOUNDKIT.UI_BLIZZARDSTORE_CLOSE)
    self.ErrorFrame:Hide()
    self.LoadingFrame:Hide()
    self.Store:Hide()
    self.ChooseStore:Show()
    self:GetParent().ArtTop:Show()
    self:GetParent().ArtBottom:Show()
end

function TicketTabMixin:OnStoreReady()
    PlaySound(SOUNDKIT.UI_BLIZZARDSTORE_OPEN)
    self.LoadingFrame:Hide()
    self.ErrorFrame:Hide()
    self.ChooseStore:Hide()
    self.Store:Show()
    if self.Store:GetStoreID() == Enum.CustomStores.DarkmoonPrizes then
        self.Store.Filter:ClearFilters()
        for _, classButton in ipairs(self.Store.ClassButtons.buttons) do
            classButton:Hide()
        end
    else
        self.Store.Filter:SetToSingleFilter("FILTER_SKILL_CARD_UNOWNED")
        for _, classButton in ipairs(self.Store.ClassButtons.buttons) do
            classButton:Show()
        end

        local tip = {
            text = TIP_TICKET_TAB_SELECT_MULTI_CLASS or "You can select multiple classes by holding |cffffd100Shift|r when selecting a class!",
            textJustifyH = "CENTER",
            targetPoint = HelpTip.Point.BottomEdgeCenter,
            buttonStyle = HelpTip.ButtonStyle.Okay,
            cvar    = "HelpTipBitfield",
            cvarBit = HelpTips.Bits.TicketTabSelectMultiClass,
        }
        HelpTip:Show(self.Store.ClassButtons, tip)
    end
    self:UpdatePage()
    self.Store.Title:SetText(self.Store:GetStoreName())
end

function TicketTabMixin:OnStoreFailed(result)
    PlaySound(SOUNDKIT.ERROR)
    self.LoadingFrame:Hide()
    self.ErrorFrame:Show()
    self.ErrorFrame:SetText(CUSTOM_STORE_FAILED, _G[result] or result)
end

function TicketTabMixin:OnPurchaseSuccess()
    PlaySound(SOUNDKIT.UI_BLIZZARDSTORE_CONFIRMPURCHASE)
end

function TicketTabMixin:OnPurchaseFailed(result)
    PlaySound(SOUNDKIT.ERROR)
    self.ErrorFrame:SetText(PURCHASE_FAILED, _G[result] or result)
    self.ErrorFrame:Show()
end

function TicketTabMixin:OnStoreUpdate()
    self:UpdatePage()
    self:UpdateClassButtons()
end

function TicketTabMixin:UpdateClassButtons()
    for _, classButton in ipairs(self.Store.ClassButtons.buttons) do
        classButton:UpdateSelected(self.Store.Filter:IsFiltered(classButton.filterKey))
    end
end

function TicketTabMixin:UpdatePage()
    if self.Store:GetMaxPages() == 0 then
        self.Store.PageText:SetText("")
    else
        self.Store.PageText:SetText(self.Store.page .. "/" .. self.Store:GetMaxPages())
    end
    self.Store.PreviousPageButton:SetEnabled(self.Store:HasPreviousPage())
    self.Store.NextPageButton:SetEnabled(self.Store:HasNextPage())
end

function TicketTabMixin:SetupStoreFilter(store, filter)
    if store:GetStoreID() == Enum.CustomStores.DarkmoonPrizes then
        return false -- Darkmoon prizes uses default filter
    end

    -- afford filters
    filter:AddFilterOption("FILTER_CAN_AFFORD", filter:CreateFilterInfo(FILTER_CAN_AFFORD))
    filter:AddFilterOption("FILTER_CANNOT_AFFORD", filter:CreateFilterInfo(FILTER_CANNOT_AFFORD))

    -- skill card owned/unowned filters
    filter:AddOptionSpacer()
    filter:AddFilterOption("FILTER_SKILL_CARD_OWNED", filter:CreateFilterInfo(COLLECTED_SKILL_CARDS))
    filter:AddFilterOption("FILTER_SKILL_CARD_UNOWNED", filter:CreateFilterInfo(UNCOLLECTED_SKILL_CARDS))


    -- quality filters
    filter:AddOptionSpacer()
    filter:AddCategoryOption("QUALITY", QUALITY)
    filter:AddSubFilterOption("QUALITY", "FILTER_SKILL_CARD_QUALITY_COMMON", filter:CreateFilterInfo("ITEM_QUALITY1_DESC", ITEM_QUALITY_COLORS[1]))
    filter:AddSubFilterOption("QUALITY", "FILTER_SKILL_CARD_QUALITY_UNCOMMON", filter:CreateFilterInfo("ITEM_QUALITY2_DESC", ITEM_QUALITY_COLORS[2]))
    filter:AddSubFilterOption("QUALITY", "FILTER_SKILL_CARD_QUALITY_RARE", filter:CreateFilterInfo("ITEM_QUALITY3_DESC", ITEM_QUALITY_COLORS[3]))
    filter:AddSubFilterOption("QUALITY", "FILTER_SKILL_CARD_QUALITY_EPIC", filter:CreateFilterInfo("ITEM_QUALITY4_DESC", ITEM_QUALITY_COLORS[4]))
    
    --class filters
    filter:AddCategoryOption("CLASS", CLASS)
    filter:AddSubFilterOption("CLASS", "FILTER_SKILL_CARD_SPELL_FAMILY_GENERIC", filter:CreateFilterInfo("CA_FILTER_CLASS_GENERAL"))
    for _, class in ipairs(CLASS_ORDER) do
        local classFilterKey = "FILTER_SKILL_CARD_SPELL_FAMILY_"..class
        if class == "DEATHKNIGHT" then
            classFilterKey = "FILTER_SKILL_CARD_SPELL_FAMILY_DEATH_KNIGHT"
        end
        filter:AddSubFilterOption("CLASS", classFilterKey, filter:CreateFilterInfo(ClassInfoUtil.GetColoredClassName(class), nil, "groupfinder-icon-class-"..class))
    end

    return true
end

function TicketTabMixin:OnClassFilterClick(classButton, button)
    local isFiltered = self.Store.Filter:IsFiltered(classButton.filterKey)
    if IsShiftKeyDown() or (button == "RightButton" and isFiltered) then
        self.Store.Filter:SetFilter(classButton.filterKey, not isFiltered)
    elseif isFiltered then
        self.Store.Filter:SetFilter(classButton.filterKey, false)
    elseif button == "LeftButton" then
        self.Store.Filter:SetToSingleFilter("FILTER_SKILL_CARD_UNOWNED")
        self.Store.Filter:SetFilter(classButton.filterKey, true)
    end
    classButton:UpdateSelected()
end