--[[
ScrollableDropDown

A drop-in replacement for UIDropDownMenuTemplate that shows its options
inside a proportional scroll list, so a poll/list with many options does
not grow the dropdown to arbitrary heights.

Usage:
    <Frame name="MyDropDown" inherits="ScrollableDropDownTemplate"/>

    MyDropDown:SetOptions({
        { text = "One",   value = 1 },
        { text = "Two",   value = 2 },
        ...
    })

    MyDropDown:SetSelectionCallback(function(value, index, option)
        -- selection changed
    end)

    MyDropDown:SetSelectedValue(2)        -- or SetSelectedIndex(2)
    MyDropDown:SetPlaceholder("Choose...")
    MyDropDown:SetMenuHeight(160)         -- optional - max height of popup
]]

ScrollableDropDownMixin = {}
ScrollableDropDownItemMixin = {}

local DEFAULT_MENU_HEIGHT = 160
local DEFAULT_MENU_WIDTH_PAD = 40 -- extra width added to popup vs dropdown width (accounts for scrollbar + backdrop)

------------------------------------------------------------------------------
-- ScrollableDropDownMixin (applied to the dropdown frame)
------------------------------------------------------------------------------

function ScrollableDropDownMixin:OnLoad()
    self.options = {}
    self.enabled = true
    self.multiSelect = false
    self.selectedIndices = {}

    self.Menu:SetClampedToScreen(true)
    self.Menu:Hide()

    local scrollList = self.Menu.ScrollList
    scrollList:SetGetNumResultsFunction(function() return self:GetNumOptions() end)
    scrollList:SetTemplate("ScrollableDropDownItemTemplate")

    if self.Menu:GetName() and UISpecialFrames then
        tinsert(UISpecialFrames, self.Menu:GetName())
    end

    self:UpdateDisplayText()
end

function ScrollableDropDownMixin:OnHide()
    self:HideMenu()
end

function ScrollableDropDownMixin:SetOptions(options)
    self.options = options or {}
    self:SyncSelectedIndexFromValue()
    self:UpdateDisplayText()
    self:RefreshMenu()
end

function ScrollableDropDownMixin:SetMultiSelect(enabled)
    self.multiSelect = not not enabled
    if not self.multiSelect then
        self.selectedIndices = {}
    end
    self:UpdateDisplayText()
    self:RefreshMenu()
end

function ScrollableDropDownMixin:IsMultiSelect()
    return self.multiSelect
end

function ScrollableDropDownMixin:IsIndexSelected(index)
    if self.multiSelect then
        return self.selectedIndices and self.selectedIndices[index] or false
    end
    return self.selectedIndex == index
end

function ScrollableDropDownMixin:GetSelectedIndices()
    local list = {}
    if self.selectedIndices then
        for i in pairs(self.selectedIndices) do
            list[#list + 1] = i
        end
        table.sort(list)
    end
    return list
end

function ScrollableDropDownMixin:SetSelectedIndices(indices, suppressCallback)
    self.selectedIndices = {}
    for _, i in ipairs(indices or {}) do
        self.selectedIndices[i] = true
    end
    self:UpdateDisplayText()
    self:RefreshMenu()
    if not suppressCallback and self.selectionCallback then
        self.selectionCallback(nil, nil, nil, self:GetSelectedIndices())
    end
end

function ScrollableDropDownMixin:ToggleSelectedIndex(index, suppressCallback)
    self.selectedIndices = self.selectedIndices or {}
    if self.selectedIndices[index] then
        self.selectedIndices[index] = nil
    else
        self.selectedIndices[index] = true
    end
    self:UpdateDisplayText()
    self:RefreshMenu()
    if not suppressCallback and self.selectionCallback then
        self.selectionCallback(nil, index, self.options[index], self:GetSelectedIndices())
    end
end

function ScrollableDropDownMixin:GetOption(index)
    return self.options[index]
end

function ScrollableDropDownMixin:GetNumOptions()
    return #self.options
end

function ScrollableDropDownMixin:SetSelectedIndex(index, suppressCallback)
    self.selectedIndex = index
    if index and self.options[index] then
        self.selectedValue = self.options[index].value
    else
        self.selectedValue = nil
    end
    self:UpdateDisplayText()
    self:RefreshMenu()
    if not suppressCallback and self.selectionCallback then
        self.selectionCallback(self.selectedValue, self.selectedIndex, self.options[self.selectedIndex])
    end
end

function ScrollableDropDownMixin:GetSelectedIndex()
    return self.selectedIndex
end

function ScrollableDropDownMixin:SetSelectedValue(value, suppressCallback)
    self.selectedValue = value
    self:SyncSelectedIndexFromValue()
    self:UpdateDisplayText()
    self:RefreshMenu()
    if not suppressCallback and self.selectionCallback then
        self.selectionCallback(self.selectedValue, self.selectedIndex, self.options[self.selectedIndex or 0])
    end
end

function ScrollableDropDownMixin:GetSelectedValue()
    return self.selectedValue
end

function ScrollableDropDownMixin:SyncSelectedIndexFromValue()
    if self.selectedValue == nil then
        self.selectedIndex = nil
        return
    end
    for i, option in ipairs(self.options) do
        if option.value == self.selectedValue then
            self.selectedIndex = i
            return
        end
    end
    self.selectedIndex = nil
end

function ScrollableDropDownMixin:UpdateDisplayText()
    if self.multiSelect then
        local indices = self:GetSelectedIndices()
        if #indices == 0 then
            self.Text:SetText(self.placeholder or "")
            return
        end
        local parts = {}
        for _, i in ipairs(indices) do
            local opt = self.options[i]
            if opt then
                parts[#parts + 1] = opt.text or ""
            end
        end
        self.Text:SetText(table.concat(parts, ", "))
        return
    end

    local selected = self.selectedIndex and self.options[self.selectedIndex]
    if selected then
        self.Text:SetText(selected.text or "")
    else
        self.Text:SetText(self.placeholder or "")
    end
end

function ScrollableDropDownMixin:SetPlaceholder(text)
    self.placeholder = text
    self:UpdateDisplayText()
end

function ScrollableDropDownMixin:SetSelectionCallback(callback)
    self.selectionCallback = callback
end

function ScrollableDropDownMixin:SetJustify(justifyH)
    self.Text:SetJustifyH(justifyH)
end

-- Sets the visual label width in the same fashion as UIDropDownMenu_SetWidth.
-- The parent frame itself becomes width + 2*labelPadding (default 25 each side)
-- to account for the end-caps. Text width is width - labelPadding.
function ScrollableDropDownMixin:SetDropDownWidth(width, padding)
    local labelPadding = padding or 25
    self.Middle:SetWidth(width)
    self:SetWidth(width + labelPadding * 2)
    self.Text:SetWidth(width - labelPadding)
end

function ScrollableDropDownMixin:SetMenuHeight(height)
    self.Menu:SetHeight(height or DEFAULT_MENU_HEIGHT)
end

function ScrollableDropDownMixin:SetMenuWidth(width)
    self.Menu:SetWidth(width)
end

function ScrollableDropDownMixin:RefreshMenu()
    if not self.multiSelect then
        self.Menu.ScrollList:SetSelectedIndex(self.selectedIndex)
    end
    if self.Menu:IsShown() and self.Menu.ScrollList:IsInitialized() then
        self:UpdateItemWidths()
        self.Menu.ScrollList:RefreshScrollFrame()
    end
end

-- Ensures that the scroll list's scrollChild and item buttons are sized to the
-- current ScrollFrame width. HybridScrollFrame only sets these at creation time,
-- so any later resize of the popup needs this resync.
function ScrollableDropDownMixin:UpdateItemWidths()
    local scrollFrame = self.Menu.ScrollList.ScrollFrame
    local width = scrollFrame:GetWidth()
    if width <= 0 then return end
    if scrollFrame.scrollChild then
        scrollFrame.scrollChild:SetWidth(width)
    end
    if scrollFrame.buttons then
        for _, button in ipairs(scrollFrame.buttons) do
            button:SetWidth(width)
        end
    end
end

function ScrollableDropDownMixin:IsMenuShown()
    return self.Menu:IsShown()
end

function ScrollableDropDownMixin:ShowMenu()
    if not self:IsEnabled() or self:GetNumOptions() == 0 then
        return
    end
    local targetWidth = self:GetWidth() + DEFAULT_MENU_WIDTH_PAD
    if self.Menu:GetWidth() < targetWidth then
        self.Menu:SetWidth(targetWidth)
    end
    self.Menu:Show()
    self:UpdateItemWidths()
    if self.Menu.ScrollList:IsInitialized() then
        self.Menu.ScrollList:RefreshScrollFrame()
    end
end

function ScrollableDropDownMixin:HideMenu()
    self.Menu:Hide()
end

function ScrollableDropDownMixin:ToggleMenu()
    if self.Menu:IsShown() then
        self:HideMenu()
    else
        self:ShowMenu()
    end
end

function ScrollableDropDownMixin:SetEnabled(enabled)
    self.enabled = not not enabled
    if self.Button then
        self.Button:SetEnabled(self.enabled)
    end
    if self.enabled then
        self.Text:SetFontObject("GameFontHighlightSmall")
    else
        self.Text:SetFontObject("GameFontDisable")
        self:HideMenu()
    end
end

function ScrollableDropDownMixin:IsEnabled()
    return self.enabled
end

function ScrollableDropDownMixin:Enable()
    self:SetEnabled(true)
end

function ScrollableDropDownMixin:Disable()
    self:SetEnabled(false)
end

------------------------------------------------------------------------------
-- ScrollableDropDownItemMixin (applied on top of ScrollListItemBaseMixin)
------------------------------------------------------------------------------

function ScrollableDropDownItemMixin:GetDropDown()
    -- hierarchy: itemButton -> scrollChild -> ScrollFrame -> ScrollList -> Menu -> DropDown
    local scrollList = self:GetScrollList()
    if not scrollList then return nil end
    local menu = scrollList:GetParent()
    return menu and menu:GetParent() or nil
end

function ScrollableDropDownItemMixin:Update()
    local dropdown = self:GetDropDown()
    if not dropdown then
        self:Hide()
        return
    end
    local option = dropdown:GetOption(self.index)
    if not option then
        self:Hide()
        return
    end
    self:SetText(option.text or "")
    if self.Check then
        local multi = dropdown:IsMultiSelect()
        self.Check:SetShown(multi and dropdown:IsIndexSelected(self.index))
        if self.Text then
            self.Text:ClearAllPoints()
            self.Text:SetPoint("LEFT", multi and 18 or 4, 0)
            self.Text:SetPoint("RIGHT", -4, 0)
        end
    end
    self:Show()
end

function ScrollableDropDownItemMixin:OnClick(button)
    if button == "RightButton" then
        self:OnRightClick()
        return
    end
    local dropdown = self:GetDropDown()
    if dropdown and dropdown:IsMultiSelect() then
        self:OnSelected()
        return
    end
    ScrollListItemBaseMixin.OnClick(self, button)
end

function ScrollableDropDownItemMixin:OnSelected()
    local dropdown = self:GetDropDown()
    if not dropdown then return end
    if SOUNDKIT and SOUNDKIT.UI_WORLDQUEST_MAP_SELECT then
        PlaySound(SOUNDKIT.UI_WORLDQUEST_MAP_SELECT)
    else
        PlaySound("igMainMenuOptionCheckBoxOn")
    end
    if dropdown:IsMultiSelect() then
        dropdown:ToggleSelectedIndex(self.index)
    else
        dropdown:SetSelectedIndex(self.index)
        dropdown:HideMenu()
    end
end
