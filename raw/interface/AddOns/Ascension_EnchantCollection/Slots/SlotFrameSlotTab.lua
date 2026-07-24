SLOTTED_ENCHANTS_TITLE = SLOTTED_ENCHANTS_TITLE or "ACTIVE ENCHANTS:"
-------------------------------------------------------------------------------
--                        Enchant Activation Preview                         --
-------------------------------------------------------------------------------
ECEnchantActivationPreview = {}

function ECEnchantActivationPreview:OnLoad()
	self:Layout()
end

function ECEnchantActivationPreview:SetScroll(item)
	local REData = C_MysticEnchant.GetEnchantInfoByItem(item:GetItemID())

	self.SpecIcon:Hide()
	self.AnimatedEnchant:Show()

	if (REData) then
		self.AnimatedEnchant:SetEnchant(REData.SpellID)
	else
		self.AnimatedEnchant:SetItem(item)
	end

	self.AnimatedEnchant:PlaySlowMovement()

	self.EnchantName:SetText(item:GetName())
	self.ActivationText:SetText(ENCHANT_COLLECTION_SLOT_ACTIVATION)

	return true
end

function ECEnchantActivationPreview:SetEnchant(REData)
	local name, _, icon = GetSpellInfo(REData.SpellID)

	self.SpecIcon:Hide()
	self.AnimatedEnchant:Show()
	self.AnimatedEnchant:SetEnchant(REData.SpellID)
	self.AnimatedEnchant:PlaySlowMovement()

	self.EnchantName:SetText(name)

	local enchantRequirementString = GameTooltip_GetEnchantRequirements(REData)
	if enchantRequirementString then
		self.EnchantName:SetTextColor(RED_FONT_COLOR:GetRGB())
		self.ActivationText:SetText(enchantRequirementString)
	else
		self.EnchantName:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		local cost = EnchantCollectionUtil:GetCollectionReforgeSlotCostWithAppliedChanges(REData.SpellID)
		self.ActivationText:SetText(EnchantCollectionUtil:FormatCostIconOnly(cost).." "..ENCHANT_COLLECTION_SLOT_ACTIVATION)
	end

	return true
end

function ECEnchantActivationPreview:SetSpecialization(index)
	self.AnimatedEnchant:Hide()
	self.SpecIcon:Show()

	self.SpecIcon.Icon:SetTexture(MysticEnchantManagerUtil.GetPresetIcon(index))
	self.EnchantName:SetText(MysticEnchantManagerUtil.GetPresetName(index))

	self.ActivationText:SetText(ENCHANT_SPECIALIZATION_PREVIEW)
end

function ECEnchantActivationPreview:Layout()
	self.AnimatedEnchant = CreateFrame("BUTTON", "$parent.AnimatedEnchant", self, "EnchantCollectionEnchantAnimated")
	self.AnimatedEnchant:SetPoint("LEFT", 24, 0)
	self.AnimatedEnchant:SetScale(1)

    self.SpecIcon = CreateFrame("FRAME", "$parent.SpecIcon", self, "PopupButtonTemplate")
    self.SpecIcon:SetSize(42,42)
    self.SpecIcon:SetPoint("LEFT", 24, 0)
	self.SpecIcon:SetScale(1.2)
	self.SpecIcon:Hide()

    self.SpecIcon.Icon = self.SpecIcon:CreateTexture(nil, "ARTWORK")
    self.SpecIcon.Icon:SetTexture("Interface\\Icons\\inv_misc_book_16")
    self.SpecIcon.Icon:SetSize(38, 38)
    self.SpecIcon.Icon:SetPoint("CENTER", 0, -1)

	self.EnchantName = self:CreateFontString(nil, "OVERLAY")
	self.EnchantName:SetFontObject("SystemFont_Shadow_Large2")
	self.EnchantName:SetJustifyH("LEFT")
	self.EnchantName:SetJustifyV("CENTER")
	self.EnchantName:SetPoint("LEFT", self.AnimatedEnchant, "RIGHT", 16, 0)
	self.EnchantName:SetWidth(256)

	self.ActivationText = self:CreateFontString(nil, "OVERLAY")
	self.ActivationText:SetFontObject("GameFontNormal")
	self.ActivationText:SetJustifyH("CENTER")
	self.ActivationText:SetJustifyV("CENTER")
	self.ActivationText:SetPoint("TOP", 0, -12)
	self.ActivationText:SetText(ENCHANT_COLLECTION_SLOT_ACTIVATION)

	self.LineUp = self:CreateTexture(nil, "BORDER", nil, 2)
	self.LineUp:SetTexture("Interface\\LevelUp\\LevelUpTex")
	self.LineUp:SetSize(365, 7)
	self.LineUp:SetPoint("TOP", self.ActivationText, "BOTTOM", 0, -2)
	self.LineUp:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
	self.LineUp:SetVertexColor(1, 1, 1)

	self.Shadow = self:CreateTexture(nil, "ARTWORK")
	self.Shadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.Shadow:SetPoint("CENTER", 0, 0)
	self.Shadow:SetHeight(96)
	self.Shadow:SetWidth(456)
	self.Shadow:SetAlpha(1)
end
-------------------------------------------------------------------------------
--                               Actual Frame                                --
-------------------------------------------------------------------------------
-- TODO: Probably make something what will clear current item if guid doesn't exist in general list

ECSlotTabMixin = {}

function ECSlotTabMixin:OnLoad()
	self.slotCollection = CreateFramePoolCollection()
	self.slotIDToButton = {}

	self.itemGUIDs = {}

	self:Layout()
	self:CreateSlots()
end

function ECSlotTabMixin:OnShow()
	EnchantCollectionUtil.OnGameModeChanged()
	self:RefreshGameModeRestrictions()
end

function ECSlotTabMixin:OnHide()
	self.SpecManager:Hide()
end

function ECSlotTabMixin:RefreshGameModeRestrictions()
	local nextLowestSlotLocked = nil
	local lowestLockedLevel = 99

	for slot in self.slotCollection:EnumerateActive() do
		slot:Init(slot:GetID())

		local slotQuality = slot:GetQuality()
		if slotQuality == 0 then
			slotQuality = nil
		end

		local fits, reqLevel = EnchantCollectionUtil:HasRequiredLevelForSlot(slot:GetID(), slotQuality)
		slot:SetFitsLevel(fits, reqLevel)

		if not fits and (reqLevel < lowestLockedLevel) then
			lowestLockedLevel = reqLevel
			nextLowestSlotLocked = slot
		end
	end

	if nextLowestSlotLocked then
		nextLowestSlotLocked:ShowRequiredLevel()
	end

	--[[if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		for slot in self.slotCollection:EnumerateActive() do 
			if EnchantCollectionUtil:CanApplyQualityToSlot(slot:GetID(), Enum.ItemQuality.Legendary) then
				if (slot:IsVisible()) then
					slot:Hide()
				end
			end
		end
	end]]
end

function ECSlotTabMixin:ReleaseAllSlots()
	self.slotCollection:ReleaseAll()
end

function ECSlotTabMixin:GetEnchantCollection()
	return self:GetParent():GetParent()
end

function ECSlotTabMixin:AcquireSlotButton()
	local pool, isNewPool = self.slotCollection:GetOrCreatePool("BUTTON", self, "EnchantCollectionEnchantSlot", nil)

	local button, isNew = pool:Acquire()

	if (isNew) then
		button:SetScript("OnEnter", function(button)
			ECEnchantSlotMixin.OnEnter(button)
			
			if button.spellID and (button.spellID ~= 0) then
				self:GetEnchantCollection():TooltipAddStackData(button.spellID)
			end
		end)
	end

	return button
end

function ECSlotTabMixin:CreateSlots()
	for i = 1, EnchantCollectionUtil.maxSlots do
		local slot = self:AcquireSlotButton()
		slot:Init(i)
		self.slotIDToButton[i] = slot
	end
end

function ECSlotTabMixin:AttemptOperation(func, callBack, ...)
	local result, errorText = EnchantCollectionUtil[func](EnchantCollectionUtil, ...)

	if result then
		self:Clear()
		callBack()
		return true
	else
		UIErrorsFrame:AddMessage(errorText, 1, 0, 0)
	end

	return false
end

function ECSlotTabMixin:PlayPlaceEnchantEffect(slot)
	PlaySound(SOUNDKIT.UI_70_ARTIFACT_FORGE_RELIC_PLACE)
	self.slotIDToButton[slot]:PlayPlaceAnim()
end

function ECSlotTabMixin:FillItemGUIDTable(slot, GUIDLow)
	self:PlayPlaceEnchantEffect(slot)

	self.itemGUIDs = self.itemGUIDs or {}
	self.itemGUIDs[GUIDLow] = true
	self:GetEnchantCollection():OnScrollUsed()
end

function ECSlotTabMixin:IsItemGUIDUsed(GUIDLow)
	return self.itemGUIDs[GUIDLow]
end

function ECSlotTabMixin:OnCollectionEnchantAdded(slot, spellID)
	self:PlayPlaceEnchantEffect(slot)

	local REData = C_MysticEnchant.GetEnchantInfoBySpell(spellID)

	local quality = EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality)

	if (quality == Enum.ItemQuality.Legendary) then
		return
	end

	if REData and (self:GetStackCount(spellID) < REData.MaxStacks) then
		self:SetEnchant(spellID)
	end
end

function ECSlotTabMixin:ApplyEnchant(slot)
	local slotID = slot:GetID()

	if (self:HasItem()) then
		self:AttemptOperation("ApplyScrollEnchant", GenerateClosure(self.FillItemGUIDTable, self, slotID, self.itemData.Guid), slotID, self.itemData)
	elseif (self:HasEnchant()) then
		self:AttemptOperation("ApplyCollectionEnchant", GenerateClosure(self.OnCollectionEnchantAdded, self, slotID, self.spellID), slotID, self.spellID)
	else
		if slot:GetEnchant() == 0 then
			if EnchantCollectionUtil:HasStagedChanges() then
				return
			end
			self:GetEnchantCollection():FilterForEnchantQuality(slot:GetQuality())
		end
	end
end

function ECSlotTabMixin:ShowSlotActivationAnimation()
	local quality = 0

	local REData
	if (self:HasItem()) then
		REData = C_MysticEnchant.GetEnchantInfoByItem(self.itemData.Entry)
	elseif (self:HasEnchant()) then
		REData = C_MysticEnchant.GetEnchantInfoBySpell(self.spellID)
	end

	quality = REData and EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality)

	if not REData or quality == 0 then
		self:ClearSlotActivationAnimation()
		return
	end

	local nextLowestSlotLocked = nil
	local lowestLockedLevel = 99

	for slot in self.slotCollection:EnumerateActive() do 
		local canApplyQuality = EnchantCollectionUtil:CanApplyQualityToSlot(slot:GetID(), quality)
		local fitsLevel, reqLevel = true, nil
		if canApplyQuality then
			fitsLevel, reqLevel = EnchantCollectionUtil:HasRequiredLevelForSlot(slot:GetID(), quality)
		end
		slot:SetFitsLevel(fitsLevel, reqLevel)

		if canApplyQuality then
			if EnchantCollectionUtil.IsClassAndSpecAppropriate(REData) then
				if slot:GetFitsLevel() then
					slot:ShowActiveAnimation()
				elseif reqLevel and (reqLevel < lowestLockedLevel) then
					lowestLockedLevel = reqLevel
					nextLowestSlotLocked = slot
				end
			else
				slot:SetLocked(ECEnchantMixin.LockState.LockedByRequirements)
			end
		else
			slot:SetLocked(ECEnchantMixin.LockState.Locked)
		end
	end

	if nextLowestSlotLocked then
		nextLowestSlotLocked:ShowRequiredLevel()
	end
end

function ECSlotTabMixin:ClearSlotActivationAnimation()
	for slot in self.slotCollection:EnumerateActive() do 
		slot:SetLocked(ECEnchantMixin.LockState.Unlocked)
		slot:ClearActiveAnimation()
	end

	self:RefreshGameModeRestrictions()
end

function ECSlotTabMixin:GetStackCount(spellID)
	local stack = 0

	for slot in self.slotCollection:EnumerateActive() do
		if slot:GetEnchant() == spellID then
			stack = stack + 1
		end
	end

	return stack
end

function ECSlotTabMixin:ShowPreview()
	PlaySound(SOUNDKIT.UI_70_ARTIFACT_FORGE_RELIC_PLACE)
	
	local presetData = MysticEnchantManagerUtil.GetPresetData(self.specIndex)

	local presetMap, presetMapLayout = MysticEnchantManagerUtil.GetPresetSlotMap(self.specIndex)
	local currentSlotMapLayout = EnchantCollectionUtil:GetSlotMapLayout()

	if not(presetMap) or presetMapLayout ~= currentSlotMapLayout then
		presetMap = EnchantCollectionUtil:GetSlotMapForEnchants(presetData)
		MysticEnchantManagerUtil.UpdatePresetSlotMap(self.specIndex, presetMap, currentSlotMapLayout)
	end

	for slot in self.slotCollection:EnumerateActive() do 
		local enchant = presetData[presetMap[slot:GetID()]] or 0
		slot:SetEnchant(enchant)

		if (enchant ~= 0) then
			slot:PlayPlaceAnim()
		end
	end
end

function ECSlotTabMixin:ClearPreview()
	for slot in self.slotCollection:EnumerateActive() do 
		slot:UpdateSlotData()
	end
end

function ECSlotTabMixin:ShowActivationFrame()
	if not(self:HasSpec()) then
		self.EnchantActivationFrame:SetScript("OnUpdate", GenerateClosure(self.UpdateCursor, self))
	end

	BaseFrameFadeIn(self.EnchantActivationFrame)
	self:ShowSlotActivationAnimation()
	self.Title:Hide()
	self.Shadow:Hide()
end

function ECSlotTabMixin:HideActivationFrame()
	self.EnchantActivationFrame:SetScript("OnUpdate", nil)

	BaseFrameFadeOut(self.EnchantActivationFrame)
	self:ClearSlotActivationAnimation()
	self.Title:Show()
	self.Shadow:Show()
end

function ECSlotTabMixin:HasItem()
	return self.itemData and true or false
end

function ECSlotTabMixin:HasEnchant()
	return self.spellID and true or false
end

function ECSlotTabMixin:HasSpec()
	return self.specIndex and true or false
end

function ECSlotTabMixin:UpdateCursor()
    if GameTooltip and GameTooltip:GetSpell() and GameTooltip.hasEnchantSlot then
        SetCursor("CAST_CURSOR")
    else
        SetCursor("CAST_ERROR_CURSOR")
    end
end

function ECSlotTabMixin:SetEnchant(spellID)
	PlaySound(SOUNDKIT.MAGICCLICK)
	
	self:Clear()

	local REData = C_MysticEnchant.GetEnchantInfoBySpell(spellID)

	if not(REData) then
		self:Clear()
	end

	if self:GetStackCount(spellID) >= REData.MaxStacks then
		UIErrorsFrame:AddMessage(_G["RE_COLLECTION_REFORGE_STACK_LIMIT"] or "RE_COLLECTION_REFORGE_STACK_LIMIT", 1, 0, 0)
		return
	end

	self.spellID = REData.SpellID

	self.EnchantActivationFrame:SetEnchant(REData)
	self:ShowActivationFrame()
	self:UpdateButtons()
	self:UpdateCursor(EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality))

	self:GetEnchantCollection():OnEnchantSelected(spellID)
end

function ECSlotTabMixin:SetItem(itemID)
	PlaySound(SOUNDKIT.MAGICCLICK)

	self:Clear()

	local itemData = self:GetEnchantCollection():GetScrollsTabItemData(itemID)

	if not(itemData) then
		self:Clear()
		return
	end

	self.itemData = itemData

	local item = Item:CreateFromID(itemData.Entry)

	self.EnchantActivationFrame:SetScroll(item)
	self:ShowActivationFrame()
	self:UpdateButtons()
	self:UpdateCursor(item:GetQuality())
end

function ECSlotTabMixin:SetPreset(index)
	self:Clear()
	self:GetEnchantCollection():ClearCollectionScrollReforge()
	EnchantCollectionUtil:ClearStagedChanges()

	self.specIndex = index

	self.EnchantActivationFrame:SetSpecialization(self.specIndex)
	self:ShowPreview()
	self:ShowActivationFrame()
	self:UpdateButtons()
end

function ECSlotTabMixin:Clear()
	if self:HasItem() or self:HasEnchant() or self:HasSpec() then
		if (self.EnchantActivationFrame:IsVisible()) then
			self:HideActivationFrame()
		end
	end

	self.specIndex = nil
	self.itemData = nil
	self.spellID = nil

	self:GetEnchantCollection():OnEnchantSelected(nil)

	ResetCursor()

	self:UpdateButtons()
	self:ClearSlotActivationAnimation()
	self:ClearPreview()
end

function ECSlotTabMixin:MYSTIC_ENCHANT_SLOT_UPDATE()
	-- update every slot because we need to re-check C_MysticEnchant.CanEquipSlot
	for slot in self.slotCollection:EnumerateActive() do
		slot:UpdateSlotData()
	end

	self:UpdateButtons()

	-- kinda crutch. Go back to reforge tab if no active item and no changes
	if not(EnchantCollectionUtil:HasStagedChanges()) and not(self:HasItem()) then
		if (self:GetEnchantCollection():IsScrollTabActive()) then
			self:GetParent():SetTab(Enum.ECSlotTabs.ReforgeTab)
		end
	end
end

function ECSlotTabMixin:ClickUndo()
	if (self:HasSpec()) then
		self.SpecManager:Show()
	end

	EnchantCollectionUtil:ClearStagedChanges()
	self:Clear() 

	if (self:GetEnchantCollection():IsScrollTabActive()) then
		self:GetParent():SetTab(Enum.ECSlotTabs.ReforgeTab)

		wipe(self.itemGUIDs)
		self:GetEnchantCollection():OnScrollUsed()
	end
end

function ECSlotTabMixin:UndoOnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:AddLine(ENCHANT_COLLECTION_UNDO_TOOLTIP, 1, 1, 1, 1)
	GameTooltip:AddLine(ENCHANT_COLLECTION_UNDO_TOOLTIP_TEXT, 1, 0.82, 0, 1)
	GameTooltip:Show()
end

function ECSlotTabMixin:Apply()
	if EnchantCollectionUtil:Apply() then
		self:Clear() 

		if (self:GetEnchantCollection():IsScrollTabActive()) then
			self:GetParent():SetTab(Enum.ECSlotTabs.ReforgeTab)
		end
	end
end

function ECSlotTabMixin:ClickApply()
	if (self:HasSpec()) then
		if (MysticEnchantManagerUtil.SaveCurrentAndActivateIndex(self.specIndex)) then
			C_Hook:SendEvent("ENCHANTCOLLECTION_PRESET_SWAP_STARTED")
			--self:Clear()
		end
		return
	end

	EnchantCollectionUtil:ShowApplyDialogue(GenerateClosure(self.Apply, self))
end

function ECSlotTabMixin:UpdateButtons()
	local hasChanges = EnchantCollectionUtil:HasStagedChanges()

	if not(hasChanges) then
		self.Button:Hide()
		self.UndoButton:Hide()
	end

	if (self:HasSpec()) then
		self.Button:Show()
		self.UndoButton:Show()
		self.Button:Enable()
		self.Button.YellowGlow:Show()
		self.Button.text = ACTIVATE
		self.Button.GetCostFunc = nil
		self.Button:Update(true)
	else
		self.Button:Show()
		self.UndoButton:Show()
		self.Button.YellowGlow:Hide()
		self.Button:Disable()
		self.Button.text = SAVE_CHANGES
		self.Button.GetCostFunc = GenerateClosure(EnchantCollectionUtil.CalculateCollectionReforgeCost, EnchantCollectionUtil)
		self.Button:Update(true)
	end
	
	if hasChanges then
		self.Button:Show()
		self.UndoButton:Show()
		self.Button.YellowGlow:Show()

		if (self.Button:IsEnabled() == 1) then
			self.Button:Enable()
		end
	elseif not(self:HasSpec()) then -- after self.Button:Update() button can turn enabled with no changes
		self.Button:Disable()
	end

	if BuildCreatorUtil.IsPickingEnchants() then
		self:GetEnchantCollection().NoAltarFrame:Hide()
	elseif not(self.Button:IsVisible()) then
		if not(EnchantCollectionUtil:GetAltar()) then -- if we switch back from set preview while there is no altar, bring text back
			if (self:GetEnchantCollection().NoAltarFrame and not(self:GetEnchantCollection().NoAltarFrame:IsVisible())) then -- can be called before UI is loaded
				self:GetEnchantCollection().NoAltarFrame:Show()
			end
		end
	else
		if not(EnchantCollectionUtil:GetAltar()) then
			self:GetEnchantCollection().NoAltarFrame:Hide()
		end
	end
end

function ECSlotTabMixin:ToggleSpecManager()
	if (self.SpecManager:IsVisible()) then
		PlaySound("igMainMenuClose")
	else
		PlaySound("igMainMenuOpen")
	end

	self.SpecManager:SetShown(not(self.SpecManager:IsVisible()))
end

function ECSlotTabMixin:IsSpecManagerOpen()
	return self.SpecManager:IsShown()
end

function ECSlotTabMixin:Layout()
	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAtlas("Enchant-Slot-Tab-Background", Const.TextureKit.UseAtlasSize)
	--self.bg:SetPoint("CENTER", -2, -22)
	self.bg:SetPoint("CENTER", 0, -22)

	self.Title = self:CreateFontString(nil, "OVERLAY")
	self.Title:SetFontObject("SystemFont_Shadow_Large2")
	self.Title:SetJustifyH("CENTER")
	self.Title:SetJustifyV("CENTER")
	self.Title:SetPoint("TOP", 0, -48)
	self.Title:SetText(SLOTTED_ENCHANTS_TITLE)

	self.Shadow = self:CreateTexture(nil, "ARTWORK")
	self.Shadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.Shadow:SetPoint("CENTER", self.Title, "CENTER", 0, 0)
	self.Shadow:SetHeight(72)
	self.Shadow:SetWidth(456)
	self.Shadow:SetAlpha(0.8)

	self.EnchantActivationFrame = CreateFrame("FRAME", "$parent.EnchantActivationFrame", self, nil)
	self.EnchantActivationFrame:SetPoint("TOPLEFT", 0, -8)
	self.EnchantActivationFrame:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -156)
	self.EnchantActivationFrame:Hide()
	MixinAndLoadScripts(self.EnchantActivationFrame, ECEnchantActivationPreview)

	self.Button = CreateFrame("BUTTON", "$parent.Button", self, "RedButtonTemplate")
	self.Button:SetSize(172, 40)
	self.Button:SetPoint("BOTTOM", 0, 24)
	self.Button:SetScript("OnClick", function()
		self:ClickApply()
	end)
	self.Button:Hide()
	self.Button.text = SAVE_CHANGES
	MixinAndLoadScripts(self.Button, ECButtonWithCostMixin)
	self.Button:SetFrameLevel(self:GetParent():GetFrameLevel()+10)
	 
	--self.Button:SetScript("OnTextChanged", function(self)
		--self:GetParent():SetWidth(math.max(self:Width()+60, 172))
	--end)

	self.UndoButton = CreateFrame("BUTTON", "$parent.UndoButton", self, "SquareIconButtonTemplate")
	self.UndoButton:SetSize(42, 42)
	--self.UndoButton:SetPoint("CENTER", self.ResetButton, "CENTER", 0)
	self.UndoButton:SetPoint("LEFT", self.Button, "RIGHT", 14, 0)
	self.UndoButton.Icon:SetAtlas("talents-button-reset", Const.TextureKit.IgnoreAtlasSize)
	self.UndoButton.Icon:SetSize(24, 24)
	self.UndoButton:SetScript("OnClick", function() PlaySound(SOUNDKIT.SPELL_PR_ARTIFACT_LIGHTSWRATH_CAST_05) self:ClickUndo() end)
	self.UndoButton:SetScript("OnEnter", function(btn) self:UndoOnEnter(btn) end)
	self.UndoButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	self.UndoButton:Hide()

	self.Button.YellowGlow = CreateFrame("FRAME", "$parent.YellowGlow", self.Button)
	self.Button.YellowGlow:SetSize(0, 1)
	self.Button.YellowGlow:SetPoint("LEFT", -24, 0)
	self.Button.YellowGlow:SetPoint("RIGHT", 24, 0)
	self.Button.YellowGlow:Hide()

	self.Button.YellowGlow.Left = self.Button.YellowGlow:CreateTexture(nil, "ARTWORK")
	self.Button.YellowGlow.Left:SetAtlas("newplayertutorial-yellowGlow-redbutton-left", Const.TextureKit.UseAtlasSize)
	self.Button.YellowGlow.Left:SetPoint("LEFT")
	self.Button.YellowGlow.Left:SetBlendMode("ADD")

	self.Button.YellowGlow.Right = self.Button.YellowGlow:CreateTexture(nil, "ARTWORK")
	self.Button.YellowGlow.Right:SetAtlas("newplayertutorial-yellowGlow-redbutton-right", Const.TextureKit.UseAtlasSize)
	self.Button.YellowGlow.Right:SetPoint("RIGHT")
	self.Button.YellowGlow.Right:SetBlendMode("ADD")

	self.Button.YellowGlow.Middle = self.Button.YellowGlow:CreateTexture(nil, "ARTWORK")
	self.Button.YellowGlow.Middle:SetAtlas("newplayertutorial-yellowGlow-redbutton-middle", Const.TextureKit.IgnoreAtlasSize)
	self.Button.YellowGlow.Middle:SetPoint("TOPLEFT", self.Button.YellowGlow.Left, "TOPRIGHT")
	self.Button.YellowGlow.Middle:SetPoint("BOTTOMRIGHT", self.Button.YellowGlow.Right, "BOTTOMLEFT")
	self.Button.YellowGlow.Middle:SetBlendMode("ADD")
	--self:SetBackdropColor(1, 1, 1, 1)

	self.ActiveSpecButton = CreateFrame("BUTTON", "$parent.ActiveSpecButton", self, "InsetFrameTemplate")
	self.ActiveSpecButton:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
	self.ActiveSpecButton:SetSize(240, 45)
	self.ActiveSpecButton.NineSlice:SetFrameLevel(self.ActiveSpecButton:GetFrameLevel()+1)
	MixinAndLoadScripts(self.ActiveSpecButton, ECActiveSpecButtonMixin)

	self.ActiveSpecButton.Button = CreateFrame("BUTTON", "$parent.Button", self.ActiveSpecButton, "RedButtonTemplate")
	self.ActiveSpecButton.Button:SetPoint("LEFT", self.ActiveSpecButton, "RIGHT", 0, 0)
	self.ActiveSpecButton.Button:SetHeight(40)
	self.ActiveSpecButton.Button:SetWidth(140)
	self.ActiveSpecButton.Button:SetText(CHANGE)

	self.ActiveSpecButton:SetScript("OnClick", GenerateClosure(self.ToggleSpecManager, self))
	self.ActiveSpecButton.Button:SetScript("OnClick", GenerateClosure(self.ToggleSpecManager, self))

	self.SpecManager = CreateFrame("FRAME", "$parent.SpecManager", self, "UIPanelDialogTemplate")
	self.SpecManager:SetPoint("BOTTOMRIGHT", self.ActiveSpecButton.Button, "TOPRIGHT", 4, 0)
	self.SpecManager:Hide()
	MixinAndLoadScripts(self.SpecManager, ECSpecManagerMixin)
end
