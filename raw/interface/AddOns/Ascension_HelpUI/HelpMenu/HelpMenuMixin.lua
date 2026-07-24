HelpMenuMixin = {}

function HelpMenuMixin:OnLoad()
	self:RegisterForDrag("LeftButton")
	self:RegisterEvent("UPDATE_TICKET")
	self:RegisterEvent("GMRESPONSE_RECEIVED")

	self.LeftInset.Background:SetAtlas("store-category-bg", Const.TextureKit.IgnoreAtlasSize)
	self.LeftInset.Divider1:SetAtlas("help-divider", Const.TextureKit.UseAtlasSize)
	self.LeftInset.Divider2:SetAtlas("help-divider", Const.TextureKit.UseAtlasSize)

	PortraitFrame_SetIcon(self, "Interface\\Icons\\mail_gmicon")
	PortraitFrame_SetTitle(self, HELP_FRAME_TITLE)
	
	self:SetupTabSystem()
end

function HelpMenuMixin:SetupTabSystem()
	local tabSystem = self.LeftInset
	MixinAndLoadScripts(tabSystem, "TabSystemMixin")

	tabSystem:SetTabSelectedSound(SOUNDKIT.UCHARACTERSHEETTAB)
	tabSystem:SetTabPoint("TOP", 0, -48)
	tabSystem:SetTabLayout(function(tabIndex, tab, previousTab)
		local y = -24
		-- make room for dividers
		if tabIndex == 2 or tabIndex == 4 then
			y = -48
		end
		tab:SetPoint("TOP", previousTab, "BOTTOM", 0, y)
	end)
	tabSystem:SetTabTemplate("HelpMenuTabTemplate")

	tabSystem:RegisterCallback("OnTabSelected", self.OnTabSelected, self)
	
	local panelParent = self.RightInset.ScrollFrame.Child
	local tab
	tab = tabSystem:AddTab(KBASE_GMTALK, panelParent.TicketPanel)
	tab:SetIcon("helpicon-chat")
	self.ticketTabID = tab:GetTabID()
	tab = tabSystem:AddTab(HELPFRAME_STUCK_TITLE, panelParent.StuckPanel)
	tab:SetIcon("helpicon-stuck")
	tab = tabSystem:AddTab(HELPFRAME_LOST_ITEM, self.RightInset.ItemRestorePanel) -- not part of scroll!
	self.recoveryTabID = tab:GetTabID()
	tab:SetIcon("helpicon-itemrestore")
	tab = tabSystem:AddTab(BUG_REPORT, panelParent.BugReportPanel)
	tab:SetIcon("helpicon-bug")
	tab = tabSystem:AddTab(SUBMIT_FEEDBACK)
	tab:SetIcon("helpicon-suggestion")
	self.feedbackTabID = tab:GetTabID()
    
    tab = tabSystem:AddTab(POLL_FRAME_TITLE)
    tab:SetIcon("ExperienceIconAscension", 40, 40)
    
    tab.Glow = CreateFrame("Frame", "$parentYellowGlow", tab, "ButtonYellowGlowTemplate")
    tab.Glow:SetFrameLevel(tab:GetFrameLevel() - 1)
    tab.Glow:SetPoint("TOPLEFT", -11, 18)
    tab.Glow:SetPoint("BOTTOMRIGHT", 11, -18)
    self.pollTabID = tab:GetTabID()
end

function HelpMenuMixin:OnTabSelected(tabID)
	self.RightInset.ScrollFrame:SetShown(tabID ~= self.recoveryTabID)
	if tabID == self.feedbackTabID then
		HideUIPanel(HelpMenuFrame)
		self.LeftInset:SelectTabID(1)
		ShowUIPanel(FeedbackFrame)
		return
	end
    
    if tabID == self.pollTabID then
        HideUIPanel(HelpMenuFrame)
        self.LeftInset:SelectTabID(1)
        Poll_LoadUI()
        ShowUIPanel(PollingFrame)
        return
    end

	local panel = self.LeftInset:GetPanelForTabID(tabID)
	if panel.RegenerateLayout then
		panel:RegenerateLayout()
	end
end

function HelpMenuMixin:OnShow()
	GetGMTicket()
	PlaySound(SOUNDKIT.ESCAPE_SCREEN_OPEN_70)
	local tabSystem = self.LeftInset
	if not tabSystem:GetCurrentTabID() then
		tabSystem:SelectFirstEnabledTab()
	else
		local panel = tabSystem:GetPanelForTabID(tabSystem:GetCurrentTabID())
		if panel.RegenerateLayout then
			panel:RegenerateLayout()
		end
	end

    if C_PlayerPoll.GetNumQuestions() > 0 then
        if C_PlayerPoll.HasUnansweredQuestions() then
            local tab = tabSystem:GetTabByID(self.pollTabID)
            if tab then
                tab.Glow:Show()
            end
        else
            local tab = tabSystem:GetTabByID(self.pollTabID)
            if tab then
                tab.Glow:Hide()
            end
        end
        tabSystem:ShowTabID(self.pollTabID)
    else
        local tab = tabSystem:GetTabByID(self.pollTabID)
        if tab then
            tab.Glow:Hide()
        end
        tabSystem:HideTabID(self.pollTabID)
    end
	self:UpdateTicketTab()
    HelpTip:Acknowledge("UNANSWERED_PLAYER_POLL_QUESTIONS")
end

function HelpMenuMixin:OpenTicketTab()
	local tabSystem = self.LeftInset
	tabSystem:SelectTabID(self.ticketTabID)
end

function HelpMenuMixin:OpenItemRecovery(category)
	local tabSystem = self.LeftInset
	tabSystem:SelectTabID(self.recoveryTabID)
	if category then
		for _, tab in self.RightInset.ItemRestorePanel.Categories:EnumerateTabs() do
			if tab.categoryID == category and tab:IsShown() then
				self.RightInset.ItemRestorePanel.Categories:SelectTabID(tab:GetTabID())
				break
			end
		end
	end
end

function HelpMenuMixin:UpdateTicketTab()
	local tabSystem = self.LeftInset
	if self.HasTicket then
		tabSystem:UpdateTabText(self.ticketTabID, HELPFRAME_VIEW_MY_TICKET)
	elseif self.HasResponse then
		tabSystem:UpdateTabText(self.ticketTabID, HELPFRAME_VIEW_GM_RESPONSE)
	else
		tabSystem:UpdateTabText(self.ticketTabID, KBASE_GMTALK)
	end
end

function HelpMenuMixin:OnHide()
	PlaySound(SOUNDKIT.ESCAPE_SCREEN_CLOSE)
end

function HelpMenuMixin:UPDATE_TICKET(hasTicket)
	self.HasResponse = false
	if hasTicket then
		self.HasTicket = true
	else
		self.HasTicket = false
	end
	self:UpdateTicketTab()
end

function HelpMenuMixin:GMRESPONSE_RECEIVED()
	self.HasTicket = false
	self.HasResponse = true
	self:UpdateTicketTab()
end