local Addon = select(2, ...)
local CallBoardUI = Addon.SharedGossip:CreateGossipFrame("CallBoardUI")
Addon.CallBoardUI = CallBoardUI
CallBoardUI:Hide()

CallBoardUI.outLawCallBoards = {
	[1804480] = true, -- outlaw
	[422000] = true, -- outlaw portable
}

CallBoardUI.callBoards = {
	402000, -- alliance
	402001, -- Horde
	412001, -- horde portble
	412000, -- alliance portable
}	

for v, _ in pairs(CallBoardUI.outLawCallBoards) do
	table.insert(CallBoardUI.callBoards, v)
end

CallBoardUI.MSGS = {
	COMPLETE_WITH_TEXT 					= CALLBOARD_UI_COMPLETE_WITH_TEXT or "Quest Completion Options",
	COMPLETE_WITH_TOOLTIP 				= CALLBOARD_UI_COMPLETE_WITH_TOOLTIP or "Use Gold or Tokens to complete specific Quests or whole categories of Quests.",
	COMPLETE_WITH_TOOLTIP_FULL 			= CALLBOARD_UI_COMPLETE_WITH_TOOLTIP_FULL or "Use Gold or Tokens to complete specific Quests or whole categories of Quests. The value indicates how many times you can complete Quests of such category in a single day. This value increases over time during the week, if you miss any Quests for the current week.",
	TELEPORT_TO 						= CALLBOARD_UI_TELEPORT_TO or "Teleport to %s",
	COMPLETE_WITH						= CALLBOARD_UI_COMPLETE_WITH or "Complete Now",
	COMPLETE_WITH_EXTRA				 	= CALLBOARD_UI_COMPLETE_WITH_EXTRA or "Complete Now |cffFFFFFF(%i)|r",
	COMPLETING							= CALLBOARD_UI_COMPLETING or "Completing...",
	COMPLETING_SUBTEXT					= CALLBOARD_UI_COMPLETING_SUBTEXT or "Please wait...",
	TOOLTIP_ERROR_TOKEN					= CALLBOARD_UI_TOOLTIP_ERROR_TOKEN or "You do not have enough Bazaar Tokens to complete this Daily Quest. Bazaar Tokens can be acquired from the Auction House or the Web Shop.\n",
	TOOLTIP_ERROR_GOLD				 	= CALLBOARD_UI_TOOLTIP_ERROR_GOLD or "You do not have enough Gold to complete this Daily Quest.\n",
	TOTAL_REWARDS_AVAILABLE 			= CALLBOARD_UI_TOTAL_REWARDS_AVAILABLE or "Total Rewards Available this Week:",
	POA									= CALLBOARD_UI_POA or "Path of Ascension",
	POA_TOOLTIP							= CALLBOARD_UI_POA_TOOLTIP or "Path to Ascension quests are special tasks that teach you the ins and outs of Ascension. Completing these quests grant epic rewards.",
	STATISTICS 							= CALLBOARD_UI_STATISTICS or "Weekly Rewards",
	STATISTICS_TOOLTIP 					= CALLBOARD_UI_STATISTICS_TOOLTIP or "Weekly rewards show what rewards can be earned for completing daily quests during the week, helping them plan and prepare for their adventures.",
	PVE 							 	= CALLBOARD_UI_PVE or "PvE",
	PVE_TOOLTIP 						= CALLBOARD_UI_PVE_TOOLTIP or "PvE daily quests are daily challenges that reward experience and loot for taking on powerful monsters and completing objectives.",
	RAID_RESETS 						= CALLBOARD_UI_RAID_RESETS or "Raid Reset Timers",
	RAID_RESETS_TOOLTIP 				= CALLBOARD_UI_RAID_RESETS_TOOLTIP or "Raid reset times show when raids will reset, helping you plan and prepare for their weekly raid events.",
	TIMEWALKING 						= CALLBOARD_UI_TIMEWALKING or "Timewalking",
	TIMEWALKING_TOOLTIP 				= CALLBOARD_UI_TIMEWALKING_TOOLTIP or "Timewalking quests are daily challenges take you back in time to relive classic adventures from World of Warcraft's past, offering great rewards upon successful completion.",
	PVP 							 	= CALLBOARD_UI_PVP or "PvP",
	PVP_TOOLTIP 						= CALLBOARD_UI_PVP_TOOLTIP or "PvP daily quests are daily challenges that pit you against other heroes in intense battles of skill and strategy, rewarding them with experience and loot upon completion.",
	HONORABLE_COMBAT 					= CALLBOARD_UI_HONORABLE_COMBAT or "Honorable Combat Zones",
	HONORABLE_COMBAT_TOOLTIP 			= CALLBOARD_UI_HONORABLE_COMBAT_TOOLTIP or "Honorable Combat allows you to engage in fair 1v1 PvP combat.",
	ARENA_RESETS 						= CALLBOARD_UI_ARENA_RESETS or "Arena resets in:\n%s",
	ARENA_RESETS_TITLE 					= CALLBOARD_UI_ARENA_RESETS_TITLE or "Arena Reset",
	ARENA_RESETS_TOOLTIP 				= CALLBOARD_UI_ARENA_RESETS_TOOLTIP or "Arena rating reset times indicate when arena ratings will be reset, allowing for strategic planning of competitive battles.",
	HIGHRISK 							= CALLBOARD_UI_HIGHRISK or "High Risk",
	HIGHRISK_TOOLTIP 					= CALLBOARD_UI_HIGHRISK_TOOLTIP or "High risk daily quests are daily challenges that require a daring expedition into dangerous areas and competing in open world PvP content, with grand rewards available upon successful completion.",
	PROF 								= CALLBOARD_UI_PROF or "Professions",			
	PROF_TOOLTIP 						= CALLBOARD_UI_PROF_TOOLTIP or "Profession daily quests are daily challenges that require expertise in crafting and gathering skills, offering experience and materials as a reward for successful completion.",
	MISC 								= CALLBOARD_UI_MISC or "Miscellaneous",
	MISC_TOOLTIP 						= CALLBOARD_UI_MISC_TOOLTIP or "Miscellaneous daily quests are daily challenges that encompass a variety of tasks, offering rewards upon successful completion.",
	DAILY_QUEST_RESET 					= CALLBOARD_UI_DAILY_QUEST_RESET or "Daily Quest Reset",
	DAILY_QUEST_RESET_TOOLTIP 			= CALLBOARD_UI_DAILY_QUEST_RESET_TOOLTIP or "Daily quest reset times indicate when daily quests will be reset.",
	WEEKLY_QUEST_RESET 					= CALLBOARD_UI_WEEKLY_QUEST_RESET or "Weekly Quest Reset",
	WEEKLY_QUEST_RESET_TOOLTIP 			= CALLBOARD_UI_WEEKLY_QUEST_RESET_TOOLTIP or "Weekly quest reset times indicate when weekly quests will be reset.",
	ERROR_TEXT_BASE 					= CALLBOARD_UI_ERROR_TEXT_BASE or "Seems like there is nothing yet! Come back later.",
	PVE_STATISTICS_TITLE				= CALLBOARD_UI_PVE_STATISTICS_TITLE or "PvE Rewards",
	PVE_STATISTICS_TOOLTIP 				= CALLBOARD_UI_PVE_STATISTICS_TOOLTIP or "PvE rewards indicate the rewards available upon completion of daily PvE quests.",
	PVP_STATISTICS_TITLE				= CALLBOARD_UI_PVP_STATISTICS_TITLE or "PvP Rewards",
	PVP_STATISTICS_TOOLTIP 				= CALLBOARD_UI_PVP_STATISTICS_TOOLTIP or "PvP rewards indicate the rewards available upon engaging in PvP combat and completing daily PvP quests.",
	HIGHRISK_STATISTICS_TITLE			= CALLBOARD_UI_HIGHRISK_STATISTICS_TITLE or "HighRisk Rewards",
	HIGHRISK_STATISTICS_TOOLTIP			= CALLBOARD_UI_HIGHRISK_STATISTICS_TOOLTIP or "High Risk rewards indicate the rewards available upon venturing into dangerous areas and completing daily High Risk quests",
	PROF_STATISTICS_TITLE				= CALLBOARD_UI_PROF_STATISTICS_TITLE or "Profession Rewards",
	PROF_STATISTICS_TOOLTIP				= CALLBOARD_UI_PROF_STATISTICS_TOOLTIP or "Profession rewards indicate the rewards available upon utilizing crafting and gathering skills.",
	MISC_STATISTICS_TITLE				= CALLBOARD_UI_MISC_STATISTICS_TITLE or "Misc Rewards",
	MISC_STATISTICS_TOOLTIP				= CALLBOARD_UI_MISC_STATISTICS_TOOLTIP or "Miscellaneous rewards indicate the rewards available upon completion of a variety of daily tasks.",
	OPEN_WORLDMAP 						= CALLBOARD_UI_OPEN_WORLDMAP or "Click to open World Map at %s",
	INSTANCES 							= CALLBOARD_UI_INSTANCES or "Instances",
	INSTANCES_TOOLTIP 					= CALLBOARD_UI_INSTANCES_TOOLTIP or "Capital Cities can get crowded! This allows you to switch to less dense instances of capitals.",
	QUEST_NOT_COMPLETABLE_TC 			= CALLBOARD_UI_QUEST_NOT_COMPLETABLE_TC or "%s |cffFF0000can not be completed via Gold or Tokens.|r",
	CONTRACT_DIALOGUE 					= CALLBOARD_UI_CONTRACT_DIALOGUE or "Are you sure you want to complete following quest(s) for:",
	ACCEPT_ALL_QUESTS					= CALLBOARD_UI_ACCEPT_ALL_QUESTS or "Accept All Quests",
	TURN_IN_ALL_QUESTS					= CALLBOARD_UI_TURN_IN_ALL_QUESTS or "Turn In All Quests",
	QUEST_IS_ACTIVE_ERROR 			 	= CALLBOARD_UI_QUEST_IS_ACTIVE_ERROR or "You have not completed this Quest yet. Click to turn in Quest once it is complete."
}

CallBoardUI.hooks = {
	{event = "CALLBOARD_VIEW_UPDATED", triggerOnShow = false},
}

CallBoardUI.MASS_COMPLETE_TIMEOUT_SECONDS = 5
CallBoardUI.massCompleteState = nil

CallBoardUI.gossipOptions = {
	QUESTS_POA						= 0,
	QUESTS_PVE						= 0,
	QUESTS_PVP						= 0,
	QUESTS_PROFESSION				= 0,
	QUESTS_MISCELLANEOUS			= 0,
	BACK							= 0,
}

-- Extend options
for i=1, 32 do
	CallBoardUI.gossipOptions["TIMEWALKING_"..i] = 0
end
for i=1, 8 do
	CallBoardUI.gossipOptions["INSTANCE_"..i] = 0
end

CallBoardUI.internalGossipOptions = {
	["path to ascension"] 					= "QUESTS_POA",
	["pve quests"] 							= "QUESTS_PVE",
	["pvp quests"]							= "QUESTS_PVP",
	["profession quests"]					= "QUESTS_PROFESSION",
	["miscellaneous quests"]			    = "QUESTS_MISCELLANEOUS",
	["return"] 								= "BACK",
	["high-risk quests"]				 	= "QUESTS_HIGHRISK"
}

CallBoardUI.menus = {}
CallBoardUI.categories = {pvp = "PvP", pve = "PvE", misc = "Misc", prof = "Profession", highRisk = "HighRisk"}
CallBoardUI.timeWalkingData = {}
CallBoardUI.timeWalkingFormat = "[timewalking] .* %((%d+)%)!"
CallBoardUI.instancesData = {}
CallBoardUI.instancesFormat = "Take me to (.*) instance (%d+)"
CallBoardUI.delayedOption = "QUESTS_PVE"
CallBoardUI.questQueue = {}
CallBoardUI.questRewards = {}

CallBoardUI.outdoor_PvP_Zones = {
	{event = 358, areaID = 3483}, -- HELLFIRE_PENINSULA
	{event = 360, areaID = 3519}, -- TEROKKAR_FOREST
	{event = 362, areaID = 3521}, -- ZANGARMARSH
	{event = 364, areaID = 3518}, -- NAGRAND
}

CallBoardUI.LFRUnlocalized = nil
CallBoardUI.TemporalContractsMap = nil
CallBoardUI.TemporalContractCategoryReference = {}
CallBoardUI.BAZAAR_TOKEN = 975001

CallBoardUI.areaIDIcons = {
	[331]		 = "achievement_zone_ashenvale_01",
	[16]		 = "achievement_zone_azshara_01",
	[3524]		 = "achievement_zone_azuremystisle_01",
	[3525]		 = "achievement_zone_bloodmystisle_01",
	[148]		 = "achievement_zone_darkshore_01",
	[1657]		 = "achievement_zone_darnassus",
	[405]		 = "achievement_zone_desolace",
	[14]		 = "achievement_zone_durotar",
	[15]		 = "achievement_zone_dustwallowmarsh",
	[361]		 = "achievement_zone_felwood",
	[357]		 = "achievement_zone_feralas",
	[493]		 = "spell_arcane_teleportmoonglade",
	[215]		 = "achievement_zone_mulgore_01",
	[1637]		 = "achievement_raid_soo_orgrimmar_outdoors",
	[1377]		 = "achievement_zone_silithus_01",
	[406]		 = "achievement_zone_stonetalon_01",
	[440]		 = "achievement_zone_tanaris_01",
	[141]		 = "achievement_zone_darnassus",
	[17]		 = "achievement_zone_barrens_01",
	[3557]		 = "spell_arcane_portalexodar",
	[400]		 = "achievement_zone_thousandneedles_01",
	[1638]		 = "spell_arcane_teleportthunderbluff",
	[490]		 = "spell_arcane_teleportthunderbluff",
	[618]		 = "achievement_zone_winterspring",
	[36]		 = "achievement_zone_alteracmountains_01",
	[45]		 = "achievement_zone_arathihighlands_01",
	[3]		 	 = "achievement_zone_badlands_01",
	[4]		 	 = "achievement_zone_blastedlands_01",
	[46]		 = "achievement_zone_burningsteppes_01",
	[41]		 = "achievement_zone_deadwindpass",
	[1]		 	 = "achievement_zone_dunmorogh",
	[10]		 = "achievement_zone_duskwood",
	[139]		 = "achievement_zone_easternplaguelands",
	[12]		 = "achievement_zone_elwynnforest",
	[3430]		 = "achievement_zone_eversongwoods",
	[3433]		 = "achievement_zone_ghostlands",
	[267]		 = "achievement_zone_hillsbradfoothills",
	[1537]		 = "achievement_zone_ironforge",
	[4080]		 = "achievement_zone_isleofqueldanas",
	[38]		 = "achievement_zone_lochmodan",
	[44]		 = "achievement_zone_redridgemountains",
	[51]		 = "achievement_zone_searinggorge_01",
	[3487]		 = "spell_arcane_teleportsilvermoon",
	[130]		 = "achievement_zone_silverpine_01",
	[1519]		 = "spell_arcane_portalstormwind",
	[33]		 = "achievement_zone_stranglethorn_01",
	[8]		 	 = "achievement_zone_swampsorrows_01",
	[47]		 = "achievement_zone_hinterlands_01",
	[85]		 = "achievement_zone_tirisfalglades_01",
	[1497]		 = "spell_arcane_teleportundercity",
	[28]		 = "achievement_zone_westernplaguelands_01",
	[40]		 = "achievement_zone_westfall_01",
	[11]		 = "achievement_zone_wetlands_01",
	[3522]		 = "achievement_zone_bladesedgemtns_01",
	[3483]		 = "achievement_zone_hellfirepeninsula_01",
	[3518]		 = "achievement_zone_nagrand_01",
	[3523]		 = "achievement_zone_netherstorm_01",
	[3520]		 = "achievement_zone_shadowmoon",
	[3703]		 = "spell_arcane_teleportshattrath",
	[3519]		 = "achievement_zone_terrokar",
	[3521]		 = "achievement_zone_zangarmarsh",
	[3537]		 = "achievement_zone_boreantundra_01",
	[2817]		 = "achievement_zone_crystalsong_01",
	[4395]		 = "spell_arcane_teleportdalaran",
	[65]		 = "achievement_zone_dragonblight_02",
	[394]		 = "achievement_zone_grizzlyhills_01",
	[495]		 = "achievement_zone_howlingfjord_02",
	[4742]		 = "",
	[210]		 = "achievement_zone_icecrown_01",
	[3711]		 = "achievement_zone_sholazar_02",
	[67]		 = "achievement_zone_stormpeaks_01",
	[4197]		 = "inv_essenceofwintergrasp",
	[66]		 = "achievement_zone_zuldrak_03",
	[2159]		 = "LFGIcon-OnyxiaEncounter",
	[3429]		 = "LFGICON-AQRUINS",
	[2557] 		 = "LFGICON-DIREMAUL",
}

StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"] = {
	text = "",
	button1 = "Okay",
	button2 = "Cancel",
	whileDead = true,
	timeout = 0,
	hasMoneyFrame = 1,
	hideOnEscape = true,
	OnShow = function(self)
		if (StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].hasMoneyFrame) then
			MoneyFrame_Update(self.moneyFrame, StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].cost)
		end
	end,
}

function CallBoardUI:StartMassComplete(category, frame)
	local startedAt = GetTime()
	self.massCompleteState = {
		category = category,
		frame = frame,
		startedAt = startedAt
	}

	if frame and frame.SetProcessing then
		frame:SetProcessing(true)
	end

	C_Timer.After(self.MASS_COMPLETE_TIMEOUT_SECONDS, function()
		if self.massCompleteState and self.massCompleteState.startedAt == startedAt then
			self:ClearMassCompleteState()
		end
	end)
end

function CallBoardUI:ClearMassCompleteState()
	if self.massCompleteState and self.massCompleteState.frame and self.massCompleteState.frame.SetProcessing then
		self.massCompleteState.frame:SetProcessing(false)
	end
	self.massCompleteState = nil
end

function CallBoardUI:ResolveMassCompleteState()
	if not self.massCompleteState then
		return
	end

	local category = self.massCompleteState.category
	local categoryData = self.TemporalContractsMap and self.TemporalContractsMap[category] and self.TemporalContractsMap[category]["TOTAL"]
	local remainingCompletions = categoryData and categoryData.remainingCompletions or 0
	local elapsed = GetTime() - (self.massCompleteState.startedAt or 0)

	if remainingCompletions <= 0 or elapsed >= self.MASS_COMPLETE_TIMEOUT_SECONDS then
		self:ClearMassCompleteState()
	end
end

function CallBoardUI:CALLBOARD_VIEW_UPDATED()
	self:LoadContractsInfo(true)
	self:ResolveMassCompleteState()

	if (self.content.statisticsContent:IsVisible()) then
		self.Tabs.tabStatistics:GetScript("OnClick")(self.Tabs.tabStatistics)
		return
	end
end

function CallBoardUI:FormatGossipOptionText(text)
	return text
end

function CallBoardUI:DefineGossipOption(text, buttonIndex, originalText)
	local optionInternal = self.internalGossipOptions[text]
	local timeWalkingMapID = string.match(text, self.timeWalkingFormat)

	if (timeWalkingMapID) then
		local index = #self.timeWalkingData+1
		self.gossipOptions["TIMEWALKING_"..index] = buttonIndex
		self.timeWalkingData[index] = tonumber(timeWalkingMapID)
		return
	end

	local areaName, instanceID = string.match(originalText, self.instancesFormat)

	if (instanceID) then
		local index = #self.instancesData+1
		self.gossipOptions["INSTANCE_"..index] = buttonIndex
		self.instancesData[index] = {instanceID, areaName}
		return
	end

	if (optionInternal) then
		self.gossipOptions[optionInternal] = buttonIndex
	end
end

function CallBoardUI:LoadContractsInfo(forced)
	if (self.TemporalContractsMap and not(forced)) then
		return true
	end

	local view = C_Callboard and C_Callboard.GetView and C_Callboard.GetView() or nil
	if not(view) or not(view.Categories) then
		if (C_Callboard and C_Callboard.RequestView) then
			C_Callboard.RequestView()
		end
		self.TemporalContractsMap = self.TemporalContractsMap or {}
		self.TemporalContractCategoryReference = self.TemporalContractCategoryReference or {}
		return false
	end

	self.TemporalContractsMap = {}
	self.TemporalContractCategoryReference = {}

	for _, category in pairs(view.Categories) do
		local categoryKey = category.ContentType or category.Name or "Unknown"

		self.TemporalContractsMap[categoryKey] = {}
		self.TemporalContractsMap[categoryKey]["TOTAL"] = {
			rewards = self:NormalizeRewards(category.Rewards),
			remainingCompletions = category.RemainingCompletions or 0,
			moneyCost = category.MoneyCost or 0,
			tokenCost = category.TokenCost or 0
		}

		for _, subCategory in pairs(category.SubCategories or {}) do
			if (subCategory.Type) then
				self.TemporalContractsMap[categoryKey][subCategory.Type] = {
					moneyCost = subCategory.MoneyCost or 0,
					tokenCost = subCategory.TokenCost or 0,
					rewards = self:NormalizeRewards(subCategory.Rewards),
					remainingCompletions = subCategory.RemainingCompletions,
					minimumLevel = subCategory.MinimumLevel or 1,
					name = subCategory.Name or subCategory.Type
				}
				self.TemporalContractCategoryReference[subCategory.Type] = categoryKey
			end
		end
	end

	if not(self.content.statisticsContent.subCategoriesInitialized) then
		self.content.statisticsContent:CreateSubCategories()
		self.content.statisticsContent.subCategoriesInitialized = true
	end

	return true
end

function CallBoardUI:GetQuestCategory(questID)
	local subCatagory = C_TemporalContracts.GetQuestCategory(questID)
	if not subCatagory then
		local sortIds = C_TemporalContracts.GetQuestSortIDs(questID, false)
		if sortIds then
			for i = 1, #sortIds do
				local sortText = C_TemporalContracts.GetQuestSortText(sortIds[i])
				if sortText then
					local lowerSortText = string.lower(sortText)
					for categoryKey, subCategories in pairs(self.TemporalContractsMap) do
						for subType, subData in pairs(subCategories) do
							if subType ~= "TOTAL" then
								local subName = subData.name or (C_TemporalContracts.GetCategoryName and C_TemporalContracts.GetCategoryName(subType)) or subType
								if string.lower(subName) == lowerSortText or string.lower(subType) == lowerSortText then
									subCatagory = subType
									break
								end
							end
						end
						if subCatagory then break end
					end
				end
				if subCatagory then break end
			end
		end

		if not subCatagory and sortIds then
			for i = 1, #sortIds do
				local sortText = C_TemporalContracts.GetQuestSortText(sortIds[i])
				if sortText then
					local lowerSortText = string.lower(sortText)
					if lowerSortText == "daily dungeon" or lowerSortText == "dungeon diving" then
						local questTemplate = GetQuestTemplate(questID)
						local questTitle = questTemplate and questTemplate.Title
						if questTitle then
							local lowerTitle = string.lower(questTitle)
							for categoryKey, subCategories in pairs(self.TemporalContractsMap) do
								for subType, subData in pairs(subCategories) do
									if subType ~= "TOTAL" then
										local subName = subData.name or (C_TemporalContracts.GetCategoryName and C_TemporalContracts.GetCategoryName(subType)) or subType
										local lowerSubName = string.lower(subName)
										local lowerSubType = string.lower(subType)

										if string.find(lowerTitle, "heroic") and (string.find(lowerSubName, "heroic") or string.find(lowerSubType, "heroic")) then
											subCatagory = subType
											break
										elseif (string.find(lowerTitle, "mythic%+") or string.find(lowerTitle, "mythic plus")) and (string.find(lowerSubName, "mythic%+") or string.find(lowerSubName, "mythicplus") or string.find(lowerSubType, "mythic%+") or string.find(lowerSubType, "mythicplus")) then
											subCatagory = subType
											break
										elseif string.find(lowerTitle, "mythic") and not (string.find(lowerTitle, "mythic%+") or string.find(lowerTitle, "mythic plus")) and string.find(lowerSubName, "mythic") and not (string.find(lowerSubName, "mythic%+") or string.find(lowerSubName, "mythicplus") or string.find(lowerSubType, "mythic%+") or string.find(lowerSubType, "mythicplus")) then
											subCatagory = subType
											break
										elseif not (string.find(lowerTitle, "heroic") or string.find(lowerTitle, "mythic")) and (string.find(lowerSubName, "normal") or string.find(lowerSubType, "normal") or string.find(lowerSubName, "crawling") or string.find(lowerSubType, "crawling")) then
											subCatagory = subType
											break
										end
									end
								end
								if subCatagory then break end
							end
						end
					end
				end
				if subCatagory then break end
			end
		end
	end
	return subCatagory
end

function CallBoardUI:GetCategoryQuestData(questID)
	local subCatagory = self:GetQuestCategory(questID)
	local category = self.TemporalContractCategoryReference[subCatagory]

	if (subCatagory and category) then
		return self.TemporalContractsMap[category][subCatagory], subCatagory, category
	end
end

function CallBoardUI:MoveQuestQueue()
	local questID = next(self.questQueue)

	if questID then
		local quest = Quest:CreateFromID(questID)

		if self.cancelToken then
			self.cancelToken()
			self.cancelToken = nil
		end

		self.cancelToken = quest:CancelableContinueOnLoad(function()
			if not quest:IsCached() then
				self.questQueue[questID] = nil
				self:MoveQuestQueue()
				return
			end

			self.questRewards[questID] = GetQuestRewards(questID)
			self.questQueue[questID] = nil
			self:MoveQuestQueue()
		end)
	else
		self:ReloadCategoryRewards()
		return
	end
end

function CallBoardUI:LoadRewards()
	if not(self.questList) or not(next(self.questList)) then
		self:ReloadCategoryRewards()
		return
	end

	for i = 1, #self.questList do
		local questID = self.questList[i].ID
		if questID and not(self.questRewards[questID]) then
			self.questQueue[questID] = true
		end
	end

	self:ReloadCategoryRewards()
	self:MoveQuestQueue()
end

function CallBoardUI:GetCategoryData(category)
	local categories = self.TemporalContractsMap[category]

	if not(categories) then
		return {rewards = {}, remainingCompletions = 0, moneyCost = 0, tokenCost = 0}, {}
	end

	if (self.TemporalContractsMap[category]["TOTAL"]) then
		return self.TemporalContractsMap[category]["TOTAL"], categories
	end
end

function CallBoardUI:UpdateContractsInfo()
	if not(self:LoadContractsInfo(true)) then
		return
	end

	if (self.content.statisticsContent:IsVisible()) then
		self.content.statisticsContent:LoadSubCategories()
	end
end

function CallBoardUI.CorrectHonorReward(value)
	local curHonor, maxHonor = GetHonorCurrency()
	return ((value+curHonor) > maxHonor) and (maxHonor-curHonor) or value
end

function CallBoardUI.CorrectArenaReward(value)
	local currAP, maxAP = Ascension_GetArenaRewardInfo()
	return ((value+currAP) > maxAP) and (maxAP-currAP) or value
end
