-------------------------------------------------------------------------------
--                          ECCollectionsButtonMixin                         --
-------------------------------------------------------------------------------
ECCollectionsButtonMixin = {}

function ECCollectionsButtonMixin:OnLoad()
	self.enchantInfo = nil
	self.isLocked = false

	self:Layout()
	self:RegisterForClicks("AnyUp")
end

function ECCollectionsButtonMixin:OnClick(button)
	PlaySound("igMainMenuOptionCheckBoxOn")

	if button == "RightButton" then
		self:OnRightClick()
		return
	end
	
	if IsModifiedClick() then
		self:OnModifiedClick(button)
		return
	end

	if BuildCreatorUtil.IsPickingEnchants() then
		if C_Player:IsHero() or self.enchantInfo.IsAvailableForCurrentClass then
			local enchant = BuildCreatorUtil.CreateEnchantInfo(self.spellID, 1, C_Player:IsHero() and 1 or self.enchantInfo.RequiredLevel)
			if C_BuildEditor.AddRandomEnchant(enchant) then
				self:GetParent():DisplayResults()
				EnchantCollection:GetArchitectTab():Update()
			else

			end
		end
		return
	end

	if not(self:GetLocked()) then
		self:GetParent():OnSelectCollectionEnchant(self:GetID())
	end
end

function ECCollectionsButtonMixin:OnRightClick()
	if BuildCreatorUtil.IsPickingEnchants() then
		if C_BuildEditor.DoesBuildHaveEnchant(self.spellID) then
			C_BuildEditor.RemoveRandomEnchant(self.spellID)
			self:GetParent():DisplayResults()
			EnchantCollection:GetArchitectTab():Update()
		end
	end
end

function ECCollectionsButtonMixin:OnModifiedClick(button)
	ECEnchantMixin.OnModifiedClick(self, button)
end

function ECCollectionsButtonMixin:OnEnter()
	ECEnchantMixin.OnEnter(self)

	self:GetParent():OnCollectionEnchantOnEnter(self:GetID())

	if not(self:GetLocked()) then
		self.Enchant.Highlight:Show()
		self.Name:SetTextColor(GameFontHighlightMedium:GetTextColor())
		if BuildCreatorUtil.IsPickingEnchants() then 
			GameTooltip:AddLine(BUILD_CREATOR_CLICK_TO_ADD, 0, 0.82, 1)
			GameTooltip:Show()
		end
	elseif BuildCreatorUtil.IsPickingEnchants() then
		self.Enchant.Highlight:Show()
		GameTooltip:AddLine(BUILD_CREATOR_CLICK_TO_REMOVE, 0, 0.82, 1)
		GameTooltip:Show()
	end
end

function ECCollectionsButtonMixin:OnLeave()
	GameTooltip:Hide()
	self.Enchant.Highlight:Hide()

	if not(self:GetLocked()) then
		if not(self.isSelected) then
			self.Name:SetTextColor(GameFontNormal:GetTextColor())
		end
	end
end

function ECCollectionsButtonMixin:Init(index)
	self:SetID(index)

	local enchantInfo = self:GetParent():GetQueriedEnchantData(self:GetID())

	local name, _, icon = GetSpellInfo(enchantInfo.SpellID)

	if not(name) then
		C_Logger.Error("Error loading enchant with spellID: "..enchantInfo.SpellID.." Please update your patch")
		return
	end

	self.spellID = enchantInfo.SpellID
	self.enchantInfo = enchantInfo

	local quality = EnchantCollectionUtil:GetQualityFromQualityName(enchantInfo.Quality)
	local isWorldForged = C_MysticEnchant.GetEnchantInfoBySpell(enchantInfo.SpellID).IsWorldforged
	local isLocked = false

	self.Enchant:SetQuality(quality, true)
	self.Enchant:SetIcon(icon)
	self.Enchant:SetState(Enum.ECSlotStates.Known)
	self.Name:SetText(name)
	self.Name:SetPoint("LEFT", self.Enchant, "RIGHT", 12, 0)
	self.SubTitle:SetText("")
	self.Enchant.DisabledOverlay:Hide()

	if (isWorldForged) then
		self.Name:SetPoint("LEFT", self.Enchant, "RIGHT", 12, 6)
		self.SubTitle:SetText(ENCHANT_COLLECTION_WORLDFORGED)
	end

	if enchantInfo.Spec then
		self.Name:SetPoint("LEFT", self.Enchant, "RIGHT", 12, 6)
		self.SubTitle:SetText(EnchantCollectionUtil:GetSpecString(enchantInfo))
	end
	
	if BuildCreatorUtil.IsPickingEnchants() then
		isLocked = C_BuildEditor.DoesBuildHaveEnchant(self.spellID)
	else
		local fitsLevel = enchantInfo.RequiredLevel <= UnitLevel("player")

		if not isLocked then -- make sure not to unlock
			isLocked = not self.enchantInfo.Known
		end

		if not(fitsLevel) and enchantInfo.IsAvailableForCurrentClass then
			self.Name:SetPoint("LEFT", self.Enchant, "RIGHT", 12, 6)
			self.SubTitle:SetText("|cffFF0000"..(string.format(ITEM_MIN_LEVEL, enchantInfo.RequiredLevel)))
		end
	end

	self.Enchant.DisabledOverlay:SetShown(isLocked)
	self:SetLocked(isLocked and ECEnchantMixin.LockState.Locked or ECEnchantMixin.LockState.Unlocked)

	local selectedSpellID = self:GetParent():GetSelectedSpellID()
	self.isSelected = selectedSpellID and (selectedSpellID == self.spellID)

	if self.isSelected then
		self.Name:SetTextColor(GameFontHighlightMedium:GetTextColor())
		self.Enchant:ShowSelected()
	else
		self.Enchant:HideSelected()
	end
end

function ECCollectionsButtonMixin:GetLocked()
	return self.isLocked
end

function ECCollectionsButtonMixin:SetLocked(lockState)
	self.Enchant:SetLocked(lockState)

	if lockState == ECEnchantMixin.LockState.Unlocked then
		self.Name:SetTextColor(GameFontNormal:GetTextColor())
		self.SubTitle:SetTextColor(GameFontNormal:GetTextColor())
		self.SubTitle:SetAlpha(1)
	else
		self.Name:SetTextColor(GameFontDisable:GetTextColor())
		self.SubTitle:SetTextColor(GameFontDisable:GetTextColor())
		self.SubTitle:SetAlpha(0.6)
	end

	self.isLocked = lockState ~= ECEnchantMixin.LockState.Unlocked
end

function ECCollectionsButtonMixin:Layout()
	self:SetSize(224, 64)
	
	self.Enchant = CreateFrame("BUTTON", "$parent.Enchant", self, "EnchantCollectionEnchantItem")
	self.Enchant:SetPoint("LEFT", 20, 2)
	self.Enchant:SetScale(0.8)
	self.Enchant:EnableMouse(false)
	self.Enchant:Show()

    self.Enchant.DisabledOverlay = CreateFrame("FRAME", "$parent.DisabledOverlay", self.Enchant, "DisabledOverlayTemplate")
    self.Enchant.DisabledOverlay.DisabledBlack:SetAtlas("talents-node-choiceflyout-square-shadow", Const.TextureKit.IgnoreAtlasSize)
    self.Enchant.DisabledOverlay.DisabledBlack:SetAlpha(0.7)
    self.Enchant.DisabledOverlay.DisabledOverlay:SetAtlas("talents-node-choiceflyout-circle-locked", Const.TextureKit.IgnoreAtlasSize)
    self.Enchant.DisabledOverlay:SetPoint("CENTER", 0, -1)
    self.Enchant.DisabledOverlay:SetSize(48, 48)
    self.Enchant.DisabledOverlay:Hide()

	self.Name = self:CreateFontString(nil, "OVERLAY")
	self.Name:SetFontObject(GameFontHighlightMedium)
	self.Name:SetPoint("LEFT", self.Enchant, "RIGHT", 12, 0)
	self.Name:SetWidth(156)
	self.Name:SetJustifyH("LEFT")
	self.Name:SetJustifyV("CENTER")

	--[[self.NameHelperFrame = CreateFrame("FRAME", "$parent.NameHelperFrame", self)
	self.NameHelperFrame:SetPoint("TOPLEFT", self.Name, "TOPLEFT", 0, 0)
	self.NameHelperFrame:SetPoint("BOTTOMRIGHT", self.Name, "BOTTOMRIGHT", 0, 0)
	self.NameHelperFrame:SetBackdrop(GameTooltip:GetBackdrop())]]--

	self.SubTitle = self:CreateFontString(nil, "OVERLAY")
	self.SubTitle:SetFontObject(GameFontNormal)
	self.SubTitle:SetPoint("TOPLEFT", self.Name, "BOTTOMLEFT", 0, -2)
	self.SubTitle:SetJustifyH("LEFT")
	self.SubTitle:SetJustifyV("CENTER")
	self.SubTitle:SetWidth(156)
	--self.SubTitle:SetText("Enchant Subtitle")

	--self:SetBackdrop(GameTooltip:GetBackdrop())
	--self:SetBackdropColor(0, 0, 0, 0)

	self.HighlightTexture = self:CreateTexture(nil, "OVERLAY")
	self.HighlightTexture:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
	self.HighlightTexture:SetAllPoints(true)
	self.HighlightTexture:SetBlendMode("ADD")
	self.HighlightTexture:Hide()
end