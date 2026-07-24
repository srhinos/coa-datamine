SuperTrackerUtil = {}

SUPER_TRACKED_POSITION = nil

hooksecurefunc(_G, "SelectQuestLogEntry", function()
    SuperTrackerUtil.SetToBestSuperTrackingType()
end)

hooksecurefunc(C_SuperTrack, "ClearSuperTracker", function()
    SUPER_TRACKED_POSITION = nil
end)

function SuperTrackerUtil.CanSuperTrack()
    return C_CVar.GetBool("showInGameNavigation")
end

function SuperTrackerUtil.SetToBestSuperTrackingType()
    if not SuperTrackerUtil.CanSuperTrack() then
        C_SuperTrack.ClearSuperTracker()
        return
    end
    local bestTrackingType = SuperTrackerUtil.GetHighestPrioritySuperTrackingType()
    if bestTrackingType == Enum.SuperTrackingType.Corpse then
        Timer.After(1, function()
            -- corpse does not track immediately
            C_SuperTrack.SetSuperTrackedCorpse(true)
        end)

    elseif bestTrackingType == Enum.SuperTrackingType.Position then
        local x, y, z, mapID = SUPER_TRACKED_POSITION.x, SUPER_TRACKED_POSITION.y, SUPER_TRACKED_POSITION.z, SUPER_TRACKED_POSITION.mapID
        C_SuperTrack.SetSuperTrackedPosition(x, y, z, mapID)

    elseif bestTrackingType == Enum.SuperTrackingType.Quest then
        local questID = select(9, GetQuestLogTitle(GetQuestLogSelection()))
        if questID then
            QuestMapUpdateAllQuests()
            QuestPOIUpdateIcons()
            C_SuperTrack.SetSuperTrackedQuestID(questID)
			QuestPOI_SelectButtonByQuestId("WatchFrameLines", questID, true);
			QuestPOI_SelectButtonByQuestId("WorldMapPOIFrame", questID, true);
        else
            C_SuperTrack.ClearSuperTracker()
        end
    else
        C_SuperTrack.ClearSuperTracker()
    end
end

function SuperTrackerUtil.GetHighestPrioritySuperTrackingType()
    if UnitIsGhost("player") then
        return Enum.SuperTrackingType.Corpse
    elseif SUPER_TRACKED_POSITION then
        return Enum.SuperTrackingType.Position
    elseif GetQuestLogSelection() ~= 0 then
        return Enum.SuperTrackingType.Quest
    end
end

function SuperTrackerUtil.HasValidScreenPosition()
    local x, y = C_SuperTrack.GetSuperTrackedPosition()
    if x and x > 0 and y and y > 0 then
        return true
    end
    
    return false
end

function SuperTrackerUtil.PositionSuperTracker(frame, x, y)
    if x and x > 0 and y and y > 0 then
        C_SuperTrack.PositionFrame(true)
        frame:SetPoint("CENTER", WorldFrame, "BOTTOMLEFT", x, y)
        C_SuperTrack.PositionFrame(false)
    elseif frame:GetPoint() then
        frame:ClearAllPoints()
    end
end

function SuperTrackerUtil.SetSuperTrackedPosition(x, y, z, mapID)
    SUPER_TRACKED_POSITION = {x = x, y = y, z = z, mapID = mapID}
    SuperTrackerUtil.SetToBestSuperTrackingType()
end

function SuperTrackerUtil.ClearSuperTrackedPosition()
    SUPER_TRACKED_POSITION = nil
    SuperTrackerUtil.SetToBestSuperTrackingType()
end

function SuperTrackerUtil.UpdateSelectedQuest()
    if GetQuestLogSelection() == 0 then
        -- select the first quest if there isnt one selected
        QuestMapUpdateAllQuests()
        local questId, questLogIndex = QuestPOIGetQuestIDByVisibleIndex(1)
        if questLogIndex then
            SelectQuestLogEntry(questLogIndex)
        end
    else
        SelectQuestLogEntry(GetQuestLogSelection())
    end
end

EventRegistry:RegisterFrameEventAndCallback("PLAYER_UNGHOST", SuperTrackerUtil.SetToBestSuperTrackingType)
EventRegistry:RegisterFrameEventAndCallback("PLAYER_ALIVE", SuperTrackerUtil.SetToBestSuperTrackingType)
EventRegistry:RegisterFrameEventAndCallback("PLAYER_FLAGS_CHANGED", SuperTrackerUtil.SetToBestSuperTrackingType)
EventRegistry:RegisterFrameEventAndCallback("QUEST_POI_UPDATE", SuperTrackerUtil.SetToBestSuperTrackingType)

-- this needs to be called several times since quest log / pois wont be cached instantly and there is no event fired when they're 'ready'
EventRegistry:RegisterFrameEventAndCallback("PLAYER_ENTERING_WORLD", function() Timer.NewTicker(2, SuperTrackerUtil.UpdateSelectedQuest, 3) end)
