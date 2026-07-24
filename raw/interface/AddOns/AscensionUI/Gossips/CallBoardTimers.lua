local Addon = select(2, ...)
local CallBoardUI = Addon.CallBoardUI

function CallBoardUI:TryRunTimer(timer, timersTime)
	if not(timer:Run(timersTime-time())) then
		Timer.After(0.5, function()
			self:RequestTimers()
		end)
		return false
	else
		self.requestTimerTimes = nil
		return true
	end
end

function CallBoardUI:RequestTimers()
	if not(self.requestTimerTimes) then
		self.requestTimerTimes = 1
	end

	if (self.requestTimerTimes > 20) then
		return
	end

	if not(CallBoardUI:TryRunTimer(self.Tabs.WeeklyUpdate.timer, GetWorldState(20002))) then
		return
	end

	if not(CallBoardUI:TryRunTimer(self.Tabs.DailyUpdate.timer, GetWorldState(20010))) then
		return
	end

	if not(CallBoardUI:TryRunTimer(self.Tabs.tabPVPArenaReset.timer, GetWorldState(20001))) then
		return
	end
end

function CallBoardUI:RequestLFRData()
	if not(CallBoardUI.LFRUnlocalized) then
		CallBoardUI.LFRUnlocalized = {}
		for _, data in pairs(GetLFDChoiceInfo({})) do
			local localizedName = data[1]
			local unlocalziedName = data[10]
			if (unlocalziedName) then
				CallBoardUI.LFRUnlocalized[localizedName] = unlocalziedName
			end
		end
	end
end

CallBoardUI.content.statisticsContent = CreateFrame("FRAME", "$parent.statisticsContent", CallBoardUI.content, nil)
CallBoardUI.content.statisticsContent:SetSize(789, 612)

function CallBoardUI.content.statisticsContent:CreateCategoryTemplate(name)
	local frame = CallBoardUI:CreateCategoryTemplate(name, self)

	if not(self.tabs) then
		self.tabs = {}
	end

	table.insert(self.tabs, frame)

	return frame
end

-- Quite similar to CallBoardUI:SelectTab(frame, button) but subTabs are readOnly table
function CallBoardUI.content.statisticsContent:SelectTab(button)
	for i = 1, #self.tabs do
		local tab = self.tabs[i]
		local nextTab = self.tabs[i+1]

		if (button ~= tab) then
			if (tab.subTabs) then
				tab:HideSubTabs(nextTab)
			end
		else
			if (tab.subTabs) then
				if (tab.subTabsAreVisible) then
					tab:HideSubTabs(nextTab)
				else
					tab:ShowSubTabs(nextTab)
				end
			end
		end
	end
end

function CallBoardUI.content.statisticsContent:CreateSubCategories()
	for category, subCategoryData in pairs(CallBoardUI.TemporalContractsMap) do
		for subCategoryName, _ in pairs(subCategoryData) do
			local categoryTab = CallBoardUI.content.statisticsContent[category]

			if (categoryTab and (subCategoryName ~= "TOTAL")) then
				local subTab = categoryTab:CreateSubCategory(subCategoryName)
				local name = CallBoardUI:GetSubCategoryName(subCategoryName)

				if (categoryTab.lastSubTab) then
					subTab:SetPoint("TOP", categoryTab.lastSubTab, "BOTTOM", 0, -1)
				else
					subTab:SetPoint("TOP", categoryTab, "BOTTOM", 0, -1)
				end

				subTab:SetName(name)

				subTab:LoadCategory(subCategoryName)

				categoryTab.subTabsTotal = categoryTab.subTabsTotal + 1
				categoryTab.lastSubTab = subTab
			end
		end
	end
end

function CallBoardUI.content.statisticsContent:LoadSubCategories()
	dprint("CallBoardUI.content.statisticsContent:LoadSubCategories")

	local hasLoadedCategories = false

	for _, category in pairs(CallBoardUI.categories) do
		local categoryData, subCategoryData = CallBoardUI:GetCategoryData(category)
		local categoryTab = CallBoardUI.content.statisticsContent[category]

		if (categoryTab) then
			dprint("Loading tab "..category)
			if categoryTab:LoadData(categoryData) then
				hasLoadedCategories = true
			end

			for subCategory, data in pairs(subCategoryData) do
				local subCategoryTab = categoryTab.subTabs[subCategory]
				if (subCategoryTab) then
					subCategoryTab:LoadData(data)
				end
			end
		end
	end

	if not(hasLoadedCategories) then
		CallBoardUI.content.statisticsScroll:Hide()
		CallBoardUI.content.errorText:Show()
	else
		CallBoardUI.content.statisticsScroll:Show()
		CallBoardUI.content.errorText:Hide()
	end
end

CallBoardUI.content.statisticsContent[CallBoardUI.categories.pve] = CallBoardUI.content.statisticsContent:CreateCategoryTemplate(CallBoardUI.categories.pve)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.pve]:SetPoint("TOP", 0, -1)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.pve]:LoadCategory(CallBoardUI.categories.pve)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.pve]:SetName(CallBoardUI.MSGS.PVE_STATISTICS_TITLE)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.pve].tooltipText = CallBoardUI.MSGS.PVE_STATISTICS_TOOLTIP

CallBoardUI.content.statisticsContent[CallBoardUI.categories.pvp] = CallBoardUI.content.statisticsContent:CreateCategoryTemplate(CallBoardUI.categories.pvp)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.pvp]:SetPoint("TOP", CallBoardUI.content.statisticsContent[CallBoardUI.categories.pve], "BOTTOM", 0, -1)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.pvp]:LoadCategory(CallBoardUI.categories.pvp)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.pvp]:SetName(CallBoardUI.MSGS.PVP_STATISTICS_TITLE)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.pvp].tooltipText = CallBoardUI.MSGS.PVP_STATISTICS_TOOLTIP

CallBoardUI.content.statisticsContent[CallBoardUI.categories.prof] = CallBoardUI.content.statisticsContent:CreateCategoryTemplate(CallBoardUI.categories.prof)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.prof]:SetPoint("TOP", CallBoardUI.content.statisticsContent[CallBoardUI.categories.pvp], "BOTTOM", 0, -1)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.prof]:LoadCategory(CallBoardUI.categories.prof)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.prof]:SetName(CallBoardUI.MSGS.PROF_STATISTICS_TITLE)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.prof].tooltipText = CallBoardUI.MSGS.PROF_STATISTICS_TOOLTIP

CallBoardUI.content.statisticsContent[CallBoardUI.categories.highRisk] = CallBoardUI.content.statisticsContent:CreateCategoryTemplate(CallBoardUI.categories.highRisk)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.highRisk]:SetPoint("TOP", CallBoardUI.content.statisticsContent[CallBoardUI.categories.prof], "BOTTOM", 0, -1)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.highRisk]:LoadCategory(CallBoardUI.categories.highRisk)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.highRisk]:SetName(CallBoardUI.MSGS.HIGHRISK_STATISTICS_TITLE)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.highRisk].tooltipText = CallBoardUI.MSGS.HIGHRISK_STATISTICS_TOOLTIP

CallBoardUI.content.statisticsContent[CallBoardUI.categories.misc] = CallBoardUI.content.statisticsContent:CreateCategoryTemplate(CallBoardUI.categories.misc)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.misc]:SetPoint("TOP", CallBoardUI.content.statisticsContent[CallBoardUI.categories.highRisk], "BOTTOM", 0, -1)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.misc]:LoadCategory(CallBoardUI.categories.misc)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.misc]:SetName(CallBoardUI.MSGS.MISC_STATISTICS_TITLE)
CallBoardUI.content.statisticsContent[CallBoardUI.categories.misc].tooltipText = CallBoardUI.MSGS.MISC_STATISTICS_TOOLTIP

CallBoardUI.content.statisticsScroll = CreateFrame("ScrollFrame", "$parent.statisticsScroll", CallBoardUI.content, "UIPanelScrollFrameTemplate")
CallBoardUI.content.statisticsScroll:SetSize(789, 612)
CallBoardUI.content.statisticsScroll:SetPoint("TOPLEFT", 0, -6)
CallBoardUI.content.statisticsScroll:EnableMouseWheel(true) -- TODO: Polish mousewheel
CallBoardUI.content.statisticsScroll:SetScrollChild(CallBoardUI.content.statisticsContent)

CallBoardUI.content:CreateScrollArtwork(_G[CallBoardUI.content.statisticsScroll:GetName().."ScrollBar"])

_G["CallBoardUI.content.statisticsScrollScrollBar"]:SetPoint("TOPLEFT", CallBoardUI.content.statisticsScroll, "TOPRIGHT", 2, -15)
_G["CallBoardUI.content.statisticsScrollScrollBar"]:SetPoint("BOTTOMLEFT", CallBoardUI.content.statisticsScroll, "BOTTOMRIGHT", 2, 14)
_G[CallBoardUI.content.statisticsScroll:GetName().."ScrollBar"].scrollTop:SetPoint("TOPRIGHT", 3, 19)
_G[CallBoardUI.content.statisticsScroll:GetName().."ScrollBar"].scrollBot:SetPoint("BOTTOMRIGHT", 3, -17)

ScrollFrame_OnLoad(CallBoardUI.content.statisticsScroll)

CallBoardUI.content.statisticsScroll:Hide()

CallBoardUI.menus["STATISTICS"] = CallBoardUI.content.statisticsScroll
-------------------------------------------------------------------------------
--                                    Init                                   --
-------------------------------------------------------------------------------
CallBoardUI:RegisterGossip(CallBoardUI.callBoards)

if not C_Realm.IsDevelopment() then
	UIPanelWindows[CallBoardUI:GetName()] = nil
	tinsert(UISpecialFrames, CallBoardUI:GetName())
end

