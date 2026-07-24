local ChallengesUI = select(2, ...)

ChallengeItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

local challengeSelectedLevels = {}
local challengeExpandedTab = {}

local function ResetChallengeIcon(pool, icon)
	icon:ClearAllPoints()
	icon.tooltipTitle = nil
	icon.tooltipText = nil
	icon.tooltipData = nil
	icon:Hide()
end

local function ResetRewardIcon(pool, icon)
	icon.itemID = nil
	icon.tooltipTitle = nil
	icon.tooltipText = nil
	icon.countText = nil
	icon.achievementID = nil
	icon:ClearAllPoints()
	icon:Hide()
end

function ChallengeItemMixin:OnLoad()
	self:GetNormalTexture():SetDrawLayer("BACKGROUND")
	self:SetHighlightAtlas("addons_list_hover")
	self.LockedIcon:SetAtlas("honorsystem-bar-lock", Const.TextureKit.IgnoreAtlasSize)
	self.Featured:SetNormalAtlas("auctionhouse-icon-favorite")
	self.FeaturedHighlight:SetAtlas("challenges-featured-highlight", Const.TextureKit.IgnoreAtlasSize)
	self.CompleteCheck:SetNormalAtlas("auctionhouse-icon-checkmark")

	self.ChallengeIcons = CreateFramePool("BUTTON", self, "ChallengeIconTemplate", ResetChallengeIcon)
	self.RewardIcons = CreateFramePool("BUTTON", self, "ChallengeRewardTemplate", ResetRewardIcon)
	
	self:RegisterEvent("CHALLENGE_COMPLETION_LIST_CHANGED")
	self:RegisterEvent("TRIAL_COMPLETION_LIST_CHANGED")
end

function ChallengeItemMixin:OnEvent(event, ...)
	local challengeID = ...
	local isThisChallenge = not challengeID or self.challenge and challengeID == self.challenge.ID
	if self.challenge and isThisChallenge and self:IsExpanded() and self:GetSelectedTab() == 2 then
		local level = not self:IsPlayerMade() and self:GetSelectedLevel()
		self.ExtendedInfo.TabContent:ShowLeaderboard(self.challenge.ID, level)
	end
end

function ChallengeItemMixin:IsPlayerMade()
	return false
end

function ChallengeItemMixin:IsPartOfCustomChallenge()
	return self:GetScrollList():GetParent():IsPartOfCustomChallenge()
end

function ChallengeItemMixin:CanRemoveFromCustomChallenge()
	local parent = self:GetScrollList():GetParent()
	if parent.CanRemoveFromCustomChallenge then
		return parent:CanRemoveFromCustomChallenge()
	end
	return true
end

function ChallengeItemMixin:SetSelectedLevel(level)
	challengeSelectedLevels[self.challenge.ID] = level
end

function ChallengeItemMixin:SetExpandedTab(tab)
	challengeExpandedTab[self.challenge.ID] = tab
end

function ChallengeItemMixin:GetSelectedLevel()
	if not self.challenge then return 1 end
	return challengeSelectedLevels[self.challenge.ID] or 1
end

function ChallengeItemMixin:GetExpandedTab()
	if not self.challenge then return end
	return challengeExpandedTab[self.challenge.ID]
end

function ChallengeItemMixin:Update()
	local challenge
	challenge = self:GetScrollList():GetParent():GetChallengeInfoByIndex(self.index, self:IsExpanded())
	self.challenge = challenge

	if ChallengesUI:IsSelectingChallenge() then
		self.IsLocked = ChallengesUI:CheckEditModeChallengeExclusiveGroup(self.challenge)
	else
		self.IsLocked = self:GetScrollList():GetParent():IsChallengeExclusiveGroupTaken(challenge)
	end

	self:UpdateChallengeLevel()
	self:SetIcon(challenge.Icon)
	self:SetName(challenge.Name)
	self:SetDescription(challenge.Description)
	self:UpdateChallengeIcons()
	self:UpdateReward()
	self:UpdateExpandedDisplay()
end

function ChallengeItemMixin:SetIcon(icon)
	if icon:find("Interface\\Icons\\") then
		self.Icon:SetTexture(icon)
	else
		self.Icon:SetTexture("Interface\\Icons\\" .. icon)
	end
	self.LockedIcon:SetShown(self.IsLocked)
	self.Icon:SetDesaturated(self.IsLocked)
	if self:IsChallengeActive() then
		self.IconBorder:SetAtlas("collections-itemborder-collected", Const.TextureKit.IgnoreAtlasSize)
	else
		self.IconBorder:SetAtlas("collections-itemborder-uncollected", Const.TextureKit.IgnoreAtlasSize)
	end
end

function ChallengeItemMixin:SetName(name)
	self.name = name
	self.Text:SetText(name)
	if self.IsLocked then
		self.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
	else
		self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	end

	self.ExtendedInfo.TabContent:SetTitle(name)
end

function ChallengeItemMixin:SetDescription(description)
	self.description = description
end

local combinedItems = {
	[ItemData.MARK_OF_ASCENSION] = true,
	[ItemData.MYSTIC_ORB]        = true,
	[ItemData.MYSTIC_RUNE]       = true,
	[ItemData.CENTENARIAN_BULLION] = true,
	[ItemData.TRIAL_MASTER_TROPHY] = true,
	-- rune / orb pouches
	[509876] = true,
	[509865] = true,
	[509866] = true,
	[509867] = true,
	[509868] = true,
	[509869] = true,
	[509870] = true,
	[509871] = true,
	[509873] = true,
	[509874] = true,
	[509875] = true,
	[509877] = true,
	[509872] = true,
	[509864] = true,
	[509863] = true,
	[518448] = true,
	[518449] = true,
	[518450] = true,
	[509886] = true,
	[413800] = true,
	[509893] = true,
	[509894] = true,
	[509895] = true,
	[509896] = true,
	[509897] = true,
	[612805] = true,
	[612806] = true,
	[612807] = true,
	[612808] = true,
	[612809] = true,
	[612810] = true,
	[612811] = true,
	[612812] = true,
	[612813] = true,
	[612814] = true,
	[612815] = true,
	[612816] = true,
	[612817] = true,
	[612818] = true,
	[612819] = true,
	[612820] = true,
	[612821] = true,
	[612822] = true,
	[612823] = true,
	[612824] = true,
	[612825] = true,
}

local function CreateEmbeddedItemTooltip(item, amount)
	local line1 = item:GetIconTextureMarkup() .. " " .. ITEM_QUALITY_COLORS[item:GetQuality()]:WrapText("[" .. item:GetName() .. "]")
	if amount and amount > 1 then
		line1 = line1 .. " |cffffffffx " .. amount .. "|r"
	end
	local flavorText = item:GetFlavorText()
	if flavorText and flavorText:len() > 0 then
		return line1, "\"" .. flavorText .. "\""
	end
	
	return line1
end

function ChallengeItemMixin:UpdateReward()
	self.RewardIcons:ReleaseAll()
	local rewards = self.detailedChallenge.Rewards

	local x = -22
	--
	local spoilsReward, achievementReward
	for _, reward in ipairs(rewards) do
		if reward.ItemID and reward.ItemID > 0 then
			local item = Item:CreateFromID(reward.ItemID)
			local rewardIcon

			if spoilsReward and combinedItems[reward.ItemID] then
				rewardIcon = spoilsReward
				-- convert to spoils
				-- tooltip is already setup
				rewardIcon.itemID = nil
				rewardIcon.Icon:SetPortraitTexture("Interface\\Icons\\trade_archaeology_chestoftinyglassanimals")
				rewardIcon.IconBorder:SetAtlas("item-border-round-gold", Const.TextureKit.IgnoreAtlasSize)
				rewardIcon.Count:Hide()
				tinsert(rewardIcon.tooltipText, " ")
				tinsertMany(rewardIcon.tooltipText, CreateEmbeddedItemTooltip(item, reward.ItemAmount))
			else
				rewardIcon = self.RewardIcons:Acquire()
				rewardIcon.itemID = reward.ItemID
				rewardIcon.Icon:SetPortraitTexture(item:GetIcon())
				if reward.IsSpecialReward then
					rewardIcon.IconBorder:SetAtlas("item-border-round-heirloom", Const.TextureKit.IgnoreAtlasSize)
				else
					rewardIcon.IconBorder:SetAtlas(ITEM_QUALITY_ROUND_BORDER_ATLAS[item:GetQuality()])
				end
				if combinedItems[reward.ItemID] then
					spoilsReward = rewardIcon
					rewardIcon.tooltipTitle = ITEM_QUALITY_COLORS[7]:WrapText(CHALLENGES_COMBINED_SPOILS)
					rewardIcon.tooltipText = { CreateEmbeddedItemTooltip(item, reward.ItemAmount) }
					
					if reward.ItemAmount > 1 then
						rewardIcon.Count:SetText("x" .. reward.ItemAmount)
						rewardIcon.Count:Show()
					else
						rewardIcon.Count:Hide()
					end
				elseif reward.ItemAmount > 1 then
					rewardIcon.Count:SetText("x" .. reward.ItemAmount)
					rewardIcon.Count:Show()
				else
					rewardIcon.Count:Hide()
				end

				rewardIcon:SetPoint("TOPRIGHT", x, -25)
				x = x - 48
				rewardIcon:Show()
			end
		elseif reward.Achievement and reward.Achievement > 0 then
			if achievementReward then
				achievementReward.achievementID = nil
				achievementReward.Icon:SetPortraitTexture("Interface\\Icons\\Spell_Holy_AvengersShield")
				local _, name = GetAchievementInfo(reward.Achievement)
				achievementReward.tooltipText = achievementReward.tooltipText .. "\n|cffffff00[" .. name .. "]|r"
			else
				local rewardIcon = self.RewardIcons:Acquire()
				achievementReward = rewardIcon
				rewardIcon.achievementID = reward.Achievement
				local _, name, _, _, _, _, _, _, _, icon = GetAchievementInfo(reward.Achievement)
				rewardIcon.Icon:SetPortraitTexture(icon)
				rewardIcon.IconBorder:SetAtlas("item-border-round-gold", Const.TextureKit.IgnoreAtlasSize)
				rewardIcon.Count:Hide()
				rewardIcon.tooltipTitle = CHALLENGES_COMBINED_ACHIEVEMENTS
				rewardIcon.tooltipText = "\n|cffffff00[" .. name .. "]|r"
				rewardIcon:SetPoint("TOPRIGHT", x, -25)
				x = x - 48
				rewardIcon:Show()
			end
		end
	end

	self.Text:SetPoint("RIGHT", x, 0)
end

function ChallengeItemMixin:SelectTab(tabID)
	self:SetExpandedTab(tabID)
	self:UpdateExtendedTab()
end

function ChallengeItemMixin:GetSelectedTab()
	return self:GetExpandedTab()
end

function ChallengeItemMixin:UpdateExtendedTab()
	local tabContent = self.ExtendedInfo.TabContent

	for i = 1, 4 do
		local tab = self.ExtendedInfo["Tab" .. i]
		if i == self:GetExpandedTab() then
			tab:LockHighlight()
			tab:SetButtonState("PUSHED", 1)
		else
			tab:UnlockHighlight()
			tab:SetButtonState("NORMAL")
		end
	end

	if self:GetExpandedTab() == 1 or not self:GetExpandedTab() then
		return tabContent:ShowAboutTab(self.description)
	elseif self:GetExpandedTab() == 2 then
		if self:IsExpanded() then
			self:QueryLeaderboardIfNeeded()
		end
		return tabContent:ShowLeaderboard(self.challenge.ID, self:GetSelectedLevel())
	elseif self:GetExpandedTab() == 3 then
		return tabContent:ShowAurasTab(self.detailedChallenge.Spells, self.detailedChallenge.Modifiers)
	elseif self:GetExpandedTab() == 4 then
		return tabContent:ShowRestrictionsTab(self.detailedChallenge.Rules)
	elseif self:GetExpandedTab() == 5 then
		return tabContent:ShowRequirementsTab(self.detailedChallenge.Conditions)
	end
end

function ChallengeItemMixin:UpdateChallengeLevel()
	local maxLevel, highestCompletedLevel = self:GetChallengeLevels()
	local isActive, currentLevel = self:IsChallengeActive()
	if isActive then
		self:SetSelectedLevel(currentLevel)
	elseif not self:GetSelectedLevel() then
		self:SetSelectedLevel(MClamp(highestCompletedLevel + 1, 1, maxLevel))
	end

	local desiredLevel = self:GetSelectedLevel()

	if self:ShowLevelSelection() then
		if maxLevel == 1 then
			self.ExtendedInfo.CurrentLevel:SetFormattedText(CURRENT_LEVEL_COLON.." |cffFFFFFF%s|r ", desiredLevel)
		else
			self.ExtendedInfo.CurrentLevel:SetFormattedText(CURRENT_LEVEL_COLON.." |cffFFFFFF%s / %s|r ", desiredLevel, maxLevel)
		end
	end

	self.detailedChallenge = self:GetChallengeInfoByLevel()
	if not self.detailedChallenge then
		C_Logger.Error("Challenge has no levels! [%s] %s", self.challenge.ID, self.challenge.Name)
	end
	self:UpdateButtons()
end

function ChallengeItemMixin:UpdateButtons()
	local isActive = self:IsChallengeActive()
	local maxLevel, _, maxPossibleLevel = self:GetChallengeLevels()
	local canActivate, reasons

	if ChallengesUI:IsSelectingChallenge() then
		canActivate = true
		if self:ShowLevelSelection() then
			self.ExtendedInfo.MinusLevelButton:Disable()
			self.ExtendedInfo.PlusLevelButton:Disable()
		end
	elseif self:IsPartOfCustomChallenge() then
		canActivate = true
		if self:ShowLevelSelection() then
			self.ExtendedInfo.MinusLevelButton:SetEnabled(self:GetSelectedLevel() > 1)
			self.ExtendedInfo.PlusLevelButton:SetEnabled(self:GetSelectedLevel() < maxPossibleLevel)
		end
	elseif isActive then
		canActivate, reasons = self:CanDeactivateChallenge()
		if self:ShowLevelSelection() then
			self.ExtendedInfo.MinusLevelButton:Disable()
			self.ExtendedInfo.PlusLevelButton:Disable()
		end
	else
		canActivate, reasons = self:CanActivateChallenge()
		if self:ShowLevelSelection() then
			self.ExtendedInfo.MinusLevelButton:SetEnabled(self:GetSelectedLevel() > 1)
			self.ExtendedInfo.PlusLevelButton:SetEnabled(self:GetSelectedLevel() < maxPossibleLevel)
		end
	end

	if self.IsLocked then
		canActivate = false
		local challenge = C_Challenge.GetChallengeInfo(self.IsLocked)
		if challenge then
			reasons = {
				CHALLENGE_START_EXCLUSIVE_GROUP_ACTIVE_S:format(challenge.Name)
			}
		end
	end

	if self:IsPartOfCustomChallenge() and not self:CanRemoveFromCustomChallenge() then
		canActivate = false
		reasons = {
			"CHALLENGES_EDITOR_CANT_CHANGE_CHALLENGES"
		}
		self.ExtendedInfo.MinusLevelButton:SetEnabled(false)
		self.ExtendedInfo.PlusLevelButton:SetEnabled(false)
	end
	self.ExtendedInfo.ActivateButton:SetEnabled(canActivate)
	self.ExtendedInfo.ActivateButton.disabledReasons = reasons
end

function ChallengeItemMixin:DecreaseChallengeLevel()
	local isActive = self:IsChallengeActive()
	if isActive then
		return
	end
	local _, _, maxPossibleLevel = self:GetChallengeLevels()
	local decreaseAmount = IsShiftKeyDown() and 10 or 1
	self:SetSelectedLevel(MClamp(self:GetSelectedLevel() - decreaseAmount, 1, maxPossibleLevel))
	self:Update()
end

function ChallengeItemMixin:IncreaseChallengeLevel()
	local isActive = self:IsChallengeActive()
	if isActive then
		return
	end
	local _, _, maxPossibleLevel = self:GetChallengeLevels()
	local increaseAmount = IsShiftKeyDown() and 10 or 1
	self:SetSelectedLevel(MClamp(self:GetSelectedLevel() + increaseAmount, 1, maxPossibleLevel))
	self:Update()
end

local cannotCombine = {}
function ChallengeItemMixin:UpdateChallengeIcons()
	self.ChallengeIcons:ReleaseAll()
	self.Featured:SetShown(self.challenge.IsFeatured)
	self.CompleteCheck:SetShown(self.detailedChallenge.IsCompleted)
	self.FeaturedHighlight:SetShown(self.challenge.IsFeatured)
	local x = 12
	local difficulty = self.challenge.DifficultyRating
	local difficultyNum = Enum.ChallengeDifficulty[difficulty]

	if difficultyNum then
		local icon = self.ChallengeIcons:Acquire()
		icon:SetNormalAtlas(format("professions-icon-quality-tier%d", difficultyNum))
		icon:SetPoint("BOTTOMLEFT", self.Icon, "BOTTOMRIGHT", x, -2)
		icon:Show()
		icon.tooltipTitle = _G[difficulty]
		icon.tooltipText = _G[difficulty .. "_DESCRIPTION"]
		x = x + 24
	end

	if self.challenge.PvP and self.challenge.PvE then
		local icon = self.ChallengeIcons:Acquire()
		icon:SetNormalAtlas("honorsystem-icon-bonus")
		icon:SetPoint("BOTTOMLEFT", self.Icon, "BOTTOMRIGHT", x, -2)
		icon:Show()
		icon.tooltipTitle = CHALLENGE_PVPVE_ACTIVE
		icon.tooltipText = CHALLENGE_PVPVE_ACTIVE_DESC
		x = x + 24
	else
		if self.challenge.PvP then
			local icon = self.ChallengeIcons:Acquire()
			icon:SetNormalAtlas("crossedflags")
			icon:SetPoint("BOTTOMLEFT", self.Icon, "BOTTOMRIGHT", x, -2)
			icon:Show()
			icon.tooltipTitle = CHALLENGE_PVP_ACTIVE
			icon.tooltipText = CHALLENGE_PVP_ACTIVE_DESC
			x = x + 24
		end

		if self.challenge.PvE then
			local icon = self.ChallengeIcons:Acquire()
			icon:SetNormalAtlas("questbonusobjective")
			icon:SetPoint("BOTTOMLEFT", self.Icon, "BOTTOMRIGHT", x, -2)
			icon:Show()
			icon.tooltipTitle = CHALLENGE_PVE_ACTIVE
			icon.tooltipText = CHALLENGE_PVE_ACTIVE_DESC
			x = x + 24
		end
	end

	self.hasRestrictedDeathCount = false
	self.combinedRequirements = {}

	for _, requirement in ipairs(self.detailedChallenge.Requirements) do
		local requirementType = requirement.RequirementType
		local name, description, atlas, altAtlas, formatter1, formatter2, formatter3 = ChallengeUtil.GetRequirementLocalization(requirementType)
		
		if requirementType ~= "CHALLENGE_REQUIREMENT_TYPE_NONE" then
			local icon
			if self.combinedRequirements[requirementType] then
				icon = self.combinedRequirements[requirementType]
			else
				icon = self.ChallengeIcons:Acquire()
				icon:SetPoint("BOTTOMLEFT", self.Icon, "BOTTOMRIGHT", x, -2)
				icon:SetNormalAtlas(atlas)
				icon:Show()
				x = x + 24
				
				local miscValue1, miscValue2, miscValue3 = ChallengeUtil.ApplyMiscValueFormatting(requirement.MiscValue1, requirement.MiscValue2, requirement.MiscValue3, formatter1, formatter2, formatter3)
				icon.tooltipTitle = name:format(miscValue1, miscValue2, miscValue3)

				if not cannotCombine[requirementType] then
					self.combinedRequirements[requirementType] = icon
				end
			end

			if requirementType == "CHALLENGE_REQUIREMENT_TYPE_COMPLETE_WITHOUT_DEATH" then
				self.hasRestrictedDeathCount = true
				if requirement.MiscValue1 > 1 then -- death count
					icon:SetNormalAtlas(altAtlas)
				end
			end
			
			if not icon.tooltipText then
				icon.tooltipText = { description = description }
			end

			tinsert(icon.tooltipText, {requirement, formatter1, formatter2, formatter3})
		end
	end
end

function ChallengeItemMixin:ChallengeIconOnEnter(icon)
	self:LockHighlight()
	GameTooltip:SetOwner(icon, "ANCHOR_TOP")
	GameTooltip:SetText(icon.tooltipTitle, 1, 1, 1)
	if type(icon.tooltipText) == "table" then
		local count = #icon.tooltipText
		for i, tooltipText in ipairs(icon.tooltipText) do
			if i > 30 then
				GameTooltip_AddSpacer(GameTooltip)
				GameTooltip:AddLine(CHALLENGES_TOOLTIP_AND_D_MORE:format(#icon.tooltipText - i), nil, nil, nil, false)
				break
			end
            -- cant unpack cuz formatter 1/2/3 can all be inserted as nil
			local requirement, formatter1, formatter2, formatter3 = tooltipText[1], tooltipText[2], tooltipText[3], tooltipText[4]
			local miscValue1, miscValue2, miscValue3 = ChallengeUtil.ApplyMiscValueFormatting(requirement.MiscValue1, requirement.MiscValue2, requirement.MiscValue3, formatter1, formatter2, formatter3)
			if i ~= 1 and count < 10 then
				GameTooltip_AddSpacer(GameTooltip)
			end
			GameTooltip:AddLine(icon.tooltipText.description:format(miscValue1, miscValue2, miscValue3), nil, nil, nil, count < 10)
		end
	else
		GameTooltip:AddLine(icon.tooltipText, nil, nil, nil, true)
	end
	GameTooltip:Show()
end

function ChallengeItemMixin:ToggleChallengeActive()
	if ChallengesUI:IsSelectingChallenge() then
		ChallengesUI:EditModeChallengeSelected(self)
		return
	elseif self:IsPartOfCustomChallenge() then
		self:GetScrollList():GetParent():RemoveChallenge(self.challenge)
		return
	end

	local isActive = self:IsChallengeActive()
	if isActive then
		PlaySound(SOUNDKIT.ESCAPE_SCREEN_CLOSE)
		if self:StopChallenge() then
			return
		else
			ChallengesFrame.ErrorInputBlock:Show()
			ChallengesFrame.ErrorInputBlock:SetText(CHALLENGES_CANNOT_ACTIVATE, "Interface Error")
		end
	else
		PlaySound(SOUNDKIT.ESCAPE_SCREEN_OPEN)
		if self.hasRestrictedDeathCount then
			ChallengesFrame.WarningInputBlock:Show()
			ChallengesFrame.WarningInputBlock:SetText(CHALLENGES_CONFIRM_ACTIVATE, CHALLENGES_ACTIVATE_LIMITED_DEATHS_WARNING)
			ChallengesFrame.WarningInputBlock.OnAccept = function()
				self:StartChallenge()
			end
		elseif self:StartChallenge() then
			return
		else
			ChallengesFrame.ErrorInputBlock:Show()
			ChallengesFrame.ErrorInputBlock:SetText(CHALLENGES_CANNOT_ACTIVATE, "Interface Error")
		end
	end
end

function ChallengeItemMixin:QueryLeaderboardIfNeeded()
	if self:IsPlayerMade() then
		if not C_TrialCreator.GetTrialCompletion(self.challenge.ID, 1) then
			C_TrialCreator.QueryTrialCompletions(self.challenge.ID)
		end
	else
		if not C_Challenge.GetChallengeCompletion(self.challenge.ID, self:GetSelectedLevel(), 1) then
			C_Challenge.QueryChallengeCompletions(self.challenge.ID, self:GetSelectedLevel())
		end
	end
end

local challengeAtlasFormat = "challenges-%s-%s"
function ChallengeItemMixin:UpdateExpandedDisplay()
	local isActive = self:IsChallengeActive()
	if self:IsExpanded() then
		self.SelectedHighlight:SetAtlas(format(challengeAtlasFormat, self.challenge.Artwork or "default", "selected", Const.TextureKit.IgnoreAtlasSize))
		self.SelectedHighlight:Show()
		if isActive then
			self:SetNormalAtlas(format(challengeAtlasFormat, self.challenge.Artwork or "default", "active-selected"))
			if ChallengesUI:IsSelectingChallenge() then
				self.ExtendedInfo.ActivateButton:SetText(SELECT)
			elseif self:IsPartOfCustomChallenge() then
				self.ExtendedInfo.ActivateButton:SetText(REMOVE)
			else
				self.ExtendedInfo.ActivateButton:SetText(DEACTIVATE)
			end
		else
			self:SetNormalAtlas(format(challengeAtlasFormat, self.challenge.Artwork or "default", "inactive-selected"))
			if ChallengesUI:IsSelectingChallenge() then
				self.ExtendedInfo.ActivateButton:SetText(SELECT)
			elseif self:IsPartOfCustomChallenge() then
				self.ExtendedInfo.ActivateButton:SetText(REMOVE)
			else
				self.ExtendedInfo.ActivateButton:SetText(ACTIVATE)
			end
		end
		self.ExtendedInfo:Show()
		self:UpdateExtendedTab()
	else
		self.SelectedHighlight:Hide()
		if isActive then
			self:SetNormalAtlas(format(challengeAtlasFormat, self.challenge.Artwork or "default", "active"))
		else
			self:SetNormalAtlas(format(challengeAtlasFormat, self.challenge.Artwork or "default", "inactive"))
		end
		self.ExtendedInfo:Hide()
	end

	if self.IsLocked then
		self:GetNormalTexture():SetVertexColor(0.6, 0.6, 0.6)
	else
		self:GetNormalTexture():SetVertexColor(1, 1, 1)
	end

	self:GetNormalTexture():SetDesaturated(self.IsLocked)
end

function ChallengeItemMixin:OnSelected()
	PlaySound(SOUNDKIT.ABILITIESTURNPAGEA)
	self:SetExpandedTab(1)
	self:ToggleExpanded(320)
end

function ChallengeItemMixin:OnEnter()
	if self.IsLocked then
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(CHALLENGES_CANNOT_ACTIVATE)
		GameTooltip:AddLine(CHALLENGE_START_EXCLUSIVE_GROUP_ACTIVE, 1, 0, 0, true)
		GameTooltip:Show()
		return
	end
end

function ChallengeItemMixin:OnLeave()
	GameTooltip:Hide()
end

function ChallengeItemMixin:GetChallengeLevels()
	return C_Challenge.GetChallengeLevels(self.challenge.ID)
end

function ChallengeItemMixin:GetChallengeInfoByLevel()
	return self.challenge.Levels[self:GetSelectedLevel()]
end

function ChallengeItemMixin:CanActivateChallenge()
	return C_Challenge.CanActivateChallenge(self.challenge.ID, self:GetSelectedLevel())
end

function ChallengeItemMixin:CanDeactivateChallenge()
	return C_Challenge.CanDeactivateChallenge(self.challenge.ID)
end

function ChallengeItemMixin:IsChallengeActive()
	return C_Challenge.IsChallengeActive(self.challenge.ID)
end

function ChallengeItemMixin:StartChallenge()
	return C_Challenge.StartChallenge(self.challenge.ID, self:GetSelectedLevel())
end

function ChallengeItemMixin:StopChallenge()
	return C_Challenge.StopChallenge(self.challenge.ID)
end

function ChallengeItemMixin:ShowLevelSelection()
	return true
end