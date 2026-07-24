---- Tab System
--[[
How to Use / Minimum Setup:
Create a Tab frame template
	<CheckButton name="MyTabTemplate" virtual="true">
		<Scripts>
			<OnLoad>
				MixinAndLoadScripts(self, "MyTabMixin")
			</OnLoad>
		</Scripts>
	</CheckButton>
	
Create a Mixin for your tab template that inherits from TabSystemTabMixin
	MyTabMixin = CreateFromMixins(TabSystemTabMixin)

Add TabSystemMixin to a frame
	MixinAndLoadScripts(frame, "TabSystemMixin")
	
Set the template
	frame:SetTabTemplate("MyTabTemplate")

Set a Tab Layout (Optional, default = HORIZONTAL)
	frame:SetTabLayout("HORIZONTAL") or frame:SetTabLayout("VERTICAL") or frame:SetTabLayout(function(tabIndex, tab, previousTab) --set point manually end)

Set an Initial Tab Point (Optional, default = TOPLEFT, self, BOTTOMLEFT, 12, 0)
	frame:SetTabPoint("TOPLEFT", frame, "BOTTOMLEFT", 12, 0)

Add Tabs
	frame:AddTab(text[, panel, tabID])
		text = button text
		panel = panel to show when tab is selected. Can be nil
		tabID = index to insert tab at. Can be nil
		
When a tab is clicked, it will hide the current panel, and show its panel, if any.
The tab button will be disabled. You can full disable a button using
	tab:SetTabEnabled(enabled[, disableReason])
you can get if a tab is fully disabled with
	tab:IsTabEnabled()

]]--
TabSystemMixin = CreateFromMixins(CallbackRegistryMixin)

function TabSystemMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({ "OnTabSelected", "OnTabAdded", "OnTabRemoved" })
	self.tabs = {}
	self.tabPanels = {}
	self.currentTab = nil
	self.tabPoint = { "TOPLEFT", self, "BOTTOMLEFT", 12, 0 }
	self.tabLayout = "HORIZONTAL"
	self.tabPadding = { 0, 0 }
	self.tabLevel = self:GetFrameLevel() + 1
end

function TabSystemMixin:SetTabPoint(...)
	self.tabPoint = { ... }
end

function TabSystemMixin:SetTabLayout(layout)
	self.tabLayout = layout
end

function TabSystemMixin:SetTabLevel(level)
	self.tabLevel = level
end

function TabSystemMixin:SetTabPadding(x, y)
	self.tabPadding = { x, y }
end

function TabSystemMixin:SetTabTemplate(template)
	self.tabTemplate = template
end

function TabSystemMixin:SetTabSelectedSound(sound)
	self.tabSelectedSound = sound
end

function TabSystemMixin:GetCurrentTabID()
	return self.currentTab and self.currentTab:GetTabID()
end

local function ResetTab(tabPool, tab)
	tab.internalTooltipTitle = nil
	tab.internalTooltipText = nil
	tab.tooltipTitle = nil
	tab.tooltipText = nil
	tab:ClearAllPoints()
	tab:Hide()
	tab:SetTabEnabled(true)
end

function TabSystemMixin:AddTab(text, panel, tabID)
	-- this is delayed so we can set template first
	if not self.tabPool then
		self.tabPool = CreateFramePool("CheckButton", self, self.tabTemplate or "TabSystemTabTemplate", ResetTab)
	end
	local newTab = self.tabPool:Acquire()
	-- check if inserting tab or appending tab
	if tabID then
		tinsert(self.tabs, tabID, newTab)
		-- reindex tabs after insertion
		for i = #self.tabs, tabID + 1, -1 do
			self.tabs[i]:SetTabID(i)
			self.tabPanels[i] = self.tabPanels[i - 1]
		end
	else
		tinsert(self.tabs, newTab)
		tabID = #self.tabs
	end

	newTab:SetTabSystem(self)
	newTab:Init(tabID, text)
	newTab:Show()
	self.tabPanels[tabID] = panel
	
	-- update layout because we may have inserted
	self:UpdateTabLayout()
	self:TriggerEvent("OnTabAdded", tabID, newTab)
	return newTab
end

function TabSystemMixin:UpdateTab(tabID, text, panel)
	local tab = self.tabs[tabID]
	if tab then
		tab:SetTabText(text)
		self.tabPanels[tabID] = panel
		return tab
	end
end

function TabSystemMixin:UpdateTabText(tabID, text)
	local tab = self.tabs[tabID]
	if tab then
		tab:SetTabText(text)
		return tab
	end
end

function TabSystemMixin:RemoveTab(tabID)
	local tab = self.tabs[tabID]
	if tab then
		self.tabPool:Release(tab)
		tremove(self.tabs, tabID)
		self.tabPanels[tabID] = nil
	end
	
	-- reindex tab and panels
	local length = #self.tabs
	for i = tabID, length do
		self.tabs[i]:SetTabID(i)
		self.tabPanels[i] = self.tabPanels[i + 1]
	end
	
	self.tabPanels[length + 1] = nil
	self:TriggerEvent("OnTabRemoved", tabID, tab)
	self:UpdateTabLayout()
end

function TabSystemMixin:RemoveAllTabs()
	for tabID, tab in pairs(self.tabs) do
		self:TriggerEvent("OnTabRemoved", tabID, tab)
	end
	wipe(self.tabs)
	wipe(self.tabPanels)
	if self.tabPool then
		self.tabPool:ReleaseAll()
	end
end

function TabSystemMixin:GetTabForPanel(panel)
	for tabID, tabPanel in pairs(self.tabPanels) do
		if type(panel) == "string" then
			if type(tabPanel) == "string" then
				if tabPanel == panel then
					return self.tabs[tabID]
				end
			else
				if _G[panel] and _G[panel] == tabPanel then
					return self.tabs[tabID]
				end
			end
		else
			if type(tabPanel) == "string" then
				if _G[tabPanel] and _G[tabPanel] == panel then
					return self.tabs[tabID]
				end
			else
				if tabPanel == panel then
					return self.tabs[tabID]
				end
			end
		end
	end
end

function TabSystemMixin:HideCurrentPanel()
	if self.currentTab then
		local currentPanel = self.tabPanels[self.currentTab:GetTabID()]
		if type(currentPanel) == "string" then
			currentPanel = _G[currentPanel]
		end
		if currentPanel then
			currentPanel:Hide()
		end
	end
end

function TabSystemMixin:ShowCurrentPanel()
	if self.currentTab then
		local currentPanel = self.tabPanels[self.currentTab:GetTabID()]
		if type(currentPanel) == "string" then
			currentPanel = _G[currentPanel]
		end
		if currentPanel then
			currentPanel:Show()
		end
	end
end

function TabSystemMixin:SelectTab(selectedTab, silent)
	if selectedTab.preClick then
		selectedTab:preClick()
	end
	
	self.currentTab = selectedTab
	for _, tab in pairs(self.tabs) do
		tab:SetTabSelected(tab == selectedTab)
		local panel = self.tabPanels[tab:GetTabID()]
		local selectedPanel = self.tabPanels[selectedTab:GetTabID()]

		if type(panel) == "string" then
			panel = _G[panel]
		end

		if type(selectedPanel) == "string" then
			selectedPanel = _G[selectedPanel]
		end

		if panel then
			panel:SetShown(panel == selectedPanel or tab == selectedTab)
		end
	end
	
	if self.tabSelectedSound and not silent then
		PlaySound(self.tabSelectedSound)
	end

	self:TriggerEvent("OnTabSelected", selectedTab:GetTabID(), selectedTab)
end

function TabSystemMixin:SelectTabID(tabID)
	local tab = self.tabs[tabID]
	if tab then
		self:SelectTab(tab)
	end
end

function TabSystemMixin:GetTabWidthConstraints()
	return self.minTabWidth, self.maxTabWidth
end

function TabSystemMixin:SetTabWidthConstraints(minWidth, maxWidth)
	self.minTabWidth = minWidth
	self.maxTabWidth = maxWidth
	self:UpdateTabLayout()
end

function TabSystemMixin:GetTabPadding()
	return unpack(self.tabPadding)
end

function TabSystemMixin:UpdateTabLayout()
	local lastTab
	for tabID, tab in pairs(self.tabs) do
		tab:SetFrameLevel(self.tabLevel)
		tab:UpdateWidth()
		if tab:IsShown() then
			if not lastTab then
				tab:ClearAndSetPoint(unpack(self.tabPoint))
			else
				if type(self.tabLayout) == "function" then
					self.tabLayout(tabID, tab, lastTab)
				elseif self.tabLayout == "HORIZONTAL" then
					tab:ClearAndSetPoint("LEFT", lastTab, "RIGHT", self:GetTabPadding())
				else
					tab:ClearAndSetPoint("TOP", lastTab, "BOTTOM", self:GetTabPadding())
				end
			end
			lastTab = tab
		end
	end
end

function TabSystemMixin:SelectFirstEnabledTab()
	for _, tab in pairs(self.tabs) do
		if tab:IsTabEnabled() then
			self:SelectTab(tab, true)
			return
		end
	end

	-- we didnt find a tab, blank panel i guess
	if self.currentTab then
		local currentPanel = self.tabPanels[self.currentTab:GetTabID()]
		if type(currentPanel) == "string" then
			currentPanel = _G[currentPanel]
		end
		if currentPanel then
			currentPanel:Hide()
		end
		self.currentTab = nil
	end
end

function TabSystemMixin:GetPanelForTabID(tabID)
	local panel = self.tabPanels[tabID]
	if type(panel) == "string" then
		panel = _G[panel]
	end
	return panel
end

function TabSystemMixin:GetTabByID(tabID)
	return self.tabs[tabID]
end

function TabSystemMixin:SetTabEnabled(tabID, enabled, reason)
	local tab = self.tabs[tabID]
	if tab then
		tab:SetTabEnabled(enabled, reason)
		if not enabled and tab == self.currentTab then
			self:SelectFirstEnabledTab()
		end
	end
end

function TabSystemMixin:HideTabs()
	for _, tab in pairs(self.tabs) do
		tab:Hide()
	end
end

function TabSystemMixin:ShowTabs()
	for _, tab in pairs(self.tabs) do
		tab:Show()
	end
end

function TabSystemMixin:HideTabID(tabID)
	local tab = self.tabs[tabID]
	if tab then
		tab:Hide()
	end
	if self:IsVisible() then
		self:UpdateTabLayout()
	end
end

function TabSystemMixin:ShowTabID(tabID)
	local tab = self.tabs[tabID]
	if tab then
		tab:Show()
	end
	if self:IsVisible() then
		self:UpdateTabLayout()
	end
end

function TabSystemMixin:EnumerateTabs()
	return ipairs(self.tabs)
end

function TabSystemMixin:CanSelectTabID(tabID)
	local tab = self.tabs[tabID]
	if tab then
		return tab:IsTabEnabled() and tab:IsShown()
	end
end

function TabSystemMixin:CanSelectCurrentTab()
	return self.currentTab and self.currentTab:IsTabEnabled() and self.currentTab:IsShown()
end

