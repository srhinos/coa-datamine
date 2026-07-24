AutoCompleteInputMixin = CreateFromMixins(CallbackRegistryMixin)

function AutoCompleteInputMixin:OnLoad()
	self.Left:SetAtlas("common-search-border-left", Const.TextureKit.IgnoreAtlasSize)
	self.Right:SetAtlas("common-search-border-right", Const.TextureKit.IgnoreAtlasSize)
	self.Middle:SetAtlas("common-search-border-middle", Const.TextureKit.IgnoreAtlasSize)

	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({ "OnSelectionChanged" })
	self.minSearchCharacters = 3
	self.maxResults = 50
	self.resultCount = 0
	self.results = {}

	self.Dialog.Scroll:SetGetNumResultsFunction(function()
		return self.resultCount or 0
	end)
	self.Dialog.Scroll:GetSelectedHighlight():SetAtlas("addons_list_active", Const.TextureKit.IgnoreAtlasSize)
	self.Dialog.Scroll:SetSelectionCallback(function(index)
		if self:HasFocus() then
			self:PreviewCompletion(self.completions[index])
		else
			self:SelectCompletion(self.completions[index])
		end
	end)
	self.Dialog:Hide()
end

-- Sets the function this auto complete will call. Should return a list of string completions
-- Signature: function(text, resultCount)
function AutoCompleteInputMixin:SetDataProvider(func)
	self.dataProvider = func
end

function AutoCompleteInputMixin:HasDataProvider()
	return type(self.dataProvider) == "function"
end

function AutoCompleteInputMixin:SetMaxResults(count)
	self.maxResults = count
end

function AutoCompleteInputMixin:SetMinSearchCharacters(count)
	self.minSearchCharacters = count
end

function AutoCompleteInputMixin:SelectCompletion(completion)
	if not completion then return end
	self:PreviewCompletion(completion)
	self:SetText(completion)
	self.Dialog:Hide()
	EditBox_ClearFocus(self)
end

function AutoCompleteInputMixin:GetSelectedCompletionValue()
	return self.SelectedCompletion
end

function AutoCompleteInputMixin:PreviewCompletion(completion)
	if not completion then return end
	self.SelectedCompletion = completion

	self:TriggerEvent("OnSelectionChanged", completion)
end

function AutoCompleteInputMixin:UpdateCompletions()
	if not self.dataProvider then return end
	if not self.Dialog.Scroll:IsInitialized() then
		self.Dialog.Scroll:SetTemplate("AutoCompleteListItemTemplate", self)
	end
	local search = self:GetText()

	if search:len() < self.minSearchCharacters then
		self.resultCount = 0
	else
		self.completions = self.dataProvider(self:GetText(), self.maxResults)
		self.resultCount = #self.completions
	end

	if self.resultCount > 0 then
		self.Dialog:Show()
	else
		self.Dialog.Scroll:ScrollToBegin()
		self.Dialog:Hide()
	end

	local height = self.Dialog.Scroll.ScrollFrame.buttonHeight
	local numButtons = #self.Dialog.Scroll.ScrollFrame.buttons - 1
	
	if self.resultCount > numButtons then
		self.Dialog.Scroll.ScrollFrame.scrollUp:Show()
		self.Dialog.Scroll.ScrollFrame.scrollDown:Show()
		self.Dialog.Scroll.ScrollFrame.scrollBar:Show()
	else
		self.Dialog.Scroll.ScrollFrame.scrollUp:Hide()
		self.Dialog.Scroll.ScrollFrame.scrollDown:Hide()
		self.Dialog.Scroll.ScrollFrame.scrollBar:Hide()
	end

	self.Dialog:SetHeight(height * math.min(self.resultCount, numButtons) + 10)
	self.Dialog.Scroll:RefreshScrollFrame()
end

function AutoCompleteInputMixin:AutoCompleteOnTextChanged()
	if self.Timer then
		return
	end
	
	self.Timer = Timer.After(0.2, function()
		self.Timer = nil
		self:UpdateCompletions()
	end)
end

function AutoCompleteInputMixin:AutoCompleteOnEnterPressed()
	if self.SelectedCompletion then
		self:SelectCompletion(self.SelectedCompletion)
	end
	EditBox_ClearFocus(self)
end

function AutoCompleteInputMixin:AutoCompleteOnTabPressed()
	if self.Dialog.Scroll:GetSelectedIndex() then
		local index = self.Dialog.Scroll:GetSelectedIndex()
		if index >= self.resultCount then
			index = 0
		end
		self.Dialog.Scroll:SetSelectedIndex(index + 1, ScrollListMixin.UpdateType.Always)
	else
		self.Dialog.Scroll:SetSelectedIndex(1, ScrollListMixin.UpdateType.Always)
	end
end 

function AutoCompleteInputMixin:SetDialogPosition(position, xOffset, yOffset)
	if position == "TOP" then
		self.Dialog:ClearAllPoints()
		self.Dialog:SetPoint("BOTTOMLEFT", self, "TOPLEFT", xOffset or 0, yOffset or 0)
		self.Dialog:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", xOffset or 0, yOffset or 0)
	elseif position == "BOTTOM" then
		self.Dialog:ClearAllPoints()
		self.Dialog:SetPoint("TOPLEFT", self, "BOTTOMLEFT", xOffset or 0, yOffset or 0)
		self.Dialog:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", xOffset or 0, yOffset or 0)
	elseif position == "LEFT" then
		self.Dialog:ClearAllPoints()
		self.Dialog:SetPoint("TOPRIGHT", self, "TOPLEFT", xOffset or 0, yOffset or 0)
		self.Dialog:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", xOffset or 0, yOffset or 0)
	elseif position == "RIGHT" then
		self.Dialog:ClearAllPoints()
		self.Dialog:SetPoint("TOPLEFT", self, "TOPRIGHT", xOffset or 0, yOffset or 0)
		self.Dialog:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", xOffset or 0, yOffset or 0)
	end
end

--
-- Auto Complete Item Mixin
--
AutoCompleteItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function AutoCompleteItemMixin:Init(args)
	ScrollListItemBaseMixin.Init(self, args)
	self.parent = args[1]
end

function AutoCompleteItemMixin:Update()
	self.completion = self.parent.completions[self.index]
	if self.completion then
		self:SetText(self.completion)
	end
end

function AutoCompleteItemMixin:OnSelected()
	self.parent:SelectCompletion(self.completion)
end

function AutoCompleteItemMixin:OnEnter()
	self.parent:PreviewCompletion(self.completion)
end 