PathFindMentorPanelMixin = {}

function PathFindMentorPanelMixin:OnLoad()
    self.Icon:SetAtlas("newplayerhelp-newcomer", Const.TextureKit.IgnoreAtlasSize)
    self.AvailableMentors:SetTemplate("PathMentorItemTemplate")
    self.AvailableMentors:SetGetNumResultsFunction(C_Tutorial.GetNumAvailableMentors)
    self.AvailableMentors:SetSelectedHighlightTexture()
    self:CreateFilter()
end

function PathFindMentorPanelMixin:CreateFilter()
    self.Filter:RegisterCallback("OnFilterChanged", GenerateClosure(self.Update, self))
    self.Filter:SetSingleOptionMode(true)

    for i, specID in ipairs(C_Tutorial.GetMentorSpecializations()) do
        local name, atlas = C_Tutorial.GetMentorSpecializationInfo(specID)
        if name then
            atlas = TutorialUtil.ConvertDynamicMentorIcon(atlas)
            self.Filter:AddFilterOption(specID, self.Filter:CreateFilterInfo(name, nil, atlas))
        end
    end
end

function PathFindMentorPanelMixin:OnShow()
    self:RegisterEvent("MENTOR_WHOIS_DATA_CONTAINER_RESET")
    self:RegisterEvent("QUERY_MENTOR_WHOIS_RESULT")
    self:Reset()
    self:RefreshData()
end 

function PathFindMentorPanelMixin:OnHide()
    self:UnregisterEvent("MENTOR_WHOIS_DATA_CONTAINER_RESET")
    self:UnregisterEvent("QUERY_MENTOR_WHOIS_RESULT")
end

function PathFindMentorPanelMixin:OnEvent(event, ...)
    if event == "MENTOR_WHOIS_DATA_CONTAINER_RESET" then
        self.RefreshButton:Enable()
        self.AvailableMentors:RefreshScrollFrame()
    elseif event == "QUERY_MENTOR_WHOIS_RESULT" then
        self.RefreshButton:Enable()
        self:Update()
    end
end

function PathFindMentorPanelMixin:Update()
    local filter = next(self.Filter:GetFilter()) or 0
    
    C_Tutorial.SetAvailableMentorFilter(self.SearchBox:GetText(), filter)
    self.AvailableMentors:RefreshScrollFrame()
end 

function PathFindMentorPanelMixin:Reset()
    self.SearchBox:SetText("")
    self.Filter:ClearFilters()
end 

function PathFindMentorPanelMixin:RefreshData()
    self.RefreshButton:Disable()
    C_Tutorial.QueryActiveMentors()
end 