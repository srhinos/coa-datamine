-------------------------------------------------------------------------------
--                              ECEnchantMixin                               --
-------------------------------------------------------------------------------
ECEnchantMixin = {}

ECEnchantMixin.LockState = {
	Unlocked = 1,
	Locked = 2,
	LockedByRequirements = 3,
}

function ECEnchantMixin:OnLoad()
	self:SetMotionScriptsWhileDisabled(true)
	self:Layout()
end

function ECEnchantMixin:GetQuality()
	return self.quality
end

function ECEnchantMixin:GetState()
	return self.state
end

function ECEnchantMixin:SetState(state, skipUpdate)
	self.state = state

	if skipUpdate then return end

	self:VisualUpdate()
end

function ECEnchantMixin:SetQuality(quality, skipUpdate)
	self.quality = quality

	if skipUpdate then return end

	self:VisualUpdate()
end

function ECEnchantMixin:GetBorderForState()
	return EnchantCollectionUtil:GetBorderStyleForSlot(self)
end

function ECEnchantMixin:VisualUpdate()
	self.Border:SetAtlas(self:GetBorderForState(), Const.TextureKit.IgnoreAtlasSize)

	if (self:GetState() == Enum.ECSlotStates.Unknown) then
		self.Icon:Hide()
	else
		self.Icon:Show()
	end
end

function ECEnchantMixin:SetLocked(lockState)
	if lockState == ECEnchantMixin.LockState.Unlocked then
		self.Icon:SetDesaturated(false)
		self.Icon:SetAlpha(1)
		self.Border:SetVertexColor(1, 1, 1)
	else
		self.Icon:SetDesaturated(true)
		self.Icon:SetAlpha(0.6)
		self.Border:SetVertexColor(0.5, 0.5, 0.5)
	end
end

function ECEnchantMixin:SetBroken()
	self.Icon:SetDesaturated(false)
	self.Icon:SetVertexColor(1, 0, 0)
end

function ECEnchantMixin:SetIcon(texture)
	local desaturated = self.Icon:IsDesaturated()

	SetPortraitToTexture(self.Icon, texture)
	self.Icon:SetDesaturated(desaturated)
end

function ECEnchantMixin:SetDefault()
	self:SetState(Enum.ECSlotStates.Unknown, true)
	self:SetQuality(0)
end

function ECEnchantMixin:OnClick(button)
	if IsModifiedClick() then
		self:OnModifiedClick(button)
		return
	end
end

function ECEnchantMixin:OnModifiedClick(button)
    if ( IsModifiedClick("CHATLINK") ) then
        ChatEdit_InsertLink(LinkUtil:GetSpellLink(self.spellID) or "")
        return
    end
end

function ECEnchantMixin:SetEnchant(spellID)
	if (spellID ~= 0) then
		local REData = C_MysticEnchant.GetEnchantInfoBySpell(spellID)

		if (REData) and next(REData) then
			local _, _, icon = GetSpellInfo(REData.SpellID)
			self:SetState(Enum.ECSlotStates.Known, true)
			self:SetQuality(EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality))
			self:SetIcon(icon)
		else
			self:SetDefault()
		end
	else
		self:SetDefault()
	end

	self.spellID = spellID
	self:VisualUpdate()
end

function ECEnchantMixin:GetEnchant()
	return self.spellID or 0
end

function ECEnchantMixin:OnEnter()
	if (self.Highlight) then 
		self.Highlight:Show()
	end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)

	if (self.spellID) and (self.spellID ~= 0) then
	    
	    local link = LinkUtil:GetSpellLink(self.spellID)
	    if link then
	    	GameTooltip:SetHyperlink(link)
	    end
	    GameTooltip:Show()
	end
end

function ECEnchantMixin:OnLeave()
	if (self.Highlight) then 
		self.Highlight:Hide()
	end

	GameTooltip.hasEnchantSlot = false

	GameTooltip:Hide()
end

function ECEnchantMixin:ShowSelected()
	self.Selected:Show()
	self.SelectedGlow:Show()
	self.SelectedGlow.Breathing:Play()
end

function ECEnchantMixin:HideSelected()
	self.Selected:Hide()
	self.SelectedGlow:Hide()
	self.SelectedGlow.Breathing:Stop()
end

function ECEnchantMixin:Layout()
	self:SetSize(48, 48)
	--self:SetBackdrop(GameTooltip:GetBackdrop())

	self.Icon = self:CreateTexture(nil, "BACKGROUND")
	self.Icon:SetAllPoints()

	self.Border = self:CreateTexture(nil, "BORDER")
	self.Border:SetSize(96, 96)
	self.Border:SetPoint("CENTER", 0, 0)

	self.Highlight = self:CreateTexture(nil, "OVERLAY")
	self.Highlight:SetAtlas("EnchantSlotBorderHighlight", Const.TextureKit.IgnoreAtlasSize)
	self.Highlight:SetSize(96, 96)
	self.Highlight:SetPoint("CENTER", 0, 0)
	self.Highlight:Hide()
	self.Highlight:SetBlendMode("ADD")

	self.Selected = self:CreateTexture(nil, "OVERLAY")
	self.Selected:SetAtlas("EnchantSlotBorderSelected", Const.TextureKit.IgnoreAtlasSize)
	self.Selected:SetSize(96, 96)
	self.Selected:SetPoint("CENTER", 0, 0)
	self.Selected:Hide()

	self.SelectedGlow = self:CreateTexture(nil, "OVERLAY")
	self.SelectedGlow:SetAtlas("EnchantSlotBorderSelected", Const.TextureKit.IgnoreAtlasSize)
	self.SelectedGlow:SetSize(96, 96)
	self.SelectedGlow:SetPoint("CENTER", 0, 0)
	self.SelectedGlow:Hide()
	self.SelectedGlow:SetBlendMode("ADD")
	self.SelectedGlow:SetAlpha(0)

	self.SelectedGlow.Breathing = self.SelectedGlow:CreateAnimationGroup(nil)
	self.SelectedGlow.Breathing:SetLooping("REPEAT")

	self.SelectedGlow.Breathing.Alpha = self.SelectedGlow.Breathing:CreateAnimation("ALPHA")
	self.SelectedGlow.Breathing.Alpha:SetDuration(1)
	self.SelectedGlow.Breathing.Alpha:SetOrder(1)
	self.SelectedGlow.Breathing.Alpha:SetChange(0.2)

	self.SelectedGlow.Breathing.Alpha2 = self.SelectedGlow.Breathing:CreateAnimation("ALPHA")
	self.SelectedGlow.Breathing.Alpha2:SetDuration(1)
	self.SelectedGlow.Breathing.Alpha2:SetOrder(2)
	self.SelectedGlow.Breathing.Alpha2:SetChange(-0.2)
end

-------------------------------------------------------------------------------
--                            ECEnchantSlotMixin                             --
-------------------------------------------------------------------------------
-- this mixin serves for enchant activation/deactivation in slot frame
ECEnchantSlotMixin = CreateFromMixins("ECEnchantMixin")

function ECEnchantSlotMixin:OnLoad()
	ECEnchantMixin.OnLoad(self)
	UIDropDownMenu_Initialize(self.DropDownMenu, GenerateClosure(self.InitializeActiveSlotDialogDropDown, self), "MENU")
end

function ECEnchantSlotMixin:Init(ID)
	self:SetID(ID)
	self.lockState = ECEnchantMixin.LockState.Unlocked

	self:SetDefault(true)

	local slotData = EnchantCollectionUtil:GetSlotSettings(ID)
	if not slotData or slotData.hidden then
		self:Hide()
		return
	end

	self:Show()

	self:UpdateSlotData()

	self:RegisterForClicks("AnyUp")
end

function ECEnchantSlotMixin:SetDefault(resetAll)
	local slotData = EnchantCollectionUtil:GetSlotSettings(self:GetID())

	if not(slotData) then	
		return
	end

	if slotData.hidden then
		self:Hide()
		return
	end

	self.defaultBorderAtlas = slotData.emptySlot

	if (resetAll) then
		self:SetPoint(unpack(slotData.point))
		self:SetScale(slotData.scale)

		local shineTranslation = 24*slotData.scale

		self.SheenTexture.Shine.Transition1:SetOffset(-shineTranslation, shineTranslation)
		self.SheenTexture.Shine.Transition2:SetOffset(shineTranslation, -shineTranslation)
		self.SheenTexture.Shine.Transition3:SetOffset(shineTranslation, -shineTranslation)
	end
	
	self:SetQuality(slotData.quality, true)
	self:SetState(Enum.ECSlotStates.Unknown, true)
	self.ActiveAnimationTexture:SetAtlas(Enum.ECSlotBorderStylesUnKnown[slotData.quality] or "EnchantSlotBorderUnknownNormal", Const.TextureKit.IgnoreAtlasSize)
end

function ECEnchantSlotMixin:VisualUpdate()
	ECEnchantMixin.VisualUpdate(self)
	self:RefreshQualityBorder()
end

function ECEnchantSlotMixin:RefreshQualityBorder()
	local slotData = EnchantCollectionUtil:GetSlotSettings(self:GetID())
	local atlas = slotData and Enum.ECSlotQualityJewelStyles[slotData.quality]

	if atlas then
		self.QualityBorder:SetAtlas(atlas, Const.TextureKit.IgnoreAtlasSize)

		if self:GetState() == Enum.ECSlotStates.Unknown then
			self.QualityBorder:Show()
		else
			self.QualityBorder:Hide()
		end
	else
		self.QualityBorder:Hide()
	end
end

function ECEnchantSlotMixin:GetBorderForState()
	if (self:GetState() == Enum.ECSlotStates.Unknown) and self.defaultBorderAtlas then
		if EnchantCollectionUtil:IsClassFusionEnabled()
			and self.lockState == ECEnchantMixin.LockState.Unlocked
			and self:GetFitsLevel() ~= false
		then
			return Enum.ECSlotBorderStylesUnKnown[self:GetQuality()] or self.defaultBorderAtlas
		end

		return self.defaultBorderAtlas
	else
		return EnchantCollectionUtil:GetBorderStyleForSlot(self)
	end
end

function ECEnchantSlotMixin:SetLocked(lockState)
	self.lockState = lockState

	if lockState == ECEnchantMixin.LockState.Unlocked then
		self.Icon:SetDesaturated(false)
		self.Icon:SetAlpha(1)
		self.Border:SetVertexColor(1, 1, 1, 1)
	else
		self.Icon:SetDesaturated(true)
		self.Icon:SetAlpha(0.6)

		if lockState == ECEnchantMixin.LockState.LockedByRequirements then
			self.Border:SetVertexColor(1, 0, 0, 0.5)
		elseif (self:GetState() == Enum.ECSlotStates.Unknown) and self.defaultBorderAtlas then
			self.Border:SetVertexColor(1, 1, 1, 0.5)
		else
			self.Border:SetVertexColor(0.5, 0.5, 0.5)
		end
	end

	self.DisabledOverlayFrame:SetAlpha(self.Icon:GetAlpha())
	self.QualityBorder:SetAlpha(self.Icon:GetAlpha())
	if EnchantCollectionUtil:IsClassFusionEnabled() then
		self.Border:SetAtlas(self:GetBorderForState(), Const.TextureKit.IgnoreAtlasSize)
		self:RefreshQualityBorder()
	end
end

function ECEnchantSlotMixin:GetFitsLevel()
	return self.isFitLevel
end

function ECEnchantSlotMixin:GetRequiredLevel()
	return self.requiredLevel
end

function ECEnchantSlotMixin:SetFitsLevel(isFitLevel, reqLevel)
	self.isFitLevel = isFitLevel
	self.requiredLevel = reqLevel
	--self:SetAlpha(isFitLevel and 1 or 0.5)
	--self.Border:SetDesaturated(not isFitLevel)
	self.DisabledOverlayFrame:SetShown(not isFitLevel)

	self.DisabledOverlayFrame.Level:Hide()
	self.DisabledOverlayFrame.Shadow2:Hide()

	if EnchantCollectionUtil:IsClassFusionEnabled() then
		self.Border:SetAtlas(self:GetBorderForState(), Const.TextureKit.IgnoreAtlasSize)
		self:RefreshQualityBorder()
	end
end

function ECEnchantSlotMixin:ShowRequiredLevel()
	self.DisabledOverlayFrame.Level:Show()
	self.DisabledOverlayFrame.Shadow2:Show()

	local reqLevel = self:GetRequiredLevel()
	self.DisabledOverlayFrame.Level:SetText(reqLevel)
end

function ECEnchantSlotMixin:SetEnchant(spellID)
	if (spellID == 0) then
		self:SetDefault()
	end

	local oldSpellID = self.spellID or 0

	if (spellID ~= 0) and (oldSpellID ~= spellID) then
		self:PlaySetEnchantAnim()
	end

	ECEnchantMixin.SetEnchant(self, spellID)
end

function ECEnchantSlotMixin:UpdateSlotData()
	self.errorMessages = nil
	self.Icon:SetVertexColor(1, 1, 1, 1)

	local enchantInfo = EnchantCollectionUtil:GetSlotData(self:GetID())
	local safeCheckResult, errorMessages = true, nil

	self:SetEnchant(enchantInfo)

	if (self:HasTempSlotData()) then -- don't check for CanEquipSlot if slot contains temp changes
		return
	end

	if self.spellID and self.spellID ~= 0 then
		safeCheckResult, errorMessages = C_MysticEnchant.CanEquipSlot(EnchantCollectionUtil:GetRealSlotID(self:GetID()))
	end

	if not(safeCheckResult) then
		self:SetBroken()
		self.errorMessages = errorMessages
	end
end

function ECEnchantSlotMixin:ClearActiveAnimation()
	self.ActiveAnimationTexture.Breathing:Stop()
end

function ECEnchantSlotMixin:ShowActiveAnimation()
	self.ActiveAnimationTexture.Breathing:Stop()
	self.ActiveAnimationTexture.Breathing:Play()
end

function ECEnchantSlotMixin:HasTempSlotData()
	return EnchantCollectionUtil:GetTempSlotData(EnchantCollectionUtil:GetRealSlotID(self:GetID()))
end

function ECEnchantSlotMixin:InitializeActiveSlotDialogDropDown(dropdown, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.text = ENCHANT_COLLECTION_SAVE_TO_COLLECTION
	info.disabled = not self:CanExtract()
	info.func = function()
		if not(EnchantCollectionUtil:GetAltar()) then
			UIErrorsFrame:AddMessage(_G["RE_DISENCHANT_NO_MYSTIC_ALTAR"] or "RE_DISENCHANT_NO_MYSTIC_ALTAR", 1, 0, 0)
			return
		end

		EnchantCollectionUtil:ShowDisenchantSlotDialogue(self:GetID(), self.spellID)
	end
	UIDropDownMenu_AddButton(info, level)

	info.text = ENCHANT_COLLECTION_REMOVE_SLOT
	info.disabled = not self:CanRemove()
	info.func = function()
		EnchantCollectionUtil:ShowDestroySlotDialogue(self:GetID(), self.spellID)
	end
	UIDropDownMenu_AddButton(info, level)
	
	info.text = CANCEL
	info.disabled = nil
	info.func = function()
		CloseDropDownMenus()
	end
	UIDropDownMenu_AddButton(info, level)
end

function ECEnchantSlotMixin:OnClick(button)
	PlaySound("igMainMenuOptionCheckBoxOn")

	if IsModifiedClick() then
		ECEnchantMixin.OnModifiedClick(self, button)
		return
	end

	if self:CanExtract() or self:CanRemove() then
		ToggleDropDownMenu(1, nil, self.DropDownMenu, "cursor", 0, 0)
		return
	end

	if self:HasTempSlotData() then
		PlaySound(SOUNDKIT.SPELL_PR_ARTIFACT_LIGHTSWRATH_CAST_05)
		EnchantCollectionUtil:RefundEnchant(self:GetID())
		return
	end

	if self.isFitLevel then
		self:GetParent():ApplyEnchant(self)
	end
end

function ECEnchantSlotMixin:CanExtract()
	if (self:GetParent():HasItem() or self:GetParent():HasEnchant()) then
		return false
	end

	if not(self.spellID) or (self.spellID == 0) then
		return false
	end

	if self:HasTempSlotData() then
		return false
	end

	local REData = C_MysticEnchant.GetEnchantInfoBySpell(self.spellID)
	if (REData and REData.Known) then
		return false
	end

	return true
end

function ECEnchantSlotMixin:CanRemove()
	if (self:GetParent():HasItem() or self:GetParent():HasEnchant() or self:GetParent():HasSpec()) then
		return false
	end

	if not(self.spellID) or (self.spellID == 0) then
		return false
	end

	if EnchantCollectionUtil:GetTempSlotData(EnchantCollectionUtil:GetRealSlotID(self:GetID())) then
		return false
	end

	return true
end

function ECEnchantSlotMixin:PlaySetEnchantAnim()
	self.SheenTexture.Shine:Stop()
	self.SheenTexture.Shine:Play()
end

function ECEnchantSlotMixin:OnEnter()
	ECEnchantMixin.OnEnter(self)

	if self:CanExtract() then
		local msg = ENCHANT_COLLECTION_TOOLTIP_EXTRACT

		if not(EnchantCollectionUtil:GetAltar()) then
			msg = msg.."|cffFF0000 - "..ENCHANT_COLLECTION_NO_ALTAR.."|r"
		end

		GameTooltip:AddLine(msg, 0, 1, 0, 1)
	end

	if not self.isFitLevel then
		local reqLevel = self:GetRequiredLevel()
		if reqLevel then
			GameTooltip:AddLine(string.format(ITEM_MIN_LEVEL, reqLevel), 1, 0, 0, 1)
		end
	end

	if self:CanRemove() or self:HasTempSlotData() then
		GameTooltip:AddLine("Right Click to |cffFFFFFFRemove|r Mystic Enchant", 0, 1, 0, 1) -- TODO: TO globalstrings
	end

	GameTooltip.hasEnchantSlot = true

	if C_CVar.GetBool("showTooltipID") and (PTR_CLIENT or IsGMClient) then
	    GameTooltip:AddLine("|cfff73600Slot ID|r |cfffc8a00"..self:GetID().."|r")
	    GameTooltip:AddLine("|cfff73600Real Slot ID|r |cfffc8a00"..EnchantCollectionUtil:GetRealSlotID(self:GetID()).."|r")
	end

	if (self.errorMessages) then
		GameTooltip:AddLine(_G[self.errorMessages] or self.errorMessages, 1, 0, 0, 1)
	end

	GameTooltip:Show()
end

function ECEnchantSlotMixin:PlayPlaceAnim()
	self.AppearAG:Stop()
	self.AppearAG:Play()
	
	self.shockWave.AnimSplash:Stop()
	self.shockWave.AnimSplash:Play()

	self.glow.AnimSplash:Stop()
	self.glow.AnimSplash:Play()
end

function ECEnchantSlotMixin:Layout()
	ECEnchantMixin.Layout(self)

	self.QualityBorder = self:CreateTexture(nil, "ARTWORK")
	self.QualityBorder:SetPoint("CENTER")
	self.QualityBorder:SetSize(96, 96)
	self.QualityBorder:Hide()

	self.DisabledOverlayFrame = CreateFrame("FRAME", "$parent.DisabledOverlayFrame", self)
	self.DisabledOverlayFrame:SetPoint("TOPLEFT")
	self.DisabledOverlayFrame:SetPoint("BOTTOMRIGHT")

	self.DisabledOverlayFrame.Lock = self.DisabledOverlayFrame:CreateTexture(nil, "BACKGROUND")
	self.DisabledOverlayFrame.Lock:SetAtlas("EnchantSlotEmptyNormal2", Const.TextureKit.IgnoreAtlasSize)
	self.DisabledOverlayFrame.Lock:SetPoint("CENTER")
	self.DisabledOverlayFrame.Lock:SetSize(80, 80)

	self.DisabledOverlayFrame.Level = self.DisabledOverlayFrame:CreateFontString(nil, "OVERLAY")
	self.DisabledOverlayFrame.Level:SetFontObject("SystemFont_Shadow_Large2")
	self.DisabledOverlayFrame.Level:SetPoint("CENTER", 0, -8)
	self.DisabledOverlayFrame.Level:SetVertexColor(1, 0.64, 0.56)
	self.DisabledOverlayFrame.Level:SetText(16)
	self.DisabledOverlayFrame.Level:Hide()

	self.DisabledOverlayFrame.Shadow = self.DisabledOverlayFrame:CreateTexture(nil, "BORDER")
	self.DisabledOverlayFrame.Shadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.DisabledOverlayFrame.Shadow:SetPoint("CENTER", self.DisabledOverlayFrame.Level, 0, 0)
	self.DisabledOverlayFrame.Shadow:SetHeight(96)
	self.DisabledOverlayFrame.Shadow:SetWidth(96)
	self.DisabledOverlayFrame.Shadow:SetAlpha(0.4)

	self.DisabledOverlayFrame.Shadow2 = self.DisabledOverlayFrame:CreateTexture(nil, "ARTWORK")
	self.DisabledOverlayFrame.Shadow2:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.DisabledOverlayFrame.Shadow2:SetPoint("CENTER", self.DisabledOverlayFrame.Level, 0, 0)
	self.DisabledOverlayFrame.Shadow2:SetHeight(32)
	self.DisabledOverlayFrame.Shadow2:SetWidth(32)
	self.DisabledOverlayFrame.Shadow2:SetAlpha(0.8)
	self.DisabledOverlayFrame.Shadow2:Hide()

	self.DisabledOverlayFrame:Hide()

	self.AppearAG = self:CreateAnimationGroup()

	self.AppearAG.Alpha = self.AppearAG:CreateAnimation("ALPHA")
	self.AppearAG.Alpha:SetDuration(0)
	self.AppearAG.Alpha:SetChange(-1)
	self.AppearAG.Alpha:SetOrder(1)

	self.AppearAG.Scale = self.AppearAG:CreateAnimation("SCALE")
	self.AppearAG.Scale:SetDuration(0)
	self.AppearAG.Scale:SetScale(1.5, 1.5)
	self.AppearAG.Scale:SetOrder(1)

	self.AppearAG.Alpha2 = self.AppearAG:CreateAnimation("ALPHA")
	self.AppearAG.Alpha2:SetDuration(0.3)
	self.AppearAG.Alpha2:SetChange(1)
	self.AppearAG.Alpha2:SetOrder(2)

	self.AppearAG.Scale = self.AppearAG:CreateAnimation("SCALE")
	self.AppearAG.Scale:SetDuration(0.2)
	self.AppearAG.Scale:SetScale(0.67, 0.67)
	self.AppearAG.Scale:SetOrder(2)
	self.AppearAG.Scale:SetSmoothing("OUT")

	self.shockWave = self:CreateTexture(nil, "OVERLAY")
	self.shockWave:SetSize(80, 80)
	self.shockWave:SetTexture("SPELLS\\7fx_alphamask_shockwavesoft_contrast_256")
	self.shockWave:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.shockWave:SetAlpha(0)
	self.shockWave:SetPoint("CENTER")
	self.shockWave:SetBlendMode("ADD")

	self.shockWave.AnimSplash = self.shockWave:CreateAnimationGroup()

	self.shockWave.AnimSplash.Alpha = self.shockWave.AnimSplash:CreateAnimation("Alpha")
	self.shockWave.AnimSplash.Alpha:SetDuration(0.2)
	self.shockWave.AnimSplash.Alpha:SetOrder(1)
	self.shockWave.AnimSplash.Alpha:SetEndDelay(0)
	self.shockWave.AnimSplash.Alpha:SetSmoothing("IN")
	self.shockWave.AnimSplash.Alpha:SetChange(1)

	self.shockWave.AnimSplash.Scale2 = self.shockWave.AnimSplash:CreateAnimation("Scale")
	self.shockWave.AnimSplash.Scale2:SetScale(2, 2)
	self.shockWave.AnimSplash.Scale2:SetDuration(1)
	self.shockWave.AnimSplash.Scale2:SetOrder(1)
	self.shockWave.AnimSplash.Scale2:SetSmoothing("OUT")

	self.shockWave.AnimSplash.Rotation2 = self.shockWave.AnimSplash:CreateAnimation("ROTATION")
	self.shockWave.AnimSplash.Rotation2:SetDuration(1)
	self.shockWave.AnimSplash.Rotation2:SetOrder(1)
	self.shockWave.AnimSplash.Rotation2:SetDegrees(-90)

	self.shockWave.AnimSplash.Alpha2 = self.shockWave.AnimSplash:CreateAnimation("Alpha")
	self.shockWave.AnimSplash.Alpha2:SetStartDelay(0.4)
	self.shockWave.AnimSplash.Alpha2:SetDuration(0.6)
	self.shockWave.AnimSplash.Alpha2:SetOrder(1)
	self.shockWave.AnimSplash.Alpha2:SetEndDelay(0)
	self.shockWave.AnimSplash.Alpha2:SetSmoothing("OUT")
	self.shockWave.AnimSplash.Alpha2:SetChange(-1)

	self.glow = self:CreateTexture(nil, "BACKGROUND")
	self.glow:SetSize(256, 256)
	self.glow:SetTexture("SPELLS\\glow_256")
	self.glow:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.glow:SetAlpha(0)
	self.glow:SetPoint("CENTER")
	self.glow:SetBlendMode("ADD")

	self.glow.AnimSplash = self.glow:CreateAnimationGroup()

	self.glow.AnimSplash.Alpha = self.glow.AnimSplash:CreateAnimation("Alpha")
	self.glow.AnimSplash.Alpha:SetDuration(0.2)
	self.glow.AnimSplash.Alpha:SetOrder(1)
	self.glow.AnimSplash.Alpha:SetEndDelay(0)
	self.glow.AnimSplash.Alpha:SetSmoothing("IN")
	self.glow.AnimSplash.Alpha:SetChange(1)

	self.glow.AnimSplash.Scale2 = self.glow.AnimSplash:CreateAnimation("Scale")
	self.glow.AnimSplash.Scale2:SetScale(0.5, 0.5)
	self.glow.AnimSplash.Scale2:SetDuration(1)
	self.glow.AnimSplash.Scale2:SetOrder(1)
	self.glow.AnimSplash.Scale2:SetSmoothing("OUT")

	self.glow.AnimSplash.Rotation2 = self.glow.AnimSplash:CreateAnimation("ROTATION")
	self.glow.AnimSplash.Rotation2:SetDuration(1)
	self.glow.AnimSplash.Rotation2:SetOrder(1)
	self.glow.AnimSplash.Rotation2:SetDegrees(-90)

	self.glow.AnimSplash.Alpha2 = self.glow.AnimSplash:CreateAnimation("Alpha")
	self.glow.AnimSplash.Alpha2:SetStartDelay(0.4)
	self.glow.AnimSplash.Alpha2:SetDuration(0.6)
	self.glow.AnimSplash.Alpha2:SetOrder(1)
	self.glow.AnimSplash.Alpha2:SetEndDelay(0)
	self.glow.AnimSplash.Alpha2:SetSmoothing("OUT")
	self.glow.AnimSplash.Alpha2:SetChange(-1)


	self.ActiveAnimationTexture = self:CreateTexture(nil, "OVERLAY")
	self.ActiveAnimationTexture:SetSize(96, 96)
	self.ActiveAnimationTexture:SetPoint("CENTER", 0, 0)
	self.ActiveAnimationTexture:SetAlpha(0)
	self.ActiveAnimationTexture:SetBlendMode("ADD")

	self.ActiveAnimationTexture.Breathing = self.ActiveAnimationTexture:CreateAnimationGroup(nil)
	self.ActiveAnimationTexture.Breathing:SetLooping("REPEAT")

	self.ActiveAnimationTexture.Breathing.Alpha = self.ActiveAnimationTexture.Breathing:CreateAnimation("ALPHA")
	self.ActiveAnimationTexture.Breathing.Alpha:SetDuration(1)
	self.ActiveAnimationTexture.Breathing.Alpha:SetOrder(1)
	self.ActiveAnimationTexture.Breathing.Alpha:SetChange(1)

	self.ActiveAnimationTexture.Breathing.Alpha2 = self.ActiveAnimationTexture.Breathing:CreateAnimation("ALPHA")
	self.ActiveAnimationTexture.Breathing.Alpha2:SetDuration(1)
	self.ActiveAnimationTexture.Breathing.Alpha2:SetOrder(2)
	self.ActiveAnimationTexture.Breathing.Alpha2:SetChange(-1)

	self.SheenTexture = self:CreateTexture(nil, "OVERLAY")
	self.SheenTexture:SetAtlas("itemupgrade_fx_framedecor_micafleckssheen", Const.TextureKit.IgnoreAtlasSize)
	self.SheenTexture:SetSize(64, 64)
	self.SheenTexture:SetBlendMode("ADD")
	self.SheenTexture:SetPoint("CENTER", 0, 0)
	self.SheenTexture:SetAlpha(0)

	self.SheenTexture.Shine = self.SheenTexture:CreateAnimationGroup(nil)

	self.SheenTexture.Shine.Transition1 = self.SheenTexture.Shine:CreateAnimation("Translation")
	self.SheenTexture.Shine.Transition1:SetOrder(1)
	self.SheenTexture.Shine.Transition1:SetOffset(-24, 24)
	self.SheenTexture.Shine.Transition1:SetDuration(0)

	self.SheenTexture.Shine.Scale1 = self.SheenTexture.Shine:CreateAnimation("SCALE")
	self.SheenTexture.Shine.Scale1:SetOrder(1)
	self.SheenTexture.Shine.Scale1:SetScale(0.1, 0.1)
	self.SheenTexture.Shine.Scale1:SetDuration(0)

	local duration = 0.5

	self.SheenTexture.Shine.Alpha1 = self.SheenTexture.Shine:CreateAnimation("ALPHA")
	self.SheenTexture.Shine.Alpha1:SetOrder(2)
	self.SheenTexture.Shine.Alpha1:SetChange(0.75)
	self.SheenTexture.Shine.Alpha1:SetDuration(duration)

	self.SheenTexture.Shine.Transition2 = self.SheenTexture.Shine:CreateAnimation("Translation")
	self.SheenTexture.Shine.Transition2:SetOrder(2)
	self.SheenTexture.Shine.Transition2:SetOffset(24, -24)
	self.SheenTexture.Shine.Transition2:SetDuration(duration)

	self.SheenTexture.Shine.Scale2 = self.SheenTexture.Shine:CreateAnimation("SCALE")
	self.SheenTexture.Shine.Scale2:SetOrder(2)
	self.SheenTexture.Shine.Scale2:SetScale(10, 10)
	self.SheenTexture.Shine.Scale2:SetDuration(duration)

	self.SheenTexture.Shine.Alpha3 = self.SheenTexture.Shine:CreateAnimation("ALPHA")
	self.SheenTexture.Shine.Alpha3:SetOrder(3)
	self.SheenTexture.Shine.Alpha3:SetChange(-1)
	self.SheenTexture.Shine.Alpha3:SetDuration(duration)

	self.SheenTexture.Shine.Transition3 = self.SheenTexture.Shine:CreateAnimation("Translation")
	self.SheenTexture.Shine.Transition3:SetOrder(3)
	self.SheenTexture.Shine.Transition3:SetOffset(24, -24)
	self.SheenTexture.Shine.Transition3:SetDuration(duration)

	self.SheenTexture.Shine.Scale3 = self.SheenTexture.Shine:CreateAnimation("SCALE")
	self.SheenTexture.Shine.Scale3:SetOrder(3)
	self.SheenTexture.Shine.Scale3:SetScale(0.1, 0.1)
	self.SheenTexture.Shine.Scale3:SetDuration(duration)
end
-------------------------------------------------------------------------------
--                             ECEnchantItemMixin                            --
-------------------------------------------------------------------------------
-- this mixin serves for enchant activation/deactivation in slot frame
ECEnchantItemMixin = CreateFromMixins("ECEnchantMixin")

function ECEnchantItemMixin:Init()
	self:SetState(Enum.ECSlotStates.Unknown, true)
	self:VisualUpdate()
	self:Show()
end

-------------------------------------------------------------------------------
--                          ECEnchantAnimatedMixin                           --
-------------------------------------------------------------------------------
-- this mixin serves for enchant activation/deactivation in slot frame
ECEnchantAnimatedMixin = CreateFromMixins("ECEnchantMixin")

function ECEnchantAnimatedMixin:OnLoad()
	self.borders = {}
	self:Layout()
	self:SetFrameLevel(self:GetFrameLevel()+2) -- TODO: polish later, GlowFrame mixes with bg
	self.GlowFrame:SetFrameLevel(self:GetFrameLevel()-1)

	self.sparklePool = CreateTexturePool(self.GlowFrame, "ARTWORK", "SparkleTemplate")
end

function ECEnchantAnimatedMixin:SetItem(item)
	self:SetState(Enum.ECSlotStates.Known, true)
	self:SetIcon(item:GetIcon())
	self:SetQuality(item:GetQuality())
	self.SpellID = 0
end

-- overrides ECEnchantMixin
function ECEnchantAnimatedMixin:GetBorderForState()
	return EnchantCollectionUtil:GetBorderStyleAnimated(self)
end

-- overrides ECEnchantMixin
function ECEnchantAnimatedMixin:VisualUpdate()
	self.sparklePool:ReleaseAll()

	local borderStyle = self:GetBorderForState()
	local color = nil

	for i = 1, #self.borders do
		if AtlasUtil:AtlasExists(borderStyle) then
			self.borders[i]:SetAtlas(borderStyle)
			local left, right, top, bottom = AtlasUtil:GetCoords(borderStyle)

			if (i == 1) then
				EnchantCollectionUtil:SetTexRotationWithCoord(self.borders[i], math.rad(0), left, right, top, bottom)
			elseif (i == 2) then
				EnchantCollectionUtil:SetTexRotationWithCoord(self.borders[i], math.rad(-120), left, right, top, bottom)
			elseif (i == 3) then
				EnchantCollectionUtil:SetTexRotationWithCoord(self.borders[i], math.rad(120), left, right, top, bottom)
			end
		end
	end

	if (self.state == Enum.ECSlotStates.Unknown) then
		self.Icon:Hide()
		self.KnownShadow:Hide()
		self.QuestionMark:SetAtlas(EnchantCollectionUtil:GetQuestionMarkStyle(self))
		self.QuestionMark:Show()
		color = EnchantCollectionUtil.unknownEnchantColor
	else
		self.QuestionMark:Hide()
		self.Icon:Show()
		self.KnownShadow:Show()
		color = ITEM_QUALITY_COLORS[self:GetQuality()]
	end

	self.GlowFrame.GlowTex.Breathing:Play()
	self.GlowFrame.GlowTex:SetVertexColor(color:GetRGBA())

	for i = 1, 16 do
		local size = math.random(8, 46)
		local sparkle = self.sparklePool:Acquire()
		sparkle:SetSize(size, size)
		sparkle.Anim:SetTranslationRange(-96, 96, -96, 96)
		sparkle:SetParent(self.GlowFrame)
		sparkle:ClearAndSetPoint("CENTER", math.sin(i) * 8, math.cos(i) * 8)
		sparkle.Anim:SetLifetimeRange(6, 16)
		sparkle:SetVertexColor(color:GetRGBA())
		sparkle:Show()
		sparkle.Anim:Refresh()
	end
end

function ECEnchantAnimatedMixin:PlaySlowMovement()
	for _, Border in pairs(self.borders) do
		Border.SlowMovement:Stop()
		Border.SlowMovement:Play()
	end
end

function ECEnchantAnimatedMixin:LoopMovement(toLoop)
	for _, Border in pairs(self.borders) do
		if (toLoop) then
			-- for some reason that kind of looping gives more smooth result than SetLooping
			-- if using smoothing. If smoothing is NONE Looping works just fine
			Border.SlowMovement:SetScript("OnFinished", function(self)
				self:Play()
			end)
		else
			Border.SlowMovement:SetScript("OnFinished", nil)
		end
	end
end

--EnchantCollection.Slots.ReforgeTab.AnimatedEnchant.Border
-- overrides ECEnchantMixin
function ECEnchantAnimatedMixin:Layout()
	ECEnchantMixin.Layout(self)

	self.Border:SetSize(66, 66)
	self.Border:SetPoint("CENTER", 2.5, 1)
	self.Border:SetDrawLayer("OVERLAY")

	self.Border2 = self:CreateTexture(nil, "OVERLAY")
	self.Border2:SetSize(66, 66)
	self.Border2:SetPoint("CENTER", 0, -4)

	self.Border3 = self:CreateTexture(nil, "OVERLAY")
	self.Border3:SetSize(66, 66)
	self.Border3:SetPoint("CENTER", -3, 0)

	table.insert(self.borders, self.Border)
	table.insert(self.borders, self.Border2)
	table.insert(self.borders, self.Border3)

	self.QuestionMark = self:CreateTexture(nil, "ARTWORK")
	self.QuestionMark:SetSize(96, 96)
	self.QuestionMark:SetPoint("CENTER", 0, 0)
	self.QuestionMark:Hide()

	self.KnownShadow = self:CreateTexture(nil, "ARTWORK")
	self.KnownShadow:SetSize(96, 96)
	self.KnownShadow:SetPoint("CENTER", 0, 0)
	self.KnownShadow:SetAtlas("EnchantSlotBorderKnownBorder", Const.TextureKit.IgnoreAtlasSize)

	self.GlowFrame = CreateFrame("FRAME", "$parent.GlowFrame", self, nil)
	self.GlowFrame:SetSize(128, 128)
	self.GlowFrame:SetPoint("CENTER")

	self.GlowFrame.GlowTex = self.GlowFrame:CreateTexture(nil, "BACKGROUND")
	self.GlowFrame.GlowTex:SetPoint("CENTER")
	self.GlowFrame.GlowTex:SetSize(256, 256)
	self.GlowFrame.GlowTex:SetTexture("spells\\mask_genericglow_a")
	self.GlowFrame.GlowTex:SetBlendMode("ADD")

	self.GlowFrame.GlowTex.Breathing = self.GlowFrame.GlowTex:CreateAnimationGroup(nil)
	self.GlowFrame.GlowTex.Breathing:SetLooping("REPEAT")

	self.GlowFrame.GlowTex.Breathing.Alpha = self.GlowFrame.GlowTex.Breathing:CreateAnimation("ALPHA")
	self.GlowFrame.GlowTex.Breathing.Alpha:SetDuration(1.5)
	self.GlowFrame.GlowTex.Breathing.Alpha:SetOrder(1)
	self.GlowFrame.GlowTex.Breathing.Alpha:SetChange(-0.5)

	self.GlowFrame.GlowTex.Breathing.Alpha2 = self.GlowFrame.GlowTex.Breathing:CreateAnimation("ALPHA")
	self.GlowFrame.GlowTex.Breathing.Alpha2:SetDuration(1.5)
	self.GlowFrame.GlowTex.Breathing.Alpha2:SetOrder(2)
	self.GlowFrame.GlowTex.Breathing.Alpha2:SetChange(0.5)

	self:LayoutAnimations()
end

function ECEnchantAnimatedMixin:LayoutAnimations()
	for i = 1, #self.borders do
		local Border = self.borders[i]

		Border.SlowMovement = Border:CreateAnimationGroup(nil)

		Border.SlowMovement.Alpha = Border.SlowMovement:CreateAnimation("ALPHA")
		Border.SlowMovement.Alpha:SetDuration(1.5)
		Border.SlowMovement.Alpha:SetOrder(1)
		Border.SlowMovement.Alpha:SetSmoothing("IN")
		Border.SlowMovement.Alpha:SetChange(-0.3)

		Border.SlowMovement.Alpha2 = Border.SlowMovement:CreateAnimation("ALPHA")
		Border.SlowMovement.Alpha2:SetDuration(1.5)
		Border.SlowMovement.Alpha2:SetOrder(2)
		Border.SlowMovement.Alpha2:SetSmoothing("OUT")
		Border.SlowMovement.Alpha2:SetChange(0.3)

		Border.SlowMovement.Rotation = Border.SlowMovement:CreateAnimation("ROTATION")
		Border.SlowMovement.Rotation:SetDuration(1.5)
		Border.SlowMovement.Rotation:SetOrder(1)
		Border.SlowMovement.Rotation:SetSmoothing("IN")
		Border.SlowMovement.Rotation:SetDegrees(-180)

		Border.SlowMovement.Rotation2 = Border.SlowMovement:CreateAnimation("ROTATION")
		Border.SlowMovement.Rotation2:SetDuration(1.5)
		Border.SlowMovement.Rotation2:SetOrder(2)
		Border.SlowMovement.Rotation2:SetSmoothing("OUT")
		Border.SlowMovement.Rotation2:SetDegrees(-180)

		Border.SlowMovement.Scale = Border.SlowMovement:CreateAnimation("SCALE")
		Border.SlowMovement.Scale:SetDuration(1.5)
		Border.SlowMovement.Scale:SetOrder(1)
		Border.SlowMovement.Scale:SetSmoothing("IN")
		Border.SlowMovement.Scale:SetScale(1.1, 1.1)

		Border.SlowMovement.Scale2 = Border.SlowMovement:CreateAnimation("SCALE")
		Border.SlowMovement.Scale2:SetDuration(1.5)
		Border.SlowMovement.Scale2:SetOrder(2)
		Border.SlowMovement.Scale2:SetSmoothing("OUT")
		Border.SlowMovement.Scale2:SetScale(0.9, 0.9)
	end
end
