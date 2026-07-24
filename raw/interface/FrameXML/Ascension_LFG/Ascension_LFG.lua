--
-- PVE Frame Mixin
--
LFGFrameMixin = {
    BASE_WIDTH = 563,
	BASE_HEIGHT = 428,
    panels = {
		{ name = "AscensionPVEFrame", check = function() return C_LFG:CanUseLFD() or C_LFG:CanUseManastorm() end },
		{ name = "AscensionPVPFrame", check = function() return C_Player:GetLevel() >= 10 end },
		{ name = "AscensionRulesetFrame", check = function() return C_Player:GetLevel() >= 15 end },
		{ name = "AscensionWeeklyKeystoneFrame", check = function() return C_Player:GetLevel() >= 60 or C_Player:IsPrestiged() end }
    }
}

function LFGFrameMixin:OnLoad()
	PanelTemplates_SetNumTabs(self, #self.panels)
	self.PortraitFrame.portrait:SetPortraitTexture("Interface\\LFGFrame\\UI-LFG-PORTRAIT")
	self.maxTabWidth = (self:GetWidth() - 19) / #self.panels
	C_Hook:Register(self, "PLAYER_ENTERING_WORLD")
end

function LFGFrameMixin:OnShow()
    for i, panel in pairs(self.panels) do
        if panel.check and not panel.check() then
            PanelTemplates_DisableTab(self, i)
        else
            PanelTemplates_EnableTab(self, i)
        end
    end

	for i = 1, 3 do
        GetArenaTeam(i) -- possible fix for missing team data?
    end

	UpdateMicroButtons()
	Ascension_QueryArenaRewardInfo()
end

function LFGFrameMixin:OnHide()
	UpdateMicroButtons()
end

function LFGFrameMixin:OnTabClick(tab)
    PlaySound("igCharacterInfoTab")
	self:ShowFrame(self.panels[tab:GetID()].name)
end

function LFGFrameMixin:ShowFrame(sidePanelName, selectionIndex)
	-- find side panel
	local tabIndex
	if sidePanelName then
		if type(sidePanelName) == "number" then
			tabIndex = sidePanelName
		else
			for index, data in pairs(self.panels) do
				if data.name == sidePanelName then
					tabIndex = index
					break
				end
			end
		end
	else
		-- no side panel specified, check current panel
		if ( self.activeTabIndex ) then
			tabIndex = self.activeTabIndex
		else
			-- no current panel, go to the first panel
			tabIndex = 1
		end
	end

	if not tabIndex then
		return
	end

	if self.panels[tabIndex].check and not self.panels[tabIndex].check() then
		tabIndex = tabIndex or 1
	end

	-- show it
	ShowUIPanel(self)
	self.activeTabIndex = tabIndex
	PanelTemplates_SetTab(self, tabIndex)
	
	if tabIndex == 1 then
		-- Path to Ascension: Dungeon Finder
		C_Quest:SendPathToAscensionEvent("ACTION_OPEN_THE_DUNGEON_FINDER")
	end
	local panelToShow
	for index, data in pairs(self.panels) do
		local panel = _G[data.name]
		if index == tabIndex then
			panelToShow = panel
		elseif panel then
			panel:Hide()
		end
	end

	if panelToShow then
		panelToShow:Show()
		if panelToShow.ShowCategory then
			self:ShowCategories()
			selectionIndex = selectionIndex or panelToShow.selectedIndex or 1
			panelToShow:ShowCategory(selectionIndex)
		else
			self:HideCategories()
		end
	end

	UpdateUIPanelPositions(self)
	UpdateMicroButtons()
end

function LFGFrameMixin:HideCategories()
	if not self.Menu:IsVisible() then return end
	self.Menu:Hide()
	self.Inset:Hide()
	self.Button1:Hide()
	self.Button2:Hide()
	self.Button3:Hide()
	self.shadows:Hide()
	self.Content:SetPoint("TOPLEFT", 3, -23)
end

function LFGFrameMixin:ShowCategories()
	if self.Menu:IsVisible() then return end
	self.Menu:Show()
	self.Inset:Show()
	self.Button1:Show()
	self.Button2:Show()
	self.Button3:Show()
	self.shadows:Show()
	self.Content:SetPoint("TOPLEFT", "$parentMenu", "TOPRIGHT", 0, 0)
end

function LFGFrameMixin:PLAYER_ENTERING_WORLD()
	for i = 1, 3 do
        GetArenaTeam(i) -- possible fix for missing team data?
    end
	C_Hook:Unregister(self, "PLAYER_ENTERING_WORLD")
end

--
-- Help Plates
--
HelpTips["LFG_FRAME_CATEGORY"] = {
	text = HELP_PLATE_LFG_FRAME_CATEGORY,
	targetPoint = HelpTip.Point.RightEdgeCenter,
}

HelpTips["LFG_FRAME_TABS"] = {
	text = HELP_PLATE_LFG_FRAME_TABS,
	targetPoint = HelpTip.Point.TopEdgeCenter,
}