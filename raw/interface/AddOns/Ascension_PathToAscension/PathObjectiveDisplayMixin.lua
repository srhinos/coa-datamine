PathObjectiveDisplayMixin = {}

function PathObjectiveDisplayMixin:OnLoad()
    self.Bg:SetAtlas("pta-book-bg", Const.TextureKit.IgnoreAtlasSize)
    self.Bg:ClearAllPoints()
    self.Bg:SetSize(733, 633)
    self.Bg:SetPoint("TOPLEFT")
    self.Description:SetHeight(590)
    self.Description.Content:SetHeight(590)

    self.NineSliceShadow:SetAlpha(0.5)

    self.NineSliceShadow:SetFrameLevel(self.QuestObjectives:GetFrameLevel()+1)
    self.NineSlice:SetFrameLevel(self.NineSliceShadow:GetFrameLevel()+1)

    self.ImagePool = CreateTexturePool(self.Description.Content, "BACKGROUND")
    self.TextPool = CreateFramePool("SimpleHTML", self.Description.Content, "PTADescriptionTemplate")

    self.LeftButton:SetScript("OnClick", GenerateClosure(self.PreviousPage, self))
    self.RightButton:SetScript("OnClick", GenerateClosure(self.NextPage, self))

    self.PageText:SetPoint("BOTTOM", self.QuestObjectives, "TOP", 0, 22)
end

function PathObjectiveDisplayMixin:OnShow()
    self:RegisterEvent("QUEST_LOG_UPDATE")
    self:RegisterEvent("CRITERIA_UPDATE")
    self:RegisterEvent("TUTORIAL_ENTRY_UPDATE")
end

function PathObjectiveDisplayMixin:OnHide() 
    self:UnregisterEvent("QUEST_LOG_UPDATE")
    self:UnregisterEvent("CRITERIA_UPDATE")
    self:UnregisterEvent("TUTORIAL_ENTRY_UPDATE")
end

function PathObjectiveDisplayMixin:SetTutorial(tutorialID)
    self.tutorialID = tutorialID
    self.name, self.description, self.questID = C_Tutorial.GetTutorialDisplay(tutorialID)
    self.page = 1
    self.pages = self:SplitPages(self.description)
    self:RefreshDisplay()

    self.QuestObjectives:SetTutorial(tutorialID, self.questID)
end

-- local testDesc = [[
-- {T:Interface\\Tutorials\\PtA\\Interesting_Ethereals_Horde:2:1}
-- <h1 align="center">Page 1</h1><br />
-- <p>This uses new p tags for every line</p>
-- <p>test desc</p>
-- <p>test desc</p>
-- <p>test desc</p>
-- <p>test desc</p>
-- {page}
-- <h1 align="center">Page 2</h1><br />
-- <p>This uses a single p tag and br / tags for new lines<br />
-- test desc<br />
-- test desc<br />
-- test desc<br />
-- test desc<br />
-- test desc</p>
-- ]]

function PathObjectiveDisplayMixin:RefreshDisplay()
    self:FormatDescription(self.pages[self.page])
    self:UpdatePages()

    self.Description:SetHeight(self:GetHeight()-43)
    self.Description.Content:SetHeight(self:GetHeight()-43)
end

function PathObjectiveDisplayMixin:UpdatePages(lastSection)
    self.PageText:SetFormattedText(MERCHANT_PAGE_NUMBER, self.page, #self.pages)

    if (#self.pages) > 1 then
        self.PageText:Show()
        self.LeftButton:Show()
        self.RightButton:Show()
    else
        self.PageText:Hide()
        self.LeftButton:Hide()
        self.RightButton:Hide()
    end

    self.LeftButton:SetEnabled(self:HasPreviousPage())
    self.RightButton:SetEnabled(self:HasNextPage())
end

function PathObjectiveDisplayMixin:NextPage()
    self.page = math.clamp(self.page + 1, 1, #self.pages)
    self:RefreshDisplay()
end

function PathObjectiveDisplayMixin:PreviousPage()
    self.page = math.clamp(self.page - 1, 1, #self.pages)
    self:RefreshDisplay()
end

function PathObjectiveDisplayMixin:HasNextPage()
    return self.page < #self.pages
end

function PathObjectiveDisplayMixin:HasPreviousPage()
    return self.page > 1
end

function PathObjectiveDisplayMixin:AddText(text, parent)
    text = text:gsub("^\n", ""):gsub("\n$", ""):trim()
    local width = self.Description.Content:GetWidth()-48

    if text:len() > 0 then
        local line = self.TextPool:Acquire()
        line:SetWidth(width)
        if parent then
            line:SetPoint("TOP", parent, "BOTTOM", 0, 0)
        else
            line:SetPoint("TOP", self.Description.Content, 0, 0)
        end
        local height = line:SetDynamicText(HTML_TAG_WRAPPER:format(text))
        line:Show()
        return line, height + 10
    end
    
    return nil, 0
end

function PathObjectiveDisplayMixin:AddImage(tag, parent)
    if tag:len() > 0 then
        local filePath, imageWidth, imageHeight, left, right, top, bottom = TextureUtil.ResolveCustomTextureTag(tag)
        local width = self.Description.Content:GetWidth()
        local image = self.ImagePool:Acquire()
        
        imageWidth = imageWidth or width
        imageHeight = imageHeight or imageWidth

        imageWidth, imageHeight = TextureUtil.FitTextureToWidth(width, imageHeight, imageWidth, imageHeight)
        image:SetSize(imageWidth, imageHeight)
        image:SetTexture(filePath)
        image:SetTexCoord(left, right, top, bottom)
        if parent then
            image:SetPoint("TOP", parent, "BOTTOM", 0, 0)
        else
            image:SetPoint("TOP", self.Description.Content, 0, 0)
        end
        image:Show()
        return image, image:GetHeight()+10
    end
    
    return nil, 0
end

function PathObjectiveDisplayMixin:FormatDescription(description)
    self.ImagePool:ReleaseAll()
    self.TextPool:ReleaseAll()

    local lastSection
    local section, sectionHeight
    local height = 10
    local imageStart = string.find(description, "{", 1, true)
    local imageEnd = string.find(description, "}", 1, true)
    if imageStart then
        -- we have image(s) in the description
        while description:len() > 0 do
            -- text before image tag
            section, sectionHeight = self:AddText(string.sub(description, 1, imageStart-1), lastSection)
            height = height + sectionHeight
            lastSection = section or lastSection
            
            -- image tag
            local image = string.sub(description, imageStart, imageEnd)
            section, sectionHeight = self:AddImage(image, lastSection)
            height = height + sectionHeight
            lastSection = section or lastSection
            
            -- text after image tag
            description = string.sub(description, imageEnd+1)
            
            -- check if the rest is just text
            imageStart = string.find(description, "{", 1, true)
            imageEnd = string.find(description, "}", 1, true)
            if not imageStart then
                section, sectionHeight = self:AddText(description, lastSection)
                height = height + sectionHeight
                lastSection = section or lastSection
                break
            end
        end
    else
        section, sectionHeight = self:AddText(description, lastSection)
        height = height + sectionHeight
    end
    
    --self.Description.Content:SetHeight(height)

    return section or lastSection
end

function PathObjectiveDisplayMixin:SplitPages(description)
    -- split pages by the {page} tag
    local pages = {}
    local page = 1
    while description:len() > 0 do
        local pageStart = string.find(description, "{page}", 1, true)
        if pageStart then
            table.insert(pages, page, string.sub(description, 1, pageStart-1))
            page = page + 1
            description = string.sub(description, pageStart+6)
        else
            table.insert(pages, page, description)
            break
        end
    end
    return pages
end

function PathObjectiveDisplayMixin:OnEvent(event, ...)
    self.QuestObjectives:OnEvent(event)
end 

--
-- Objectives mixin (TODO: MOVE TO IS OWN FILE)
--
PathObjectiveQuestObjectivesMixin = {}

function PathObjectiveQuestObjectivesMixin:OnLoad()
    self.RewardTitle:SetPoint("TOPLEFT", self.ObjectiveText, "BOTTOMLEFT", 0, -8)

    --self:SetBackdrop(GameTooltip:GetBackdrop())

    self.BgTop:ClearAllPoints()
    self.BgTop:SetPoint("TOPLEFT", -6, 22)
    self.BgTop:SetAtlas("pta-book-beltTop", Const.TextureKit.IgnoreAtlasSize)
    self.BgTop:SetSize(735.075, 43.37)

    self.BgBottom:ClearAllPoints()
    self.BgBottom:SetPoint("BOTTOMLEFT", -6, 0)
    self.BgBottom:SetAtlas("pta-book-beltBottom", Const.TextureKit.IgnoreAtlasSize)
    self.BgBottom:SetSize(735.075, 39.14)

    self.BgMiddle:ClearAllPoints()
    self.BgMiddle:SetPoint("TOPLEFT", self.BgTop, "BOTTOMLEFT", 0, 0)
    self.BgMiddle:SetPoint("BOTTOMRIGHT", self.BgBottom, "TOPRIGHT", 0, 0)
    self.BgMiddle:SetAtlas("pta-book-beltMiddle", Const.TextureKit.IgnoreAtlasSize)

    self.Buckle:ClearAllPoints()
    self.Buckle:SetPoint("RIGHT", 0, 0)
    self.Buckle:SetAtlas("pta-book-buckle", Const.TextureKit.IgnoreAtlasSize)
    self.Buckle:SetSize(50.6, 185.4)

    self.RewardPool = CreateFramePool("Button", self.RewardGroup, "ItemIconTemplate")
end

function PathObjectiveQuestObjectivesMixin:SetTutorial(tutorialID, questID)
    self.tutorialID = tutorialID
    self.questID = questID

    self:RefreshDisplay()
end

function PathObjectiveQuestObjectivesMixin:RefreshDisplay()
    local totalHeight = 42

    if self:UpdateInteractButton() then

        local hasRewards = self:UpdateRewards()
        local hasObjectives = self:UpdateObjectives()

        if hasRewards then
            totalHeight = totalHeight + self.RewardTitle:GetHeight() + self.RewardGroup:GetHeight() + 8

            self.RewardTitle:ClearAndSetPoint("TOP", self, 0, -16)
        end

        if hasObjectives then
            totalHeight = totalHeight + self.ObjectiveTitle:GetHeight() + self.ObjectiveText:GetHeight()

            self.RewardTitle:ClearAndSetPoint("TOPLEFT", self.ObjectiveText, "BOTTOMLEFT", 0, -8)

            if hasRewards then
                totalHeight = totalHeight + 8
            end
        end

        -- 100% is ~150. adjust buckle together with the belt. Can be improved by slicing the buckle to 3 pieces
        local pct = (totalHeight*100)/150/100
        self.Buckle:SetHeight(pct*185)
        self:SetHeight(totalHeight)
        --self:GetParent():SetPoint("BOTTOMRIGHT", self:GetParent(), "BOTTOMRIGHT", -4, 6+totalHeight)
        self:Show()
    else
        self:SetHeight(totalHeight/2)
        self:Hide()
        --self:GetParent():SetPoint("BOTTOMRIGHT", self:GetParent(), "BOTTOMRIGHT", -4, 6)
    end
end

function PathObjectiveQuestObjectivesMixin:UpdateObjectives()
    local objectiveText
    for _, objectiveID in ipairs(C_Tutorial.GetObjectives(self.tutorialID)) do
        local objectiveName = C_Tutorial.GetObjectiveInfo(objectiveID)
        if not objectiveText then
            objectiveText = "• "..objectiveName
        else
            objectiveText = objectiveText.."\n".."• "..objectiveName
        end
    end

    if objectiveText then
        self.ObjectiveTitle:Show()
        self.ObjectiveText:Show()
        self.ObjectiveText:SetDynamicText(objectiveText)
        return true
    else
        self.ObjectiveTitle:Hide()
        self.ObjectiveText:Hide()
        return false
    end
end

function PathObjectiveQuestObjectivesMixin:UpdateRewards()
    self.RewardPool:ReleaseAll()
    local rewards = C_Tutorial.GetRewards(self.tutorialID)
    if rewards and next(rewards) then
        self.RewardTitle:Show()
        --self.RewardDivider:Show()
        self.RewardGroup:Show()
        local index = 1
        for itemID, count in pairs(rewards) do
            local button = self.RewardPool:Acquire()
            button:SetItem(itemID, count)
            button.layoutIndex = index
            button.align = "left"
            button:Show()
            index = index + 1
        end

        self.RewardGroup:MarkDirty()
        return true
    else
        self.RewardTitle:Hide()
        --self.RewardDivider:Hide()
        self.RewardGroup:Hide()
        self.RewardGroup:MarkDirty()
        return false
    end
end

function PathObjectiveQuestObjectivesMixin:UpdateInteractButton()
    if C_Tutorial.IsTutorialComplete(self.tutorialID) then
        if C_Tutorial.CanCollectReward(self.tutorialID) then
            self.Interact.Button:SetText(COLLECT_REWARD)
            self.Interact.Button:Enable()
            self.Interact:Show()
            return true
        else
            self.Interact:Hide()
            return false
        end
    elseif self.questID and not QuestUtil.IsQuestTurnedIn(self.questID) then
        if QuestUtil.IsOnQuestID(self.questID) then
            self.Interact.Button:SetText(TRACK_QUEST)
        else
            self.Interact.Button:SetText(START_QUEST)
        end
        self.Interact.Button:Enable()
        self.Interact:Show()
        return true
    else
        self.Interact:Hide()
        return false
    end
end

function PathObjectiveQuestObjectivesMixin:OnInteractClick()
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON_50)
    if C_Tutorial.IsRewardCollected(self.tutorialID) then
        return
    end

    if C_Tutorial.IsTutorialComplete(self.tutorialID) then
        if C_Tutorial.CanCollectReward(self.tutorialID) then
            C_Tutorial.CollectReward(self.tutorialID)
            self.Interact.Button:Disable()
        end
        return
    end

    if self.questID then
        if QuestUtil.IsOnQuestID(self.questID) then
            local questIndex = GetQuestLogIndexByID(self.questID)
            if questIndex then
                QuestLog_SetSelection(questIndex)
                QuestPOI_SelectButtonByQuestId("WatchFrameLines", self.questID, true)
                if not IsQuestWatched(questIndex) then
                    if GetNumQuestWatches() >= MAX_WATCHABLE_QUESTS then
                        UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY, MAX_WATCHABLE_QUESTS), 1.0, 0.1, 0.1, 1.0)
                        return
                    end
                    AddQuestWatch(questIndex)
                    WatchFrame_Update()
                end
            end
            return
        end

        C_Tutorial.StartQuest(self.questID)
        self.Interact.Button:Disable()
    end
end

function PathObjectiveQuestObjectivesMixin:OnEvent(event, ...)
    if event == "QUEST_LOG_UPDATE" then
        self:UpdateInteractButton()
    else
        if self.tutorialID then
            local _, _, _, questID = C_Tutorial.GetTutorialByID(self.tutorialID)
            self:SetTutorial(self.tutorialID, questID)
        end
    end
end