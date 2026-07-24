PathAppendixPanelMixin = {}

function PathAppendixPanelMixin:OnLoad()
    self.Keywords:SetTemplate("PathAppendixItemTemplate")
    self.Keywords:SetGetNumResultsFunction(C_Tutorial.GetNumKeywords)
    self.Keywords:SetAllowSelectingSelected(true)
    
    self.Keywords:SetSelectionCallback(GenerateClosure(self.OnKeywordSelected, self))

    local highlight = self.Keywords:GetSelectedHighlight()
    highlight:SetAtlas("GarrMission_ListGlow-Select", Const.TextureKit.UseAtlasSize)
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.5)
    self.Keywords:SetSelectedHighlightInset(0, 0, 4, 0)
    
    
    self.Display.Background:SetAtlas("pta-book-bg", Const.TextureKit.IgnoreAtlasSize)
end

function PathAppendixPanelMixin:OnShow()
    self.KeywordsHeader.Search:SetText("")
    self:UpdateSearch("")
    
    if not self.Keywords:GetSelectedIndex() then
        self.Keywords:SetSelectedIndex(1, ScrollListMixin.UpdateType.AlwaysSimulateClick)
    end
end

function PathAppendixPanelMixin:UpdateSearch(text)
    local searchText = text:trim()
    C_Tutorial.SetKeywordFilter(searchText)
    
    -- if search changed our selected index, we need to reset it
    local currentIndex = self.Keywords:GetSelectedIndex()
    if currentIndex then
        local keyword = C_Tutorial.GetKeywordAtIndex(currentIndex)
        if self.currentKeyword ~= keyword then
            self.Keywords:SetSelectedIndex(1, ScrollListMixin.UpdateType.AlwaysSimulateClick)
            return
        end
    end
    self.Keywords:RefreshScrollFrame()
end 

function PathAppendixPanelMixin:SelectSpecificKeyword(keywordID)
    C_Tutorial.SetKeywordFilter("")
    local currentIndex = self.Keywords:GetSelectedIndex()
    local keywordIndex = C_Tutorial.GetIndexByKeywordID and C_Tutorial.GetIndexByKeywordID(keywordID) or 1
    if not currentIndex or currentIndex ~= keywordIndex then
        self.Keywords:SetSelectedIndex(keywordIndex, ScrollListMixin.UpdateType.AlwaysSimulateClick)
        self.Keywords:ScrollToSelection()
    end
end

function PathAppendixPanelMixin:OnKeywordSelected(index)
    local keyword, description, icon, banner = C_Tutorial.GetKeywordAtIndex(index)
    self.currentKeyword = keyword

    if string.isNilOrEmpty(banner) then
        banner = "Book_of_Ascension"
    end
    
    -- remove images
    if description then -- ?
        description = description:gsub("{[^}]+}", "")
        description = description:gsub("^\n+", "")
        description = description:trim()
    else
        description = ""
    end

    self.Display.Title:SetText(keyword)
    self.Display.Description:SetText(description)
    self.Display.Banner:SetTexture("Interface\\Tutorials\\PtA\\"..banner)
    
    self.Display:Show()
end 