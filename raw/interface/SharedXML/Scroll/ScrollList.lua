ScrollListMixin = {}

ScrollListMixin.UpdateType = EnumUtil.MakeEnum(
		"Always",
		"OnlyNewIndex",
		"AlwaysSimulateClick",
		"OnlyNewIndexSimulateClick"
)

function ScrollListMixin:OnLoad()
end

function ScrollListMixin:SetTemplate(template, ...)
	if self.template or not template then return end

	self.template = template
	self.templateArgs = { ... }

	self:Init()

	if self:IsShown() then
		self:RefreshScrollFrame()
	end
end

function ScrollListMixin:SetGetNumResultsFunction(func)
	self.getNumResultsFunction = func
end

function ScrollListMixin:SetSelectionCallback(callback)
	self.selectionCallback = callback
end


function ScrollListMixin:SetRefreshCallback(refreshCallback)
	self.refreshCallback = refreshCallback
end

function ScrollListMixin:GetSelectedHighlight()
	return self.ScrollFrame.ArtOverlay.SelectedHighlight
end

function ScrollListMixin:SetSelectedHighlightAtlas(atlas)
    self:GetSelectedHighlight():SetAtlas(atlas)
end

function ScrollListMixin:SetSelectedHighlightVertexColor(r, g, b, a)
    self:GetSelectedHighlight():SetVertexColor(r, g, b, a)
end

function ScrollListMixin:SetSelectedHighlightTexture(texture)
    self:GetSelectedHighlight():SetTexture(texture)
end	

function ScrollListMixin:SetSelectedHighlightBlendMode(blendMode)
    self:GetSelectedHighlight():SetBlendMode(blendMode)
end

function ScrollListMixin:SetSelectedHighlightInset(left, right, top, bottom)
	if self.ScrollFrame.ArtOverlay.SelectedHighlightInsets then
		self.ScrollFrame.ArtOverlay.SelectedHighlightInsets[1] = left or 0
		self.ScrollFrame.ArtOverlay.SelectedHighlightInsets[2] = right or 0
		self.ScrollFrame.ArtOverlay.SelectedHighlightInsets[3] = top or 0
		self.ScrollFrame.ArtOverlay.SelectedHighlightInsets[4] = bottom or 0
	else
		self.ScrollFrame.ArtOverlay.SelectedHighlightInsets = { left or 0, right or 0, top or 0, bottom or 0 }
	end 
end

function ScrollListMixin:GetSelectedHighlightInset()
	local left, right, top, bottom = 0, 0, 0, 0
	if self.ScrollFrame.ArtOverlay.SelectedHighlightInsets then
		left, right, top, bottom = unpack(self.ScrollFrame.ArtOverlay.SelectedHighlightInsets)
	end
	return left, right, top, bottom
end

function ScrollListMixin:OnShow()
	if self.isInitialized then
		self:RefreshScrollFrame()
	end
end

local function UpdateScrollButtons(self)
	HybridScrollFrame_CreateButtons(self.ScrollFrame, self.template, 0, 0)
	for i, button in ipairs(self.ScrollFrame.buttons) do
		if not button.scrollListInitialized then
			button:Init(self.templateArgs)
			button.scrollListInitialized = true
		end
	end
end

function ScrollListMixin:UpdateButtons()
	UpdateScrollButtons(self)
end

function ScrollListMixin:UpdateButtonsAndRefresh()
	local scrollValue = self.pendingScrollValue or self.ScrollFrame.scrollBar:GetValue()
	self.pendingScrollValue = nil

	UpdateScrollButtons(self)
	self:RefreshScrollFrame()

	if self:IsVisible() then
		local _, maxValue = self.ScrollFrame.scrollBar:GetMinMaxValues()
		self.ScrollFrame.scrollBar:SetValue(math.min(scrollValue, maxValue))
	else
		self.pendingScrollValue = scrollValue
	end
end

function ScrollListMixin:Init()
	if self.isInitialized or self.template == nil then
		return
	end

	self.ScrollFrame.update = function()
		self:RefreshScrollFrame()
	end

	UpdateScrollButtons(self)

	HybridScrollFrame_SetDoNotHideScrollBar(self.ScrollFrame, true)
	self.isInitialized = true

	self:UpdatedSelectedHighlight()
end

function ScrollListMixin:IsInitialized()
	return self.isInitialized
end

function ScrollListMixin:ScrollToBegin()
	self.ScrollFrame.scrollBar:SetValue(0)
end

function ScrollListMixin:ScrollToEnd()
	local _, maxValue = self.ScrollFrame.scrollBar:GetMinMaxValues()
	self.ScrollFrame.scrollBar:SetValue(maxValue)
end

function ScrollListMixin:IsAtEnd()
	local _, maxValue = self.ScrollFrame.scrollBar:GetMinMaxValues()
	return math.NearlyEquals(self.ScrollFrame.scrollBar:GetValue(), maxValue, 0.1)
end

function ScrollListMixin:IsAtBegin()
	return self.ScrollFrame.scrollBar:GetValue() < 0.1
end

function ScrollListMixin:UpdatedSelectedHighlight()
	local selectedHighlight = self:GetSelectedHighlight()
	selectedHighlight:ClearAllPoints()
	selectedHighlight:Hide()

	if self.isInitialized and self.selectedIndex ~= nil then
		local buttonOffset = self.selectedIndex - self:GetScrollOffset()
		local buttons = HybridScrollFrame_GetButtons(self.ScrollFrame)
		if buttonOffset >= 1 and buttonOffset < #buttons then
			local button = buttons[buttonOffset]
			local left, right, top, bottom = self:GetSelectedHighlightInset()
			selectedHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", left, -top)
			selectedHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -right, bottom)
			selectedHighlight:SetParent(button)
			selectedHighlight:Show()
		end
	end
end

function ScrollListMixin:SimulateSelectionClick()
	if self.isInitialized and self.selectedIndex ~= nil then
		local buttonOffset = self.selectedIndex - self:GetScrollOffset()
		local buttons = HybridScrollFrame_GetButtons(self.ScrollFrame)
		if buttonOffset >= 1 and buttonOffset < #buttons then
			local button = buttons[buttonOffset]
			button:Click("LeftButton")
		end
	end
end

function ScrollListMixin:GetSelectedButton()
	if self.isInitialized and self.selectedIndex ~= nil then
		local buttonOffset = self.selectedIndex - self:GetScrollOffset()
		local buttons = HybridScrollFrame_GetButtons(self.ScrollFrame)
		if buttonOffset >= 1 and buttonOffset < #buttons then
			return buttons[buttonOffset]
		end
	end
end

function ScrollListMixin:SetCanSelect(canSelect)
	self.PreventSelection = not canSelect
	if not canSelect then
		self.selectedIndex = nil
		self:UpdatedSelectedHighlight()
		self:RefreshScrollFrame()
	end
end

function ScrollListMixin:SetSelectedIndex(index, updateType)
	if self.PreventSelection then return end

	local sameIndex = self.selectedIndex == index
	self.selectedIndex = index

	if updateType and updateType > 0 then
		if self.selectionCallback then
			self.selectionCallback(index)
		end
	end

	if sameIndex and updateType == ScrollListMixin.UpdateType.OnlyNewIndex then
		return
	elseif sameIndex and updateType == ScrollListMixin.UpdateType.OnlyNewIndexSimulateClick then
		return
	end

	self:RefreshScrollFrame()

	if updateType == ScrollListMixin.UpdateType.AlwaysSimulateClick or updateType == ScrollListMixin.UpdateType.OnlyNewIndexSimulateClick then
		self:SimulateSelectionClick()
	else
		self:UpdatedSelectedHighlight()
	end
end

function ScrollListMixin:ScrollToSelection()
	if self.selectedIndex ~= nil then
		HybridScrollFrame_ScrollToIndex(self.ScrollFrame, self.selectedIndex)
	end
end

function ScrollListMixin:GetSelectedIndex()
	return self.selectedIndex
end

function ScrollListMixin:GetLine(index)
	return self.ScrollFrame.buttons[index]
end

function ScrollListMixin:Reset()
	if self.isInitialized then
		self.ScrollFrame.scrollBar:SetValue(0)
	end
end

function ScrollListMixin:GetScrollOffset()
	return HybridScrollFrame_GetOffset(self.ScrollFrame)
end

function ScrollListMixin:CollapseExpandedButton()
	HybridScrollFrame_CollapseButton(self.ScrollFrame)
end

function ScrollListMixin:OnSizeChanged()
	if self.isInitialized then
		self:RefreshScrollFrame()
	end
end

function ScrollListMixin:AllowSelectingSelected()
	return self.allowSelectingSelected
end

function ScrollListMixin:SetAllowSelectingSelected(allow)
	self.allowSelectingSelected = allow
end

function ScrollListMixin:RefreshScrollFrame()
	if not self:IsVisible() then
		return
	end

	if self.template == nil then
		error("Scroll list Template not set. Use ScrollListMixin:SetTemplate.")
		return
	end

	if self.getNumResultsFunction == nil then
		error("Scroll list getNumResultsFunction not set. Use ScrollListMixin:SetGetNumResultsFunction.")
		return
	end

	if not self.isInitialized then
		error("Scroll list has not been initialized. This should generally happen in OnShow.")
		return
	end

	local numResults = self.getNumResultsFunction()
	local buttons = HybridScrollFrame_GetButtons(self.ScrollFrame)
	local buttonCount = #buttons

	local offset = self:GetScrollOffset()
	local lastDisplayedOffset = 0
	local expandedIndex, expandedHeight = HybridScrollFrame_GetExpandedButton(self.ScrollFrame)

	for i = 1, buttonCount do
		local listIndex = offset + i
		local button = buttons[i]

		if listIndex <= numResults then
			button:SetIndex(listIndex)
			if expandedIndex == listIndex then
				if self.ScrollFrame.isHorizontal then
					button:SetWidth(expandedHeight)
				else
					button:SetHeight(expandedHeight)
				end
			else
				if self.ScrollFrame.isHorizontal then
					if button:GetWidth() ~= self.ScrollFrame.buttonHeight then
						button:SetWidth(self.ScrollFrame.buttonHeight)
					end
				else
					if button:GetHeight() ~= self.ScrollFrame.buttonHeight then
						button:SetHeight(self.ScrollFrame.buttonHeight)
					end
				end
			end
			button:Show()
			lastDisplayedOffset = i
		else
			button:Hide()
		end
	end

	local numDisplayed = math.min(buttonCount, numResults)
	local buttonHeight = self.ScrollFrame.buttonHeight
	local displayedHeight = numDisplayed * buttonHeight
	local totalHeight = numResults * buttonHeight
	
	HybridScrollFrame_Update(self.ScrollFrame, totalHeight, displayedHeight)

	self:UpdatedSelectedHighlight()

	if self.refreshCallback ~= nil then
		self.refreshCallback(lastDisplayedOffset)
	end
end

------------------------------------------------------------------------------------------------
--[[
------------------------------------------------------------------------------------------------
-- Bare bones ScrollList Setup
------------------------------------------------------------------------------------------------

Create a Mixin for your template inheriting from ScrollListItemBaseMixin
```
MyScrollListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)
``` 

Create an XML Template for your scroll list item. Inherit from `ScrollListItemTemplate` or `ScrollListItemTextTemplate`
In <OnLoad> do (See: AddonPanelTemplates.xml > `AddonScrollListItemTemplate`)
```
Mixin(self, MyScrollListItemMixin)
```

------------------------------------------------------------------------------------------------
MyScrollListItemMixin MUST define the following or you will get a warning error
```
function MyScrollListItemMixin:Update()
	-- called when its time to update this buttons info
	-- see: AddonScrollListItemMixin.lua > AddonScrollListItemMixin:Update()
end

function MyScrollListItemMixin:OnSelected()
	-- Called when this button is left clicked and highlighted by the scroll list
end
```

MyScrollListItemMixin can optionally define the following
```
function MyScrollListItemMixin:Init(args)
	ScrollListItemBaseMixin.Init(self, args)
end

function MyScrollListItemMixin:OnRightClick()
end

function MyScrollListItemMixin:OnEnter()
end

function MyScrollListItemMixin:OnLeave()
end
```

------------------------------------------------------------------------------------------------
Make a frame inheriting from a ScrollListTemplate
```
local MyList = CreateFrame("Frame", "MyList", UIParent, "MinimalScrollListTemplate")
```

Make a function that returns the number of results to show. Ex: (AddonPanel.lua)
```
local function getNumResults()
	if not self.addons then return 0 end
	return #self.addons
end
```

Initialize the scroll list
```
MyList:SetGetNumResultsFunction(getNumResults)
-- Pass the string name for your template here
MyList:SetTemplate("MyScrollListTemplate", self)
```

------------------------------------------------------------------------------------------------
You can now force update the list with
`MyList:RefreshScrollFrame()`

or force select an index with
`MyList:SetSelectedIndex(index[, ScrollListMixin.UpdateType.])`
```
ScrollListMixin.UpdateType.OnlyNewIndex
ScrollListMixin.UpdateType.OnlyNewIndexSimulateClick
ScrollListMixin.UpdateType.Always
ScrollListMixin.UpdateType.AlwaysSimulateClick
```

Change the selection texture with
`MyList:GetSelectedHighlight()`
ex: `self.AddonList:GetSelectedHighlight():SetAtlas("addons_list_active", Const.TextureKit.IgnoreAtlasSize)`
]]--
