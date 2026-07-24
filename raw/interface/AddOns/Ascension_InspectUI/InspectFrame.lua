InspectFrameMixin = {}

local EXPANDED_WIDTH = 574
local COLLAPSED_WIDTH = 384

local function ShouldShowMysticEnchantTab(unit)
	return not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) and not IsCustomClass(unit)
end

function InspectFrameMixin:OnLoad()
	InspectFrame = self
	self.TitleText:SetFontObject(GameFontHighlight)
	self.unit = "target"
	self.Tabs = {}
	self.SideTabs = {}
	MixinAndLoadScripts(self, "TabSystemMixin")
	self:SetupTabSystem()
	self:SetupSideTabSystem()
end

function InspectFrameMixin:SetupTabSystem()
	self:SetTabPoint("TOPLEFT", self, "BOTTOMLEFT", 12, 4)
	self:SetTabTemplate("AscensionInspectFrameTabTemplate")
	self:RegisterCallback("OnTabSelected", self.OnTabSelected, self)
	self:SetTabSelectedSound(SOUNDKIT.UCHARACTERSHEETTAB)

	local tab = self:AddTab(CHARACTER, "InspectPaperDollPanel")
	self.Tabs.Character = tab:GetTabID()

	tab = self:AddTab(PVP, "InspectPvPPanel")
	self.Tabs.PvP = tab:GetTabID()

	if C_Config.GetBoolConfig("CONFIG_CHARACTER_ADVANCEMENT_BUILD_INSPECT_ENABLED") then
		tab = self:AddTab(BUILD, "InspectBuildPanel")
		self.Tabs.Build = tab:GetTabID()
	end
end

function InspectFrameMixin:SetupSideTabSystem()
	MixinAndLoadScripts(self.RightInset, "TabSystemMixin")
	local tabSystem = self.RightInset
	tabSystem:SetTabPoint("BOTTOMLEFT", tabSystem, "TOPLEFT", 12, -2)
	tabSystem:SetTabTemplate("AscensionInspectFrameSideTabTemplate")
	tabSystem:SetTabSelectedSound(SOUNDKIT.UCHARACTERSHEETTAB)
	tabSystem:SetTabPadding(-2, 0)

	local tab = tabSystem:AddTab("", "InspectStatsPanel")
	tab:SetTextPadding(10)
	tab:SetTooltip(PAPERDOLL_SIDEBAR_STATS, PAPERDOLL_SIDEBAR_STATS_TOOLTIP)
	self.StatsTab = tab
end

function InspectFrameMixin:OnShow()
	--[[if not self:CanInspectUnit() then
		return self:Hide()
	end]]
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	self:RegisterEvent("MYSTIC_ENCHANT_INSPECT_RESULT")
	self:UpdateCharacterInfo()
	self:SelectFirstEnabledTab()
	self:UpdateMysticEnchantTab()
	self.RightInset:SelectFirstEnabledTab()
end

function InspectFrameMixin:OnHide()
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
	self:UnregisterEvent("UNIT_NAME_UPDATE")
	self:UnregisterEvent("UNIT_PORTRAIT_UPDATE")
	self:UnregisterEvent("MYSTIC_ENCHANT_INSPECT_RESULT")
	self:SelectFirstEnabledTab()
	ClearInspectPlayer()
end

function InspectFrameMixin:OnEvent(event, ...)
	if not self:IsShown() then
		return
	end
	if self.unit and (event == "PLAYER_TARGET_CHANGED" or event == "PARTY_MEMBERS_CHANGED") then
		if (event == "PLAYER_TARGET_CHANGED" and self.unit == "target" or
				event == "PARTY_MEMBERS_CHANGED" and self.unit ~= "target") then
			if CanInspect(self.unit) then
				self:InspectUnit(self.unit)
			else
				HideUIPanel(self)
			end
		end
		return
	elseif event == "UNIT_NAME_UPDATE" or event == "UNIT_PORTAIT_UPDATE" then
		local unit = ...
		if self:IsUnit(unit) then
			self:UpdateCharacterInfo()
		end
		return
	elseif event == "MYSTIC_ENCHANT_INSPECT_RESULT" then
		self:UpdateCharacterInfo()
	end
end

function InspectFrameMixin:InspectUnit(unit)
	_NotifyInspect(unit)
	self:SetUnit(unit)
	if self:IsShown() then
		self:OnShow()
	else
		ShowUIPanel(self)
	end
end

function InspectFrameMixin:UpdateCharacterInfo()
	local class, classFile = UnitClass(self.unit)
	local isHero = classFile == "HERO"
	self.StatsTab:SetIconToPortrait(self.unit)

	local specName, specIcon = UnitSpecAndIcon(self.unit)

	PortraitFrame_SetIcon(self, specIcon)
	PortraitFrame_SetTitle(self, UnitPVPName(self.unit))

	local color = RAID_CLASS_COLORS[classFile] or WHITE_FONT_COLOR

	-- prefix class with spec name for non hero
	if not isHero and specName ~= class then
		class = specName .. " " .. class
	end

	local coloredClass = color:WrapText(class)

	-- add new line suffix of legendary enchant for hero
	if isHero and specName ~= class then
		-- legendary enchant 
		coloredClass = coloredClass .. "\n" .. ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]:WrapText(specName)
	end
	local level = UnitLevel(self.unit)
	if level <= 0 then
		level = "??"
	end

	self.ClassLevelLabel:SetFormattedText(PLAYER_LEVEL, level, WHITE_FONT_COLOR:WrapText(UnitRace(self.unit)), coloredClass)

	if not ShouldShowMysticEnchantTab(self.unit) then
		if self.MysticEnchantTab then
			self.MysticEnchantTab:Hide()
		end
		self.RightInset:SelectTabID(self.StatsTab:GetTabID())
	elseif self.MysticEnchantTab then
		if self.RightInset:GetCurrentTabID() ~= self.MysticEnchantTab:GetTabID() then
			self.RightInset:SelectTabID(self.MysticEnchantTab:GetTabID())
		end
	end
end

function InspectFrameMixin:SetUnit(unit)
	self.unit = unit
	local paperDoll = self:GetPanelForTabID(self.Tabs.Character)
	paperDoll:SetUnit(unit)
	InspectMysticEnchantPanel:SetUnit(unit)
	InspectStatsPanel:SetUnit(unit)
	InspectStatsPanel:ScheduleUpdate()
end

function InspectFrameMixin:GetUnit()
	return self.unit
end

function InspectFrameMixin:IsUnit(unit)
	return unit and self.unit and UnitIsUnit(self.unit, unit)
end

function InspectFrameMixin:CanInspectUnit()
	return CanInspect(self.unit) and UnitExists(self.unit) and UnitIsVisible(self.unit)
end

function InspectFrameMixin:UpdateMysticEnchantTab()
	if not ShouldShowMysticEnchantTab(self.unit) then
		if self.MysticEnchantTab then
			self.MysticEnchantTab:Hide()
		end
		if self.RightInset:GetCurrentTabID() ~= self.StatsTab:GetTabID() then
			self.RightInset:SelectTabID(self.StatsTab:GetTabID())
		end
	else
		if not self.MysticEnchantTab then
			local tab = self.RightInset:AddTab("", "InspectMysticEnchantPanel")
			tab:SetIconAtlas("paperdoll-mystic-enchant-tab")
			tab:SetTextPadding(10)
			tab:SetTooltip(PAPERDOLL_SIDEBAR_MYSTIC_ENCHANTS, PAPERDOLL_SIDEBAR_MYSTIC_ENCHANTS_TOOLTIP)
			self.MysticEnchantTab = tab
		else
			self.MysticEnchantTab:Show()
		end

		if C_MysticEnchant.CanInspect(self.unit) then
			C_MysticEnchant.Inspect(self.unit, true)
		end
	end
end

function InspectFrameMixin:OnTabSelected(tabID)
	if tabID == 1 then
		self:Expand(true)
		self.ClassLevelLabel:Show()
		InspectStatsPanel:ScheduleUpdate()
	elseif tabID == 3 then
		self:Expand(false)
		self.ClassLevelLabel:Show()
	else
		self:Collapse()
		self.ClassLevelLabel:Hide()
	end
end

function InspectFrameMixin:Expand(showRightInset)
	self:SetWidth(EXPANDED_WIDTH)
	if showRightInset then
		self.RightInset:Show()
		self.RightInset:ShowCurrentPanel()
	else
		self.RightInset:Hide()
		self.RightInset:HideCurrentPanel()
	end
end

function InspectFrameMixin:Collapse()
	self:SetWidth(COLLAPSED_WIDTH)
	self.RightInset:Hide()
end
