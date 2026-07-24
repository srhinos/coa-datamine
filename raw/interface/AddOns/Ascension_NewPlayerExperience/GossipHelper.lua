local _, NPE = ... 

-- functions to properly define gossip button
local function ReturnGossipButtonByQuestID(questID)
    local gossipDataAvailable = {GetGossipAvailableQuests()}
    local buttonIndex = 1

    local questName = C_Quest:GetQuestNameByID(questID)
    
    if not(questName) then
        return
    end

    if next(gossipDataAvailable) then
        for i=1, #gossipDataAvailable, 2 do
            local questText = gossipDataAvailable[i]
            
            if (questText == questName) then
                return _G["GossipTitleButton"..buttonIndex]
            end

            buttonIndex =  buttonIndex + 1
        end
    end

    if next(gossipDataAvailable) then
        buttonIndex =  buttonIndex + 1 -- skip 1 entry for active quests
    end

    local gossipDataActive = {GetGossipActiveQuests()}

    if next(gossipDataActive) then
        for i=1, #gossipDataActive, 2 do
            local questText = gossipDataActive[i]
            local isComplete = gossipDataActive[i+3]

            if (questText == questName) and isComplete then
                return _G["GossipTitleButton"..buttonIndex]
            end

            buttonIndex =  buttonIndex + 1
        end
    end
end

local function ReturnQuestButtonByQuestID(questID)
    local buttonIndex = 1
    local questName = C_Quest:GetQuestNameByID(questID)
    -- first scan active quests
    local totalActive = GetNumActiveQuests()

    if totalActive then
        for i= 1, totalActive do
            local questText = GetActiveTitle(i)
            
            if (questText == questName) then
                return _G["QuestTitleButton"..buttonIndex]
            end

            buttonIndex =  buttonIndex + 1
        end
    end

    -- then scan available quests
    local totalAvailable = GetNumAvailableQuests()
    
    if not(questName) then
        return
    end

    if totalAvailable then
        for i= 1, totalAvailable do
            local questText = GetAvailableTitle(i)
            
            if (questText == questName) then
                return _G["QuestTitleButton"..buttonIndex]
            end

            buttonIndex =  buttonIndex + 1
        end
    end
end

function DecideParentForGossipHelper(quest, event)
    HelpTip:Hide("GOSSIP_SELECT_HELPER")

    local btn = ReturnGossipButtonByQuestID(quest)

    if (event == "QUEST_GREETING") then
        btn = ReturnQuestButtonByQuestID(quest)
    end

    if (btn) then
        HelpTips["GOSSIP_SELECT_HELPER"].parent = btn:GetName()
        HelpTip:Show("GOSSIP_SELECT_HELPER")
        return true
    end

    return false
end

function DecideParentForQuestAccept(questID)
    local portraitQuestID = NPE:ScanStartingQuestPortrait()

    if portraitQuestID == questID then
        return true
    end
end