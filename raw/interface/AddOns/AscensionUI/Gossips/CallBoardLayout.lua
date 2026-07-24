local Addon = select(2, ...)
local CallBoardUI = Addon.CallBoardUI

function CallBoardUI:IsQuestHybridScrollVisible()
	return self.content.ExtraSlots:IsVisible() or self.content.ExtraSlotsCategorized:IsVisible()
end

function CallBoardUI:SelectMenu(tab)
	local menus = tab.menu
	local frames = {}

	for _, frame in pairs(self.menus) do
		frame:Hide()
	end

	if (type(menus) == "table") then
		for _, frameName in pairs(menus) do
			table.insert(frames, self.menus[frameName])
		end
	elseif (type(menus) == "string") then
		table.insert(frames, self.menus[menus])
	end

	if not(next(frames)) then
		return
	end

	for _, frame in pairs(frames) do
		frame:Show()
	end
end

function CallBoardUI:SelectTab(frame, button)
	if (self.disabled) then
		return
	end

	self.CurrentTabButton = button
	StaticPopup_Hide("ASC_TEMPORAL_CONTRACT_CONFIRM")
	self.content.errorText:Hide()

	for i = 1, #frame.tabs do
		local tab = frame.tabs[i]
		local nextTab = frame.tabs[i+1]

		if (button ~= tab) then
			tab.checked:Hide()
			if (tab.subTabs) then
				tab:HideSubTabs(nextTab)
			end
		else
			tab.checked:Show()
			if (tab.menu) then
				self:SelectMenu(tab)
			end
			if (tab.subTabs) then
				if (tab.subTabs[1]:IsVisible()) then
					tab:HideSubTabs(nextTab)
				else
					tab:ShowSubTabs(nextTab)
				end
			end
		end
	end
end

function CallBoardUI:BuildCategoryMap()
	self.categorizedQuestList = {}

	for _, questData in pairs(self.questList) do
		local questSortIds = C_TemporalContracts.GetQuestSortIDs(questData.ID, false)
		for _, questSortId in pairs(questSortIds) do
			self.categorizedQuestList[questSortId] = self.categorizedQuestList[questSortId] or {name = C_TemporalContracts.GetQuestSortText(questSortId), quests = {}}
			table.insert(self.categorizedQuestList[questSortId].quests, questData)
		end
	end
end

function CallBoardUI:LoadQuestScrolls()
	if (self.content.ExtraSlotsCategorized:IsVisible()) then
		self:BuildCategoryMap()
		self.content.ExtraSlotsCategorized:LoadQuests(self.categorizedQuestList)
	end
end

function CallBoardUI:RefreshSubMenus()
	if (self.content.AreaHybridScroll.Content:IsVisible()) then
		self.content.AreaHybridScroll:LoadInstancesData()
		self.content.AreaHybridScroll:RefreshLayout()
	end

	if (self.content.raidResets.Content:IsVisible()) then
		self.content.raidResets:LoadTimeWalkingData()
		self.content.raidResets:RefreshLayout()
	end
end

function CallBoardUI:ClearSubMenus()
	self.timeWalkingData = {}
	self.instancesData = {}
end

function CallBoardUI:LoadExtraSlotsCategory(category)
	self.content.ExtraSlotsCategorized.category = category
	self.content.TotalRewards:LoadCategory(category)
end
