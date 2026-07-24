-------------------------------------------------------------------------------
--                               Name Template                               --
-------------------------------------------------------------------------------
SkillCardNameFrameMixin = {}

function SkillCardNameFrameMixin:OnLoad()
	self:Layout()

	self.Name._SetText = self.Name.SetText

	function self.Name:SetText(...)
		self:SetFontObject(GameFontHighlightMedium)
		self:_SetText(...)
		
		if self:GetHeight() > 30 then
			self:SetFontObject(GameFontHighlight)
		end
	end
end

function SkillCardNameFrameMixin:Layout()
	self:SetSize(171, 56)

	self.NameBG = self:CreateTexture(nil, "ARTWORK")
	self.NameBG:SetAtlas("UI-Frame-Alliance-Ribbon", Const.TextureKit.IgnoreAtlasSize)
	self.NameBG:SetPoint("CENTER", 0, 0)
	self.NameBG:SetSize(171, 56)

	self.Name = self:CreateFontString(nil, "OVERLAY")
	self.Name:SetFontObject(GameFontHighlightMedium)
	self.Name:SetPoint("CENTER", self.NameBG)
	self.Name:SetJustifyH("CENTER")
	self.Name:SetJustifyV("CENTER")
	self.Name:SetWidth(self:GetWidth()-48)
	self.Name:SetShadowOffset(0, 0)
	self.Name:SetVertexColor(0, 0, 0, 1)
end

-------------------------------------------------------------------------------
--                                 Shiny Glow                                --
-------------------------------------------------------------------------------
SkillCardShinyGlowMixin = {}

function SkillCardShinyGlowMixin:OnLoad()
	self:Layout()
end

function SkillCardShinyGlowMixin:GetQuality()
	return self:GetParent():GetQuality()
end

function SkillCardShinyGlowMixin:UpdateVisual()
	local r, g, b = GetItemQualityColor(self:GetQuality())
	
	self.Shine1:SetVertexColor(r, g, b)
	self.Shine3:SetVertexColor(r, g, b)
	self.Shine2:SetVertexColor(r, g, b)
	self.Shine3Add:SetVertexColor(r, g, b)

	-- visually improve green and blue
	if (self.quality == 2) or (self.quality == 3) then
		self.Shine3:SetVertexColor(1, 1, 1, 0.5)
	end
end

function SkillCardShinyGlowMixin:Layout()
	self.Shine3 = self:CreateTexture(nil, "BACKGROUND")
	self.Shine3:SetSize(220.16, 220.16)
	self.Shine3:SetTexture("Interface\\draft\\card_shine_3")
	self.Shine3:SetPoint("CENTER", 0, -4)

	self.Shine1 = self:CreateTexture(nil, "BACKGROUND")
	self.Shine1:SetSize(220.16, 220.16)
	self.Shine1:SetTexture("Interface\\draft\\card_shine_1")
	self.Shine1:SetPoint("CENTER", 0, -2)
	self.Shine1:SetBlendMode("ADD")

	self.Shine2 = self:CreateTexture(nil, "BORDER")
	self.Shine2:SetSize(243.2, 243.2)
	self.Shine2:SetTexture("Interface\\draft\\card_shine_2")
	self.Shine2:SetPoint("CENTER", 0, -4)
	self.Shine2:SetBlendMode("ADD")

	self.Shine3Add = self:CreateTexture(nil, "ARTWORK")
	self.Shine3Add:SetSize(220.16, 220.16)
	self.Shine3Add:SetTexture("Interface\\draft\\card_shine_3")
	self.Shine3Add:SetPoint("CENTER", 0, -4)
	self.Shine3Add:SetBlendMode("ADD")
end

-------------------------------------------------------------------------------
--                   Functional Shine with Moving Sparkles                   --
-------------------------------------------------------------------------------
SkillCardShineMixin = {}
SkillCardShineMixin.sparkleSizes = {
	13, 10, 7, 4
}

function SkillCardShineMixin:OnLoad()
	self:Layout()

	self.custom_shine_timers = {0, 0, 0, 0}
	self.sparkles = {}
	self.sparklePool = CreateTexturePool(self, "OVERLAY", "SparkleTemplate")
	self:AcquireSparkles()

	self.BackgroundFrame.AG:SetScript("OnPlay", GenerateClosure(self.PlayPulse, self.BackgroundFrame.AG))
    self.BackgroundFrame.AG:SetScript("OnFinished", function(self) self:Play() end)
end

function SkillCardShineMixin:GetQuality()
	return self:GetParent():GetQuality()
end

function SkillCardShineMixin:GetSpellID()
	return self:GetParent():GetSpellID() or 1
end

function SkillCardShineMixin:GetReplace()
	return self:GetParent():GetReplace()
end

function SkillCardShineMixin:AcquireSparkles()
	for i = 1, 4 do
		for j = 1, 4 do
			local size = SkillCardShineMixin.sparkleSizes[j]
			local sparkle = self.sparklePool:Acquire()
			sparkle:SetTexture("Interface\\ItemSocketingFrame\\UI-ItemSockets")
			sparkle:SetTexCoord(0.3984375, 0.4453125, 0.40234375, 0.44921875)
			sparkle:SetPoint("CENTER")
			sparkle:SetSize(size, size)
			sparkle:Show()
			table.insert(self.sparkles, sparkle)
		end
	end
end

function SkillCardShineMixin:UpdateVisual()
	local r, g, b = GetItemQualityColor(self:GetQuality())
	local name, _, icon = GetSpellInfo(self:GetSpellID())

	for _, sparkle in next, self.sparkles do
		sparkle:SetVertexColor(r, g, b)
	end

	self.BackgroundFrame:UpdateVisual()
	self.NameFrame.Name:SetText(name)

	if (self:GetReplace()) then
		self.OkButton:SetText(REPLACE)
	else
		self.OkButton:SetText(ACTIVATE)
	end
end

function SkillCardShineMixin:OnUpdate(elapsed)	-- edited one from UIParent
	local speeds = { 8, 9, 12, 16}

	for i in next, self.custom_shine_timers do
		self.custom_shine_timers[i] = self.custom_shine_timers[i] + elapsed
		if ( self.custom_shine_timers[i] > speeds[i]*4 ) then
			self.custom_shine_timers[i] = 0
		end
	end

	local parent, distance_h, distance_v = self, self:GetWidth(), self:GetHeight()
	
	for i = 1, 4 do
		local timer = self.custom_shine_timers[i]
		local speed = speeds[i]
		
		if ( timer <= speed ) then
			local basePosition_h = timer/speed*distance_h
			local basePosition_v = timer/speed*distance_v
			self.sparkles[0+i]:SetPoint("CENTER", parent, "TOPLEFT", basePosition_h, 0)
			self.sparkles[4+i]:SetPoint("CENTER", parent, "BOTTOMRIGHT", -basePosition_h, 0)
			self.sparkles[8+i]:SetPoint("CENTER", parent, "TOPRIGHT", 0, -basePosition_v)
			self.sparkles[12+i]:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, basePosition_v)
		elseif ( timer <= speed*2 ) then
			local basePosition_h = (timer-speed)/speed*distance_h
			local basePosition_v = (timer-speed)/speed*distance_v
			self.sparkles[0+i]:SetPoint("CENTER", parent, "TOPRIGHT", 0, -basePosition_v)
			self.sparkles[4+i]:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, basePosition_v)
			self.sparkles[8+i]:SetPoint("CENTER", parent, "BOTTOMRIGHT", -basePosition_h, 0)
			self.sparkles[12+i]:SetPoint("CENTER", parent, "TOPLEFT", basePosition_h, 0)	
		elseif ( timer <= speed*3 ) then
			local basePosition_h = (timer-speed*2)/speed*distance_h
			local basePosition_v = (timer-speed*2)/speed*distance_v
			self.sparkles[0+i]:SetPoint("CENTER", parent, "BOTTOMRIGHT", -basePosition_h, 0)
			self.sparkles[4+i]:SetPoint("CENTER", parent, "TOPLEFT", basePosition_h, 0)
			self.sparkles[8+i]:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, basePosition_v)
			self.sparkles[12+i]:SetPoint("CENTER", parent, "TOPRIGHT", 0, -basePosition_v)	
		else
			local basePosition_h = (timer-speed*3)/speed*distance_h
			local basePosition_v = (timer-speed*3)/speed*distance_v
			self.sparkles[0+i]:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, basePosition_v)
			self.sparkles[4+i]:SetPoint("CENTER", parent, "TOPRIGHT", 0, -basePosition_v)
			self.sparkles[8+i]:SetPoint("CENTER", parent, "TOPLEFT", basePosition_h, 0)
			self.sparkles[12+i]:SetPoint("CENTER", parent, "BOTTOMRIGHT", -basePosition_h, 0)
		end
	end	
end

function SkillCardShineMixin:PlayPulse()
	math.random(1, 5)
	local change = math.random(2, 7)/10
	local duration = math.random(3, 5)/2

	self.Alpha0:SetChange(-change)
	self.Alpha1:SetChange(change)
	self.Alpha0:SetDuration(duration)
	self.Alpha1:SetDuration(duration)
end

function SkillCardShineMixin:Layout()
	self.NameFrame = CreateFrame("FRAME", "$parent.NameFrame", self)
	self.NameFrame:SetPoint("TOP", 0, -76)
	MixinAndLoadScripts(self.NameFrame, SkillCardNameFrameMixin)

	self.NameBG = self:CreateTexture(nil, "ARTWORK")
	self.NameBG:SetAtlas("UI-Frame-Alliance-Ribbon", Const.TextureKit.IgnoreAtlasSize)
	self.NameBG:SetPoint("TOP", 0, -76)
	self.NameBG:SetSize(171, 56)

	self.Name = self:CreateFontString(nil, "OVERLAY")
	self.Name:SetFontObject(GameFontHighlightMedium)
	self.Name:SetPoint("CENTER", self.NameBG)
	self.Name:SetJustifyH("CENTER")
	self.Name:SetJustifyV("CENTER")
	self.Name:SetWidth(self:GetWidth()-48)
	self.Name:SetShadowOffset(0, 0)
	self.Name:SetVertexColor(0, 0, 0, 1)

	self.OkButton = CreateFrame("BUTTON", "$parent.OkButton", self, "RedButtonTemplate")
	self.OkButton:SetSize(128, 44)
	self.OkButton:SetPoint("TOP", self.NameBG, "BOTTOM", 0, 0)
	self.OkButton:SetText(ACTIVATE)

	self.BackgroundFrame = CreateFrame("FRAME", "$parent.BackgroundFrame", self)
	self.BackgroundFrame:SetPoint("TOPLEFT")
	self.BackgroundFrame:SetPoint("BOTTOMRIGHT")
	MixinAndLoadScripts(self.BackgroundFrame, SkillCardShinyGlowMixin)

	self.BackgroundFrame:SetFrameLevel(self:GetFrameLevel()-1)

    self.BackgroundFrame.AG = self.BackgroundFrame:CreateAnimationGroup()

    self.BackgroundFrame.AG.Alpha0 = self.BackgroundFrame.AG:CreateAnimation("Alpha")
    self.BackgroundFrame.AG.Alpha0:SetChange(-0.5)
    self.BackgroundFrame.AG.Alpha0:SetDuration(0)
    self.BackgroundFrame.AG.Alpha0:SetOrder(1)

    self.BackgroundFrame.AG.Alpha1 = self.BackgroundFrame.AG:CreateAnimation("Alpha")
    self.BackgroundFrame.AG.Alpha1:SetChange(0.5)
    self.BackgroundFrame.AG.Alpha1:SetDuration(2)
    self.BackgroundFrame.AG.Alpha1:SetOrder(2)
    self.BackgroundFrame.AG.Alpha1:SetSmoothing("IN")

    self.BackgroundFrame.AG:Play()
end

-------------------------------------------------------------------------------
--                             Cover for unlock                              --
-------------------------------------------------------------------------------
SkillCardUnlockCoverMixin = CreateFromMixins(CallbackRegistryMixin)

SkillCardUnlockCoverMixin.qualitySounds = {
	[0] = SOUNDKITEXTRA.SKILL_CARD_QUALITY_COMMON,
	[1] = SOUNDKITEXTRA.SKILL_CARD_QUALITY_COMMON,
	[2] = SOUNDKITEXTRA.SKILL_CARD_QUALITY_UNCOMMON,
	[3] = SOUNDKITEXTRA.SKILL_CARD_QUALITY_RARE,
	[4] = SOUNDKITEXTRA.SKILL_CARD_QUALITY_EPIC,
	[5] = SOUNDKITEXTRA.SKILL_CARD_QUALITY_LEGENDARY,
	[6] = SOUNDKITEXTRA.SKILL_CARD_QUALITY_LEGENDARY,
}

SkillCardUnlockCoverMixin.normalScale = 0.9
SkillCardUnlockCoverMixin.maxScale = 1

function SkillCardUnlockCoverMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self:Layout()

	self:GenerateCallbackEvents({
		"OnFlip",
	})

	self.FlipBookCommon:GetTextureIndex(2):RegisterCallback("OnPlay", self.OnFlip, self)
	self.FlipBookQuality:RegisterCallback("OnFinished", self.OnFlip, self)

	self:AcquireSparkles()
end

function SkillCardUnlockCoverMixin:OnFlip()
	self:TriggerEvent("OnFlip")
end

function SkillCardUnlockCoverMixin:OnEnter()
	BaseFrameFadeIn(self.HoverOverFrame)
	self.targetScale = self.maxScale
	self:SetScript("OnUpdate", self.OnUpdateScale)

	PlaySound(SOUNDKITEXTRA.SKILL_CARD_ACTIVATE)
end

function SkillCardUnlockCoverMixin:OnLeave()
	BaseFrameFadeOut(self.HoverOverFrame)
	self.targetScale = self.normalScale
	self:SetScript("OnUpdate", self.OnUpdateScale)

	--StopSound()
end

function SkillCardUnlockCoverMixin:OnUpdateScale()
	local scaleTimer = 0.1
	local scale = self:GetScale()

	if not(math.NearlyEquals(scale, self.targetScale, 0.01)) then
		self:SetScale(scale + (self.targetScale-scale)*scaleTimer)
	else
		self:SetScale(self.targetScale)
		self:SetScript("OnUpdate", nil)
	end

	--PlaySound(SOUNDKIT.UI_72_ARTIFACT_FORGE_TRAIT_REFUND_LOOP, false, true) 
end

function SkillCardUnlockCoverMixin:ResetVisual()
	self.HoverOverFrame:Hide()
	self:SetScale(self.normalScale)
	self:EnableMouse(true)

	self.FlipBookCommon:Stop()
	self.FlipBookQuality:Stop()
	self.FlipBookQualityGlow:Stop()
end

function SkillCardUnlockCoverMixin:UpdateVisual()
	self:ResetVisual()

	local quality = self:GetParent():GetQuality()
	local isGolden = self:GetParent():IsGolden()

	local color = (quality == 1) and CreateColor(0, 0, 0, 1) or ITEM_QUALITY_COLORS[quality]

	for sparkle in self.HoverOverFrame.sparklePool:EnumerateActive() do
		sparkle:SetVertexColor(color:GetRGB())
	end

	self.HoverOverFrame.CardHover:SetVertexColor(color:GetRGB())
	self.HoverOverFrame.CardHover:Show()

	self.PreCastShockWave.AnimSplash:Stop()
	self.PreCastGlow.AnimSplash:Stop()
	self.PreCastShockWave:SetVertexColor(color:GetRGB())
	self.PreCastGlow:SetVertexColor(color:GetRGB())

	if quality >= 2 then
		self.FlipBookCommon:Hide()

		if (isGolden) then
			self.FlipBookQuality:GetTextureIndex(1):SetAtlas("SkillCardQualityFlipBookGolden", Const.TextureKit.IgnoreAtlasSize)
		else
			self.FlipBookQuality:GetTextureIndex(1):SetAtlas("SkillCardQualityFlipBookNormal", Const.TextureKit.IgnoreAtlasSize)
		end

		self.FlipBookQualityGlow:GetTextureIndex(1):SetVertexColor(color:GetRGB())

		self.FlipBookQuality:Show()
		self.FlipBookQualityGlow:Show()
	else
		self.FlipBookQuality:Hide()
		self.FlipBookQualityGlow:Hide()

		if (isGolden) then
			self.FlipBookCommon:GetTextureIndex(1):SetAtlas("SkillCardCommonFlipBookGolden", Const.TextureKit.IgnoreAtlasSize)
		else
			self.FlipBookCommon:GetTextureIndex(1):SetAtlas("SkillCardCommonFlipBookNormal", Const.TextureKit.IgnoreAtlasSize)
		end

		self.FlipBookCommon:Show()
	end

end

function SkillCardUnlockCoverMixin:OnMouseUp()
	self.HoverOverFrame.CardHover:Hide()
	self.PreCastShockWave.AnimSplash:Play()
	self.PreCastGlow.AnimSplash:Play()

	if self:GetParent():GetQuality() >= 2 then
		self.FlipBookQuality:Play()
		self.FlipBookQualityGlow:Play()
	else
		self.FlipBookCommon:Play()
	end

	self:EnableMouse(false)
	self:OnEnter()

	--if not(self:GetParent():IsForceRevealed()) then
		PlaySound(self.qualitySounds[self:GetParent():GetQuality()] or self.qualitySounds[0], true)
	--end
end

function SkillCardUnlockCoverMixin:AcquireSparkles()
	local smokeTCoords = {
		{0, 0.5, 0, 0.5},
		{0.5, 1, 0, 0.5},
		{0.5, 1, 0.5, 1},
		{0, 0.5, 0.5, 1},
	}

	for i = 1, 32 do
		local size = math.random(8, 46)
		local sparkle = self.HoverOverFrame.sparklePool:Acquire()
		sparkle:SetSize(size, size)
		sparkle.Anim:SetTranslationRange(-128, 128, -128, 128)
		sparkle:SetParent(self.HoverOverFrame)
		sparkle:ClearAndSetPoint("CENTER", math.sin(i) * 8, math.cos(i) * 8)
		sparkle.Anim:SetLifetimeRange(6, 16)
		sparkle:SetVertexColor(ITEM_QUALITY_COLORS[3]:GetRGB())
		sparkle:Show()
		sparkle.Anim:Refresh()
	end

	for i = 1, 32 do
		local size = math.random(64, 128)
		local sparkle = self.HoverOverFrame.sparklePool:Acquire()
		sparkle:SetSize(size, size)
		sparkle:SetTexture("spells\\smoke_loose_02_256_blend_contrast.blp")
		sparkle:SetTexCoord(unpack(smokeTCoords[math.random(1, 4)]))
		sparkle.Anim:SetTranslationRange(-32, 32, -32, 32)
		sparkle:SetParent(self.HoverOverFrame)
		sparkle:ClearAndSetPoint("CENTER", math.sin(i) * 56, math.cos(i) * 96)
		sparkle.Anim:SetLifetimeRange(8, 16)
		sparkle:SetVertexColor(ITEM_QUALITY_COLORS[3]:GetRGB())
		sparkle:Show()
		sparkle.Anim:Refresh()
	end
end

function SkillCardUnlockCoverMixin:Layout()
	self.FlipBookCommon = CreateFromMixinsAndLoad(AtlasMultiFlipBookMixin)
	self.FlipBookCommon:Initialize(self, "ARTWORK")
	self.FlipBookCommon:SetSize(nil, 259, 259)
	self.FlipBookCommon:SetPoint(nil, "CENTER")
	self.FlipBookCommon:AddFlipBook("SkillCardCommonFlipBookNormal", 512, 512, 32, 60)
	self.FlipBookCommon:AddFlipBook("SkillCardCommonFlipBookGlow", 512, 512, 32, 60)
	self.FlipBookCommon:GetTextureIndex(2):SetBlendMode("ADD")
	self.FlipBookCommon:Hide()

	self.FlipBookQuality = CreateFromMixinsAndLoad(AtlasMultiFlipBookMixin)
	self.FlipBookQuality:Initialize(self, "ARTWORK")
	self.FlipBookQuality:SetSize(nil, 259, 259)
	self.FlipBookQuality:SetPoint(nil, "CENTER")
	self.FlipBookQuality:AddFlipBook("SkillCardQualityFlipBookNormal", 512, 512, 32, 60)
	self.FlipBookQuality:Hide()

	self.FlipBookQualityGlow = CreateFromMixinsAndLoad(AtlasMultiFlipBookMixin)
	self.FlipBookQualityGlow:Initialize(self, "OVERLAY")
	self.FlipBookQualityGlow:SetSize(nil, 259, 259)
	self.FlipBookQualityGlow:SetPoint(nil, "CENTER")
	self.FlipBookQualityGlow:SetBlendMode("ADD")
	self.FlipBookQualityGlow:AddFlipBook("SkillCardQualityFlipBookGlow", 512, 512, 64, 60)
	self.FlipBookQuality:Hide()

	self.HoverOverFrame = CreateFrame("FRAME", "$parent.HoverOverFrame", self)
	self.HoverOverFrame:SetFrameLevel(self:GetFrameLevel()-1)
	self.HoverOverFrame:SetPoint("TOPLEFT")
	self.HoverOverFrame:SetPoint("BOTTOMRIGHT")
	self.HoverOverFrame.sparklePool = CreateTexturePool(self, "OVERLAY", "SparkleTemplate")
	
	self.HoverOverFrame.CardHover = self.HoverOverFrame:CreateTexture(nil, "BACKGROUND")
	self.HoverOverFrame.CardHover:SetBlendMode("ADD")
	self.HoverOverFrame.CardHover:SetTexture("Interface\\Draft\\CardHover")
	self.HoverOverFrame.CardHover:SetSize(262, 530)
	self.HoverOverFrame.CardHover:SetPoint("CENTER", 1, 0)

	self.HoverOverFrame:Hide()

	-- animated textures
	self.PreCastShockWave = self:CreateTexture(nil, "BACKGROUND")
	self.PreCastShockWave:SetSize(192, 192)
	self.PreCastShockWave:SetTexture("SPELLS\\7fx_alphamask_shockwavesoft_contrast_256")
	self.PreCastShockWave:SetVertexColor(ITEM_QUALITY_COLORS[4]:GetRGBA())
	self.PreCastShockWave:SetAlpha(0)
	self.PreCastShockWave:SetPoint("CENTER")
	self.PreCastShockWave:SetBlendMode("ADD")

	self.PreCastShockWave.AnimSplash = self.PreCastShockWave:CreateAnimationGroup()

	self.PreCastShockWave.AnimSplash.Alpha = self.PreCastShockWave.AnimSplash:CreateAnimation("Alpha")
	self.PreCastShockWave.AnimSplash.Alpha:SetDuration(0.2)
	self.PreCastShockWave.AnimSplash.Alpha:SetOrder(1)
	self.PreCastShockWave.AnimSplash.Alpha:SetEndDelay(0)
	self.PreCastShockWave.AnimSplash.Alpha:SetSmoothing("IN")
	self.PreCastShockWave.AnimSplash.Alpha:SetChange(1)

	self.PreCastShockWave.AnimSplash.Scale2 = self.PreCastShockWave.AnimSplash:CreateAnimation("Scale")
	self.PreCastShockWave.AnimSplash.Scale2:SetScale(2, 2)
	self.PreCastShockWave.AnimSplash.Scale2:SetDuration(1)
	self.PreCastShockWave.AnimSplash.Scale2:SetOrder(1)
	self.PreCastShockWave.AnimSplash.Scale2:SetSmoothing("OUT")

	self.PreCastShockWave.AnimSplash.Rotation2 = self.PreCastShockWave.AnimSplash:CreateAnimation("ROTATION")
	self.PreCastShockWave.AnimSplash.Rotation2:SetDuration(1)
	self.PreCastShockWave.AnimSplash.Rotation2:SetOrder(1)
	self.PreCastShockWave.AnimSplash.Rotation2:SetDegrees(-90)

	self.PreCastShockWave.AnimSplash.Alpha2 = self.PreCastShockWave.AnimSplash:CreateAnimation("Alpha")
	self.PreCastShockWave.AnimSplash.Alpha2:SetStartDelay(0.4)
	self.PreCastShockWave.AnimSplash.Alpha2:SetDuration(0.6)
	self.PreCastShockWave.AnimSplash.Alpha2:SetOrder(1)
	self.PreCastShockWave.AnimSplash.Alpha2:SetEndDelay(0)
	self.PreCastShockWave.AnimSplash.Alpha2:SetSmoothing("OUT")
	self.PreCastShockWave.AnimSplash.Alpha2:SetChange(-1)

	self.PreCastGlow = self:CreateTexture(nil, "BACKGROUND")
	self.PreCastGlow:SetSize(384, 384)
	self.PreCastGlow:SetTexture("SPELLS\\glow_256")
	self.PreCastGlow:SetVertexColor(ITEM_QUALITY_COLORS[4]:GetRGBA())
	self.PreCastGlow:SetAlpha(0)
	self.PreCastGlow:SetPoint("CENTER")
	self.PreCastGlow:SetBlendMode("ADD")

	self.PreCastGlow.AnimSplash = self.PreCastGlow:CreateAnimationGroup()

	self.PreCastGlow.AnimSplash.Alpha = self.PreCastGlow.AnimSplash:CreateAnimation("Alpha")
	self.PreCastGlow.AnimSplash.Alpha:SetDuration(0.2)
	self.PreCastGlow.AnimSplash.Alpha:SetOrder(1)
	self.PreCastGlow.AnimSplash.Alpha:SetEndDelay(0)
	self.PreCastGlow.AnimSplash.Alpha:SetSmoothing("IN")
	self.PreCastGlow.AnimSplash.Alpha:SetChange(1)

	self.PreCastGlow.AnimSplash.Scale2 = self.PreCastGlow.AnimSplash:CreateAnimation("Scale")
	self.PreCastGlow.AnimSplash.Scale2:SetScale(2, 2)
	self.PreCastGlow.AnimSplash.Scale2:SetDuration(1)
	self.PreCastGlow.AnimSplash.Scale2:SetOrder(1)
	self.PreCastGlow.AnimSplash.Scale2:SetSmoothing("OUT")

	self.PreCastGlow.AnimSplash.Rotation2 = self.PreCastGlow.AnimSplash:CreateAnimation("ROTATION")
	self.PreCastGlow.AnimSplash.Rotation2:SetDuration(1)
	self.PreCastGlow.AnimSplash.Rotation2:SetOrder(1)
	self.PreCastGlow.AnimSplash.Rotation2:SetDegrees(-90)

	self.PreCastGlow.AnimSplash.Alpha2 = self.PreCastGlow.AnimSplash:CreateAnimation("Alpha")
	self.PreCastGlow.AnimSplash.Alpha2:SetStartDelay(0.4)
	self.PreCastGlow.AnimSplash.Alpha2:SetDuration(0.6)
	self.PreCastGlow.AnimSplash.Alpha2:SetOrder(1)
	self.PreCastGlow.AnimSplash.Alpha2:SetEndDelay(0)
	self.PreCastGlow.AnimSplash.Alpha2:SetSmoothing("OUT")
	self.PreCastGlow.AnimSplash.Alpha2:SetChange(-1)
end
-------------------------------------------------------------------------------
--                          Duplicate Moving Glow                            --
-------------------------------------------------------------------------------
SkillCardDuplicateGlowMixin = CreateFromMixins(CallbackRegistryMixin)

function SkillCardDuplicateGlowMixin:OnLoad()
	self.moveUp = 32
	self.targetRegion = nil
	self.duplicatePoints = 0

	CallbackRegistryMixin.OnLoad(self)
	self:Layout()

	self.sparklePool = CreateTexturePool(self, "OVERLAY", "SparkleTemplate")

	self:GenerateCallbackEvents({
		"OnRelease",
	})

	self.Movement:SetScript("OnFinished", function() 
		PlaySound(SOUNDKIT.UI_GARRISON_COMMANDTABLE_100PERCENTSUCCESS_31)
		self:TriggerEvent("OnRelease") 
	end)
end

function SkillCardDuplicateGlowMixin:AcquireSparkles()
	self.sparklePool:ReleaseAll()

	for i = 1, 16 do
		local size = math.random(8, 46)
		local sparkle = self.sparklePool:Acquire()
		sparkle:SetSize(size, size)
		sparkle.Anim:SetTranslationRange(-32, 32, -32, 32)
		sparkle:SetParent(self)
		sparkle:ClearAndSetPoint("CENTER", math.sin(i) * 4, math.cos(i) * 4)
		sparkle.Anim:SetLifetimeRange(6, 16)
		sparkle:SetVertexColor(ITEM_QUALITY_COLORS[self:GetQuality() or 1]:GetRGB())
		sparkle:Show()
		sparkle.Anim:Refresh()
	end
end

function SkillCardDuplicateGlowMixin:SetDestinationPoint(region)
	self.targetRegion = region
end

function SkillCardDuplicateGlowMixin:CorrectTranslation() -- need to happen while all objects are visible
	local self_x, self_y = self:GetCenter()
	local target_x, target_y = self.targetRegion:GetCenter()

	if not(self_x) or not(self_y) or not(target_x) or not(target_y) then
		self:TriggerEvent("OnRelease") 
		return false
	end

	self_y = self_y + self.moveUp

	self.Movement.MoveEnd:SetOffset((target_x-self_x)*UIParent:GetEffectiveScale(), (target_y-self_y)*UIParent:GetEffectiveScale())

	return true
end

function SkillCardDuplicateGlowMixin:PlayMove()
	PlaySound(SOUNDKIT.UI_72_BUILDINGS_CONTRIBUTE_RESOURCES_39)
	if self:CorrectTranslation() then
		self:UpdateVisual()
		self.Movement:Stop()
		self.Movement:Play()
	end
end

function SkillCardDuplicateGlowMixin:SetQuality(value)
	self.quality = value
end

function SkillCardDuplicateGlowMixin:GetQuality()
	return self.quality
end

function SkillCardDuplicateGlowMixin:UpdateVisual()
	self.Glow:SetVertexColor(ITEM_QUALITY_COLORS[self:GetQuality() or 1]:GetRGB())
	self:AcquireSparkles()
end

function SkillCardDuplicateGlowMixin:Layout()
	self:SetSize(96, 96)
	self:SetAlpha(0)

	self.Glow = self:CreateTexture(nil, "BACKGROUND")
	self.Glow:SetPoint("CENTER", 0, 0)
	self.Glow:SetAtlas("OBJFX_Glow", Const.TextureKit.IgnoreAtlasSize)
	self.Glow:SetSize(96, 96)

	self.Movement = self:CreateAnimationGroup()

	self.Movement.MoveStart = self.Movement:CreateAnimation("Translation")
	self.Movement.MoveStart:SetDuration(0.5)
	self.Movement.MoveStart:SetSmoothing("IN_OUT")
	self.Movement.MoveStart:SetOffset(0, self.moveUp)
	self.Movement.MoveStart:SetOrder(1)

	self.Movement.AlphaStart = self.Movement:CreateAnimation("Alpha")
	self.Movement.AlphaStart:SetOrder(1)
	self.Movement.AlphaStart:SetDuration(0.3)
	self.Movement.AlphaStart:SetChange(1)
	self.Movement.AlphaStart:SetSmoothing("IN")

	self.Movement.MoveEnd = self.Movement:CreateAnimation("Translation")
	self.Movement.MoveEnd:SetDuration(0.5)
	self.Movement.MoveEnd:SetSmoothing("OUT")
	self.Movement.MoveEnd:SetOrder(2)

	self.Movement.AlphaEnd = self.Movement:CreateAnimation("Alpha")
	self.Movement.AlphaEnd:SetOrder(2)
	self.Movement.AlphaEnd:SetDuration(0.2)
	self.Movement.AlphaEnd:SetChange(-1)
	self.Movement.AlphaEnd:SetSmoothing("OUT")
	self.Movement.AlphaEnd:SetStartDelay(0.2)
end
