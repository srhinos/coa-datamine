PetPaperDollPanelMixin = {}

function PetPaperDollPanelMixin:OnLoad()
	self:SetupTabSystem()
	self.CompanionTab.CompanionModel:SetCamera(1)
end

function PetPaperDollPanelMixin:SetupTabSystem()
	MixinAndLoadScripts(self, "TabSystemMixin")
	self:SetTabPoint("BOTTOMLEFT", self, "TOPLEFT", 54, -2)
	self:SetTabTemplate("AscensionPetPaperDollTabTemplate")
	self:RegisterCallback("OnTabSelected", self.OnTabSelected, self)
	self:SetTabSelectedSound(SOUNDKIT.UCHARACTERSHEETTAB)

	local tab = self:AddTab(PET, self.PetTab)
	--tab:SetTooltip(GenerateClosure(MicroButtonTooltipText, CHARACTER_INFO, "TOGGLECHARACTER0"))
	tab = self:AddTab(COMPANIONS, self.CompanionTab)
	tab = self:AddTab(MOUNTS, self.CompanionTab)
end 

function PetPaperDollPanelMixin:OnShow()
	self:RegisterEvent("PET_UI_UPDATE")
	self:RegisterEvent("PET_BAR_UPDATE")
	self:RegisterEvent("PET_UI_CLOSE")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_MODEL_CHANGED")
	self:RegisterEvent("UNIT_LEVEL")
	self:RegisterEvent("UNIT_RESISTANCES")
	self:RegisterEvent("UNIT_STATS")
	self:RegisterEvent("UNIT_DAMAGE")
	self:RegisterEvent("UNIT_RANGEDDAMAGE")
	self:RegisterEvent("UNIT_ATTACK_SPEED")
	self:RegisterEvent("UNIT_ATTACK_POWER")
	self:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:RegisterEvent("UNIT_DEFENSE")
	self:RegisterEvent("UNIT_ATTACK")
	self:RegisterEvent("UNIT_HAPPINESS")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("COMPANION_LEARNED")
	self:RegisterEvent("COMPANION_UNLEARNED")
	self:RegisterEvent("COMPANION_UPDATE")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("UNIT_ENTERED_VEHICLE")
	self:RegisterEvent("UNIT_EXITED_VEHICLE")
	self:RegisterEvent("PET_SPELL_POWER_UPDATE")
	self:RefreshTabs()
	self:SelectFirstEnabledTab()
end

function PetPaperDollPanelMixin:OnHide()
	self:UnregisterEvent("COMPANION_UPDATE")
	self:UnregisterEvent("PET_UI_UPDATE")
	self:UnregisterEvent("PET_BAR_UPDATE")
	self:UnregisterEvent("PET_UI_CLOSE")
	self:UnregisterEvent("UNIT_NAME_UPDATE")
	self:UnregisterEvent("UNIT_PET")
	self:UnregisterEvent("UNIT_MODEL_CHANGED")
	self:UnregisterEvent("UNIT_LEVEL")
	self:UnregisterEvent("UNIT_RESISTANCES")
	self:UnregisterEvent("UNIT_STATS")
	self:UnregisterEvent("UNIT_DAMAGE")
	self:UnregisterEvent("UNIT_RANGEDDAMAGE")
	self:UnregisterEvent("UNIT_ATTACK_SPEED")
	self:UnregisterEvent("UNIT_ATTACK_POWER")
	self:UnregisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:UnregisterEvent("UNIT_DEFENSE")
	self:UnregisterEvent("UNIT_ATTACK")
	self:UnregisterEvent("UNIT_HAPPINESS")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("COMPANION_LEARNED")
	self:UnregisterEvent("COMPANION_UNLEARNED")
	self:UnregisterEvent("COMPANION_UPDATE")
	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
	self:UnregisterEvent("UNIT_ENTERED_VEHICLE")
	self:UnregisterEvent("UNIT_EXITED_VEHICLE")
	self:UnregisterEvent("PET_SPELL_POWER_UPDATE")
end

function PetPaperDollPanelMixin:RefreshTabs()
	local tab = self:GetTabForPanel(self.PetTab)
	tab:SetTabEnabled(HasPetUI())
	if self:GetCurrentTabID() == tab:GetTabID() then
		self:SelectFirstEnabledTab()
	end
end

function PetPaperDollPanelMixin:OnEvent(event, ...)
	local unit = ...
	if event == "PET_UI_UPDATE" or
			event == "PET_UI_CLOSE" or
			event == "PET_BAR_UPDATE" or 
			(event == "UNIT_PET" and unit == "player") or
			(event == "UNIT_NAME_UPDATE" and unit == "pet") then
		self:RefreshTabs()
	elseif event == "COMPANION_LEARNED" or
			event == "COMPANION_UNLEARNED" then
		if self:GetCurrentTabID() ~= 1 then
			self:RefreshCompanionTab(true)
		end
	elseif event == "COMPANION_UPDATE" or
			event == "SPELL_UPDATE_COOLDOWN" then
		if self:GetCurrentTabID() ~= 1 then
			self:RefreshCompanionTab()
		end
	elseif event == "PET_SPELL_POWER_UPDATE" then
		if self:GetCurrentTabID() == 1 then
			self:RefreshPetInfo()
		end
	elseif (event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and (unit == "player") then
		if self:GetCurrentTabID() ~= 1 then
			self:RefreshCompanionTab()
		end
	elseif unit == "pet" then
		if self:GetCurrentTabID() == 1 then
			self:RefreshPetInfo()
		end
	end
end

function PetPaperDollPanelMixin:RefreshCompanionTab(updateSelection)
	AscensionCharacterCompanionPanel:UpdateCompanionList(self.companionType, updateSelection)
end

function PetPaperDollPanelMixin:OnTabSelected(tabID)
	AscensionCharacterFrame:Expand()
	AscensionCharacterFrame:HideSideTabs()
	if tabID == 1 then
		AscensionCharacterFrame:ShowStatsPanel()
		self:RefreshPetInfo()
	elseif tabID == 2 then
		self.companionType = "CRITTER"
		AscensionCharacterFrame:ShowCompanionPanel()
		self:RefreshCompanionTab(true)
	elseif tabID == 3 then
		self.companionType = "MOUNT"
		AscensionCharacterFrame:ShowCompanionPanel()
		self:RefreshCompanionTab(true)
	end
end

function PetPaperDollPanelMixin:RefreshPetInfo()
	AscensionCharacterStatsPanel:SetUnit("pet")
	AscensionCharacterStatsPanel:ScheduleUpdate()
	local petType = UnitCreatureType("pet")
	local atlas = "DressUpBackground-pet-"..(petType and petType:lower() or "beast")
	if AtlasUtil:AtlasExists(atlas) then
		self.PetTab.Background:SetAtlas(atlas)
	else
		self.PetTab.Background:SetAtlas("DressUpBackground-pet-beast", Const.TextureKit.IgnoreAtlasSize)
	end
	
	self.PetTab:SetUnit("pet")
	self.PetTab:ResetValues()
	
	self.PetTab.Overlay.PetName:SetText(UnitName("pet"))

	local levelText = ""
	local family = UnitCreatureFamily("pet")
	local level = UnitLevel("pet")
	if family then
		levelText = format(UNIT_TYPE_LEVEL_TEMPLATE, level, family)
	elseif level then
		levelText = format(UNIT_TYPE_LEVEL_TEMPLATE, level, "")
	end

	self.PetTab.Overlay.PetLevel:SetText(levelText)

	local happiness, damagePercentage = GetPetHappiness()
	local _, isHunterPet = HasPetUI()
	if not happiness or not isHunterPet then
		self.PetTab.Overlay.Happiness:Hide()
	else
		self.PetTab.Overlay.Happiness:Show()
		if happiness == 1 then
			self.PetTab.Overlay.Happiness.Texture:SetTexCoord(0.375, 0.5625, 0, 0.359375)
		elseif happiness == 2 then
			self.PetTab.Overlay.Happiness.Texture:SetTexCoord(0.1875, 0.375, 0, 0.359375)
		elseif happiness == 3 then
			self.PetTab.Overlay.Happiness.Texture:SetTexCoord(0, 0.1875, 0, 0.359375)
		end
		self.PetTab.Overlay.Happiness.tooltip = _G["PET_HAPPINESS"..happiness]
		self.PetTab.Overlay.Happiness.tooltipDamage = format(PET_DAMAGE_PERCENTAGE, damagePercentage)
	end
end

function PetPaperDollPanelMixin:ShowNoCompanionsScreen(companionType)
	local overlay = self.CompanionTab.CompanionModel.Overlay
	if companionType == "CRITTER" then
		overlay.NoCompanionText:SetText(YOU_HAVE_NO_PETS)
	else
		overlay.NoCompanionText:SetText(YOU_HAVE_NO_MOUNTS)
	end
	overlay.NoCompanionText:Show()
	overlay.Title:Hide()
	overlay.Description:Hide()
	overlay.SummonButton:Hide()
end 

function PetPaperDollPanelMixin:HideNoCompanionsScreen()
	local overlay = self.CompanionTab.CompanionModel.Overlay
	overlay.NoCompanionText:Hide()
	overlay.Title:Show()
	overlay.Description:Show()
	overlay.SummonButton:Show()
end 