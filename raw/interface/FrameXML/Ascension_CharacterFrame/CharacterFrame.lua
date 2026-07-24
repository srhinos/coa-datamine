CharacterFrameMixin = CreateFromMixins(TabSystemMixin)
local EXPANDED_WIDTH = 574
local COLLAPSED_WIDTH = 384

function CharacterFrameMixin:OnLoad()
	self:RegisterEvent("COMPANION_LEARNED")
	self:RegisterEvent("COMPANION_UNLEARNED")
	self.TitleText:SetFontObject(GameFontHighlight)
	self.Tabs = {}
	self.SideTabs = {}
	MixinAndLoadScripts(self, "TabSystemMixin")
	self:SetupTabSystem()
	self:SetupSideTabSystem()
end

function CharacterFrameMixin:SetupTabSystem()
	self:SetTabPoint("TOPLEFT", self, "BOTTOMLEFT", 12, 4)
	self:SetTabTemplate("AscensionCharacterFrameTabTemplate")
	self:RegisterCallback("OnTabSelected", self.OnTabSelected, self)
	self:SetTabSelectedSound(SOUNDKIT.UCHARACTERSHEETTAB)

	local tab = self:AddTab(CHARACTER, "AscensionPaperDollPanel")
	tab:SetTooltip(GenerateClosure(MicroButtonTooltipText, CHARACTER_INFO, "TOGGLECHARACTER0"))
	self.Tabs.Character = tab:GetTabID()

	tab = self:AddTab(PETS, "AscensionPetPaperDollPanel")
	tab:SetTooltip(GenerateClosure(MicroButtonTooltipText, PETS, "TOGGLECHARACTER3"))
	self.Tabs.Pets = tab:GetTabID()

	tab = self:AddTab(REPUTATION_ABBR, "AscensionReputationPanel")
	tab:SetTooltip(GenerateClosure(MicroButtonTooltipText, REPUTATION, "TOGGLECHARACTER2"))
	self.Tabs.Reputation = tab:GetTabID()

	tab = self:AddTab(SKILLS_ABBR, "AscensionSkillsPanel")
	tab:SetTooltip(GenerateClosure(MicroButtonTooltipText, SKILLS, "TOGGLECHARACTER1"))
	self.Tabs.Skills = tab:GetTabID()

	tab = self:AddTab(CURRENCY, "AscensionCurrencyPanel")
	tab:SetTooltip(GenerateClosure(MicroButtonTooltipText, CURRENCY, "TOGGLECURRENCY"))
	self.Tabs.Currency = tab:GetTabID()
end

function CharacterFrameMixin:SetupSideTabSystem()
	local customClass = IsCustomClass()
	MixinAndLoadScripts(self.RightInset, "TabSystemMixin")

	local tabSystem = self.RightInset
	tabSystem:SetTabPoint("BOTTOMLEFT", tabSystem, "TOPLEFT", customClass and 32 or 12, -2)
	tabSystem:SetTabTemplate("AscensionCharacterFrameSideTabTemplate")
	tabSystem:SetTabSelectedSound(SOUNDKIT.UCHARACTERSHEETTAB)
	tabSystem:SetTabPadding(-2, 0)

	local tab = tabSystem:AddTab("", "AscensionCharacterStatsPanel")
	tab:SetIconToPortrait()
	tab:SetTextPadding(10)
	tab:SetTooltip(PAPERDOLL_SIDEBAR_STATS, PAPERDOLL_SIDEBAR_STATS_TOOLTIP)
	self.CharacterStatsTab = tab

	tab = tabSystem:AddTab("", "AscensionCharacterTitlesPanel")
	tab:SetIconAtlas("paperdoll-title-tab")
	tab:SetTextPadding(10)
	tab:SetTooltip(PAPERDOLL_SIDEBAR_TITLES, PAPERDOLL_SIDEBAR_TITLES_TOOLTIP)

	tab = tabSystem:AddTab("", "AscensionCharacterEquipmentManagerPanel")
	tab:SetIconAtlas("paperdoll-equipment-manager-tab")
	tab:SetTextPadding(10)
	tab:SetTooltip(EQUIPMENT_MANAGER, NEWBIE_TOOLTIP_EQUIPMENT_MANAGER)

	if not customClass then
		tab = tabSystem:AddTab("", "AscensionCharacterMysticEnchantPanel")
		tab:SetIconAtlas("paperdoll-mystic-enchant-tab")
		tab:SetTextPadding(10)
		tab:SetTooltip(PAPERDOLL_SIDEBAR_MYSTIC_ENCHANTS, PAPERDOLL_SIDEBAR_MYSTIC_ENCHANTS_TOOLTIP)
        self.EnchantSideTab = tab
	end
end

function CharacterFrameMixin:OnShow()
	self:RegisterEvent("MYSTIC_ENCHANT_SLOT_UPDATE")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	self:RegisterEvent("PLAYER_PVP_RANK_CHANGED")
	self:RegisterEvent("UNIT_LEVEL")

	self:UpdateCharacterInfo()
	self:SelectFirstEnabledTab()
	self.RightInset:SelectFirstEnabledTab()

	UpdateMicroButtons()
	PlayerFrameHealthBar.showNumeric = true
	PlayerFrameManaBar.showNumeric = true
	PlayerFrameAlternateManaBar.showNumeric = true
	MainMenuExpBar.showNumeric = true
	PetFrameHealthBar.showNumeric = true
	PetFrameManaBar.showNumeric = true
	ShowTextStatusBarText(PlayerFrameHealthBar)
	ShowTextStatusBarText(PlayerFrameManaBar)
	ShowTextStatusBarText(PlayerFrameAlternateManaBar)
	ShowTextStatusBarText(MainMenuExpBar)
	ShowTextStatusBarText(PetFrameHealthBar)
	ShowTextStatusBarText(PetFrameManaBar)
	ShowWatchedReputationBarText()

	SetButtonPulse(CharacterMicroButton, 0, 1)	--Stop the button pulse

    if self.EnchantSideTab then
        self.EnchantSideTab:SetTabEnabled(C_Player:GetLevel() >= 10, string.format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, 10))
    end
end

function CharacterFrameMixin:OnHide()
	PlaySound(SOUNDKIT.CHARACTER_SHEET_CLOSE)
	self:UnregisterEvent("MYSTIC_ENCHANT_SLOT_UPDATE")
	self:UnregisterEvent("UNIT_NAME_UPDATE")
	self:UnregisterEvent("UNIT_PORTRAIT_UPDATE")
	self:UnregisterEvent("PLAYER_PVP_RANK_CHANGED")
	self:UnregisterEvent("UNIT_LEVEL")

	UpdateMicroButtons()
	PlayerFrameHealthBar.showNumeric = nil
	PlayerFrameManaBar.showNumeric = nil
	PlayerFrameAlternateManaBar.showNumeric = nil
	MainMenuExpBar.showNumeric =nil
	PetFrameHealthBar.showNumeric = nil
	PetFrameManaBar.showNumeric = nil
	HideTextStatusBarText(PlayerFrameHealthBar)
	HideTextStatusBarText(PlayerFrameManaBar)
	HideTextStatusBarText(PlayerFrameAlternateManaBar)
	HideTextStatusBarText(MainMenuExpBar)
	HideTextStatusBarText(PetFrameHealthBar)
	HideTextStatusBarText(PetFrameManaBar)
	HideWatchedReputationBarText()
end

function CharacterFrameMixin:UpdateCharacterInfo()
	local class, classFile = UnitClass("player")
	local isHero = classFile == "HERO"
	local enableMysticEnchantSpec = C_Config.GetBoolConfig("CONFIG_RANDOM_ENCHANT_DISPLAY_LEGENDARY_ENCHANT_ON_CHARACTER_SHEET_ENABLED")
	self.CharacterStatsTab:SetIconToPortrait()

	local specName, specIcon = UnitSpecAndIcon("player")

	if not isHero or enableMysticEnchantSpec then
		PortraitFrame_SetIcon(self, specIcon)
	else
		PortraitFrame_SetIcon(self, "Interface\\Icons\\classicon_hero")
	end
	PortraitFrame_SetTitle(self, UnitPVPName("player"))

	local color = RAID_CLASS_COLORS[classFile] or WHITE_FONT_COLOR

	-- prefix class with spec name for non hero
	if not isHero and specName ~= class then
		class = specName .. " " .. class
	end

	local coloredClass = color:WrapText(class)

	-- add new line suffix of legendary enchant for hero
	if isHero and specName ~= class and enableMysticEnchantSpec then
		-- legendary enchant 
		coloredClass = coloredClass .. "\n" .. ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]:WrapText(specName)
	end
	
	self.ClassLevelLabel:SetFormattedText(PLAYER_LEVEL, UnitLevel("player"), WHITE_FONT_COLOR:WrapText(UnitRace("player")), coloredClass)
end

function CharacterFrameMixin:OnEvent(event, ...)
	local unit = ...
	if event == "COMPANION_LEARNED" or event == "COMPANION_UNLEARNED" then
		if not self:IsVisible() then
			SetButtonPulse(CharacterMicroButton, 60, 1)
		end
	end
	if not unit or unit == "player" or event == "MYSTIC_ENCHANT_SLOT_UPDATE" then
		self:UpdateCharacterInfo()
	end
end

function CharacterFrameMixin:OnTabSelected(tabID)
	if tabID == 1 then
		self:Expand()
		-- might be hidden by pet side panels
		self:ShowSideTabs()

		self.ClassLevelLabel:Show()
		AscensionCharacterCompanionPanel:Hide()
		AscensionCharacterStatsPanel:SetUnit("player")
		AscensionCharacterStatsPanel:ScheduleUpdate()
	elseif tabID == 2 then
		-- tab2 (pets) handles char frame size itself
		self.ClassLevelLabel:Hide()
	else
		AscensionCharacterCompanionPanel:Hide()
		self:Collapse()
		self.ClassLevelLabel:Hide()
	end
end

function CharacterFrameMixin:Expand()
	self:SetWidth(EXPANDED_WIDTH)
	self.RightInset:Show()
end

function CharacterFrameMixin:Collapse()
	self:SetWidth(COLLAPSED_WIDTH)
	self.RightInset:Hide()
end

function CharacterFrameMixin:HideSideTabs()
	self.RightInset:HideTabs()
end

function CharacterFrameMixin:ShowSideTabs()
	self.RightInset:ShowTabs()
	self.RightInset:ShowCurrentPanel()
end

function CharacterFrameMixin:ShowStatsPanel()
	AscensionCharacterCompanionPanel:Hide()
	self.RightInset:SelectFirstEnabledTab()
end

function CharacterFrameMixin:ShowCompanionPanel()
	self.RightInset:HideCurrentPanel()
	AscensionCharacterCompanionPanel:Show() -- not part of tab system
end

--
-- Side Tab Mixin
--
CharacterFrameSideTabMixin = CreateFromMixins(TabSystemTabMixin)

function CharacterFrameSideTabMixin:SetIconAtlas(icon)
	self.Icon:SetAtlas(icon)
	self.Icon:SetBlendMode("BLEND")
end

function CharacterFrameSideTabMixin:SetIconToPortrait(unit)
	self.Icon:SetTexCoord(0, 1, 0, 1)
	self.Icon:SetPortraitUnit(unit or "player")
	self.Icon:SetBlendMode("ADD")
end

function CharacterFrameSideTabMixin:OnSelected()
	self.Icon:SetAlpha(0.9)
end

function CharacterFrameSideTabMixin:OnDeselected()
	self.Icon:SetAlpha(0.6)
end 

--
-- Globals
--

local TabRemap = {
	PaperDollFrame = "AscensionPaperDollPanel",
	PetPaperDollFrame = "AscensionPetPaperDollPanel", 
	SkillFrame = "AscensionSkillsPanel",
	ReputationFrame = "AscensionReputationPanel",
	TokenFrame = "AscensionCurrencyPanel",
}

function ToggleCharacter(tab)
	tab = TabRemap[tab] or tab

	local tabButton = AscensionCharacterFrame:GetTabForPanel(tab)
	if tabButton then
		local tabID = tabButton:GetTabID()
		if AscensionCharacterFrame:IsShown() and AscensionCharacterFrame:GetCurrentTabID() == tabID then
			HideUIPanel(AscensionCharacterFrame)
		else
			ShowUIPanel(AscensionCharacterFrame)
			AscensionCharacterFrame:SelectTabID(tabID)
		end
	end
end

function GetCharacterFrameSidePanelBackgroundAtlas(unit)
	local _, class = UnitClass(unit)
	local background = "UI-Character-Info-"..(class or "WARRIOR").."-BG"
	if not AtlasUtil:AtlasExists(background) then
		background = "UI-Character-Info-Warrior-BG"
	end

	return background
end