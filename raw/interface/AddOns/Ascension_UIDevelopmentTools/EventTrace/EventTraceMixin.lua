EventTraceMixin = {}

function EventTraceMixin:OnLoad()
    PortraitFrame_SetTitle(self, "Event Trace")
    self:SetUserPlaced(false)
    self:SetParent(InGlue() and GlueParent or UIParent)
    self:SetFrameStrata("FULLSCREEN_DIALOG")
    self:RegisterForDrag("LeftButton")
    
    self.EventList:SetGetNumResultsFunction(EventTrace.GetNumEvents)
    self.EventList:SetTemplate("EventTraceItemTemplate")
    self.EventList:GetSelectedHighlight():SetTexture(0.05, 0.05, 0.05, 1)
    self.EventList:GetSelectedHighlight():SetBlendMode("ADD")
    self.EventList.Background:SetAtlas("auctionhouse-background-buy-noncommodities-market", Const.TextureKit.IgnoreAtlasSize)
    
    self.FilterList:SetGetNumResultsFunction(EventTrace.GetNumFilters)
    self.FilterList:SetTemplate("EventTraceFilterItemTemplate")
    self.FilterList:GetSelectedHighlight():SetTexture(0.05, 0.05, 0.05, 1)
    self.FilterList:GetSelectedHighlight():SetBlendMode("ADD")
    self.FilterList.Background:SetAtlas("auctionhouse-background-auctions", Const.TextureKit.IgnoreAtlasSize)
    
    EventTrace:RegisterCallback("EventsChanged", self.Update, self)
    EventTrace:RegisterCallback("FiltersChanged", self.Update, self)
    EventTrace:RegisterCallback("ClearedSearch", self.ClearSearch, self)
    EventTrace:RegisterCallback("Started", self.UpdateToggleButton, self)
    EventTrace:RegisterCallback("Stopped", self.UpdateToggleButton, self)
    
    UIDropDownMenu_Initialize(self.OptionsButton.DropDown, GenerateClosure(self.InitializeOptionsDropDown, self), "MENU")
end

function EventTraceMixin:OnShow()
    if not self.initialized then
        EventTrace.Start()
        self.initialized = true
    end
end

function EventTraceMixin:OnHide()
    if not C_CVar.GetBool("eventTraceKeepActive") then
        EventTrace.Stop()
    end
end

function EventTraceMixin:Update()
    local atEnd = self.EventList:IsAtEnd()
    self.EventList:RefreshScrollFrame()

    if atEnd then
        self.EventList:ScrollToEnd()
    end

    self.FilterList:RefreshScrollFrame()
    if self.FilterList:IsShown() then
        self.FilterList:ScrollToEnd()
    end
end

function EventTraceMixin:UpdateToggleButton()
    if EventTrace.IsPaused() then
        self.ToggleButton:SetText(START)
    else
        self.ToggleButton:SetText(PAUSE)
    end
end

function EventTraceMixin:ClearSearch()
    self.SearchBox:SetText("")
end

function EventTraceMixin:ToggleFilterTab()
    if self.FilterList:IsShown() then
        self.EventList:Show()
        self.FilterList:Hide()
        self.FiltersButton:SetText(SHOW_FILTERS)
        self.EventList:ScrollToEnd()
    else
        self.EventList:Hide()
        self.FilterList:Show()
        self.FiltersButton:SetText(SHOW_LOG)
        self.FilterList:ScrollToEnd()
    end
end

function EventTraceMixin:InitializeOptionsDropDown(dropdown, level, menuList)
    if not self:IsVisible() then return end
    local info = UIDropDownMenu_CreateInfo()
    info.text = EVENT_TRACE_LOG_WHILE_HIDDEN
    info.checked = C_CVar.GetBool("eventTraceKeepActive")
    info.func = function()
        C_CVar.Set("eventTraceKeepActive", not C_CVar.GetBool("eventTraceKeepActive"))
    end
    UIDropDownMenu_AddButton(info, level)
    
    info = UIDropDownMenu_CreateInfo()
    info.text = EVENT_TRACE_SHOW_ARGS
    info.checked = C_CVar.GetBool("eventTraceArgs")
    info.func = function()
        C_CVar.Set("eventTraceArgs", not C_CVar.GetBool("eventTraceArgs"))
        EventTrace:TriggerEvent("EventsChanged")
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = EVENT_TRACE_SHOW_COUNT
    info.checked = C_CVar.GetBool("eventTraceCount")
    info.func = function()
        C_CVar.Set("eventTraceCount", not C_CVar.GetBool("eventTraceCount"))
        EventTrace:TriggerEvent("EventsChanged")
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "Show EventRegistry Events"
    info.checked = EVENT_TRACE_SHOW_EVENT_REGISTRY
    info.func = function()
        EVENT_TRACE_SHOW_EVENT_REGISTRY = not EVENT_TRACE_SHOW_EVENT_REGISTRY
        EventTrace:TriggerEvent("EventsChanged")
    end
    UIDropDownMenu_AddButton(info, level)
end

