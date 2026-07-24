--
-- navigation button base
--
CharacterCreateNavigationButtonBaseMixin = CreateFromMixins(CallbackRegistryMixin)

function CharacterCreateNavigationButtonBaseMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({ "OnSelected"})
end

function CharacterCreateNavigationButtonBaseMixin:SetUp(setUpFunc)
	if setUpFunc then
		setUpFunc(self)
	end
end

function CharacterCreateNavigationButtonBaseMixin:OnClick(isForced)
	if type(isForced) == "string" then
		isForced = nil
	end

	self:TriggerEvent("OnSelected", self, isForced)
end


--
-- navigation button mixin
--
CharacterCreateNavigationButtonMixin = CreateFromMixins(CharacterCreateNavigationButtonBaseMixin)

function CharacterCreateNavigationButtonMixin:OnLoad()
	self:SetScale(0.8)
	CharacterCreateNavigationButtonBaseMixin.OnLoad(self)
	self.Shadow:SetVertexColor(1, 1, 0, 1)
end

function CharacterCreateNavigationButtonMixin:SetUp(setUpFunc)
	CharacterCreateNavigationButtonBaseMixin.SetUp(self, setUpFunc)
	-- default tex
	self.Icon:SetTexture("Interface\\Glues\\CharacterCreate\\charactercreate")
	self.Icon:SetTexCoord(0.2958984375, 0.3720703125, 0.3212890625, 0.4736328125)

	self.IconAdd:SetAtlas("ExperienceIconBeginner", Const.TextureKit.IgnoreAtlasSize)
	self.IconAdd:Show()
end

function CharacterCreateNavigationButtonMixin:OnClick(isForced)
	CharacterCreateNavigationButtonBaseMixin.OnClick(self, isForced)
end

function CharacterCreateNavigationButtonMixin:MarkSelected()
	self.Shadow:Show()
end

function CharacterCreateNavigationButtonMixin:ClearSelected()
	self.Shadow:Hide()
end

function CharacterCreateNavigationButtonMixin:OnEnable()
	self.Text:SetFontObject(GlueFontNormal)
	self:Show()
	self:GetParent():MarkDirty()
end

function CharacterCreateNavigationButtonMixin:OnDisable()
	self.Text:SetFontObject(GlueFontDisable)
	self:Hide()
	self:GetParent():MarkDirty()
end
--
-- Char Create Selection Frame mixin
--
CharacterCreateSelectionMixin = CreateFromMixins(CallbackRegistryMixin)

function CharacterCreateSelectionMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self.tabsByID = {}
	self.tabsPool = CreateFramePool("CheckButton", self, self:GetAttribute("template") or "CharacterCreateNavigationButtonTemplate")
	self.currentIndex = nil

	self:GenerateCallbackEvents({ "OnIndexSelected"})
end

function CharacterCreateSelectionMixin:ClearSelected()
	self:OnSelectIndex(nil)
end

function CharacterCreateSelectionMixin:ClearAll()
	self.tabsByID = {}
	self.tabsPool:ReleaseAll()
	self.currentIndex = nil
end

function CharacterCreateSelectionMixin:GetCurrentIndex()
	return self.currentIndex
end

function CharacterCreateSelectionMixin:GetPrevIndex()
	local button = self:GetButtonByIndex(self.currentIndex)

	local prevIndex = button.id - 1

	if prevIndex < 1 then
		return
	else
		return self.tabsByID[prevIndex].step
	end
end

function CharacterCreateSelectionMixin:GetNextIndex()
	local button = self:GetButtonByIndex(self.currentIndex)

	local prevIndex = button.id + 1

	if prevIndex > (#self.tabsByID) then
		return
	else
		return self.tabsByID[prevIndex].step
	end
end

function CharacterCreateSelectionMixin:OnSelectIndex(button, isForced)
	self.currentIndex = button and button.step or nil

	if self.currentIndex then
		self:TriggerEvent("OnIndexSelected", self.currentIndex, isForced)
	end

	for button in self.tabsPool:EnumerateActive() do
		if self.currentIndex and (self.currentIndex == button.step) then
			button:SetChecked(true)

			if button.MarkSelected then
				button:MarkSelected()
			end
		else
			button:SetChecked(false)

			if button.ClearSelected then
				button:ClearSelected()
			end
		end
	end
end

function CharacterCreateSelectionMixin:GoToIndex(step, isForced)
	local button = self:GetButtonByIndex(step)

	if button then
		button:OnClick(isForced)
	end
end

function CharacterCreateSelectionMixin:AddIndex(step, initFunc)
	local layoutIndex = #self.tabsByID+1

	local button, isNew = self.tabsPool:Acquire()
	button.layoutIndex = layoutIndex
	button.step = step
	button.id = layoutIndex
	button:SetUp(initFunc)
	button:Show()
	button:Enable()

	if isNew then
		button:RegisterCallback("OnSelected", self.OnSelectIndex, self)
	end

	self.tabsByID[layoutIndex] = button
	self:MarkDirty()
end

function CharacterCreateSelectionMixin:GetButtonByIndex(step)
	for button in self.tabsPool:EnumerateActive() do
		if button.step == step then
			return button
		end
	end
end

--
-- navigation frame mixin
--
CharacterCreateNavigationMixin = CreateFromMixins(CharacterCreateSelectionMixin)

function CharacterCreateNavigationMixin:OnLoad()
	CharacterCreateSelectionMixin.OnLoad(self)
	MixinAndLoadScripts(self, "VerticalLayoutMixin")
end

--
-- Updated archetype selection buttons
--
CharCreateArchetypeSelectButtonMixin = CreateFromMixins(CharacterCreateNavigationButtonBaseMixin, ExperienceRoundIconMixin)

function CharCreateArchetypeSelectButtonMixin:OnLoad()
	ExperienceRoundIconMixin.OnLoad(self)

	self.Background:SetSize(96, 96)
	self.Checked:SetSize(96, 96)
	self.Highlight:SetSize(96, 96)
	self.Icon:SetSize(96, 96)

	self.highlightFontObject = GlueFontHighlight
	self.normalFontObject = GlueFontNormal

	self.NameFrame:SetPoint("TOP", self.Icon, "BOTTOM", 0, 16)
	self.NameFrame.ShadowText:SetSize(166, 52)
	self.NameFrame.Text:SetFontObject(self.normalFontObject)
	self.NameFrame.Text:SetWidth(100)

	CharacterCreateNavigationButtonBaseMixin.OnLoad(self)
end

function CharCreateArchetypeSelectButtonMixin:OnClick()
	CharacterCreateNavigationButtonBaseMixin.OnClick(self)
end

function CharCreateArchetypeSelectButtonMixin:SetChecked(isChecked)
	if isChecked then
		self:Disable()
		self:OnDisable()
	else
		self:OnLeave()
		self:Enable()
		self:OnEnable()
	end
end

--
-- Freepick/Archetype selection menu
--
USE_ARCHETYPE_BUTTON = USE_ARCHETYPE_BUTTON or "Choose Archetype"
USE_FREEPICK_BUTTON = USE_FREEPICK_BUTTON or "Free Pick"
USE_ARCHETYPE_BUTTON_DESC = USE_ARCHETYPE_BUTTON_DESC or "USE_ARCHETYPE_BUTTON_DESC"
USE_FREEPICK_BUTTON_DESC = USE_FREEPICK_BUTTON_DESC or "USE_FREEPICK_BUTTON_DESC"

CharCreateArchetypeMainChoiceMixin = CreateFromMixins(CharacterCreateSelectionMixin)

function CharCreateArchetypeMainChoiceMixin:OnLoad()
	CharacterCreateSelectionMixin.OnLoad(self)
	MixinAndLoadScripts(self, "HorizontalLayoutMixin")

	self:AddIndex(Enum.CharCreateArchetypeBases.UseArchetype, function(button)
		button:SetIconHighlighted("ExperienceIconBeginnerHighlight")
		button:SetIconNormal("ExperienceIconBeginner")
		button:UpdateText(USE_ARCHETYPE_BUTTON, "")
		button:SetScript("OnEnter", function(self)
			ExperienceRoundIconMixin.OnEnter(self)
			GlueTooltip:SetOwner(self, "ANCHOR_TOP")
			GlueTooltip:AddLine(USE_ARCHETYPE_BUTTON, 1, 1, 1, true)
			GlueTooltip:AddLine(USE_ARCHETYPE_BUTTON_DESC, 1, 0.82, 0, true)
			GlueTooltip:Show()
		end)
	end)

	self:AddIndex(Enum.CharCreateArchetypeBases.Freepick, function(button)
		button:SetIconHighlighted("ExperienceIconFreepickHighlight")
		button:SetIconNormal("ExperienceIconFreepick")
		button:UpdateText(USE_FREEPICK_BUTTON, "")
		button:SetScript("OnEnter", function(self)
			ExperienceRoundIconMixin.OnEnter(self)
			GlueTooltip:SetOwner(self, "ANCHOR_TOP")
			GlueTooltip:AddLine(USE_FREEPICK_BUTTON, 1, 1, 1, true)
			GlueTooltip:AddLine(USE_FREEPICK_BUTTON_DESC, 1, 0.82, 0, true)
			GlueTooltip:Show()
		end)
	end)
end

--
-- Role selection menu
--
CharCreateArchetypeRoleChoiceMixin = CreateFromMixins(CharacterCreateSelectionMixin)

function CharCreateArchetypeRoleChoiceMixin:OnLoad()
	CharacterCreateSelectionMixin.OnLoad(self)
	MixinAndLoadScripts(self, "HorizontalLayoutMixin")

	local roles = C_CharacterCreate.GetArchetypeRoles()

	if next(roles) then
		for i = 1, #roles do
			local roleID = roles[i]

			self:AddIndex(roleID, function(button)
				local artwork, name, shortDescription, description = C_CharacterCreate.GetArchetypeRoleInfo(roleID)

				if AtlasUtil:AtlasExists(artwork.."Highlight") then
					button:SetIconHighlighted(artwork.."Highlight")
				end

				button:SetIconNormal(artwork)

				button:UpdateText(name, "")
				button:SetScript("OnEnter", GenerateClosure(self.OnEnterRole, self, button))
			end)
		end
	end
end

function CharCreateArchetypeRoleChoiceMixin:OnEnterRole(button)
	ExperienceRoundIconMixin.OnEnter(button)

	local _, name, shortDescription, description = C_CharacterCreate.GetArchetypeRoleInfo(button.step)

	if not name then 
		return
	end

	GlueTooltip:SetOwner(button, "ANCHOR_TOP")
	GlueTooltip:AddLine(name, 1, 1, 1, 1, true)
	GlueTooltip:AddLine(shortDescription, 1, 0.82, 0, 1, true)
	GlueTooltip:Show()
end
--
-- Subrole selection menu
--
CharCreateArchetypeSubroleChoiceMixin = CreateFromMixins(CharacterCreateSelectionMixin)

function CharCreateArchetypeSubroleChoiceMixin:OnLoad()
	CharacterCreateSelectionMixin.OnLoad(self)
	MixinAndLoadScripts(self, "HorizontalLayoutMixin")
end

function CharCreateArchetypeSubroleChoiceMixin:LoadSubroles(roleID)
	self:ClearAll()

	local categories = C_CharacterCreate.GetArchetypeCategories(roleID)

	if next(categories) then
		for i = 1, #categories do
			local categoryID = categories[i]

			self:AddIndex(categoryID, function(button)
				local iconArtwork, _, name = C_CharacterCreate.GetArchetypeCategoryInfo(categoryID)

				if AtlasUtil:AtlasExists(iconArtwork.."Highlight") then
					button:SetIconHighlighted(iconArtwork.."Highlight")
				end

				button:SetIconNormal(iconArtwork)
				button:UpdateText(name, "")
				button:SetScript("OnEnter", GenerateClosure(self.OnEnterSubrole, self, button))
			end)
		end
	end
end

function CharCreateArchetypeSubroleChoiceMixin:OnEnterSubrole(button)
	ExperienceRoundIconMixin.OnEnter(button)

	local _, _, name, shortDescription = C_CharacterCreate.GetArchetypeCategoryInfo(button.step)

	if not name then 
		return
	end

	GlueTooltip:SetOwner(button, "ANCHOR_TOP")
	GlueTooltip:AddLine(name, 1, 1, 1, 1, true)
	GlueTooltip:AddLine(shortDescription, 1, 0.82, 0, 1, true)
	GlueTooltip:Show()
end

--
-- Archetype selection menu
--
CharCreateArchetypeChoiceMixin = CreateFromMixins(CharacterCreateSelectionMixin)

function CharCreateArchetypeChoiceMixin:OnLoad()
	CharacterCreateSelectionMixin.OnLoad(self)
	MixinAndLoadScripts(self, "HorizontalLayoutMixin")
end

function CharCreateArchetypeChoiceMixin:LoadArchetypes(categoryID)
	self:ClearAll()

	local archetypes = C_CharacterCreate.GetArchetypes(categoryID)

	if next(archetypes) then
		for i = 1, #archetypes do
			local archetypeID = archetypes[i]

			self:AddIndex(archetypeID, function(button)
				local buildID, primarySpell, primaryStat, weaponType, armorType, icon, iconArtwork, infoArtwork, previewArtwork, name, description = C_CharacterCreate.GetArchetypeInfo(archetypeID)
				button:SetBasicIcon("Interface\\Icons\\"..icon)
				button.NameFrame:ClearAndSetPoint("TOP", button.Background, "BOTTOM", 0, 16)

				button.Background:SetAtlas("ExperienceIconBorderEmpty", Const.TextureKit.IgnoreAtlasSize)
				button.Background:SetDrawLayer("BORDER")
				button.Checked:SetDrawLayer("ARTWORK")
				button.Highlight:SetDrawLayer("ARTWORK")
				button.Icon:SetDrawLayer("BACKGROUND")
				button.Icon:SetSize(48, 48)
				button:UpdateText(name, "")

				button:SetScript("OnEnter", GenerateClosure(self.OnEnterArchetype, self, button))
			end)
		end
	end
end

function CharCreateArchetypeChoiceMixin:OnEnterArchetype(button)
	ExperienceRoundIconMixin.OnEnter(button)

	--local _, primarySpell, primaryStat, weaponTypes, armorTypes, _, _, _, _, name, shortDescription, description = C_CharacterCreate.GetArchetypeInfo(button.step)
	local _, _, _, _, _, _, _, _, _, name, shortDescription, description = C_CharacterCreate.GetArchetypeInfo(button.step)
					
	if not name then 
		return
	end

	GlueTooltip:SetOwner(button, "ANCHOR_TOP")
	GlueTooltip:SetMinWidth(340)
	GlueTooltip:AddLine(name, 1, 1, 1, 1, true)

	GlueTooltip:AddLine(shortDescription ~= "" and shortDescription or description, 1, 0.82, 0, 1, true)

	GlueTooltip:Show()
end
--
-- Description Spell
--
CharCreateDescriptionSpellMixin = {}

function CharCreateDescriptionSpellMixin:OnLoad()
	self.Title:SetWidth(200)

	self.Description:SetWidth(200)
	self.Description:SetPoint("TOPLEFT", self.Title, "BOTTOMLEFT", 0, -4)
	self.Description:SetJustifyV("TOP")
	self.Description:SetJustifyH("LEFT")
end

function CharCreateDescriptionSpellMixin:SetSpell(spellID, archetypeID)
	self:SetHeight(self.Slot:GetHeight())

	local spellName, spellDescription, spellIconPath = GetSpellData(spellID, false, true)
	local archetypeDesc = C_CharacterCreate.GetArchetypeSpellDescription(archetypeID, spellID)

	archetypeDesc = (archetypeDesc ~= " ") and archetypeDesc or spellDescription

	self.Icon:SetTexture(spellIconPath)
	self.Title:SetText(spellName)
	self.Description:SetText(archetypeDesc)

	self:SetHeight(math.max(self.Slot:GetHeight(), (self.Title:GetHeight()+self.Description:GetHeight()+4)))
end

--
-- Description equipment
--
CharCreateDescriptionEquipmentMixin = {}

function CharCreateDescriptionEquipmentMixin:OnLoad()
	CharCreateDescriptionSpellMixin.OnLoad(self)
	self.Title:SetFontObject(GlueFontHighlight)
	self:SetHeight(32)

	self.Icon:SetSize(32, 32)
	self.Slot:SetSize(32, 32)
	self.Border:SetSize(32, 32)

	self.Slot:Hide()
end

function CharCreateDescriptionEquipmentMixin:SetStat(stat)
	local spellID = Enum.PrimaryStat[stat] and PRIMARY_STATS[Enum.PrimaryStat[stat]]

	if not spellID then
		return
	end

	local spellName, _, spellIconPath = GetSpellData(spellID)
	self.Border:SetAtlas("quickslot-border-grey", Const.TextureKit.IgnoreAtlasSize)
	self.Description:SetText(PRIMARY_STAT)

	self.Icon:SetTexture(spellIconPath)
	self.Title:SetText(spellName)
end

function CharCreateDescriptionEquipmentMixin:SetEquipment(equipmentType)
	local spellID = Enum.ArmorSubClassSID[equipmentType] or Enum.WeaponSubClassSID[equipmentType]

	if not spellID then
		return
	end

	local spellName, _, spellIconPath = GetSpellData(spellID)

	self.Icon:SetTexture(spellIconPath)

	if Enum.ArmorSubClassSID[equipmentType] then
        self.Border:SetAtlas("itemupgrade_slotborder", Const.TextureKit.IgnoreAtlasSize)
        self.Description:SetText(ITEM_CLASS_4)
    else
        self.Border:SetAtlas("quickslot-border-grey", Const.TextureKit.IgnoreAtlasSize)
        self.Description:SetText(ITEM_CLASS_2)
    end

    self.Title:SetText(spellName)
end

--
-- Video block menu
--
CharCreateMovieFrameMixin = {}

function CharCreateMovieFrameMixin:OnMovieFinished()
	if self.video and self:IsVisible() then
		self:StartMovie(self.video, ARCHETYPE_PREVIEW_VOLUME)
		self:SetVolume(ARCHETYPE_PREVIEW_VOLUME/100 * C_CVar.GetNumber("Sound_MasterVolume"))
		if self.fadeInHandle then
			self.fadeInHandle:Unregister()
			self.fadeInHandle = nil
		end
	else
		if self.musicEnabled ~= nil and self.musicVolume ~= nil then
			if self.musicEnabled then
				-- we had music enabled, fade music back in
				self.fadeInHandle = EventRegistry:RegisterCallbackWithHandle("GLUE_MUSIC_FADED_IN", function()
					self.fadeInHandle:Unregister()
					self.fadeInHandle = nil
					C_CVar.SetCVarSave("Sound_MusicVolume", true)
					C_CVar.Set("Sound_MusicVolume", self.musicVolume)

					self.musicVolume = nil
				end)

				FadeGlueMusic(self.musicVolume, 0.5)
			else
				self.musicEnabled = nil
				self.musicVolume = nil
			end
		end
	end
end

function CharCreateMovieFrameMixin:OnHide()
	self.video = nil
end

function CharCreateMovieFrameMixin:StartMovieForArchetype(archetypeID)
	local video = select(13, C_CharacterCreate.GetArchetypeInfo(archetypeID))

	self.video = nil

	if video then
		self:StopMovie()
		video = string.gsub(video, "(....)$", "")
		if self:StartMovie(video, ARCHETYPE_PREVIEW_VOLUME) then
			self:SetVolume(ARCHETYPE_PREVIEW_VOLUME/100 * C_CVar.GetNumber("Sound_MasterVolume"))
			if not self.musicVolume then
				self.musicVolume = C_CVar.GetNumber("Sound_MusicVolume")
			end
			self.musicEnabled = C_CVar.GetBool("Sound_EnableMusic") and self.musicVolume > 0
			if self.musicEnabled then
				if self.fadeInHandle then
					self.fadeInHandle:Unregister()
					self.fadeInHandle = nil
				end
				C_CVar.SetCVarSave("Sound_MusicVolume", false)
				FadeGlueMusic(0.1, 0.5)
			end
			self.video = video
		end
	end
end

--
-- Description block menu
--
CharCreateDescriptionMixin = {}

function CharCreateDescriptionMixin:OnLoad()
	self.scrollChild.Title:SetWidth(281)
	self.scrollChild.ShortDesc:SetWidth(192)

	self.scrollChild.Description:SetWidth(281)
	self.scrollChild.Description:SetPoint("TOPLEFT", self.scrollChild.Title, "BOTTOMLEFT", 0, -2)
	self.scrollChild.Description:SetJustifyV("TOP")
	self.scrollChild.Description:SetJustifyH("LEFT")

	self.scrollChild.SpellDescriptions.spellPool = CreateFramePool("Frame", self.scrollChild.SpellDescriptions, "CharCreateDescriptionSpellTemplate")
	self.scrollChild.SpellDescriptions.equipmentPool = CreateFramePool("Frame", self.scrollChild.Equipments, "CharCreateDescriptionEquipmentTemplate")

end

function CharCreateDescriptionMixin:ClearAll()	
	self.scrollChild.SpellDescriptions.spellPool:ReleaseAll()
	self.scrollChild.SpellDescriptions:MarkDirty()

	self.scrollChild.SpellDescriptions.equipmentPool:ReleaseAll()
	self.scrollChild.Equipments:MarkDirty()

	self.scrollChild.Icon:Hide()
	self.scrollChild.Title:ClearAndSetPoint("TOPLEFT", 16, -12)
	self.scrollChild.Description:ClearAndSetPoint("TOPLEFT", self.scrollChild.Title, "BOTTOMLEFT", 0, -2)
	self.scrollChild.ShortDesc:Hide()
end

function CharCreateDescriptionMixin:SetRole(roleID)
	self:ClearAll()

	self.scrollChild.Icon:Show()
	self.scrollChild.ShortDesc:Show()
	self.scrollChild.Title:ClearAndSetPoint("BOTTOMLEFT", self.scrollChild.Icon, "RIGHT", -16, 0)
	self.scrollChild.Description:ClearAndSetPoint("TOPLEFT", self.scrollChild.Icon, "BOTTOMLEFT", 32, 16)

	local artwork, name, shortDescription, description = C_CharacterCreate.GetArchetypeRoleInfo(roleID)
	self.scrollChild.Title:SetText(name)
	self.scrollChild.Description:SetText(description)
	self.scrollChild.ShortDesc:SetText(shortDescription)

	self.scrollChild.Icon:SetAtlas(artwork)
end

function CharCreateDescriptionMixin:SetCategory(categoryID)
	self:ClearAll()

	self.scrollChild.Icon:Show()
	self.scrollChild.ShortDesc:Show()
	self.scrollChild.Title:ClearAndSetPoint("BOTTOMLEFT", self.scrollChild.Icon, "RIGHT", -16, 0)
	self.scrollChild.Description:ClearAndSetPoint("TOPLEFT", self.scrollChild.Icon, "BOTTOMLEFT", 32, 16)

	local iconArtwork, _, name, shortDescription, description = C_CharacterCreate.GetArchetypeCategoryInfo(categoryID)
	self.scrollChild.Title:SetText(name)
	self.scrollChild.Description:SetText(description)
	self.scrollChild.ShortDesc:SetText(shortDescription)

	self.scrollChild.Icon:SetAtlas(iconArtwork)
end

function CharCreateDescriptionMixin:SetArchetype(archetypeID)
	self:ClearAll()

	if not archetypeID then 
		return
	end

	local buildID, primarySpell, primaryStat, weaponTypes, armorTypes, icon, iconArtwork, infoArtwork, previewArtwork, name, shortDescription, description = C_CharacterCreate.GetArchetypeInfo(archetypeID)
	
	if not buildID then
		return
	end

	self.scrollChild.Title:SetText(name)
	self.scrollChild.Description:SetText(description)

	local layoutIndex = 0

	do -- equipment
		local stat = Enum.PrimaryStat[primaryStat] and PRIMARY_STATS[Enum.PrimaryStat[primaryStat]]

		if stat then
			layoutIndex = layoutIndex + 1

			local statFrame = self.scrollChild.SpellDescriptions.equipmentPool:Acquire()
			statFrame:SetStat(primaryStat)
			statFrame.layoutIndex = layoutIndex
			statFrame:Show()
		end

		for _, armorType in pairs(armorTypes) do
			local spellID = Enum.ArmorSubClassSID[armorType]

			if spellID then
				layoutIndex = layoutIndex + 1

				local armorFrame = self.scrollChild.SpellDescriptions.equipmentPool:Acquire()
				armorFrame:SetEquipment(armorType)
				armorFrame.layoutIndex = layoutIndex
				armorFrame:Show()
			end
		end

		for _, weaponType in pairs(weaponTypes) do
			local spellID = Enum.WeaponSubClassSID[weaponType]

			if spellID then
				layoutIndex = layoutIndex + 1

				local weaponFrame = self.scrollChild.SpellDescriptions.equipmentPool:Acquire()
				weaponFrame:SetEquipment(weaponType)
				weaponFrame.layoutIndex = layoutIndex
				weaponFrame:Show()
			end
		end
	end

	do -- primary spells
		layoutIndex = 0

		for _, spellID in ipairs(primarySpell) do
			if spellID and (spellID ~= 0) then
				layoutIndex = layoutIndex + 1
				local spellFrame = self.scrollChild.SpellDescriptions.spellPool:Acquire()
				spellFrame:SetSpell(spellID, archetypeID)
				spellFrame.layoutIndex = layoutIndex
				spellFrame:Show()
			end
		end
	end

	self.scrollChild.SpellDescriptions:MarkDirty()
	self.scrollChild.Equipments:MarkDirty()
end