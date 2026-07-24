C_PopupQueue = {
    Queue = {},
    Achievements = {},
}
C_PopupQueue.Frame = CreateFrame("Frame")
C_PopupQueue.Frame:Hide()

C_PopupQueue.Frame:SetScript("OnUpdate", function(self)
    local item = C_PopupQueue.Queue[1]

    local isShowingAchievement = false
    for i=MAX_ACHIEVEMENT_ALERTS, 1, -1 do
		local frame = _G["AchievementAlertFrame"..i]
		if frame and frame:IsShown() then
			isShowingAchievement = true
            break
		end
	end

    if isShowingAchievement or not item then
        -- queues empty, do we have achievements?
        if #C_PopupQueue.Achievements > 0 then
            -- display all achievements
            for _, id in ipairs(C_PopupQueue.Achievements) do
                AchievementAlertFrame_ShowAlert(id)
            end

            C_PopupQueue.Achievements = {}
        end

        if not isShowingAchievement then
            self:Hide()
        end

        return
    end

    if not item.didShow and not item.frame:IsVisible() then
        if item.show then
            item.show()
        else
            item.frame:Show()
        end
        item.didShow = true
    end

    if item.isDone and item.isDone() or not item.frame:IsVisible() then
        tremove(C_PopupQueue.Queue, 1)
    end
end)

function C_PopupQueue:Add(frame, show, isDone, pos)
    tinsert(self.Queue, pos or (#self.Queue+1), { frame = frame, show = show, isDone = isDone })

    self.Frame:Show()
end

function C_PopupQueue:AddAchievement(id)
    tinsert(self.Achievements, id)
    self.Frame:Show()
end