GamemodesTabMixin = {}

local GameModeData = {
	{
		mask = Enum.GameMode.BuildDraft,
		toggle = ToggleBuildDraftMode,
		canToggle = CanToggleBuildDraftMode,
		confirmDeactivate = true,
		confirmActivate = true,
		deactivatePopup = "BUILD_DRAFT_DEACTIVATE_CONFIRM",
		activatePopup = "BUILD_DRAFT_ACTIVATE_CONFIRM",
		title = BUILDDRAFT_MODE,
		description = BUILDDRAFT_MODE_DESC,
		config = "CONFIG_BUILD_DRAFT_ENABLED",
		hidden = "CONFIG_BUILD_DRAFT_HIDDEN",
		icon = "Interface\\Icons\\ability_priest_angelicfeather",
		artwork = "builddraft",
		rewards = {
			{ configItemID = "CONFIG_BUILD_DRAFT_REWARD_ITEM1", configAmount = "CONFIG_BUILD_DRAFT_REWARD_AMOUNT1" },
			{ configItemID = "CONFIG_BUILD_DRAFT_REWARD_ITEM2", configAmount = "CONFIG_BUILD_DRAFT_REWARD_AMOUNT2" },
			{ configItemID = "CONFIG_BUILD_DRAFT_REWARD_ITEM3", configAmount = "CONFIG_BUILD_DRAFT_REWARD_AMOUNT3" },
			{ configItemID = "CONFIG_BUILD_DRAFT_REWARD_ITEM4", configAmount = "CONFIG_BUILD_DRAFT_REWARD_AMOUNT4" },
			{ itemID = ItemData.BUILD_MASTERS_TROPHY, amount = 1 },
		}
	},
	{
		mask = Enum.GameMode.Ironman,
		toggle = ToggleIronmanMode,
		canToggle = CanToggleIronmanMode,
		title = IRONMAN_MODE,
		description = IRONMAN_MODE_DESC,
		config = "CONFIG_IRONMAN_ENABLE",
		hidden = "CONFIG_IRONMAN_HIDDEN",
		icon = "Interface\\Icons\\Ability_Warrior_ImprovedDisciplines",
		artwork = "ironman"
	},
	{
		mask = Enum.GameMode.Survivalist,
		toggle = ToggleSurvivalistMode,
		canToggle = CanToggleSurvivalistMode,
		title = SURVIVALIST_MODE,
		description = SURVIVALIST_MODE_DESC,
		config = "CONFIG_SURVIALIST_ENABLE", -- intentional typo
		hidden = "CONFIG_SURVIALIST_HIDDEN",
		icon = "Interface\\Icons\\Achievement_BG_KillFlagCarriers_grabFlag_CapIt",
		artwork = "hardcore",
	},
	{
		mask = Enum.GameMode.Draft,
		toggle = ToggleDraftMode,           -- sends new draft start/stop opcodes
		canToggle = CanToggleDraftMode,     -- validates new draft flow
		title = DRAFT_MODE,
		description = DRAFT_MODE_DESC,
		config = "CONFIG_DRAFT_ENABLE",
		hidden = "CONFIG_DRAFT_HIDDEN",
		icon = "Interface\\Icons\\inv_misc_dmc_destructiondeck",
		artwork = "draft",
	},
	{
		mask = Enum.GameMode.Resolute,
		toggle = ToggleResoluteMode,
		canToggle = CanToggleResoluteMode,
		title = RESOLUTE_MODE,
		description = RESOLUTE_MODE_DESC,
		config = "CONFIG_RESOLUTE_ENABLE",
		hidden = "CONFIG_RESOLUTE_HIDDEN",
		icon = "Interface\\Icons\\_d3slowtime",
		artwork = "resolute",
	},
	{
		mask = Enum.GameMode.WildCard,
		toggle = ToggleWildCardMode,
		canToggle = CanToggleWildCardMode,
		title = WILDCARD_MODE,
		description = WILDCARD_MODE_DESC,
		config = "CONFIG_WILD_CARD_ENABLE",
		hidden = "CONFIG_WILD_CARD_HIDDEN",
		icon = "Interface\\Icons\\misc_rune_pvp_random",
		artwork = "wildcard",
	},
	{
		mask = Enum.GameMode.Felforged,
		toggle = ToggleFelforgedMode,
		canToggle = CanToggleFelforgedMode,
		title = FELFORGED_MODE,
		description = FELFORGED_MODE_DESC,
		config = "CONFIG_FELFORGED_ENABLED",
		hidden = "CONFIG_FELFORGED_HIDDEN",
		icon = "Interface\\Icons\\spell_fire_felimmolation",
		artwork = "felforged"
	},
	{
		mask = Enum.GameMode.Nightmare,
		toggle = ToggleNightmareMode,
		canToggle = CanToggleNightmareMode,
		title = NIGHTMARE_MODE,
		description = NIGHTMARE_MODE_DESC,
		config = "CONFIG_NIGHTMARE_ENABLE",
		hidden = "CONFIG_NIGHTMARE_HIDDEN",
		icon = "Interface\\Icons\\sha_ability_rogue_bloodyeye_nightborne",
		artwork = "nightmare"
	},
	{
		mask = Enum.GameMode.Crusader,
		toggle = ToggleCrusaderMode,
		canToggle = CanToggleCrusaderMode,
		title = CRUSADER_MODE,
		description = CRUSADER_MODE_DESC,
		config = "CONFIG_CRUSADER_ENABLED",
		hidden = "CONFIG_CRUSADER_HIDDEN",
		icon = "Interface\\Icons\\ability_paladin_beaconoflight",
		artwork = "crusader",
	},
}
function GamemodesTabMixin:OnLoad()
	self.filteredGameModes = {}
	self.Challenges:SetTemplate("GameModeItemTemplate")
	self.Challenges:SetGetNumResultsFunction(function() return #self.filteredGameModes end)
	self.Challenges.Divider:SetAtlas("activities-divider", Const.TextureKit.IgnoreAtlasSize)

	local highlight = self.Challenges:GetSelectedHighlight()
	highlight:SetTexture() -- disable
	
	self:RegisterEvent("TOGGLE_GAME_MODE_RESULT")
	self:RegisterEvent("ASCENSION_CUSTOM_GAME_MODE_CHANGED")
end

function GamemodesTabMixin:UpdateFilteredChallenges()
	wipe(self.filteredGameModes)
	local search = self.Search:GetText():lower():trim()

	for _, gamemode in ipairs(GameModeData) do
		if not gamemode.deprecated and (C_GameMode:IsGameModeActive(gamemode.mask) or not C_Config.GetBoolConfig(gamemode.hidden)) then
			if search:len() == 0 or gamemode.title:lower():find(search, 1, true) or gamemode.description:lower():find(search, 1, true) then
				tinsert(self.filteredGameModes, gamemode)
			end
		end
	end
	
	self.Challenges:RefreshScrollFrame()
end

function GamemodesTabMixin:OnShow()
	self:UpdateFilteredChallenges()
end

function GamemodesTabMixin:TOGGLE_GAME_MODE_RESULT(response)
	self:UpdateFilteredChallenges()
	if response and response:endswith("_OK") then
		CloseChallengesUI()
	else
		ChallengesFrame.ErrorInputBlock:Show()
		response = S_SERVER_ERROR:format(_G[response] or response)
		ChallengesFrame.ErrorInputBlock:SetText(CHALLENGES_TOGGLE_GAME_MODE_FAILED, response)
	end
end

function GamemodesTabMixin:ASCENSION_CUSTOM_GAME_MODE_CHANGED()
	self:UpdateFilteredChallenges()
end

GameModeItemTemplate = CreateFromMixins(ScrollListItemBaseMixin)

local function ResetRewardIcon(pool, icon)
	icon.itemID = nil
	icon.tooltipTitle = nil
	icon.tooltipText = nil
	icon.countText = nil
	icon.achievementID = nil
	icon:ClearAllPoints()
	icon:Hide()
end

function GameModeItemTemplate:OnLoad()
	self:GetNormalTexture():SetDrawLayer("BACKGROUND")
	self:SetHighlightAtlas("addons_list_hover")
	self.LockedIcon:SetAtlas("honorsystem-bar-lock", Const.TextureKit.IgnoreAtlasSize)
	self.RewardIcons = CreateFramePool("BUTTON", self, "ChallengeRewardTemplate", ResetRewardIcon)
end

function GameModeItemTemplate:SetIcon(icon)
	self.Icon:SetTexture(icon)
	self.LockedIcon:SetShown(self.IsLocked)
	self.Icon:SetDesaturated(self.IsLocked)
	if C_GameMode:IsGameModeActive(self.gamemode.mask) then
		self.IconBorder:SetAtlas("collections-itemborder-collected", Const.TextureKit.IgnoreAtlasSize)
	else
		self.IconBorder:SetAtlas("collections-itemborder-uncollected", Const.TextureKit.IgnoreAtlasSize)
	end
end

function GameModeItemTemplate:SetName(name)
	self.name = name
	self.Text:SetText(name)
	if self.IsLocked then
		self.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
	else
		self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
	end

	self.ExtendedInfo.TabContent:SetTitle(name)
end

function GameModeItemTemplate:SetDescription(description)
	self.ExtendedInfo.TabContent:ShowAboutTab(description)
end

function GameModeItemTemplate:Update()
	local gamemode = self:GetScrollList():GetParent().filteredGameModes[self.index]
	self.gamemode = gamemode
	
	self.IsLocked = not gamemode.canToggle(not C_GameMode:IsGameModeActive(gamemode.mask)) or not C_Config.GetBoolConfig(gamemode.config)

	self:SetName(gamemode.title)
	self:SetDescription(gamemode.description)
	self:SetIcon(gamemode.icon)
	self:UpdateExpandedDisplay()
	self:SetRewards()
end

function GameModeItemTemplate:SetRewards()
	self.RewardIcons:ReleaseAll()
	local rewards = self.gamemode.rewards
	if not rewards then return end

	local x = -22
	local itemID, itemAmount
	for _, reward in ipairs(rewards) do
		if reward.configItemID then
			itemID = C_Config.GetIntConfig(reward.configItemID)
			itemAmount = C_Config.GetIntConfig(reward.configAmount)
		else
			itemID = reward.itemID
			itemAmount = reward.amount
		end

		if itemID and itemID > 0 then
			local rewardIcon = self.RewardIcons:Acquire()
			local item = Item:CreateFromID(itemID)
			rewardIcon:SetParent(self)
			rewardIcon.itemID = itemID
			rewardIcon.Icon:SetPortraitTexture(item:GetIcon())
			rewardIcon.IconBorder:SetAtlas(ITEM_QUALITY_ROUND_BORDER_ATLAS[item:GetQuality()])
			if itemAmount and itemAmount > 1 then
				rewardIcon.Count:SetText("x" .. itemAmount)
				rewardIcon.Count:Show()
			else
				rewardIcon.Count:Hide()
			end

			rewardIcon:SetPoint("TOPRIGHT", x, -25)
			x = x - 48
			rewardIcon:Show()
		end
	end
end

local challengeAtlasFormat = "challenges-%s-%s"
function GameModeItemTemplate:UpdateExpandedDisplay()
	local isActive = C_GameMode:IsGameModeActive(self.gamemode.mask)

	self.ExtendedInfo.ActivateButton:SetEnabled(not self.IsLocked)
	if self.IsLocked then
		self.ExtendedInfo.ActivateButton.disabledReasons = select(2, self.gamemode.canToggle(not C_GameMode:IsGameModeActive(self.gamemode.mask)))
	else
		self.ExtendedInfo.ActivateButton.disabledReasons = nil
	end

	if self:IsExpanded() then
		self.SelectedHighlight:SetAtlas(format(challengeAtlasFormat, self.gamemode.artwork or "default", "selected", Const.TextureKit.IgnoreAtlasSize))
		self.SelectedHighlight:Show()
		if isActive then
			self:SetNormalAtlas(format(challengeAtlasFormat, self.gamemode.artwork or "default", "active-selected"))
			self.ExtendedInfo.ActivateButton:SetText(DEACTIVATE)
		else
			self:SetNormalAtlas(format(challengeAtlasFormat, self.gamemode.artwork or "default", "inactive-selected"))
			self.ExtendedInfo.ActivateButton:SetText(ACTIVATE)
		end
		self.ExtendedInfo:Show()
	else
		self.SelectedHighlight:Hide()
		if isActive then
			self:SetNormalAtlas(format(challengeAtlasFormat, self.gamemode.artwork or "default", "active"))
		else
			self:SetNormalAtlas(format(challengeAtlasFormat, self.gamemode.artwork or "default", "inactive"))
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

function GameModeItemTemplate:OnSelected()
	PlaySound(SOUNDKIT.ABILITIESTURNPAGEA)
	self:ToggleExpanded(320)
end

function GameModeItemTemplate:ToggleGameMode()
	local enable = not C_GameMode:IsGameModeActive(self.gamemode.mask)
	if self.gamemode.confirmDeactivate and not enable then
		local deactivate = GenerateClosure(self.gamemode.toggle, false)
		StaticPopup_Show(self.gamemode.deactivatePopup, nil, nil, deactivate)
	elseif self.gamemode.confirmActivate and enable then
		local activate = GenerateClosure(self.gamemode.toggle, true)
		StaticPopup_Show(self.gamemode.activatePopup, nil, nil, activate)
	else
		self.gamemode.toggle(enable)
	end
end

