CollectionsMixin = CreateFromMixins(TabSystemMixin)

local function ShouldShowMysticEnchantTab()
	return not IsCustomClass() and not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)
end

function CollectionsMixin:OnLoad()
	self:SetupTabSystem()

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	-- auto show CoA talents
	if IsCustomClass() and C_Player:GetLevel() < COA_AUTO_SHOW_TALENTS_LEVEL then
		self:RegisterEvent("PLAYER_LEVEL_UP")
	end

	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	local uiScale = GetUIScale()
	if uiScale > 0.9 then
		uiScale = uiScale - 0.9
		self:SetScale(1 - uiScale)
	end
end

function CollectionsMixin:SetupTabSystem()
	TabSystemMixin.OnLoad(self)
	self:SetTabTemplate("CollectionTabTemplate")
	self:SetTabSelectedSound(SOUNDKIT.CHARACTER_SHEET_TAB_70)
	self:SetTabPoint("TOPLEFT", self, "BOTTOMLEFT", 12, 10)
	self:RegisterCallback("OnTabSelected", self.OnTabSelected, self)
	self.Tabs = {}
	
	-- Character Advancement Tab
	local tab
	do
		if IsCustomClass() then
			tab = self:AddTab(CHARACTER_ADVANCEMENT, "CoATalentFrame")
		else
			tab = self:AddTab(CHARACTER_ADVANCEMENT, "CharacterAdvancement")
		end
		tab:SetPreClick(CharacterAdvancement_LoadUI)
		tab:SetIcon("Interface\\Icons\\spell_Paladin_divinecircle")
		tab:SetTooltip(CHARACTER_ADVANCEMENT, CHARACTER_ADVANCEMENT_TOOLTIP)
		self.Tabs.CharacterAdvancement = tab:GetTabID()
	end
	
	-- Hero Architect Tab
	local isHero = C_Player:IsHero()

	if isHero then
		tab = self:AddTab(HERO_ARCHITECT, "BuildCreatorFrame")
		tab:SetPreClick(BuildCreator_LoadUI)
		tab:SetIcon("Interface\\Icons\\ability_priest_angelicfeather")
		tab:SetTooltip(HERO_ARCHITECT, HERO_ARCHITECT_TOOLTIP)
		self.Tabs.HeroArchitect = tab:GetTabID()
	end

	-- Skill Card Tab
	if isHero then
		tab = self:AddTab(UNLOCK_SKILL_CARDS_TITLE, "SkillCardsFrame")
		tab:SetPreClick(SkillCards_LoadUI)
		tab:SetIcon("Interface\\Icons\\inv_inscription_darkmooncard_putrescence")
		tab:SetTooltip(UNLOCK_SKILL_CARDS_TITLE, BOOSTER_TAB_SUBTEXT)
		self.Tabs.SkillCards = tab:GetTabID()
	end
	
	-- Vanity Tab
	do
		tab = self:AddTab(VANITY, "StoreCollectionFrame")
		tab:SetPreClick(VanityCollection_LoadUI)
		tab:SetIcon("Interface\\icons\\INV_Chest_Awakening")
		tab:SetTooltip(VANITY, VANITY_TOOLTIP)
		self.Tabs.Vanity = tab:GetTabID()
	end

	-- Mystic Enchanting Tab
	if not IsCustomClass() then -- coa does not have mystic enchants
		tab = self:AddTab(MYSTIC_ENCHANT, "EnchantCollection")
		tab:SetPreClick(MysticEnchant_LoadUI)
		tab:SetIcon("Interface\\icons\\inv_custom_ReforgeToken")
		tab:SetTooltip(MYSTIC_ENCHANT, MYSTIC_ENCHANT_TOOLTIP)
		self.Tabs.MysticEnchants = tab:GetTabID()
	end
	
	-- Wardrobe Tab
	do
		tab = self:AddTab(WARDROBE, "AppearanceWardrobeFrame")
		tab:SetPreClick(AppearanceUI_LoadUI)
		tab:SetIcon("Interface\\Icons\\inv_arcane_orb")
		tab:SetTooltip(WARDROBE, WARDROBE_TOOLTIP)
		self.Tabs.Wardrobe = tab:GetTabID()
	end
end

function CollectionsMixin:OnTabSelected(tabID, tab)
	local panel = self:GetPanelForTabID(tabID)
	if panel then
		local sizeX, sizeY = panel:GetSize()
		
		local tabX = 12
		-- @andrew
		-- hack fix: some panels seem to have sizes bigger than the art randomly
		--so tab Y needs to be changed to match per tab
		local tabY = 10
		if tabID == self.Tabs.Wardrobe then
			tabY = 2
		elseif tabID == self.Tabs.Vanity then
			sizeY = sizeY + 50
			sizeX = sizeX + 80
		end
		
		self:SetSize(sizeX, sizeY)
		self:SetTabPoint("TOPLEFT", self, "BOTTOMLEFT", tabX, tabY)
		self:UpdateTabLayout()
	end
end

function CollectionsMixin:OnShow()
	-- nov 26th 2023 @andrew
	-- huge issue where `toplevel="true"` would cause this frame to climb level every time staticpopup was shown while this was open
	-- it was then saved in layout-cache.txt and persists on that character indefinitely. 
	-- extremely high levels (like 200k+) cause fps issues
	self:SetFrameLevel(MainMenuBarOverlayFrame:GetFrameLevel()+1)
	PlaySound(SOUNDKIT.CHARACTER_SHEET_OPEN_70)
	if Draft then
		Draft:HideCards()
	end
	UpdateMicroButtons()
	
	-- disable character advancement tab if player is a coa class and not level 10+
	local caTab = self:GetCharacterAdvancementTab()
	caTab:SetTabEnabled(not IsCustomClass() or C_Player:GetLevel() >= COA_AUTO_SHOW_TALENTS_LEVEL, format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, COA_AUTO_SHOW_TALENTS_LEVEL))
	
	-- disable enchanting tab if player is not 60+, is not prestiged, and has not opened the ui before
	local enchantTab = self:GetMysticEnchantTab()
	if enchantTab then
		if ShouldShowMysticEnchantTab() then
			self:ShowTabID(self.Tabs.MysticEnchants)
			enchantTab:SetTabEnabled(MysticEnchantUtil.HasUnlockedEnchantTab(), format(MYSTIC_ENCHANTING_ALTAR_UNLOCK, 60))
		else
			self:HideTabID(self.Tabs.MysticEnchants)
			if self:GetCurrentTabID() == self.Tabs.MysticEnchants then
				self:SelectTabID(self.Tabs.CharacterAdvancement)
			end
		end
	end

	-- skill card tab only shown in draft/wildcard
	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) or C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
		self:ShowTabID(self.Tabs.SkillCards)
	else
		self:HideTabID(self.Tabs.SkillCards)
	end
	
	HelpTip:Acknowledge("WARDROBE_CHANGE_TRANSMOG_HINT")
end

function CollectionsMixin:OnHide()
	PlaySound(SOUNDKIT.CHARACTER_SHEET_CLOSE_70)
	self:HideCurrentPanel()
	UpdateMicroButtons()
end

function CollectionsMixin:PLAYER_REGEN_DISABLED()
	HideUIPanel(self)
end

function CollectionsMixin:GetCharacterAdvancementTab()
	return self:GetTabByID(self.Tabs.CharacterAdvancement)
end

function CollectionsMixin:GetMysticEnchantTab()
	return self:GetTabByID(self.Tabs.MysticEnchants)
end

function CollectionsMixin:GetTransmogTab()
	return self:GetTabByID(self.Tabs.Wardrobe)
end

function CollectionsMixin:GoToTab(id)
	if not id then return end
	if id == self.Tabs.MysticEnchants and not ShouldShowMysticEnchantTab() then
		id = self.Tabs.CharacterAdvancement
	end
	ShowUIPanel(self)
	self:SelectTabID(id)
	UpdateMicroButtons()
end

function CollectionsMixin:IsOnTab(id)
	return self:IsShown() and self:GetCurrentTabID() == id
end

function CollectionsMixin:PLAYER_LEVEL_UP(level)
	if level < COA_AUTO_SHOW_TALENTS_LEVEL then
		return
	end
	
	Timer.AfterCombat(function()
		Timer.After(2, function()
			C_PopupQueue:Add(self, function() self:GoToTab(Collections.Tabs.CharacterAdvancement) end, function() return not self:IsVisible() end)
		end)
	end)
	
	self:UnregisterEvent("PLAYER_LEVEL_UP")
end
