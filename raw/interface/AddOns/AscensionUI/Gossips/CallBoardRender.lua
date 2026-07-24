local Addon = select(2, ...)
local CallBoardUI = Addon.CallBoardUI


function GetQuestRewards(questID)
	local templateInfo = GetQuestTemplate(questID) or {}
	if not(next(templateInfo)) then
		return
	end

	return {
		RewardMoney = templateInfo.RewardMoney,
		RewardArenaPoints = templateInfo.RewardArenaPoints,
		RewardHonor = templateInfo.RewardHonor,
		RewardItems = templateInfo.RewardItems,
		RewardAmount = templateInfo.RewardAmount,
	}
end

function TooltipAddQuestRewards(owner, questID, preloadedRewards)
	local rewards = preloadedRewards or GetQuestRewards(questID) or {}
	local text = {}

	if not(rewards) or not(next(rewards)) then
		return
	end

	table.insert(text, {"l", " "})
	table.insert(text, {"l", LFD_REWARDS, 1, 0.82, 0, 1})

	if (rewards.RewardMoney and (rewards.RewardMoney > 0)) then
		table.insert(text, {"m", rewards.RewardMoney})
	end

	if (rewards.RewardHonor and (rewards.RewardHonor > 0)) then
		local honor = CallBoardUI.CorrectHonorReward(rewards.RewardHonor)
		local honorIcon = (UnitFactionGroup("player") == "Horde" and "|TInterface\\PvPFrame\\PVP-Currency-Horde.blp:16:16:0:0|t") or "|TInterface\\PvPFrame\\PVP-Currency-Alliance.blp:16:16:0:0|t"
		table.insert(text, {"dl", " - "..BONUS_HONOR, honor.."  "..honorIcon, 1, 1, 1, 1, 1, 1})
	end

	if (rewards.RewardArenaPoints and (rewards.RewardArenaPoints > 0)) then
		table.insert(text, {"dl", " - "..BONUS_ARENA_POINTS, rewards.RewardArenaPoints.."  |TInterface\\PvPFrame\\PVP-ArenaPoints-Icon.blp:16:16:0:0|t", 1, 1, 1, 1, 1, 1})
	end

	if (#text > 2) then
		table.insert(text, {"l", " "})
	end

	for i = 1, #rewards.RewardAmount do
		local total = rewards.RewardAmount[i]
		if (total > 0) then
			local itemID = rewards.RewardItems[i]
			local item = Item:CreateFromID(itemID)

			if owner.cancelToken then
				owner.cancelToken()
				owner.cancelToken = nil
			end

			owner.cancelToken = item:CancelableContinueOnLoad(function()
				if not item:IsCached() then
					return
				end

				local icon = GetItemIcon(itemID) 
				icon = (icon and "|T"..icon..".blp:16:16:0:0|t") or ""
				table.insert(text, {"dl", " - "..item:GetInfo(), total.."  "..icon, 1, 1, 1, 1, 1, 1})
			end)
		end
	end

	if (#text > 2) then
		for i = 1, #text do
			local lineType = text[i][1]
			if (lineType == "l") then
				GameTooltip:AddLine(select(2, unpack(text[i])))
			elseif (lineType == "dl") then
				GameTooltip:AddDoubleLine(select(2, unpack(text[i])))
			elseif (lineType == "m") then
				SetTooltipMoney(GameTooltip, select(2, unpack(text[i])))
			end
		end
	end

	GameTooltip:Show()
end

CallBoardUI._UpdateQuestButtons = CallBoardUI.UpdateQuestButtons

function CallBoardUI:UpdateQuestButtons()
	if self._UpdateQuestButtons then
		self:_UpdateQuestButtons()
	end
	self:LoadQuestScrolls()
	self:LoadRewards()
end

function CallBoardUI:UpdateCacheProgress()
	local ProgressBar = self.Tabs.CacheProgress
	local TierRewardProgressBar = self.Tabs.TierReward.ProgressBar
	
	local achievedItemLevel, currentRewardLevel, nextRewardLevel = C_CallboardCache.GetItemLevelInfo()
	local rewardCacheItemID = C_CallboardCache.GetCallboardCacheInfo()
	self:SetTierRewardItem(rewardCacheItemID)
	if not currentRewardLevel or not nextRewardLevel then
		self.Tabs.TierReward:SetBorderAtlas("services-ring")
		TierRewardProgressBar:Hide()
		TierRewardProgressBar.Background:Hide()
	else
		self.Tabs.TierReward:SetBorderTexture(nil)
		TierRewardProgressBar:Show()
		TierRewardProgressBar.Background:Show()
		local itemLevel = UnitAverageItemLevel("player")

		local tierProgress = math.RemapToRange(itemLevel, currentRewardLevel, nextRewardLevel, 0, 1)
		TierRewardProgressBar:SetProgress(0, 360, tierProgress, true)
	end
	
	local currentProgress, maxProgress = C_CallboardCache.GetCurrentPoints()
	if not maxProgress then
		ProgressBar:Hide()
		CallBoardUI.Tabs.TierReward:ClearAndSetPoint("CENTER", CallBoardUI.Tabs.CacheProgress, "CENTER", 0, 0)
		return
	end
	local itemName = GetItemName(rewardCacheItemID)
	ProgressBar.RewardText:SetText(itemName)
	CallBoardUI.Tabs.TierReward:ClearAndSetPoint("RIGHT", CallBoardUI.Tabs.CacheProgress, "LEFT", -12, 4)
	
	local percent = (currentProgress / maxProgress) * 100

	ProgressBar:SetMinMaxValues(0, maxProgress)
	ProgressBar:SetValue(currentProgress)
	ProgressBar:SetText(CACHE_PROGRESS_D:format(currentProgress, maxProgress, percent))
end

function CallBoardUI:SetTierRewardItem(itemID)
	local TierReward = self.Tabs.TierReward
	if TierReward.cancelItemLoad then
		TierReward.cancelItemLoad()
		TierReward.cancelItemLoad = nil
	end

	TierReward:SetItem(itemID)

	local item = TierReward.item
	if not item or item:IsEmpty() then
		return
	end

	TierReward.cancelItemLoad = item:CancelableContinueOnLoad(function(loadedItemID)
		if TierReward.item ~= item or item:GetItemID() ~= loadedItemID then
			return
		end

		TierReward.cancelItemLoad = nil
		TierReward:SetIcon(item:GetIcon())

		if self.Tabs.CacheProgress.RewardText then
			self.Tabs.CacheProgress.RewardText:SetText(item:GetName())
		end

		if TierReward:IsMouseOver() then
			TierReward:OnEnter()
		end
	end)
end

function CallBoardUI:GetPortrait()
	if (C_Gossip.currentNPC and self.outLawCallBoards[C_Gossip.currentNPC]) then
		return "achievement_boss_edwinvancleef"
	end

	local factionName = UnitFactionGroup("player")
	if not(factionName == "Alliance") then
		return "inv_hordewareffort"
	else
		return "inv_alliancewareffort"
	end
end

function CallBoardUI:GetCurrentQuestsRewardList()
	local category = self.content.ExtraSlotsCategorized.category
	local categoryData = self.TemporalContractsMap and self.TemporalContractsMap[category] and self.TemporalContractsMap[category]["TOTAL"]
	local rewardList = {categoryData and categoryData.rewards or {RewardItems = {}, RewardAmount = {}, RewardMoney = 0, RewardHonor = 0, RewardArenaPoints = 0, CallboardCachePoints = 0}}

	if not(self.questList) or not(next(self.questList)) then
		return rewardList
	end

	for i = 1, #self.questList do
		local questID = self.questList[i].ID
		if questID then
			local subCatagory = CallBoardUI:GetQuestCategory(questID)
			if not(subCatagory) and (self.questRewards[questID]) then
				table.insert(rewardList, self.questRewards[questID])
			end
		end
	end

	return rewardList
end

function CallBoardUI:ReloadCategoryRewards(questID)
	if (self.content.ExtraSlotsCategorized:IsVisible()) then
		self.content.ExtraSlotsCategorized:RefreshButtonRewards()
	elseif (self.content.statisticsContent:IsVisible()) then
		self.content.statisticsContent:LoadSubCategories()
	end
end

function CallBoardUI:NormalizeRewards(rewards)
	if not(rewards) then
		return {RewardItems = {}, RewardAmount = {}, RewardMoney = 0, RewardHonor = 0, RewardArenaPoints = 0, CallboardCachePoints = 0}
	end

	if (rewards.RewardItems and rewards.RewardAmount) then
		return rewards
	end

	local normalized = {
		RewardItems = {},
		RewardAmount = {},
		RewardMoney = rewards.RewardMoney or 0,
		RewardHonor = rewards.RewardHonor or 0,
		RewardArenaPoints = rewards.RewardArenaPoints or 0,
		CallboardCachePoints = rewards.CallboardCachePoints or 0,
		CacheProgress = rewards.CacheProgress or rewards.CallboardCachePoints or 0
	}

	if (rewards.Items) then
		for _, item in pairs(rewards.Items) do
			table.insert(normalized.RewardItems, item.ItemID)
			table.insert(normalized.RewardAmount, item.Amount)
		end
	end

	return normalized
end

function CallBoardUI:GetSubCategoryName(subCategoryType)
	local category = self.TemporalContractCategoryReference and self.TemporalContractCategoryReference[subCategoryType]
	if (category and self.TemporalContractsMap and self.TemporalContractsMap[category]) then
		local data = self.TemporalContractsMap[category][subCategoryType]
		if (data and data.name) then
			return data.name
		end
	end
	return subCategoryType
end

function CallBoardUI:CombineRewards(rewards, multiply)
	local combinedRewards = {
		RewardItems = {},
		RewardAmount = {},
		RewardMoney = 0,
		RewardHonor = 0,
		RewardArenaPoints = 0,
		CacheProgress = 0,
	}

	for index, quest in pairs(rewards) do
		if (quest.RewardAmount) then
			for i = 1, #quest.RewardAmount do
				local rewardAmount = quest.RewardAmount[i]
				if (multiply) then
					rewardAmount = rewardAmount*multiply
				end

				if (rewardAmount > 0) then
					local itemID = quest.RewardItems[i]
					local isExisting = false

					for combinedItemIndex, combinedItemID in pairs(combinedRewards.RewardItems) do
						if (combinedItemID == itemID) then
							local combinedAmount = combinedRewards.RewardAmount[combinedItemIndex]
							combinedRewards.RewardAmount[combinedItemIndex] = combinedAmount + rewardAmount
							isExisting = true
						end
					end

					if not(isExisting) then
						table.insert(combinedRewards.RewardAmount, rewardAmount)
						table.insert(combinedRewards.RewardItems, itemID)
					end
				end
			end
		end

		if (quest.RewardMoney and (quest.RewardMoney ~= 0)) then
			combinedRewards.RewardMoney = combinedRewards.RewardMoney + quest.RewardMoney
		end
		if (quest.RewardHonor and (quest.RewardHonor ~= 0)) then
			combinedRewards.RewardHonor = combinedRewards.RewardHonor + quest.RewardHonor
		end
		if (quest.RewardArenaPoints and (quest.RewardArenaPoints ~= 0)) then
			combinedRewards.RewardArenaPoints = combinedRewards.RewardArenaPoints + quest.RewardArenaPoints
		end
		if (quest.CacheProgress and (quest.CacheProgress ~= 0)) then
			combinedRewards.CacheProgress = combinedRewards.CacheProgress + quest.CacheProgress
		end
	end

	table.insert(combinedRewards.RewardAmount, 0)
	return combinedRewards
end

function CallBoardUI:ApplyCategoryRewardsToTooltip(frame, category)
	local categoryData = self.TemporalContractsMap and self.TemporalContractsMap[category] and self.TemporalContractsMap[category]["TOTAL"]
	local rewards = categoryData and categoryData.rewards or {RewardItems = {}, RewardAmount = {}, RewardMoney = 0, RewardHonor = 0, RewardArenaPoints = 0, CallboardCachePoints = 0}
	rewards = self:NormalizeRewards(rewards)
	TooltipAddQuestRewards(frame, nil, rewards)
end

function CallBoardUI.OnGossipShow()
	CallBoardUI:ClearSubMenus()
	CallBoardUI:LoadContractsInfo()
	CallBoardUI:MoveQuestQueue()

	C_Gossip:SilentHideGossip()
	ShowUIPanel(CallBoardUI)
	CallBoardUI:ScanGossip() 

	CallBoardUI:RequestTimers()
	CallBoardUI:RequestLFRData()
	CallBoardUI:RefreshSubMenus()
	
	CallBoardUI:UpdateCacheProgress()
	CallBoardUI.Tabs.BazaarTokens:SetItem(CallBoardUI.BAZAAR_TOKEN)
	SetPortraitToTexture(CallBoardUI.portrait, "Interface\\Icons\\"..CallBoardUI:GetPortrait())

	if not CallBoardUI.initCrutch then 
		CallBoardUI.initCrutch = true
		CallBoardUI.Tabs.tabPVE:Click()
	end
end

function CallBoardUI.OnGossipHide()
	C_Gossip:RestoreGossip()
	HideUIPanel(CallBoardUI)
	StaticPopup_Hide("ASC_TEMPORAL_CONTRACT_CONFIRM")
	CallBoardUI:ClearMassCompleteState()

	if not CallBoardUI.CurrentTabButton then
		CallBoardUI.CurrentTabButton = CallBoardUI.Tabs.tabPVE
	end
	CallBoardUI.CurrentTabButton:GetScript("OnClick")(CallBoardUI.CurrentTabButton)
end
