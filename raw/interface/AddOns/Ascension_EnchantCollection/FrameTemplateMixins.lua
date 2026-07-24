ECButtonWithCostMixin = {}

function ECButtonWithCostMixin:OnLoad()
	self.text = self.text or ""
	self.GetCostFunc = self.GetCostFunc or nil
	self:Layout()
	self:SetMotionScriptsWhileDisabled(true)
end

function ECButtonWithCostMixin:OnUpdate()
	self:SetText(self:GetText())
end

function ECButtonWithCostMixin:OnEnter()
	if self.tooltipTitle then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.tooltipTitle, 1, 0, 0)
		GameTooltip:Show()
	end
end

function ECButtonWithCostMixin:OnLeave()
	GameTooltip:Hide()
end

function ECButtonWithCostMixin:Update(skipAltarCheck)
	if (self.GetCostFunc) then
		self.cost = self:GetCostFunc()
	else
		self.cost = nil
	end

	if self.cost and next(self.cost) then
		self:SetText(EnchantCollectionUtil:FormatCostIconOnly(self.cost).." "..self.text)
	else
		self:SetText(self.text)
	end

	self:SetWidth(math.max(self:GetFontString():GetWidth()+60, 172))

	if not(EnchantCollectionUtil:GetAltar()) and not(skipAltarCheck) then
		self.tooltipTitle = RE_PURCHASE_NO_MYSTIC_ALTAR

		self:Disable()
		return
	end

	self.tooltipTitle = nil

	if not CostUtil:CanPayThePrice(self.cost) then
		self:Disable()
		return
	end

	if self.CooldownSpellID then
		local startTime, duration = GetSpellCooldown(self.CooldownSpellID)
		if duration and duration > 0 then
			self:Disable()
			return
		end
	end
	
	self:Enable()
end


function ECButtonWithCostMixin:Layout()
	self:GetFontString():SetDrawLayer("OVERLAY")
end
-------------------------------------------------------------------------------
--                            disabled text frame                            --
-------------------------------------------------------------------------------
ECLargeDisabledTextFrameMixin = {}

function ECLargeDisabledTextFrameMixin:OnLoad()
	self:Layout()
end

function ECLargeDisabledTextFrameMixin:Layout()
	self.Shadow = self:CreateTexture(nil, "ARTWORK")
	self.Shadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.Shadow:SetPoint("CENTER")
	self.Shadow:SetSize(400, 96)

	self.Text = self:CreateFontString(nil, "OVERLAY")
	self.Text:SetWidth(350)
	self.Text:SetPoint("CENTER", 0, 0)
	self.Text:SetFontObject(GameFontDisableLarge)
end
-------------------------------------------------------------------------------
--                              Currency Preview                             --
-------------------------------------------------------------------------------
ECCurrencyFrameMixin = {}

function ECCurrencyFrameMixin:OnLoad()
	self:Layout()
	MagicButton_OnLoad(self)
end

function ECCurrencyFrameMixin:OnShow()
	self:Update()
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

function ECCurrencyFrameMixin:OnHide()
	self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

function ECCurrencyFrameMixin:OnEvent(event, ...)
	if (event == "CURRENCY_DISPLAY_UPDATE") then
		self:Update()
	elseif event == "UNIT_INVENTORY_CHANGED" then
		local unit = ...
		if unit == "player" then
			self:Update()
		end
	end
end
function ECCurrencyFrameMixin:Update()
	if (self.item) then
		self.Text:SetText(self.item:GetName()..": |cffFFFFFF"..GetItemCount(self.item:GetItemID()))
	end
end

function ECCurrencyFrameMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	if (self.item) then
		GameTooltip:SetHyperlink(self.item:GetLink())
	end
	GameTooltip:Show()
end

function ECCurrencyFrameMixin:OnLeave()
	GameTooltip:Hide()
end

function ECCurrencyFrameMixin:OnModifiedClick()
	if (self.item) then
		ChatEdit_InsertLink(self.item:GetLink())
	end
end

function ECCurrencyFrameMixin:SetItem(itemID)
	local item = Item:CreateFromID(itemID)
	self.Text:SetText(item:GetName()..": |cffFFFFFF"..GetItemCount(itemID))
	self.Icon:SetTexture(item:GetIcon())

	self.item = item
end

function ECCurrencyFrameMixin:Layout()
	self:SetHeight(22)

	self.BG_Left = self:CreateTexture(nil, "ARTWORK")
	self.BG_Left:SetSize(6, 19)
	self.BG_Left:SetPoint("LEFT", 0, 0)
	self.BG_Left:SetTexCoord(0.0, 0.01171875, 0.421875, 0.5625)
	self.BG_Left:SetTexture("Interface\\Buttons\\UI-Button-Borders2")

	self.BG_Right = self:CreateTexture(nil, "ARTWORK")
	self.BG_Right:SetSize(6, 19)
	self.BG_Right:SetPoint("RIGHT", 0, 0)
	self.BG_Right:SetTexCoord(0.3046875, 0.31640625, 0.421875, 0.5625)
	self.BG_Right:SetTexture("Interface\\Buttons\\UI-Button-Borders2")

	self.BG_Middle = self:CreateTexture(nil, "ARTWORK")
	self.BG_Middle:SetPoint("TOPLEFT", self.BG_Left, "TOPRIGHT", 0, 0)
	self.BG_Middle:SetPoint("BOTTOMRIGHT", self.BG_Right, "BOTTOMLEFT", 0, 0)
	self.BG_Middle:SetTexCoord(0.01171875, 0.3046875, 0.421875, 0.5625)
	self.BG_Middle:SetTexture("Interface\\Buttons\\UI-Button-Borders2")

	self.Icon = self:CreateTexture(nil, "OVERLAY")
	self.Icon:SetSize(14,14)
	self.Icon:SetPoint("RIGHT", -6, 0)
	self.Icon:SetTexture("Interface\\Icons\\inv_custom_abilityessence")

	self.Text = self:CreateFontString(nil, "OVERLAY")
	self.Text:SetFontObject(GameFontNormalSmall)
	self.Text:SetPoint("RIGHT", self.Icon, "LEFT", -6, 0)
	self.Text:SetJustifyH("RIGHT")
end

-------------------------------------------------------------------------------
--                          Enchant Activation Popup                         --
-------------------------------------------------------------------------------
EnchantActivationPopupMixin = {}

function EnchantActivationPopupMixin:OnLoad()
	self:Layout()

	--[[self.LineDown.AnimationGroup.Grow2:SetScript("OnPlay", function()
		BaseFrameFadeIn(self.Enchant)
	end)]]--

	self.LineDown.AnimationGroup.Grow2:SetScript("OnFinished", function()
		BaseFrameFadeOut(self)
	end)

	self.Enchant:HookScript("OnEnter", function()
		if self.LineDown.AnimationGroup.Grow2:IsPlaying() then
			self.LineUp.AnimationGroup.Grow2:Pause()
			self.LineDown.AnimationGroup.Grow2:Pause()
		end
	end)

	self.Enchant:HookScript("OnLeave", function()
		if not self.LineDown.AnimationGroup.Grow2:IsPlaying() then
			self.LineUp.AnimationGroup.Grow2:Play()
			self.LineDown.AnimationGroup.Grow2:Play()
		end
	end)
end

function EnchantActivationPopupMixin:OnShow()
	self.Enchant:Hide()
	self.Animation:Play()
	self.LineUp.AnimationGroup:Stop()
	self.LineDown.AnimationGroup:Stop()
end

function EnchantActivationPopupMixin:SetEnchant(spellID)
	if (self:IsVisible()) then
		BaseFrameFadeIn(self.Enchant)
		self.LineUp.AnimationGroup:Play()
		self.LineDown.AnimationGroup:Play()
	end

	if not(spellID) or (spellID == 0) then
		dprint("|cffFF0000EnchantActivationPopupMixin:SetEnchant called with empty spell id")
		return
	end

	self.Enchant:SetEnchant(spellID)
	self.EnchantName:SetText(GetSpellInfo(spellID) or "|cffFF0000NO ENCHANT NAME|r")
end

function EnchantActivationPopupMixin:Layout()
	self.Enchant = CreateFrame("BUTTON", "$parent.AnimatedEnchant", self, "EnchantCollectionEnchantItem")
	self.Enchant:SetPoint("TOP", 0, 0)
	self.Enchant:SetScale(1.2)
	self.Enchant:Hide()
	self.Enchant:SetFrameLevel(self:GetFrameLevel()+3)

	self.Shadow = self:CreateTexture(nil, "BACKGROUND")
	self.Shadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.Shadow:SetPoint("CENTER", 0, 0)
	self.Shadow:SetHeight(400)
	self.Shadow:SetWidth(600)
	self.Shadow:SetAlpha(1)

	self.Animation = CreateFrame("FRAME", "$parent.Animation", self, nil)
	self.Animation:SetSize(376, 376)
	self.Animation:SetPoint("CENTER", self.Enchant, "CENTER", 0, 0)
	self.Animation:SetFrameLevel(self.Enchant:GetFrameLevel()-1)
	self.Animation.flashStartDelay = 1
	--self.Animation:Hide()
	MixinAndLoadScripts(self.Animation, ECEnchantDisenchantAnimMixin)

	self.EnchantName = self.Enchant:CreateFontString(nil, "OVERLAY")
	self.EnchantName:SetFontObject(GameFontDisableLarge)
	self.EnchantName:SetVertexColor(1, 1, 1, 1)
	self.EnchantName:SetJustifyH("CENTER")
	self.EnchantName:SetJustifyV("TOP")
	self.EnchantName:SetPoint("TOP", self.Enchant, "BOTTOM", 0, -12)
	self.EnchantName:SetWidth(256)

	self.EnchantSubText = self.Enchant:CreateFontString(nil, "OVERLAY")
	self.EnchantSubText:SetFontObject(GameFontNormal)
	self.EnchantSubText:SetPoint("TOP", self.EnchantName, "BOTTOM", 0, -4)
	self.EnchantSubText:SetWidth(256)
	self.EnchantSubText:SetJustifyH("TOP")
	self.EnchantSubText:SetJustifyV("CENTER")
	self.EnchantSubText:SetText(string.format(NEW_MYSTIC_ENCHANT_LEARNED, BUG_REPORT_LABEL_MYSTICENCHANT))

	self.LineUp = self.Enchant:CreateTexture(nil, "BORDER", nil, 2)
	self.LineUp:SetTexture("Interface\\LevelUp\\LevelUpTex")
	self.LineUp:SetSize(0.324, 7)
	self.LineUp:SetPoint("TOP", self.Enchant, "BOTTOM", 0, 8)
	self.LineUp:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
	self.LineUp:SetVertexColor(1, 1, 1)

	self.LineDown = self.Enchant:CreateTexture(nil, "BORDER", nil, 2)
	self.LineDown:SetTexture("Interface\\LevelUp\\LevelUpTex")
	self.LineDown:SetSize(0.324, 7)
	self.LineDown:SetPoint("TOP", self.EnchantSubText, "BOTTOM", 0, -8)
	self.LineDown:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
	self.LineDown:SetVertexColor(1, 1, 1)

	self.Texture = self.Enchant:CreateTexture(nil, "BACKGROUND", nil, 2)
	self.Texture:SetTexture("Interface\\LevelUp\\LevelUpTex")
	self.Texture:SetSize(354, 115)
	self.Texture:SetPoint("BOTTOM", self.LineDown, "TOP", 0, -6)
	self.Texture:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125)
	self.Texture:SetVertexColor(1, 1, 1, 0.6)

	self.LineUp.AnimationGroup = self.LineUp:CreateAnimationGroup()

	self.LineUp.AnimationGroup.Grow2 = self.LineUp.AnimationGroup:CreateAnimation("Scale")
	self.LineUp.AnimationGroup.Grow2:SetScale(1000.0, 1.0)
	self.LineUp.AnimationGroup.Grow2:SetDuration(0.5)
	self.LineUp.AnimationGroup.Grow2:SetOrder(1)
	self.LineUp.AnimationGroup.Grow2:SetEndDelay(self.Animation.animTime*1.5)

	self.LineDown.AnimationGroup = self.LineDown:CreateAnimationGroup()

	self.LineDown.AnimationGroup.Grow2 = self.LineDown.AnimationGroup:CreateAnimation("Scale")
	self.LineDown.AnimationGroup.Grow2:SetScale(1000.0, 1.0)
	self.LineDown.AnimationGroup.Grow2:SetDuration(0.5)
	self.LineDown.AnimationGroup.Grow2:SetOrder(1)
	self.LineDown.AnimationGroup.Grow2:SetEndDelay(self.Animation.animTime*1.5)
end


-------------------------------------------------------------------------------
--                        Enchant Unlock Splash Mixin                        --
-------------------------------------------------------------------------------
ECEnchantUnlockSplashMixin = {}

function ECEnchantUnlockSplashMixin:OnLoad()	
	self.animTime = self.animTime or 2
	self.flashStartDelay = self.flashStartDelay or 1.3
	self.coloredTextures = {}

	self:Layout()

	self.sparklePool = CreateTexturePool(self, "OVERLAY", "SparkleTemplate")

	for i = 1, 32 do
		local size = math.random(8, 46)
		local sparkle = self.sparklePool:Acquire()
		sparkle:SetSize(size, size)
		sparkle.Anim:SetTranslationRange(-64, 64, -64, 64)
		sparkle:SetParent(self)
		sparkle:ClearAndSetPoint("CENTER", math.random(-128, 128), math.random(-128, 128))
		sparkle.Anim:SetLifetimeRange(2, 4)
		sparkle:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
		sparkle:Show()
		sparkle.Anim:Refresh()
	end

	self.shineColored.AG:SetScript("OnFinished", function()
		BaseFrameFadeOut(self)
	end)
end

function ECEnchantUnlockSplashMixin:Play()
	BaseFrameFadeIn(self)

	self.shine.AG:Stop()
	self.shockWave.AnimSplash:Stop()
	self.shockWave2.AnimSplash:Stop()
	self.shineColored.AG:Stop()
	self.shineColored2.AG:Stop()

	self.shockWave2.AnimSplash:Play()
	self.shine.AG:Play()
	self.shineColored.AG:Play()
	self.shockWave.AnimSplash:Play()
	self.shineColored2.AG:Play()
end

function ECEnchantUnlockSplashMixin:SetQuality(quality)
	quality = EnchantCollectionUtil:GetQualityFromQualityName(quality) or 1
	local color = ITEM_QUALITY_COLORS[quality]

	for _, texture in pairs(self.coloredTextures) do
		texture:SetVertexColor(color.r, color.g, color.b)
	end
end

function ECEnchantUnlockSplashMixin:Layout()
	self:SetSize(512, 512)

	self.shine = self:CreateTexture(nil, "OVERLAY")
	self.shine:SetSize(16, 16)
	self.shine:SetTexture("SPELLS\\starburst_blue")
	self.shine:SetPoint("CENTER")
	--self.shine:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.shine:SetAlpha(0)
	self.shine:SetBlendMode("ADD")

	SetParentArray(self.shine, "coloredTextures")

	self.shine.AG = self.shine:CreateAnimationGroup()

	self.shine.AG.Scale = self.shine.AG:CreateAnimation("SCALE")
	self.shine.AG.Scale:SetDuration(0.15)
	self.shine.AG.Scale:SetOrder(1)
	self.shine.AG.Scale:SetSmoothing("IN_OUT")
	self.shine.AG.Scale:SetScale(10, 10)
	self.shine.AG.Scale:SetStartDelay(self.flashStartDelay)

	self.shine.AG.Alpha = self.shine.AG:CreateAnimation("ALPHA")
	self.shine.AG.Alpha:SetDuration(0.1)
	self.shine.AG.Alpha:SetOrder(1)
	self.shine.AG.Alpha:SetSmoothing("IN_OUT")
	self.shine.AG.Alpha:SetChange(1)
	self.shine.AG.Alpha:SetStartDelay(self.flashStartDelay)

	self.shine.AG.Scale2 = self.shine.AG:CreateAnimation("SCALE")
	self.shine.AG.Scale2:SetDuration(self.animTime/8)
	self.shine.AG.Scale2:SetOrder(2)
	self.shine.AG.Scale2:SetSmoothing("OUT")
	self.shine.AG.Scale2:SetScale(0.5, 0.5)

	self.shine.AG.Alpha2 = self.shine.AG:CreateAnimation("ALPHA")
	self.shine.AG.Alpha2:SetDuration(self.animTime/8)
	self.shine.AG.Alpha2:SetOrder(3)
	self.shine.AG.Alpha2:SetSmoothing("OUT")
	self.shine.AG.Alpha2:SetChange(-1)

	self.shineColored = self:CreateTexture(nil, "ARTWORK")
	self.shineColored:SetSize(58, 58)
	self.shineColored:SetTexture("SPELLS\\glow_256")
	self.shineColored:SetPoint("CENTER")
	--self.shineColored:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.shineColored:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.shineColored:SetAlpha(0)
	self.shineColored:SetBlendMode("ADD")

	SetParentArray(self.shineColored, "coloredTextures")

	self.shineColored.AG = self.shineColored:CreateAnimationGroup()

	self.shineColored.AG.Scale = self.shineColored.AG:CreateAnimation("SCALE")
	self.shineColored.AG.Scale:SetDuration(0.2)
	self.shineColored.AG.Scale:SetOrder(1)
	self.shineColored.AG.Scale:SetSmoothing("IN_OUT")
	self.shineColored.AG.Scale:SetScale(10, 10)
	self.shineColored.AG.Scale:SetStartDelay(self.flashStartDelay)

	self.shineColored.AG.Alpha = self.shineColored.AG:CreateAnimation("ALPHA")
	self.shineColored.AG.Alpha:SetDuration(0.1)
	self.shineColored.AG.Alpha:SetOrder(1)
	self.shineColored.AG.Alpha:SetSmoothing("IN_OUT")
	self.shineColored.AG.Alpha:SetChange(1)
	self.shineColored.AG.Alpha:SetStartDelay(self.flashStartDelay)

	self.shineColored.AG.Scale2 = self.shineColored.AG:CreateAnimation("SCALE")
	self.shineColored.AG.Scale2:SetDuration(self.animTime/2)
	self.shineColored.AG.Scale2:SetOrder(2)
	self.shineColored.AG.Scale2:SetSmoothing("OUT")
	self.shineColored.AG.Scale2:SetScale(0.5, 0.5)

	self.shineColored.AG.Alpha2 = self.shineColored.AG:CreateAnimation("ALPHA")
	self.shineColored.AG.Alpha2:SetDuration(self.animTime/2)
	self.shineColored.AG.Alpha2:SetOrder(3)
	self.shineColored.AG.Alpha2:SetSmoothing("OUT")
	self.shineColored.AG.Alpha2:SetChange(-1)

	self.shineColored2 = self:CreateTexture(nil, "OVERLAY")
	self.shineColored2:SetSize(32, 32)
	self.shineColored2:SetTexture("SPELLS\\starburst_blue")
	self.shineColored2:SetPoint("CENTER")
	self.shineColored2:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.shineColored2:SetAlpha(0)
	self.shineColored2:SetBlendMode("ADD")

	SetParentArray(self.shineColored2, "coloredTextures")

	self.shineColored2.AG = self.shineColored2:CreateAnimationGroup()

	self.shineColored2.AG.Scale = self.shineColored2.AG:CreateAnimation("SCALE")
	self.shineColored2.AG.Scale:SetDuration(0.15)
	self.shineColored2.AG.Scale:SetOrder(1)
	self.shineColored2.AG.Scale:SetSmoothing("IN_OUT")
	self.shineColored2.AG.Scale:SetScale(10, 10)
	self.shineColored2.AG.Scale:SetStartDelay(self.flashStartDelay)

	self.shineColored2.AG.Alpha = self.shineColored2.AG:CreateAnimation("ALPHA")
	self.shineColored2.AG.Alpha:SetDuration(0.1)
	self.shineColored2.AG.Alpha:SetOrder(1)
	self.shineColored2.AG.Alpha:SetSmoothing("IN_OUT")
	self.shineColored2.AG.Alpha:SetChange(1)
	self.shineColored2.AG.Alpha:SetStartDelay(self.flashStartDelay)

	self.shineColored2.AG.Scale2 = self.shineColored2.AG:CreateAnimation("SCALE")
	self.shineColored2.AG.Scale2:SetDuration(self.animTime/4)
	self.shineColored2.AG.Scale2:SetOrder(2)
	self.shineColored2.AG.Scale2:SetSmoothing("OUT")
	self.shineColored2.AG.Scale2:SetScale(0.5, 0.5)

	self.shineColored2.AG.Alpha2 = self.shineColored2.AG:CreateAnimation("ALPHA")
	self.shineColored2.AG.Alpha2:SetDuration(self.animTime/4)
	self.shineColored2.AG.Alpha2:SetOrder(3)
	self.shineColored2.AG.Alpha2:SetSmoothing("OUT")
	self.shineColored2.AG.Alpha2:SetChange(-1)

	self.shockWave = self:CreateTexture(nil, "OVERLAY")
	self.shockWave:SetSize(300, 300)
	self.shockWave:SetTexture("SPELLS\\7fx_alphamask_shockwavesoft_contrast_256")
	self.shockWave:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.shockWave:SetAlpha(0)
	self.shockWave:SetPoint("CENTER")
	self.shockWave:SetBlendMode("ADD")

	SetParentArray(self.shockWave, "coloredTextures")

	self.shockWave.AnimSplash = self.shockWave:CreateAnimationGroup()

	self.shockWave.AnimSplash.Alpha = self.shockWave.AnimSplash:CreateAnimation("Alpha")
	self.shockWave.AnimSplash.Alpha:SetDuration(0.2)
	self.shockWave.AnimSplash.Alpha:SetOrder(1)
	self.shockWave.AnimSplash.Alpha:SetEndDelay(0)
	self.shockWave.AnimSplash.Alpha:SetSmoothing("IN")
	self.shockWave.AnimSplash.Alpha:SetChange(1)

	self.shockWave.AnimSplash.Rotation = self.shockWave.AnimSplash:CreateAnimation("ROTATION")
	self.shockWave.AnimSplash.Rotation:SetDuration(self.flashStartDelay)
	self.shockWave.AnimSplash.Rotation:SetOrder(1)
	self.shockWave.AnimSplash.Rotation:SetDegrees(-180)

	self.shockWave.AnimSplash.Scale2 = self.shockWave.AnimSplash:CreateAnimation("Scale")
	self.shockWave.AnimSplash.Scale2:SetScale(2, 2)
	self.shockWave.AnimSplash.Scale2:SetDuration(self.animTime)
	self.shockWave.AnimSplash.Scale2:SetOrder(2)
	self.shockWave.AnimSplash.Scale2:SetSmoothing("OUT")

	self.shockWave.AnimSplash.Rotation2 = self.shockWave.AnimSplash:CreateAnimation("ROTATION")
	self.shockWave.AnimSplash.Rotation2:SetDuration(self.animTime)
	self.shockWave.AnimSplash.Rotation2:SetOrder(2)
	self.shockWave.AnimSplash.Rotation2:SetDegrees(-90)

	self.shockWave.AnimSplash.Alpha2 = self.shockWave.AnimSplash:CreateAnimation("Alpha")
	self.shockWave.AnimSplash.Alpha2:SetDuration(self.animTime)
	self.shockWave.AnimSplash.Alpha2:SetOrder(2)
	self.shockWave.AnimSplash.Alpha2:SetEndDelay(0)
	self.shockWave.AnimSplash.Alpha2:SetSmoothing("OUT")
	self.shockWave.AnimSplash.Alpha2:SetChange(-1)

	self.shockWave2 = self:CreateTexture(nil, "OVERLAY")
	self.shockWave2:SetSize(200, 200)
	self.shockWave2:SetTexture("SPELLS\\7fx_alphamask_shockwaveshadow_ba")
	self.shockWave2:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.shockWave2:SetAlpha(0)
	self.shockWave2:SetPoint("CENTER")
	self.shockWave2:SetBlendMode("ADD")

	SetParentArray(self.shockWave2, "coloredTextures")

	self.shockWave2.AnimSplash = self.shockWave2:CreateAnimationGroup()

	self.shockWave2.AnimSplash.Alpha = self.shockWave2.AnimSplash:CreateAnimation("Alpha")
	self.shockWave2.AnimSplash.Alpha:SetDuration(0.2)
	self.shockWave2.AnimSplash.Alpha:SetOrder(1)
	self.shockWave2.AnimSplash.Alpha:SetEndDelay(0)
	self.shockWave2.AnimSplash.Alpha:SetSmoothing("IN")
	self.shockWave2.AnimSplash.Alpha:SetChange(1)
	self.shockWave2.AnimSplash.Alpha:SetStartDelay(self.flashStartDelay)

	self.shockWave2.AnimSplash.Scale2 = self.shockWave2.AnimSplash:CreateAnimation("Scale")
	self.shockWave2.AnimSplash.Scale2:SetScale(2, 2)
	self.shockWave2.AnimSplash.Scale2:SetDuration(2)
	self.shockWave2.AnimSplash.Scale2:SetOrder(2)
	self.shockWave2.AnimSplash.Scale2:SetSmoothing("OUT")

	self.shockWave2.AnimSplash.Rotation = self.shockWave2.AnimSplash:CreateAnimation("ROTATION")
	self.shockWave2.AnimSplash.Rotation:SetDuration(2)
	self.shockWave2.AnimSplash.Rotation:SetOrder(2)
	self.shockWave2.AnimSplash.Rotation:SetDegrees(-90)

	self.shockWave2.AnimSplash.Alpha2 = self.shockWave2.AnimSplash:CreateAnimation("Alpha")
	self.shockWave2.AnimSplash.Alpha2:SetDuration(2)
	self.shockWave2.AnimSplash.Alpha2:SetOrder(2)
	self.shockWave2.AnimSplash.Alpha2:SetEndDelay(0)
	self.shockWave2.AnimSplash.Alpha2:SetSmoothing("OUT")
	self.shockWave2.AnimSplash.Alpha2:SetChange(-1)
end

-------------------------------------------------------------------------------
--                       Enchant Disenchant Animation                        --
-------------------------------------------------------------------------------
ECEnchantDisenchantAnimMixin = CreateFromMixins("ECEnchantUnlockSplashMixin")

function ECEnchantDisenchantAnimMixin:OnLoad()
	self.colorSec = CreateColorFromCode("|cff5d9ee3")
	self.color3 = CreateColorFromCode("|cff9f80ff")

	ECEnchantUnlockSplashMixin.OnLoad(self)

	self.sparklePool:ReleaseAll()

	for i = 1, 32 do
		local pointX, pointY = math.random(-164, 164), math.random(-164, 164)

		local size = math.random(8, 46)
		local sparkle = self.sparklePool:Acquire()
		sparkle:SetSize(size, size)
		sparkle.Anim:SetTranslationRange(-pointX, -pointX, -pointY, -pointY)
		sparkle:SetParent(self)
		sparkle:ClearAndSetPoint("CENTER", pointX, pointY)
		sparkle.Anim:SetLifetimeRange(1, 1.5)

		if (math.random(-1, 4) > 0) then
			sparkle:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
		else
			sparkle:SetVertexColor(self.color3:GetRGBA())
		end

		sparkle:Show()
		sparkle.Anim:Refresh()
	end
end

function ECEnchantDisenchantAnimMixin:Play()
	ECEnchantUnlockSplashMixin.Play(self)

	--self.fill2.AG:Stop()
	self.fill1.AG:Stop()
	self.fill3.AG:Stop()
	self.center.AG:Stop()

	--self.fill2.AG:Play()
	self.fill1.AG:Play()
	self.fill3.AG:Play()
	self.center.AG:Play()
end

function ECEnchantDisenchantAnimMixin:Layout()
	ECEnchantUnlockSplashMixin.Layout(self)
	self.fill1 = self:CreateTexture(nil, "ARTWORK")
	self.fill1:SetSize(5.24, 5.24)
	self.fill1:SetTexture("SPELLS\\7fx_alphamask_shockwaveholy_a2")
	self.fill1:SetPoint("CENTER")
	self.fill1:SetVertexColor(self.colorSec:GetRGBA())
	self.fill1:SetAlpha(0)
	self.fill1:SetBlendMode("ADD")

	self.fill1.AG = self.fill1:CreateAnimationGroup()

	self.fill1.AG:SetLooping("REPEAT")

	self.fill1.AG.Scale = self.fill1.AG:CreateAnimation("SCALE")
	self.fill1.AG.Scale:SetDuration(0.1)
	self.fill1.AG.Scale:SetOrder(1)
	self.fill1.AG.Scale:SetSmoothing("IN")
	self.fill1.AG.Scale:SetScale(100.1, 100.1)

	self.fill1.AG.Alpha = self.fill1.AG:CreateAnimation("ALPHA")
	self.fill1.AG.Alpha:SetDuration(self.animTime/4)
	self.fill1.AG.Alpha:SetOrder(2)
	self.fill1.AG.Alpha:SetSmoothing("IN")
	self.fill1.AG.Alpha:SetChange(1)

	self.fill1.AG.Scale2 = self.fill1.AG:CreateAnimation("SCALE")
	self.fill1.AG.Scale2:SetDuration(self.animTime/2)
	self.fill1.AG.Scale2:SetOrder(2)
	self.fill1.AG.Scale2:SetSmoothing("IN_OUT")
	self.fill1.AG.Scale2:SetScale(0.1, 0.1)

	self.fill1.AG.Alpha2 = self.fill1.AG:CreateAnimation("ALPHA")
	self.fill1.AG.Alpha2:SetStartDelay(self.animTime/4)
	self.fill1.AG.Alpha2:SetDuration(self.animTime/4)
	self.fill1.AG.Alpha2:SetOrder(2)
	self.fill1.AG.Alpha2:SetSmoothing("OUT")
	self.fill1.AG.Alpha2:SetChange(-1)

	self.fill3 = self:CreateTexture(nil, "OVERLAY")
	self.fill3:SetSize(2.56, 2.56)
	self.fill3:SetTexture("SPELLS\\8fx_mask_glowgeneric_a_128_brighter")
	self.fill3:SetPoint("CENTER")
	self.fill3:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.fill3:SetAlpha(0)
	self.fill3:SetBlendMode("ADD")

	self.fill3.AG = self.fill3:CreateAnimationGroup()

	self.fill3.AG.Scale = self.fill3.AG:CreateAnimation("SCALE")
	self.fill3.AG.Scale:SetDuration(0.2)
	self.fill3.AG.Scale:SetOrder(1)
	self.fill3.AG.Scale:SetSmoothing("IN")
	self.fill3.AG.Scale:SetScale(100.1, 100.1)

	self.fill3.AG.Alpha = self.fill3.AG:CreateAnimation("ALPHA")
	self.fill3.AG.Alpha:SetDuration(0.1)
	self.fill3.AG.Alpha:SetOrder(1)
	self.fill3.AG.Alpha:SetSmoothing("IN")
	self.fill3.AG.Alpha:SetChange(1)

	self.fill3.AG.Scale2 = self.fill3.AG:CreateAnimation("SCALE")
	self.fill3.AG.Scale2:SetDuration(self.animTime/2)
	self.fill3.AG.Scale2:SetOrder(2)
	self.fill3.AG.Scale2:SetSmoothing("OUT")
	self.fill3.AG.Scale2:SetScale(0.2, 0.2)
	
	self.fill3.AG.Rotation = self.fill3.AG:CreateAnimation("ROTATION")
	self.fill3.AG.Rotation:SetDuration(self.animTime/2)
	self.fill3.AG.Rotation:SetOrder(2)
	self.fill3.AG.Rotation:SetDegrees(90)

	self.fill3.AG.Alpha2 = self.fill3.AG:CreateAnimation("ALPHA")
	self.fill3.AG.Alpha2:SetDuration(self.animTime)
	self.fill3.AG.Alpha2:SetOrder(3)
	self.fill3.AG.Alpha2:SetSmoothing("OUT")
	self.fill3.AG.Alpha2:SetChange(-1)

	self.center = self:CreateTexture(nil, "ARTWORK")
	self.center:SetSize(192, 192)
	self.center:SetTexture("SPELLS\\FLARE_PERFECT")
	self.center:SetPoint("CENTER")
	self.center:SetVertexColor(self.colorSec:GetRGBA())
	self.center:SetAlpha(0)
	self.center:SetBlendMode("ADD")
	self.center.AG = self.center:CreateAnimationGroup()

	self.center.AG.Scale = self.center.AG:CreateAnimation("SCALE")
	self.center.AG.Scale:SetDuration(0.3)
	self.center.AG.Scale:SetOrder(1)
	self.center.AG.Scale:SetSmoothing("IN")
	self.center.AG.Scale:SetScale(1.5, 1.5)

	self.center.AG.Alpha = self.center.AG:CreateAnimation("ALPHA")
	self.center.AG.Alpha:SetDuration(0.1)
	self.center.AG.Alpha:SetOrder(1)
	self.center.AG.Alpha:SetSmoothing("IN")
	self.center.AG.Alpha:SetChange(1)

	self.center.AG.Scale2 = self.center.AG:CreateAnimation("SCALE")
	self.center.AG.Scale2:SetDuration(self.animTime)
	self.center.AG.Scale2:SetOrder(2)
	self.center.AG.Scale2:SetSmoothing("OUT")
	self.center.AG.Scale2:SetScale(0.6, 0.6)

	self.center.AG.Rotation = self.center.AG:CreateAnimation("ROTATION")
	self.center.AG.Rotation:SetDuration(self.animTime)
	self.center.AG.Rotation:SetOrder(2)
	self.center.AG.Rotation:SetDegrees(-180)
	self.center.AG.Rotation:SetSmoothing("OUT")
end
-------------------------------------------------------------------------------
--                         Enchant Unlock Animation                          --
-------------------------------------------------------------------------------
ECEnchantUnlockAnimMixin = CreateFromMixins("ECEnchantUnlockSplashMixin")

function ECEnchantUnlockAnimMixin:OnLoad()
	self.effectLeft = 0
	self.effectRight = 1
	self.effectTop = 0
	self.effectBottom = 1
	self.effects = {}

	ECEnchantUnlockSplashMixin.OnLoad(self)

	self.shockWave.AnimSplash:SetScript("OnFinished", function()
		BaseFrameFadeOut(self)
	end)
	
	self:ApplyEffectAnimation()
end

function ECEnchantUnlockAnimMixin:SetQuality(quality)
	ECEnchantUnlockSplashMixin.SetQuality(self, quality)

	quality = EnchantCollectionUtil:GetQualityFromQualityName(quality) or 1
	local color = ITEM_QUALITY_COLORS[quality]

	for _, texture in pairs(self.effects) do
		texture:SetVertexColor(color.r, color.g, color.b)
	end

end

function ECEnchantUnlockAnimMixin:Play()
	BaseFrameFadeIn(self)

	self.shine:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGB())
	self.shineColored:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGB())
	self.shineColored2:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGB())
	self.shockWave:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGB())
	self.shockWave2:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGB())

	--self.shine.AG:Stop()
	self.shockWave.AnimSplash:Stop()
	--self.shockWave2.AnimSplash:Stop()
	--self.shineColored.AG:Stop()
	--self.shineColored2.AG:Stop()

	--self.shine.AG:Play()
	--self.shockWave2.AnimSplash:Play()
	--self.shineColored.AG:Play()
	self.shockWave.AnimSplash:Play()
	--self.shineColored2.AG:Play()

	for _, effects in pairs(self.effects) do
		effects:SetVertexColor(1, 1, 1)
		effects.Movement:Stop()
		effects.Movement:Play()
	end
end

function ECEnchantUnlockAnimMixin:Layout()
	ECEnchantUnlockSplashMixin.Layout(self)

	local modifier = 8 -- TODO: Replace via calculations

	self.effect1 = self:CreateTexture(nil, "ARTWORK")
	self.effect1:SetSize(512, 512)
	self.effect1:SetPoint("CENTER", 2.5*modifier, 1*modifier)
	self.effect1:SetTexture("Interface\\Collections\\EnchantAtlas3")
	self.effect1:SetBlendMode("ADD")
	self.effect1:SetAlpha(0)
	EnchantCollectionUtil:SetTexRotationWithCoord(self.effect1, math.rad(0), self.effectLeft, self.effectRight, self.effectTop, self.effectBottom)
	table.insert(self.effects, self.effect1)

	self.effect2 = self:CreateTexture(nil, "ARTWORK")
	self.effect2:SetSize(512, 512)
	self.effect2:SetPoint("CENTER", 0, -4*modifier)
	self.effect2:SetTexture("Interface\\Collections\\EnchantAtlas3")
	self.effect2:SetBlendMode("ADD")
	self.effect2:SetAlpha(0)
	EnchantCollectionUtil:SetTexRotationWithCoord(self.effect2, math.rad(-120), self.effectLeft, self.effectRight, self.effectTop, self.effectBottom)
	table.insert(self.effects, self.effect2)

	self.effect3 = self:CreateTexture(nil, "ARTWORK")
	self.effect3:SetSize(512, 512)
	self.effect3:SetPoint("CENTER", -3*modifier, 0)
	self.effect3:SetTexture("Interface\\Collections\\EnchantAtlas3")
	self.effect3:SetBlendMode("ADD")
	self.effect3:SetAlpha(0)
	EnchantCollectionUtil:SetTexRotationWithCoord(self.effect3, math.rad(120), self.effectLeft, self.effectRight, self.effectTop, self.effectBottom)
	table.insert(self.effects, self.effect3)
end

function ECEnchantUnlockAnimMixin:ApplyEffectAnimation()
	for i = 1, #self.effects do
		local effect = self.effects[i]

		effect.Movement = effect:CreateAnimationGroup(nil)

		effect.Movement.Start = effect.Movement:CreateAnimation("ALPHA")
		effect.Movement.Start:SetDuration(0)
		effect.Movement.Start:SetOrder(1)
		effect.Movement.Start:SetSmoothing("IN")
		effect.Movement.Start:SetChange(0)

		effect.Movement.Alpha = effect.Movement:CreateAnimation("ALPHA")
		effect.Movement.Alpha:SetDuration(0.5)
		effect.Movement.Alpha:SetOrder(2)
		effect.Movement.Alpha:SetSmoothing("OUT")
		effect.Movement.Alpha:SetChange(0.7)

		effect.Movement.Rotation = effect.Movement:CreateAnimation("ROTATION")
		effect.Movement.Rotation:SetDuration(self.flashStartDelay)
		effect.Movement.Rotation:SetOrder(2)
		--effect.Movement.Rotation:SetSmoothing("IN")
		effect.Movement.Rotation:SetDegrees(-360)

		effect.Movement.Scale = effect.Movement:CreateAnimation("SCALE")
		effect.Movement.Scale:SetDuration(self.flashStartDelay)
		effect.Movement.Scale:SetOrder(2)
		--effect.Movement.Scale:SetSmoothing("IN")
		effect.Movement.Scale:SetScale(0.4, 0.4)

		effect.Movement.Rotation2 = effect.Movement:CreateAnimation("ROTATION")
		effect.Movement.Rotation2:SetDuration(self.animTime/2)
		effect.Movement.Rotation2:SetOrder(3)
		--effect.Movement.Rotation2:SetSmoothing("OUT")
		effect.Movement.Rotation2:SetDegrees(-180)

		effect.Movement.Alpha2 = effect.Movement:CreateAnimation("ALPHA")
		effect.Movement.Alpha2:SetDuration(self.animTime/2)
		effect.Movement.Alpha2:SetOrder(3)
		effect.Movement.Alpha2:SetSmoothing("OUT")
		effect.Movement.Alpha2:SetChange(1)

		effect.Movement.Alpha3 = effect.Movement:CreateAnimation("ALPHA")
		effect.Movement.Alpha3:SetDuration(self.animTime/2)
		effect.Movement.Alpha3:SetOrder(4)
		effect.Movement.Alpha3:SetSmoothing("OUT")
		effect.Movement.Alpha3:SetChange(-1)

		effect.Movement.Rotation3 = effect.Movement:CreateAnimation("ROTATION")
		effect.Movement.Rotation3:SetDuration(self.animTime/2)
		effect.Movement.Rotation3:SetOrder(4)
		effect.Movement.Rotation3:SetDegrees(-90)
	end
end

-------------------------------------------------------------------------------
--                        Enchant Unlock Animation #2                        --
-------------------------------------------------------------------------------
ECEnchantPostReforgeMixin = CreateFromMixins(ECEnchantUnlockSplashMixin)

function ECEnchantPostReforgeMixin:SetQuality(quality)
	ECEnchantUnlockSplashMixin.SetQuality(self, quality)

	quality = EnchantCollectionUtil:GetQualityFromQualityName(quality) or 1

	if quality == 2 then
		self.shineColored2:SetTexture("SPELLS\\8fx_mask_glowgeneric_a_128_brighter")
		self.shockWave2:SetTexture("SPELLS\\shockwave_smoke_02")
		self.preCastGlow:SetTexture("SPELLS\\7fx_flash_shard")
	elseif quality == 3 then
		self.shineColored2:SetTexture("SPELLS\\8fx_mask_glowgeneric_a_128_brighter_blend")
		self.shockWave2:SetTexture("SPELLS\\7fx_alphamask_shockwaveshadow_ba")
		self.preCastGlow:SetTexture("SPELLS\\7fx_flash_shard")
	elseif quality == 4 then
		self.shineColored2:SetTexture("SPELLS\\8fx_mask_glowgeneric_a_128_dissipate")
		self.shockWave2:SetTexture("SPELLS\\shockwave_magic_a2")
		self.preCastGlow:SetTexture("SPELLS\\glow_256")

	elseif quality == 5 then
		self.shineColored2:SetTexture("SPELLS\\starburst_blue")
		self.shockWave2:SetTexture("SPELLS\\shockwave_spikey_bright_ba_ice")
		self.preCastGlow:SetTexture("SPELLS\\glow_256")
	end
end

function ECEnchantPostReforgeMixin:OnLoad()
	ECEnchantUnlockSplashMixin.OnLoad(self)

	self.sparklePool:ReleaseAll()

	--[[for i = 1, 32 do
		local pointX, pointY = math.random(-164, 164), math.random(-164, 164)

		local size = math.random(8, 46)
		local sparkle = self.sparklePool:Acquire()
		sparkle:SetSize(size, size)
		sparkle.Anim:SetTranslationRange(-pointX, -pointX, -pointY, -pointY)
		sparkle:SetParent(self)
		sparkle:ClearAndSetPoint("CENTER", pointX, pointY)
		sparkle.Anim:SetLifetimeRange(0.5, 1)

		sparkle:Show()
		sparkle.Anim:Refresh()
	end]]--

	self.preCastGlow.AG.Alpha2:SetScript("OnFinished", function()
		if self.explosionCallBack then
			self:explosionCallBack()
		end
	end)
end

function ECEnchantPostReforgeMixin:Play()
	ECEnchantUnlockSplashMixin.Play(self)
	self.preCastGlow.AG:Stop()
	self.preCastGlow.AG:Play()

	self.shockWave.AnimSplash.Rotation:SetDuration(0)
	--self.shockWave:Hide()
end

function ECEnchantPostReforgeMixin:Layout()
	ECEnchantUnlockSplashMixin.Layout(self)

	self.preCastGlow = self:CreateTexture(nil, "ARTWORK")
	self.preCastGlow:SetSize(16, 16)
	self.preCastGlow:SetTexture("SPELLS\\glow_256")
	self.preCastGlow:SetPoint("CENTER")
	--self.preCastGlow:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.preCastGlow:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.preCastGlow:SetAlpha(0)
	self.preCastGlow:SetBlendMode("ADD")

	SetParentArray(self.preCastGlow, "coloredTextures")

	self.preCastGlow.AG = self.preCastGlow:CreateAnimationGroup()

	self.preCastGlow.AG.Scale = self.preCastGlow.AG:CreateAnimation("SCALE")
	self.preCastGlow.AG.Scale:SetDuration(self.flashStartDelay/2)
	self.preCastGlow.AG.Scale:SetOrder(1)
	self.preCastGlow.AG.Scale:SetSmoothing("IN_OUT")
	self.preCastGlow.AG.Scale:SetScale(20, 20)
	--self.preCastGlow.AG.Scale:SetStartDelay(self.flashStartDelay)

	self.preCastGlow.AG.Alpha = self.preCastGlow.AG:CreateAnimation("ALPHA")
	self.preCastGlow.AG.Alpha:SetDuration(self.flashStartDelay/3)
	self.preCastGlow.AG.Alpha:SetOrder(1)
	self.preCastGlow.AG.Alpha:SetSmoothing("IN_OUT")
	self.preCastGlow.AG.Alpha:SetChange(1)
	--self.preCastGlow.AG.Alpha:SetStartDelay(self.flashStartDelay)

	self.preCastGlow.AG.Scale2 = self.preCastGlow.AG:CreateAnimation("SCALE")
	self.preCastGlow.AG.Scale2:SetDuration(self.flashStartDelay)
	self.preCastGlow.AG.Scale2:SetOrder(2)
	self.preCastGlow.AG.Scale2:SetSmoothing("OUT")
	self.preCastGlow.AG.Scale2:SetScale(0.1, 0.1)

	self.preCastGlow.AG.Alpha2 = self.preCastGlow.AG:CreateAnimation("ALPHA") -- basically a controller
	self.preCastGlow.AG.Alpha2:SetDuration(self.flashStartDelay/2)
	self.preCastGlow.AG.Alpha2:SetOrder(2)
	self.preCastGlow.AG.Alpha2:SetSmoothing("IN_OUT")
	self.preCastGlow.AG.Alpha2:SetChange(1)
end
