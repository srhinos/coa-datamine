PathToAscensionMixin = CreateFromMixins(TabSystemMixin)

function PathToAscensionMixin:OnLoad()
    self:RegisterEvent("CLAIM_TUTORIAL_REWARDS_RESULT")
    self.TitleText:SetText(PATH_TO_ASCENSION)
    PortraitFrame_SetIcon(self, "Interface\\pta\\pta_portrait")
    self.Objectives:SetGetNumResultsFunction(C_Tutorial.GetNumTutorials)
    self.Objectives:SetTemplate("PathObjectiveItemTemplate")
    self.CompleteProgress:SetFrameLevel(self.Objectives:GetFrameLevel() + 5)
    
    self.ObjectivesHeader:SetFrameLevel(self.Objectives:GetFrameLevel() + 5)

    local highlight = self.Objectives:GetSelectedHighlight()
    highlight:SetAtlas("GarrMission_ListGlow-Select", Const.TextureKit.UseAtlasSize)
    highlight:SetBlendMode("ADD")
    highlight:SetAlpha(0.5)
    self.Objectives:SetSelectedHighlightInset(0, 0, 4, 0)
    self.DisplayBackground:SetPoint("TOPLEFT", self.Display, "TOPLEFT", 12, -12)
    self.DisplayBackground:SetPoint("BOTTOMRIGHT", self.Display, "BOTTOMRIGHT", -12, 12)

    self:SetupCategoryTabs()
    
    self:RegisterForDrag("LeftButton")
end

function PathToAscensionMixin:SetupCategoryTabs()
    TabSystemMixin.OnLoad(self)
    --self:SetTabTemplate("PTATabButtonTemplate")
    self:SetTabLevel(self:GetFrameLevel()+5)
    self:SetTabSelectedSound(SOUNDKIT.CHARACTER_SHEET_TAB)
    self:SetTabPoint("TOPLEFT", self, "BOTTOMLEFT", 12, 4)
    self:SetTabPadding(-4, 0)
    self:RegisterCallback("OnTabSelected", self.OnCategorySelected, self)
    self:RefreshTabs()
end

function PathToAscensionMixin:RefreshTabs()
    self:RemoveAllTabs()
    local categories = C_Tutorial.GetCategories()
    for i, categoryID in ipairs(categories) do
        local name = C_Tutorial.GetCategoryInfo(categoryID)
        local tab = self:AddTab(name)
        tab.categoryID = categoryID
        tab:SetTextPadding(20)
        local tabEnabled = C_Tutorial.IsCategoryEnabled(categoryID)
        self:SetTabEnabled(tab:GetTabID(), tabEnabled)
        local newCategory = tabEnabled and not PTA_TUTORIALS_SEEN["Category"..categoryID]
        --tab.NewIcon:SetShown(newCategory)
        SetButtonPulse(tab, newCategory and 60 or 0, 2)
    end
    
    local tab = self:AddTab(MENTOR_SYSTEM)
    tab.categoryID = -1
    tab:SetTextPadding(20)
    self:SetTabEnabled(tab:GetTabID(), true)


    tab = self:AddTab(PTA_KEYWORD_APPENDIX)
    tab.categoryID = -2
    tab:SetTextPadding(20)
    self:SetTabEnabled(tab:GetTabID(), true)
    self.AppendixTab = tab:GetTabID()

    if self:IsShown() then
        self:SelectBestTutorial()
    end
end

function PathToAscensionMixin:OnShow()
    PlaySound(SOUNDKIT.QUESTLOGOPENA)
    SetButtonPulse(PathToAscensionMicroButton, 0, 1)
    HelpTip:HideAllSystem("micromenu")
    self:RegisterEvent("TUTORIAL_CONTAINER_RESET")
    self:RegisterEvent("TUTORIAL_ENTRY_UPDATE")
    self:RegisterEvent("TUTORIAL_ENTRY_COMPLETE")
    UpdateMicroButtons()
    self:RefreshTabs()
end

function PathToAscensionMixin:OnHide()
    PlaySound(SOUNDKIT.QUESTLOGCLOSEA)
    self:UnregisterEvent("TUTORIAL_CONTAINER_RESET")
    self:UnregisterEvent("TUTORIAL_ENTRY_UPDATE")
    self:UnregisterEvent("TUTORIAL_ENTRY_COMPLETE")
    UpdateMicroButtons()
end

function PathToAscensionMixin:SelectBestTutorial()
    local categoryID
    
    -- find first tab with uncollected rewards and/or incomplete tutorials
    for _, tab in self:EnumerateTabs() do
        if tab:IsTabEnabled() then
            local _, numRewarded, total = C_Tutorial.GetCategoryProgress(tab.categoryID)
            if numRewarded and numRewarded < total then
                categoryID = tab.categoryID
                self:SelectTab(tab)
                break
            end
        end
    end
    
    if categoryID then
        -- try to select any uncollected reward
        -- if not found, select the first incomplete tutorial
        local incompleteIndex
        for i = 1, C_Tutorial.GetNumTutorials() do
            local tutorialID = C_Tutorial.GetTutorialAtIndex(i)
            if not C_Tutorial.IsRewardCollected(tutorialID) then
                self.Objectives:SetSelectedIndex(i, ScrollListMixin.UpdateType.OnlyNewIndexSimulateClick)
                self.Objectives:ScrollToSelection()
                return
            elseif not incompleteIndex then
                -- save the first incomplete index
                incompleteIndex = C_Tutorial.IsTutorialComplete(tutorialID) and nil or i
            end
        end

        if incompleteIndex then
            self.Objectives:SetSelectedIndex(incompleteIndex, ScrollListMixin.UpdateType.OnlyNewIndexSimulateClick)
            self.Objectives:ScrollToSelection()
        end
    end
    
    -- we didnt find anything just select first enabled tab & first tutorial
    self:SelectFirstEnabledTab()
    self.Objectives:SetSelectedIndex(1, ScrollListMixin.UpdateType.OnlyNewIndexSimulateClick)
    self.Objectives:ScrollToSelection()
end

function PathToAscensionMixin:OnCategorySelected(tabID, tab)
    self.selectedCategoryID = tab.categoryID
    --tab.NewIcon:Hide()
    PTA_TUTORIALS_SEEN["Category"..self.selectedCategoryID] = true
    SetButtonPulse(tab, 0, 1)
    self.ObjectivesHeader.Search:SetText("")
    self:Refresh()
    if self.selectedCategoryID == -1 then
        self:DisplayMentorSystem()
    elseif self.selectedCategoryID == -2 then
        self:DisplayAppendix()
    else
        self:DisplayTutorials()
    end
end 

function PathToAscensionMixin:DisplayTutorials()
    self.Objectives:Show()
    self.CompleteProgress:Show()
    self.ObjectivesHeader:Show()
    self.Display:Show()
    self.DisplayBackground:Show()

    self.AppendixPanel:Hide()
    
    self.MentorPanel:Hide()

    self.Objectives:SetSelectedIndex(1, ScrollListMixin.UpdateType.AlwaysSimulateClick)
    self.Objectives:ScrollToSelection()
end

function PathToAscensionMixin:DisplayMentorSystem()
    self.Objectives:Hide()
    self.CompleteProgress:Hide()
    self.ObjectivesHeader:Hide()
    self.Display:Hide()
    self.DisplayBackground:Hide()
    
    self.AppendixPanel:Hide()

    self.MentorPanel:Show()
end

function PathToAscensionMixin:DisplayAppendix()
    self.Objectives:Hide()
    self.CompleteProgress:Hide()
    self.ObjectivesHeader:Hide()
    self.Display:Hide()
    self.DisplayBackground:Hide()

    self.MentorPanel:Hide()
    
    self.AppendixPanel:Show()
end


function PathToAscensionMixin:Refresh()
    local searchText = self.ObjectivesHeader.Search:GetText():trim()
    C_Tutorial.SetTutorialFilter(self.selectedCategoryID, searchText)
    self.Objectives:RefreshScrollFrame()

    local numCompleted, numRewarded, total = C_Tutorial.GetCategoryProgress(self.selectedCategoryID)
    local categoryName = C_Tutorial.GetCategoryInfo(self.selectedCategoryID)

    -- background bar (yellow)
    self.CompleteProgress:SetMinMaxValues(0, total)
    self.CompleteProgress:SetValue(numCompleted)
    
    -- overlay bar (green)
    self.CompleteProgress.RewardProgress:SetMinMaxValues(0, total)
    self.CompleteProgress.RewardProgress:SetValue(numRewarded)

    if numCompleted ~= numRewarded then
        self.CompleteProgress.RewardProgress:SetFormattedText("%s %s (%s) / %s", categoryName or "", numRewarded, numCompleted-numRewarded, total)
    else
        self.CompleteProgress.RewardProgress:SetFormattedText("%s %s / %s", categoryName or "", numCompleted, total)
    end
end

function PathToAscensionMixin:UpdateSearch()
    self:Refresh()
end 

function PathToAscensionMixin:OnEvent(event, ...)
    if event == "TUTORIAL_CONTAINER_RESET" then
        self:Refresh()
    elseif event == "CLAIM_TUTORIAL_REWARDS_RESULT" then
        local result = ...
        if result == "CLAIM_TUTORIAL_OK" then
            PlaySound(SOUNDKIT.TUTORIAL_CLAIM_REWARD)
        else
            UIErrorsFrame:AddMessage(_G[result] or result, 1.0, 0.1, 0.1, 1.0)
        end
    elseif event == "TUTORIAL_ENTRY_UPDATE" or event == "TUTORIAL_ENTRY_COMPLETE" then
        self:Refresh()
    end
end 

function PathToAscensionMixin:OnProgressEnter()
    GameTooltip:SetOwner(self.CompleteProgress, "ANCHOR_TOP")
    GameTooltip:SetText(string.format(S_PROGRESS, C_Tutorial.GetCategoryInfo(self.selectedCategoryID)), 1, 1, 1)
    local numCompleted, numRewarded, total = C_Tutorial.GetCategoryProgress(self.selectedCategoryID)
    GameTooltip:AddLine(string.format(TUTORIALS_COMPLETED_S, HIGHLIGHT_FONT_COLOR:WrapText(numCompleted .. " / " .. total)), 1, 0.82, 0)
    if numCompleted ~= numRewarded then
        GameTooltip:AddLine(string.format(TUTORIALS_PENDING_REWARDS_S, HIGHLIGHT_FONT_COLOR:WrapText(numCompleted-numRewarded)), GREEN_FONT_COLOR:GetRGB())
    end
    GameTooltip:Show()
end 

function PathToAscensionMixin:OnDragStart()
    self:StartMoving()
end 

function PathToAscensionMixin:OnDragStop()
    self:StopMovingOrSizing()
end 