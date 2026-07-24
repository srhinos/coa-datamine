local REFORGE_SPELL = 93235

-------------------------------------------------------------------------------
--                      ECReforgeTabMixin                     --
-------------------------------------------------------------------------------
ECReforgeTabMixin = {}
ECReforgeTabMixin.OnEvent = OnEventToMethod

function ECReforgeTabMixin:OnLoad()
	self.MysticScrollCost = C_MysticEnchant.GetMysticScrollCost()
	self:Layout()
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("MYSTIC_ENCHANT_PURCHASE_MYSTIC_EXTRACT_RESULT")
end

function ECReforgeTabMixin:Init(value, skipItemUpdate)
	if not(skipItemUpdate) then
		self:UpdateItem(self.itemData and self.itemData.Entry)
	end
	
	self:UpdateButtons()
	--self.CurrencyRune:SetItem(ItemData.MYSTIC_RUNE)
end

function ECReforgeTabMixin:ClearItem()
	self.itemData = nil
	-- request next untrained scroll
	if self:GetEnchantCollection():GetScrollsTabItemData(ItemData.UNTARNISHED_MYSTIC_SCROLL) then
		self:UpdateItem(ItemData.UNTARNISHED_MYSTIC_SCROLL)
	else
		self:SetInitialSetup()
	end
end

function ECReforgeTabMixin:UpdateItem(itemID, playAnimation)
	if not(itemID) then
		self:ClearItem()
		return
	end

	if itemID == -1 then
		self.itemData = nil
		self:SetInitialSetup()
		return
	end

	local itemData = self:GetEnchantCollection():GetScrollsTabItemData(itemID)

	if not(itemData) or not(itemData.Entry) then
		self:ClearItem()
		return
	end

	if self.itemData then
		if itemData.Entry == self.itemData.Entry then
			return
		end
	end

	self.itemData = itemData

	self:GetEnchantCollection():SetScrollTabSelectedItem(itemID)

	local item = Item:CreateFromID(self.itemData.Entry)

	if (itemData.Entry == ItemData.UNTARNISHED_MYSTIC_SCROLL) then
		self:SetUntrainedScroll()
	else
		self:SetScroll(item, playAnimation)
	end
end

function ECReforgeTabMixin:RefreshMysticScrollCost()
	self.MysticScrollCost = C_MysticEnchant.GetMysticScrollCost()

	if not(self.MysticScrollCost) then
		local item = Item:CreateFromID(ItemData.UNTARNISHED_MYSTIC_SCROLL)

		item:ContinueOnLoad(function(item)
			Timer.After(0.5, function() self:RefreshMysticScrollCost() end)
		end)
		return 
	end

	self.Button1:Update()
end

function ECReforgeTabMixin:GetMysticScrollCost()
	return {[Enum.UnlearnCost.Gold] = self.MysticScrollCost or 12345}
end

function ECReforgeTabMixin:SetInitialSetup()
	--PlaySound(SOUNDKIT.SPELL_PR_REVAMP_HOLY_WORD_SERENITY_IMPACT_01)

	self.ProgressBar:Hide()
	self.Button2:Hide()
	if (self.AnimatedEnchant:IsVisible()) then
		BaseFrameFadeOut(self.AnimatedEnchant)
	end
	self.EnchantName:Hide()
	self.SubTitle:SetText("")

	self:GetEnchantCollection():SetScrollTabSelectedItem(nil)

	if not(self.MysticScrollCost) then
		self:RefreshMysticScrollCost()
	end

	self:UpdateButton(self.Button1, GenerateClosure(self.GetMysticScrollCost, self), GenerateClosure(self.BuyScroll, self), ENCHANT_COLLECTION_OBTAIN_SCROLLS)
	self.Button1:ClearAndSetPoint("BOTTOM", 0, 64)
end

function ECReforgeTabMixin:SetUntrainedScroll()
	--PlaySound(SOUNDKIT.SPELL_PR_REVAMP_HOLY_WORD_SERENITY_IMPACT_01)

	self.ProgressBar:Hide()
	self.SubTitle:SetText("")
	
	self.EnchantName:Hide()
	self.EnchantName:Hide()
	
	BaseFrameFadeIn(self.AnimatedEnchant)
	self.AnimatedEnchant:SetEnchant(0)
	self.AnimatedEnchant:LoopMovement(true)
	self.AnimatedEnchant:PlaySlowMovement()

	self:UpdateButton(self.Button1, EnchantCollectionUtil.CalculateReforgeCost, GenerateClosure(self.Reforge, self), ENCHANT_COLLECTION_REFORGE)

	-- show 2 buttons if user has known enchants
	if self:GetEnchantCollection():IsAnyEnchantKnown() then
		self.Button1:ClearAndSetPoint("BOTTOM", self, "BOTTOM", 0, 88)
		self.Button2:Show()
		self.Button2.YellowGlow:Hide()
		self:UpdateButton(self.Button2, nil, GenerateClosure(self.CollectionReforgeScroll, self), ENCHANT_COLLECTION_SCROLL_COLLECTION_REFORGE)
	else
		self.Button1:ClearAndSetPoint("BOTTOM", 0, 64)
		self.Button2:Hide()
	end
end

function ECReforgeTabMixin:SetScroll(item, playAnimation)
	dprint("ECReforgeTabMixin:SetScroll")
	--PlaySound(SOUNDKIT.SPELL_PR_REVAMP_HOLY_WORD_SERENITY_IMPACT_01)
	self.AnimatedEnchant:Hide()
	self.ProgressBar:Show()
	self.EnchantName:Show()
	self.SubTitle:SetText("")

	local REData = C_MysticEnchant.GetEnchantInfoByItem(item:GetItemID())
	local fitsLevel = REData.RequiredLevel <= UnitLevel("player")

	if (REData) then
		self.AnimatedEnchant:SetEnchant(REData.SpellID)
	else
		self.AnimatedEnchant:SetItem(item)
	end

	if self.isPlayingAnimation then
		self.isPlayingAnimation = false -- not to overwrite enchant when you click another scroll during the anim process
		self:GetEnchantCollection():BAG_UPDATE()
	end

	if playAnimation then
		self.isPlayingAnimation = true

		self.ReforgeAnimation:SetQuality(REData.Quality)
		self.PostReforgeAnimation:SetQuality(REData.Quality)
		self.PostReforgeAnimation.explosionCallBack = function() 
			if self.isPlayingAnimation then 
				self:SetScroll(item) 
				
			end 
		end
		self.PostReforgeAnimation:Play()
		return
	else
		BaseFrameFadeIn(self.AnimatedEnchant)
	end
	
	self.AnimatedEnchant:LoopMovement(false)
	self.AnimatedEnchant:PlaySlowMovement()

	if (REData and REData.Known) then
		self.Button2:Hide()
		self.Button1:ClearAndSetPoint("BOTTOM", 0, 64)
	else
		self.Button2:Show()
		self.Button2.YellowGlow:SetShown(REData.IsAvailableForCurrentClass)
		self:UpdateButton(self.Button2, function() return EnchantCollectionUtil:CalculateExtractCost(REData.SpellID) end, GenerateClosure(self.SaveToCollection, self), ENCHANT_COLLECTION_SAVE_TO_COLLECTION)
		self.Button1:ClearAndSetPoint("BOTTOM", self, "BOTTOM", 0, 88)
	end

	self:UpdateButton(self.Button1, EnchantCollectionUtil.CalculateReforgeCost, GenerateClosure(self.Reforge, self), ENCHANT_COLLECTION_REFORGE)

	self.EnchantName:SetText(item:GetName())

	self.SubTitle:SetText(EnchantCollectionUtil:GetSpecString(REData))

	if REData.IsAvailableForCurrentClass then
		if not(fitsLevel) then
			self.SubTitle:SetText("|cffFF0000"..(string.format(ITEM_MIN_LEVEL, REData.RequiredLevel)))
		end
	end
end

function ECReforgeTabMixin:UpdateButton(button, GetCostFunc, func, text)
	button.text = text
	button.GetCostFunc = GetCostFunc
	button:SetScript("OnClick", func)

	button:Update()

	if (text == ENCHANT_COLLECTION_SAVE_TO_COLLECTION) and (button:IsEnabled() == 0) and not(button.tooltipTitle) then
		button:SetScript("OnEnter", function() self:GetEnchantCollection():ShowSaveToCollectionTutorial() end)
		button:SetScript("OnLeave", function() self:GetEnchantCollection():HideSaveToCollectionTutorial() end)
	else
		button:SetScript("OnEnter", ECButtonWithCostMixin.OnEnter)
		button:SetScript("OnLeave", ECButtonWithCostMixin.OnLeave)
	end
end

function ECReforgeTabMixin:UpdateButtons()
	self.Button1:Update()
	self.Button2:Update()
end

function ECReforgeTabMixin:StopReforgeAnim()
	BaseFrameFadeOut(self.ReforgeAnimation)
end

function ECReforgeTabMixin:Reforge()
	if self.itemData and next(self.itemData) then
		if EnchantCollectionUtil:AttemptOperation("ReforgeItem", "CanReforgeItem", self.itemData.Guid) then
			self:GetEnchantCollection():SetWaitingForReforge()
			BaseFrameFadeOut(self.AnimatedEnchant)
			self.ReforgeAnimation:Play()
			self.Button1:Disable()
		end
	end
end

function ECReforgeTabMixin:MYSTIC_ENCHANT_REFORGE_RESULT(result)
	if result == "RE_REFORGE_OK" then
		return
	end
	
	self.Button1:Update()
end

function ECReforgeTabMixin:SPELL_UPDATE_COOLDOWN()
	local startTime, duration, enabled = GetSpellCooldown(REFORGE_SPELL)
	if duration and duration > 0 then
		self.Button1:Disable()
	else
		self.Button1:Update()
	end
end

function ECReforgeTabMixin:MYSTIC_ENCHANT_PURCHASE_MYSTIC_EXTRACT_RESULT(result)
	if result:endswith("_OK") then
		EnchantCollectionUtil:AttemptOperation("DisenchantItem", "CanDisenchantItem", self.itemData.Guid, MysticEnchantUtil.NeedsToPurchaseExtract())
	end
end

function ECReforgeTabMixin:BuyScroll()
	EnchantCollectionUtil:AttemptOperation("PurchaseMysticScroll", "CanPurchaseMysticScroll")
end

function ECReforgeTabMixin:CollectionReforgeScroll()
	self:GetEnchantCollection():CollectionReforgeScroll(self.itemData)
end

function ECReforgeTabMixin:GetEnchantCollection()
	return self:GetParent():GetParent()
end

function ECReforgeTabMixin:SaveToCollection()
	EnchantCollectionUtil:ShowDisenchantItemDialogue(self.itemData.Entry, self.itemData.Guid)
end

function ECReforgeTabMixin:PurchaseExtract()
	if C_MysticEnchant.CanPurchaseMysticExtract() then
		self.Button2:Disable()
		C_MysticEnchant.PurchaseMysticExtract()
	end
end

function ECReforgeTabMixin:Layout()
	self.bg = self:CreateTexture(nil, "BACKGROUND")
	self.bg:SetAtlas("Enchant-Slot-Frame-Background", Const.TextureKit.UseAtlasSize)
	self.bg:SetPoint("CENTER", -2, -22)

	self.anvil = self:CreateTexture(nil, "BORDER")
	self.anvil:SetAtlas("Enchant-Reforge-Anvil", Const.TextureKit.UseAtlasSize)
	self.anvil:SetPoint("BOTTOM", -2, 0)

	self.Button1 = CreateFrame("BUTTON", "$parent.Button1", self, "SharedButtonTemplate")
	self.Button1:SetSize(172, 40)
	self.Button1:SetPoint("BOTTOM", self, "BOTTOM", -4, 88)
	self.Button1.CooldownSpellID = REFORGE_SPELL
	MixinAndLoadScripts(self.Button1, ECButtonWithCostMixin)

	self.Button2 = CreateFrame("BUTTON", "$parent.Button2", self, "SharedButtonTemplate")
	self.Button2:SetSize(172, 40)
	self.Button2:SetPoint("TOP", self.Button1, "BOTTOM", 0, -8)
	MixinAndLoadScripts(self.Button2, ECButtonWithCostMixin)
	self.Button2.YellowGlow = CreateFrame("Frame", "$parentYellowGlow", self.Button2, "ButtonYellowGlowTemplate")
	self.Button2.YellowGlow:SetFrameLevel(self.Button2:GetFrameLevel() - 1)
	self.Button2.YellowGlow:SetPoint("TOPLEFT", -8, 16)
	self.Button2.YellowGlow:SetPoint("BOTTOMRIGHT", 8, -16)

	self.ProgressBar = CreateFrame("FRAME", "$parent.ProgressBar", self, "EnchantCollectionProgressBar")
	self.ProgressBar:SetPoint("TOP", 0, -48)
	self.ProgressBar:Hide()

	self.AnimatedEnchant = CreateFrame("BUTTON", "$parent.AnimatedEnchant", self, "EnchantCollectionEnchantAnimated")
	self.AnimatedEnchant:SetPoint("CENTER", 0, 48)
	self.AnimatedEnchant:SetScale(1.2)
	self.AnimatedEnchant:Hide()

	self.EnchantName = self.AnimatedEnchant:CreateFontString(nil, "OVERLAY")
	self.EnchantName:SetFontObject("SystemFont_Shadow_Large2")
	self.EnchantName:SetJustifyH("CENTER")
	self.EnchantName:SetJustifyV("TOP")
	self.EnchantName:SetPoint("TOP", self.AnimatedEnchant, "BOTTOM", 0, -16)
	self.EnchantName:SetWidth(256)

	self.SubTitle = self.AnimatedEnchant:CreateFontString(nil, "OVERLAY")
	self.SubTitle:SetFontObject(GameFontNormal)
	self.SubTitle:SetPoint("TOP", self.EnchantName, "BOTTOM", 0, -2)
	self.SubTitle:SetJustifyH("CENTER")
	self.SubTitle:SetJustifyV("CENTER")

	--[[self.CurrencyRune = CreateFrame("BUTTON", "$parent.CurrencyRune", self, nil)
	self.CurrencyRune:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -2)
	self.CurrencyRune:SetWidth(196)
	MixinAndLoadScripts(self.CurrencyRune, ECCurrencyFrameMixin)
	self.CurrencyRune:SetItem(ItemData.MYSTIC_RUNE)]]--

	self.ReforgeAnimation = CreateFrame("FRAME", "$parent.ReforgeAnimation", self, nil)
	self.ReforgeAnimation:SetSize(376, 376)
	self.ReforgeAnimation:SetPoint("CENTER", self.AnimatedEnchant, "CENTER", 0, 0)
	self.ReforgeAnimation:Hide()
	MixinAndLoadScripts(self.ReforgeAnimation, ECEnchantUnlockAnimMixin)

	self.PostReforgeAnimation = CreateFrame("FRAME", "$parent.PostReforgeAnimation", self, nil)
	self.PostReforgeAnimation:SetSize(376, 376)
	self.PostReforgeAnimation:SetPoint("CENTER", self.AnimatedEnchant, "CENTER", 0, 0)
	self.PostReforgeAnimation:Hide()
	self.PostReforgeAnimation.animTime = 2
	self.PostReforgeAnimation.flashStartDelay = 0.8
	MixinAndLoadScripts(self.PostReforgeAnimation, ECEnchantPostReforgeMixin)
end