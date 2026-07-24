RandomModeGossipMixin = CreateFromMixins("CallbackRegistryMixin")

local GOSSIP_NPCS = {342827, 342828, 642827}

function RandomModeGossipMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    self:GenerateCallbackEvents({
        "OnSpecializationSelected"
    })
    self:RegisterForDrag("LeftButton")
    self.Tabs.Bg:SetTexture("Interface\\darkmoon\\bg_256", "MIRROR", "MIRROR")
    self.Content.Bg:SetTexture("Interface\\darkmoon\\bg", "REPEAT", "REPEAT")
    self.Content.Bg:SetHorizTile(true)
    self.Content.Bg:SetVertTile(true)
    PortraitFrame_SetIcon(self, "Interface\\Icons\\ability_mage_timewarp")
    
    self.Specs:SetTemplate("RandomModeSpecItemTemplate")
    self.Specs:SetGetNumResultsFunction(SpecializationUtil.GetNumSpecializations)
    self.Specs:SetSelectionCallback(function(index)
        self.selectedSpecialization = index
        self:TriggerEvent("OnSpecializationSelected", index)
    end)
    for _, npcID in ipairs(GOSSIP_NPCS) do
        C_Gossip:RedirectNPC(npcID, GenerateClosure(self.OnGossipShow, self), GenerateClosure(self.OnGossipHide, self))
    end
end

function RandomModeGossipMixin:OnGossipShow()
    C_Gossip:SilentHideGossip()
    ShowUIPanel(self)
end

function RandomModeGossipMixin:OnGossipHide()
    C_Gossip:RestoreGossip()
    HideUIPanel(self)
end

function RandomModeGossipMixin:OnShow()
    self:RegisterEvent("COLLECT_SCROLL_OF_FORTUNE_REWARDS_RESULT")
    self:RegisterEvent("COLLECT_HAND_OF_FATE_REWARDS_RESULT")
    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    self:RegisterEvent("BAG_UPDATE")

    self:SetupTabs()
    local title = ""
    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        title = WILDCARD_MODE
    elseif C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
        title = DRAFT_MODE
    end
    PortraitFrame_SetTitle(self, title)
    self.Specs:SetSelectedIndex(SpecializationUtil.GetActiveSpecialization(), ScrollListMixin.UpdateType.AlwaysSimulateClick)
end

function RandomModeGossipMixin:OnHide()
    CloseGossip()
    self:UnregisterEvent("COLLECT_SCROLL_OF_FORTUNE_REWARDS_RESULT")
    self:UnregisterEvent("COLLECT_HAND_OF_FATE_REWARDS_RESULT")
end

function RandomModeGossipMixin:OnEvent(event, ...)
    if event == "BAG_UPDATE" then
        self.Tabs.Currency.GoldenTickets:UpdateDisplay()
        self.Tabs.Currency.Tickets:UpdateDisplay()
        self.Tabs.Currency.Marks:UpdateDisplay()
    elseif event == "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED" then
        self.Specs:SetSelectedIndex(SpecializationUtil.GetActiveSpecialization(), ScrollListMixin.UpdateType.AlwaysSimulateClick)
        self.Specs:RefreshScrollFrame()
    else
        self.Specs:RefreshScrollFrame()
    end
end

function RandomModeGossipMixin:SetupTabs()
    self.Tabs:RemoveAllTabs()
    local tab
    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        tab = self.Tabs:AddTab(SOF_TAB_TITLE, self.Content.RewardsTab)
        tab.Icon:SetIcon("Interface\\Icons\\inv_custom_scrollofunlearning_seasonal")
        tab:SetTooltip(SOF_TAB_TITLE, SOF_TAB_SUBTEXT)
        self.Tabs.RewardsTab = tab:GetTabID()

        if C_Config.GetBoolConfig("CONFIG_WILDCARD_ROLL_REPURCHASING_ENABLED") then
            tab = self.Tabs:AddTab(REPURCHASE_SCROLLS, self.Content.RepurchaseTab)
            tab.Icon:SetIcon("Interface\\Icons\\inv_custom_scrollofunlearning_seasonal")
            tab:SetTooltip(REPURCHASE_SCROLLS, REPURCHASE_SCROLLS_SUBTEXT)
            tab:SetTabEnabled(C_Wildcard.CanRepurchaseAnyRolls(false), REPURCHASE_SCROLLS, REPURCHASE_SCROLLS_SUBTEXT, RED_FONT_COLOR:WrapText(REPURCHASE_SCROLLS_DISABLED_TOOLTIP))
        end

        tab = self.Tabs:AddTab(BOOSTER_TAB_TITLE, self.Content.BoosterTab)
        tab.Icon:SetIcon("Interface\\Icons\\inv_inscription_tarot_6otankdeck")
        tab:SetTooltip(BOOSTER_TAB_TITLE, BOOSTER_TAB_SUBTEXT)
    elseif C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
        tab = self.Tabs:AddTab(HOF_TAB_TITLE, self.Content.RewardsTab)
        tab.Icon:SetIcon("Interface\\Icons\\inv_custom_handofunlearning_seasonal")
        tab:SetTooltip(HOF_TAB_TITLE, HOF_TAB_SUBTEXT)
        self.Tabs.RewardsTab = tab:GetTabID()
    end

    tab = self.Tabs:AddTab(TICKET_TAB_TITLE, self.Content.TicketTab)
    tab.Icon:SetIcon("Interface\\Icons\\inv_misc_ticket_darkmoon_01")
    tab:SetTooltip(TICKET_TAB_TITLE, TICKET_TAB_SUBTEXT)
    self.Tabs.TicketTab = tab:GetTabID()
    
    self.Tabs:SelectFirstEnabledTab()

    self.Tabs.Currency.GoldenTickets:SetItem(ItemData.GOLDEN_DARKMOON_TICKET, true)
    self.Tabs.Currency.Tickets:SetItem(ItemData.DARKMOON_TICKET, true)
    self.Tabs.Currency.Marks:SetItem(ItemData.MARK_OF_ASCENSION, true)

    self.Tabs.Currency.GoldenTickets:UpdateDisplay()
    self.Tabs.Currency.Tickets:UpdateDisplay()
    self.Tabs.Currency.Marks:UpdateDisplay()

    self.Tabs:RegisterCallback("OnTabSelected", self.OnTabSelected, self)
end

function RandomModeGossipMixin:OnTabSelected(tabID)
    if tabID == self.Tabs.RewardsTab then
        self.Specs:Show()
        self.Content:SetPoint("RIGHT", self.Specs, "LEFT", -2, 0)
        self.Content.ArtBottom:SetSize(558, 279)
        self.Content.ArtBottom:SetTexture("Interface\\Darkmoon\\art_bottom")
        self.Content.ArtBottom:SetTexCoord(1, 0, 0, 1)
    else
        self.Specs:Hide()
        self.Content:SetPoint("RIGHT", self, "RIGHT", -2, 0)
        self.Content.ArtBottom:SetSize(839, 419)
        self.Content.ArtBottom:SetTexture("Interface\\Darkmoon\\art_bottom_expand")
        self.Content.ArtBottom:SetTexCoord(0, 1, 0, 1)
    end
end

function RandomModeGossipMixin:GetSelectedSpecialization()
    return self.selectedSpecialization or 1
end 

function RandomModeGossipMixin:OnDragStart()
    self:StartMoving()
end

function RandomModeGossipMixin:OnDragStop()
    self:StopMovingOrSizing()
end