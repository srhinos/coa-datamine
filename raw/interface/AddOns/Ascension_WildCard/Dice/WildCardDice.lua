-------------------------------------------------------------------------------
--                                Dice Mixin                                 --
-------------------------------------------------------------------------------
AnimatedDiceMixin = CreateFromMixins(CallbackRegistryMixin)

AnimatedDiceMixin.color = CreateColorFromCode("|cff01b2ff")
AnimatedDiceMixin.explosionDelay = 0.0

function AnimatedDiceMixin:OnLoad()
	MixinAndLoad(self, CallbackRegistryMixin)
	
	self.flipBooks = {}

	AnimatedDiceMixin.Layout(self)

	self:GenerateCallbackEvents({
		"OnSpellReveal",
	})

	self.sparklePool = CreateTexturePool(self.GlowFrame, "ARTWORK", "SparkleTemplate")
	
	self.Visuals = CreateFromMixins(WildCardDiceVisuals)
	self.Visuals:Initialize(self)
	
	self.Visuals:AcquireSparkles()

	self.DiceAppearFlipBook:RegisterCallback("OnPlay", self.OnPlayAppear, self)
	self.DiceCrackFlipBook:RegisterCallback("OnPlay", self.OnPlayCrack, self)
	self.DiceCollapseFlipBook:RegisterCallback("OnPlay", self.OnPlayCollapse, self)
	self.DiceRollFlipBook:RegisterCallback("OnPlay", self.OnPlayRoll, self)

	self.DiceAppearFlipBook:RegisterCallback("OnFinished", self.OnFinishedAppear, self)
	self.DiceCrackFlipBook:RegisterCallback("OnFinished", self.OnFinishedCrack, self)
	self.DiceCollapseFlipBook:RegisterCallback("OnFinished", self.OnFinishedCollapse, self)
	self.DiceRollFlipBook:RegisterCallback("OnFinished", self.OnFinishedRoll, self)
end

function AnimatedDiceMixin:OnPlayAppear()
	self.Visuals:PlayAppear()
end

function AnimatedDiceMixin:OnFinishedAppear()
	dprint("OnFinishAppear")
	if self.Core then
		self.Core:TransitionTo(self.Core.State.READY_TO_ROLL)
		if self.isRapidRolling and self.pendingReveal then
			self:OnClick()
		end
	else
		if self.isRapidRolling and self.pendingReveal then -- reveal immediately in rapid rolling
			self:RegisterOnClick()
			self:OnClick()
		else -- make dice ready for clicks
			self.Visuals:ShowHint()
			self:RegisterOnClick()
		end
	end
end

function AnimatedDiceMixin:OnPlayCrack()
	self:TriggerEvent("OnSpellReveal")

	self:ResetVisual() -- clean up before roulette/roll
	self.Visuals:PlayShockWave()
	self.GlowFrame.Energy.Grow:Play()
end

function AnimatedDiceMixin:OnFinishedCrack()
	-- set up each mixin
end

function AnimatedDiceMixin:OnPlayCollapse()
	-- set up each mixin
end

function AnimatedDiceMixin:OnFinishedCollapse()
	-- set up each mixin
end

function AnimatedDiceMixin:OnPlayRoll()
	-- set up each mixin
end

function AnimatedDiceMixin:OnFinishedRoll()
	-- set up each mixin
end

function AnimatedDiceMixin:OnEnter()
	self.Highlight:Show()
end

function AnimatedDiceMixin:OnLeave()
	GameTooltip:Hide()
	self.Highlight:Hide()
end

function AnimatedDiceMixin:ResetVisual()
	if self.Visuals then
		self.Visuals:ResetVisual()
	end
end

function AnimatedDiceMixin:HideFlipBooks()
	if self.Visuals then
		self.Visuals:HideFlipBooks()
	end
end

function AnimatedDiceMixin:PlayFlipBook(flipBook)
	if self.Visuals then
		self.Visuals:PlayFlipBook(flipBook)
	end
end

function AnimatedDiceMixin:UnregisterOnClick()
	self:EnableMouse(false)
	
	if (self:IsMouseOver()) then
		self:OnLeave()
	end
end

function AnimatedDiceMixin:RegisterOnClick()
	self:EnableMouse(true)

	if (self:IsMouseOver()) then
		self:OnEnter()
	end
end

function AnimatedDiceMixin:PlayQualitySound(quality)
	if self.Visuals then
		self.Visuals:PlayQualitySound(quality)
	end
end

function AnimatedDiceMixin:ReleaseSparkles()
	if self.Visuals then
		self.Visuals:ReleaseSparkles()
	end
end

function AnimatedDiceMixin:AcquireSparkles(color)
	if self.Visuals then
		self.Visuals:AcquireSparkles(color)
	end
end

function AnimatedDiceMixin:SetSparklesQualityColor(color)
	if self.Visuals then
		self.Visuals:SetSparklesQualityColor(color)
	end
end

function AnimatedDiceMixin:PlayExplosion()
	if self.Visuals then
		self.Visuals:PlayExplosion()
	end
end

function AnimatedDiceMixin:StopExplosion()
	if self.Visuals then
		self.Visuals:StopExplosion()
	end
end

function AnimatedDiceMixin:PlayShockWave()
	if self.Visuals then
		self.Visuals:PlayShockWave()
	end
end

function AnimatedDiceMixin:StopShockWave()
	if self.Visuals then
		self.Visuals:StopShockWave()
	end
end

function AnimatedDiceMixin:Layout()
	self:SetFrameLevel(2)

	self.Hover = self:CreateAnimationGroup()

	self.Hover.MoveUp = self.Hover:CreateAnimation("TRANSLATION")
	self.Hover.MoveUp:SetOffset(0, -4)
	self.Hover.MoveUp:SetOrder(1)
	self.Hover.MoveUp:SetDuration(2)
	self.Hover.MoveUp:SetSmoothing("IN")

	self.Hover.MoveDown = self.Hover:CreateAnimation("TRANSLATION")
	self.Hover.MoveDown:SetOffset(0, 4)
	self.Hover.MoveDown:SetOrder(2)
	self.Hover.MoveDown:SetDuration(2)
	self.Hover.MoveDown:SetSmoothing("OUT")

	self.Hover:SetScript("OnFinished", function(self)
		self:Play()
	end)
	self.Hover:Play()

	self.Highlight = self:CreateTexture(nil, "OVERLAY")
	self.Highlight:SetPoint("CENTER", 3, 0.75)
	self.Highlight:SetAtlas("WildCardDiceEmptyCenterGlow", Const.TextureKit.UseAtlasSize)
	self.Highlight:SetHeight(183)
	self.Highlight:Hide()

	self.DiceAppearFlipBook = CreateFromMixinsAndLoad(AtlasMultiFlipBookMixin)
	self.DiceAppearFlipBook:Initialize(self, "ARTWORK")
	self.DiceAppearFlipBook:SetSize(nil, 120, 120)
	self.DiceAppearFlipBook:SetPoint(nil, "CENTER")
	self.DiceAppearFlipBook:AddFlipBook("WildCardDiceAppearFlipBook1", 371, 375, 25, 60)
	self.DiceAppearFlipBook:AddFlipBook("WildCardDiceAppearFlipBook2", 371, 375, 25, 60)
	self.DiceAppearFlipBook:AddFlipBook("WildCardDiceAppearFlipBook3", 371, 375, 25, 60)
	self.DiceAppearFlipBook:Hide()
	table.insert(self.flipBooks, self.DiceAppearFlipBook)

	self.DiceCrackFlipBook = CreateFromMixinsAndLoad(AtlasMultiFlipBookMixin)
	self.DiceCrackFlipBook:Initialize(self, "ARTWORK")
	self.DiceCrackFlipBook:SetSize(nil, 430, 108)
	self.DiceCrackFlipBook:SetPoint(nil, "CENTER")
	self.DiceCrackFlipBook:AddFlipBook("WildCardDiceCrackFlipBook1", 371, 375, 16, 60)
	self.DiceCrackFlipBook:AddFlipBook("WildCardDiceCrackFlipBook2", 1484, 375, 5, 60)
	self.DiceCrackFlipBook:AddFlipBook("WildCardDiceCrackFlipBook3", 1484, 375, 5, 60)
	self.DiceCrackFlipBook:SetSpeed(3)
	self.DiceCrackFlipBook:GetTextureIndex(1):SetSize(108, 108)
	self.DiceCrackFlipBook:Hide()
	table.insert(self.flipBooks, self.DiceCrackFlipBook)

	self.DiceCollapseFlipBook = CreateFromMixinsAndLoad(AtlasMultiFlipBookMixin)
	self.DiceCollapseFlipBook:Initialize(self, "ARTWORK")
	self.DiceCollapseFlipBook:SetSize(nil, 430, 108)
	self.DiceCollapseFlipBook:SetPoint(nil, "CENTER")
	self.DiceCollapseFlipBook:AddFlipBook("WildCardDiceCrackFlipBook3", 1484, 375, 5, 60)
	self.DiceCollapseFlipBook:AddFlipBook("WildCardDiceCrackFlipBook2", 1484, 375, 5, 60)
	self.DiceCollapseFlipBook:SetSpeed(2)
	self.DiceCollapseFlipBook:Invert()
	self.DiceCollapseFlipBook:Hide()
	table.insert(self.flipBooks, self.DiceCollapseFlipBook)

	self.DiceRollFlipBook = CreateFromMixinsAndLoad(AtlasMultiFlipBookMixin)
	self.DiceRollFlipBook:Initialize(self, "ARTWORK")
	self.DiceRollFlipBook:SetSize(nil, 120, 120)
	self.DiceRollFlipBook:SetPoint(nil, "CENTER")
	self.DiceRollFlipBook:AddFlipBook("WildCardDiceRollFlipBook1", 371, 375, 25, 60)
	self.DiceRollFlipBook:AddFlipBook("WildCardDiceRollFlipBook2", 371, 375, 25, 60)
	self.DiceRollFlipBook:SetSpeed(2)
	self.DiceRollFlipBook:Hide()
	table.insert(self.flipBooks, self.DiceRollFlipBook)

	self.QualityGlowFrame = CreateFrame("FRAME", "$parent.QualityGlowFrame", self)
	self.QualityGlowFrame:SetPoint("CENTER", 0, 0)
	self.QualityGlowFrame:SetSize(self:GetSize())
	self.QualityGlowFrame.time = 0.2
	self.QualityGlowFrame:Hide()
	MixinAndLoadScripts(self.QualityGlowFrame, WildCardQualityGlowMixin)

	self.RewardingBGGlow = CreateFrame("FRAME", "$parent.HintFrame", self)
	self.RewardingBGGlow:SetSize(self:GetSize())
	self.RewardingBGGlow:SetPoint("CENTER")
	self.RewardingBGGlow:SetFrameLevel(self.QualityGlowFrame:GetFrameLevel()-1)
	self.RewardingBGGlow:Hide()

	self.RewardingBGGlow.RingTexture = self.RewardingBGGlow:CreateTexture(nil, "BACKGROUND")
	self.RewardingBGGlow.RingTexture:SetSize(256, 256)
	self.RewardingBGGlow.RingTexture:SetAtlas("services-ring-large-glowspin", Const.TextureKit.IgnoreAtlasSize)
	self.RewardingBGGlow.RingTexture:SetPoint("CENTER")
	self.RewardingBGGlow.RingTexture:SetBlendMode("ADD")

	self.RewardingBGGlow.RingTexture.AnimationGroup = self.RewardingBGGlow.RingTexture:CreateAnimationGroup()
	self.RewardingBGGlow.RingTexture.AnimationGroup:SetLooping("REPEAT")

	self.RewardingBGGlow.RingTexture.AnimationGroup.Rotation = self.RewardingBGGlow.RingTexture.AnimationGroup:CreateAnimation("ROTATION")
	self.RewardingBGGlow.RingTexture.AnimationGroup.Rotation:SetDuration(6)
	self.RewardingBGGlow.RingTexture.AnimationGroup.Rotation:SetOrder(1)
	self.RewardingBGGlow.RingTexture.AnimationGroup.Rotation:SetDegrees(360)

	self.HintFrame = CreateFrame("FRAME", "$parent.HintFrame", self)
	self.HintFrame:SetSize(32, 32)
	self.HintFrame:SetPoint("BOTTOM")
	self.HintFrame:SetFrameLevel(self.QualityGlowFrame:GetFrameLevel()+1)
	self.HintFrame:SetAlpha(0)
	self.HintFrame:Hide()

	self.HintFrame.BG = self.HintFrame:CreateTexture(nil, "ARTWORK")
	self.HintFrame.BG:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.HintFrame.BG:SetSize(256, 64)
	self.HintFrame.BG:SetPoint("CENTER", 0, 0)

	self.HintFrame.Text = self.HintFrame:CreateFontString(nil, "OVERLAY")
	self.HintFrame.Text:SetFontObject(GameFontDisableLarge)
	self.HintFrame.Text:SetVertexColor(1, 0.82, 0, 1)
	self.HintFrame.Text:SetText(WILDCARD_HINT_GENERAL)
	self.HintFrame.Text:SetPoint("CENTER", 0, 0)

	self.GlowFrame = CreateFrame("FRAME", "$parent.GlowFrame", self, nil)
	self.GlowFrame:SetSize(128, 128)
	self.GlowFrame:SetPoint("CENTER")
	self.GlowFrame:SetFrameLevel(self:GetFrameLevel()-1)

	self.GlowFrame.GlowTex = self.GlowFrame:CreateTexture(nil, "BORDER")
	self.GlowFrame.GlowTex:SetPoint("CENTER")
	self.GlowFrame.GlowTex:SetSize(300, 300)
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

	self.GlowFrame.Energy = self.GlowFrame:CreateTexture(nil, "OVERLAY")
	self.GlowFrame.Energy:SetPoint("CENTER")
	self.GlowFrame.Energy:SetSize(708, 128)
	self.GlowFrame.Energy:SetTexture("Interface\\WildCard\\Energy")
	self.GlowFrame.Energy:SetBlendMode("ADD")
	self.GlowFrame.Energy:SetAlpha(0)

	self.GlowFrame.Energy.Grow = self.GlowFrame.Energy:CreateAnimationGroup()

	self.GlowFrame.Energy.Grow.ScaleDown = self.GlowFrame.Energy.Grow:CreateAnimation("SCALE")
	self.GlowFrame.Energy.Grow.ScaleDown:SetScale(0.5, 1)
	self.GlowFrame.Energy.Grow.ScaleDown:SetOrder(1)
	self.GlowFrame.Energy.Grow.ScaleDown:SetDuration(0)

	self.GlowFrame.Energy.Grow.ScaleUp = self.GlowFrame.Energy.Grow:CreateAnimation("SCALE")
	self.GlowFrame.Energy.Grow.ScaleUp:SetScale(2, 1)
	self.GlowFrame.Energy.Grow.ScaleUp:SetOrder(2)
	self.GlowFrame.Energy.Grow.ScaleUp:SetDuration(0.5)	
	self.GlowFrame.Energy.Grow.ScaleUp:SetStartDelay(0.25)

	self.GlowFrame.Energy.Grow.FadeIn = self.GlowFrame.Energy.Grow:CreateAnimation("ALPHA")
	self.GlowFrame.Energy.Grow.FadeIn:SetDuration(1)
	self.GlowFrame.Energy.Grow.FadeIn:SetOrder(2)
	self.GlowFrame.Energy.Grow.FadeIn:SetChange(1)
	self.GlowFrame.Energy.Grow.FadeIn:SetEndDelay(3600)

	self.GlowFrame.Energy.Exit = self.GlowFrame.Energy:CreateAnimationGroup()

	self.GlowFrame.Energy.Exit.FadeIn = self.GlowFrame.Energy.Exit:CreateAnimation("ALPHA")
	self.GlowFrame.Energy.Exit.FadeIn:SetDuration(0)
	self.GlowFrame.Energy.Exit.FadeIn:SetOrder(2)
	self.GlowFrame.Energy.Exit.FadeIn:SetChange(1)

	self.GlowFrame.Energy.Exit.FadeOut = self.GlowFrame.Energy.Exit:CreateAnimation("ALPHA")
	self.GlowFrame.Energy.Exit.FadeOut:SetDuration(0.2)
	self.GlowFrame.Energy.Exit.FadeOut:SetOrder(2)
	self.GlowFrame.Energy.Exit.FadeOut:SetChange(-1)

	self.GlowFrame.Energy.Exit:SetScript("OnFinished", function()
		if self.GlowFrame.Energy.Grow:IsPlaying() then
			self.GlowFrame.Energy.Grow:Stop()
		end
	end)

	self.GlowFrame.GlowTex.Breathing:Play()
	self.GlowFrame.GlowTex:SetVertexColor(AnimatedDiceMixin.color:GetRGBA())

	self.PreCastShockWave = self:CreateTexture(nil, "BACKGROUND")
	self.PreCastShockWave:SetSize(128, 128)
	self.PreCastShockWave:SetTexture("SPELLS\\7fx_alphamask_shockwavesoft_contrast_256")
	self.PreCastShockWave:SetVertexColor(AnimatedDiceMixin.color:GetRGBA())
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
	self.PreCastGlow:SetSize(256, 256)
	self.PreCastGlow:SetTexture("SPELLS\\glow_256")
	self.PreCastGlow:SetVertexColor(AnimatedDiceMixin.color:GetRGBA())
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

	self.ExplosionTexture = self:CreateTexture(nil, "BACKGROUND")
	self.ExplosionTexture:SetSize(16, 16)
	self.ExplosionTexture:SetTexture("SPELLS\\starburst_blue")
	self.ExplosionTexture:SetPoint("CENTER")
	self.ExplosionTexture:SetAlpha(0)
	self.ExplosionTexture:SetBlendMode("ADD")

	self.ExplosionTexture.AG = self.ExplosionTexture:CreateAnimationGroup()

	self.ExplosionTexture.AG.Scale = self.ExplosionTexture.AG:CreateAnimation("SCALE")
	self.ExplosionTexture.AG.Scale:SetDuration(0.15)
	self.ExplosionTexture.AG.Scale:SetOrder(1)
	self.ExplosionTexture.AG.Scale:SetSmoothing("IN_OUT")
	self.ExplosionTexture.AG.Scale:SetScale(10, 10)
	self.ExplosionTexture.AG.Scale:SetStartDelay(self.explosionDelay)

	self.ExplosionTexture.AG.Alpha = self.ExplosionTexture.AG:CreateAnimation("ALPHA")
	self.ExplosionTexture.AG.Alpha:SetDuration(0.1)
	self.ExplosionTexture.AG.Alpha:SetOrder(1)
	self.ExplosionTexture.AG.Alpha:SetSmoothing("IN_OUT")
	self.ExplosionTexture.AG.Alpha:SetChange(1)
	self.ExplosionTexture.AG.Alpha:SetStartDelay(self.explosionDelay)

	self.ExplosionTexture.AG.Scale2 = self.ExplosionTexture.AG:CreateAnimation("SCALE")
	self.ExplosionTexture.AG.Scale2:SetDuration(0.25)
	self.ExplosionTexture.AG.Scale2:SetOrder(2)
	self.ExplosionTexture.AG.Scale2:SetSmoothing("OUT")
	self.ExplosionTexture.AG.Scale2:SetScale(0.5, 0.5)

	self.ExplosionTexture.AG.Alpha2 = self.ExplosionTexture.AG:CreateAnimation("ALPHA")
	self.ExplosionTexture.AG.Alpha2:SetDuration(0.25)
	self.ExplosionTexture.AG.Alpha2:SetOrder(3)
	self.ExplosionTexture.AG.Alpha2:SetSmoothing("OUT")
	self.ExplosionTexture.AG.Alpha2:SetChange(-1)

	self.ExplosionGlow = self:CreateTexture(nil, "BACKGROUND")
	self.ExplosionGlow:SetSize(58, 58)
	self.ExplosionGlow:SetTexture("SPELLS\\glow_256")
	self.ExplosionGlow:SetPoint("CENTER")
	self.ExplosionGlow:SetVertexColor(AnimatedDiceMixin.color:GetRGBA())
	self.ExplosionGlow:SetAlpha(0)
	self.ExplosionGlow:SetBlendMode("ADD")

	self.ExplosionGlow.AG = self.ExplosionGlow:CreateAnimationGroup()

	self.ExplosionGlow.AG.Scale = self.ExplosionGlow.AG:CreateAnimation("SCALE")
	self.ExplosionGlow.AG.Scale:SetDuration(0.2)
	self.ExplosionGlow.AG.Scale:SetOrder(1)
	self.ExplosionGlow.AG.Scale:SetSmoothing("IN_OUT")
	self.ExplosionGlow.AG.Scale:SetScale(10, 10)
	self.ExplosionGlow.AG.Scale:SetStartDelay(self.explosionDelay)

	self.ExplosionGlow.AG.Alpha = self.ExplosionGlow.AG:CreateAnimation("ALPHA")
	self.ExplosionGlow.AG.Alpha:SetDuration(0.1)
	self.ExplosionGlow.AG.Alpha:SetOrder(1)
	self.ExplosionGlow.AG.Alpha:SetSmoothing("IN_OUT")
	self.ExplosionGlow.AG.Alpha:SetChange(1)

	self.ExplosionTexture2 = self:CreateTexture(nil, "BACKGROUND")
	self.ExplosionTexture2:SetSize(32, 32)
	self.ExplosionTexture2:SetTexture("SPELLS\\starburst_blue")
	self.ExplosionTexture2:SetPoint("CENTER")
	self.ExplosionTexture2:SetVertexColor(AnimatedDiceMixin.color:GetRGBA())
	self.ExplosionTexture2:SetAlpha(0)
	self.ExplosionTexture2:SetBlendMode("ADD")

	self.ExplosionTexture2.AG = self.ExplosionTexture2:CreateAnimationGroup()

	self.ExplosionTexture2.AG.Scale = self.ExplosionTexture2.AG:CreateAnimation("SCALE")
	self.ExplosionTexture2.AG.Scale:SetDuration(0.15)
	self.ExplosionTexture2.AG.Scale:SetOrder(1)
	self.ExplosionTexture2.AG.Scale:SetSmoothing("IN_OUT")
	self.ExplosionTexture2.AG.Scale:SetScale(10, 10)
	self.ExplosionTexture2.AG.Scale:SetStartDelay(self.explosionDelay)

	self.ExplosionTexture2.AG.Alpha = self.ExplosionTexture2.AG:CreateAnimation("ALPHA")
	self.ExplosionTexture2.AG.Alpha:SetDuration(0.1)
	self.ExplosionTexture2.AG.Alpha:SetOrder(1)
	self.ExplosionTexture2.AG.Alpha:SetSmoothing("IN_OUT")
	self.ExplosionTexture2.AG.Alpha:SetChange(1)
	self.ExplosionTexture2.AG.Alpha:SetStartDelay(self.explosionDelay)

	self.ExplosionTexture2.AG.Scale2 = self.ExplosionTexture2.AG:CreateAnimation("SCALE")
	self.ExplosionTexture2.AG.Scale2:SetDuration(0.5)
	self.ExplosionTexture2.AG.Scale2:SetOrder(2)
	self.ExplosionTexture2.AG.Scale2:SetSmoothing("OUT")
	self.ExplosionTexture2.AG.Scale2:SetScale(0.5, 0.5)

	self.ExplosionTexture2.AG.Alpha2 = self.ExplosionTexture2.AG:CreateAnimation("ALPHA")
	self.ExplosionTexture2.AG.Alpha2:SetDuration(0.5)
	self.ExplosionTexture2.AG.Alpha2:SetOrder(3)
	self.ExplosionTexture2.AG.Alpha2:SetSmoothing("OUT")
	self.ExplosionTexture2.AG.Alpha2:SetChange(-1)

	self.ExplosionShockWave = self:CreateTexture(nil, "OVERLAY")
	self.ExplosionShockWave:SetSize(200, 200)
	self.ExplosionShockWave:SetTexture("SPELLS\\7fx_alphamask_shockwaveshadow_ba")
	self.ExplosionShockWave:SetVertexColor(AnimatedDiceMixin.color:GetRGBA())
	self.ExplosionShockWave:SetAlpha(0)
	self.ExplosionShockWave:SetPoint("CENTER")
	self.ExplosionShockWave:SetBlendMode("ADD")

	self.ExplosionShockWave.AnimSplash = self.ExplosionShockWave:CreateAnimationGroup()

	self.ExplosionShockWave.AnimSplash.Alpha = self.ExplosionShockWave.AnimSplash:CreateAnimation("Alpha")
	self.ExplosionShockWave.AnimSplash.Alpha:SetDuration(0.2)
	self.ExplosionShockWave.AnimSplash.Alpha:SetOrder(1)
	self.ExplosionShockWave.AnimSplash.Alpha:SetEndDelay(0)
	self.ExplosionShockWave.AnimSplash.Alpha:SetSmoothing("IN")
	self.ExplosionShockWave.AnimSplash.Alpha:SetChange(1)
	self.ExplosionShockWave.AnimSplash.Alpha:SetStartDelay(self.explosionDelay)

	self.ExplosionShockWave.AnimSplash.Scale2 = self.ExplosionShockWave.AnimSplash:CreateAnimation("Scale")
	self.ExplosionShockWave.AnimSplash.Scale2:SetScale(2, 2)
	self.ExplosionShockWave.AnimSplash.Scale2:SetDuration(2)
	self.ExplosionShockWave.AnimSplash.Scale2:SetOrder(2)
	self.ExplosionShockWave.AnimSplash.Scale2:SetSmoothing("OUT")

	self.ExplosionShockWave.AnimSplash.Rotation = self.ExplosionShockWave.AnimSplash:CreateAnimation("ROTATION")
	self.ExplosionShockWave.AnimSplash.Rotation:SetDuration(2)
	self.ExplosionShockWave.AnimSplash.Rotation:SetOrder(2)
	self.ExplosionShockWave.AnimSplash.Rotation:SetDegrees(-90)

	self.ExplosionShockWave.AnimSplash.Alpha2 = self.ExplosionShockWave.AnimSplash:CreateAnimation("Alpha")
	self.ExplosionShockWave.AnimSplash.Alpha2:SetDuration(2)
	self.ExplosionShockWave.AnimSplash.Alpha2:SetOrder(2)
	self.ExplosionShockWave.AnimSplash.Alpha2:SetEndDelay(0)
	self.ExplosionShockWave.AnimSplash.Alpha2:SetSmoothing("OUT")
	self.ExplosionShockWave.AnimSplash.Alpha2:SetChange(-1)
end

-------------------------------------------------------------------------------
--                        Regular WildCard Dice Mixin                        --
-------------------------------------------------------------------------------
local WILDCARD_STARTING_ABILITY_REROLL_MAX_LEVEL = 9

local function IsStartingChoiceRerollOK(result)
	return result == "OK" or result == "REROLL_UNLOCKED_STARTING_ABILITIES_OK"
end

local function GetActiveWildcardSpec()
	return SpecializationUtil and SpecializationUtil.GetActiveSpecialization and SpecializationUtil.GetActiveSpecialization()
end

WildCardDiceMixin = CreateFromMixins(AnimatedDiceMixin)

function WildCardDiceMixin:OnLoad()
	AnimatedDiceMixin.OnLoad(self)
	self:RegisterForDrag("LeftButton")

	self:Layout()

	self.Core = CreateFromMixins(WildCardDiceCore)
	self.Core:Initialize(self)

	self.LayoutEngine = CreateFromMixins(WildCardDiceLayout)
	self.LayoutEngine:Initialize(self)

	self.ScrollFrame:RegisterCallback("OnRouletteFinished", self.OnRouletteFinished, self)
	self.NameFrame:RegisterCallback("OnFinished", self.OnFinished, self)
	self.RankFrame:RegisterCallback("OnRankChange", self.OnRankChange, self)
	self.RollButton:SetScript("OnEnter", GenerateClosure(self.RollButtonOnEnter, self))
	self.RollButton:SetScript("OnLeave", GenerateClosure(self.OnLeave, self))
	self.RollButton:SetScript("OnClick", GenerateClosure(self.RollButtonOnClick, self))
	self.RollButton.ScrollCount:SetScript("OnEnter", GenerateClosure(self.ScrollCountOnEnter, self))
	self.RollButton.ScrollCount:SetScript("OnLeave", GenerateClosure(self.OnLeave, self))

	self.staticPopupActiveCount = StaticPopup_GetNumVisible and StaticPopup_GetNumVisible() or 0
	EventRegistry:RegisterCallback("UI.StaticPopup.Show", self.OnStaticPopupShow, self)
	EventRegistry:RegisterCallback("UI.StaticPopup.Hide", self.OnStaticPopupHide, self)

	self:ResetVisual()

	local animationGroups = {self.RankFrame.Reveal, self.RankFrame.Rank.Fade, self.RankFrame.RankQualityOutline.Anim, self.RankFrame.RankGlow.Anim, self.RankFrame.Jiggle}
	for _, AG in pairs(animationGroups) do
		for _, anim in pairs({AG:GetAnimations()}) do
			anim:SetDuration(anim:GetDuration()/2)
			anim:SetEndDelay(anim:GetEndDelay()/2)
			anim:SetStartDelay(anim:GetStartDelay()/2)
		end
	end
end

function WildCardDiceMixin:OnEvent(event, ...)
	OnEventToMethod(self, event, ...)
end

function WildCardDiceMixin:SetRapidRollIsDesired(isDesired)
	self.isDesiredSpell = (isDesired == nil) or isDesired
end

function WildCardDiceMixin:SetRapidRolling(parent)
	self.isRapidRolling = true
	self.LayoutEngine:SetRapidRolling(parent)
end

function WildCardDiceMixin:SetNotRapidRolling()
	self.isRapidRolling = false
	self.LayoutEngine:SetNotRapidRolling()
end

function WildCardDiceMixin:IsStaticPopupVisible()
	return (self.staticPopupActiveCount or 0) > 0
end

function WildCardDiceMixin:DeferShowForStaticPopup(reason)
	if self.isRapidRolling or not self:IsStaticPopupVisible() then
		return false
	end

	self.showDeferredByStaticPopup = true
	self.staticPopupDeferredReason = reason
	return true
end

function WildCardDiceMixin:HideForStaticPopup(activeCount)
	self.staticPopupActiveCount = activeCount or 0

	if self.isRapidRolling or self.hiddenByStaticPopup or not self:IsShown() then
		return
	end

	self.hiddenByStaticPopup = true
	self.hidingForStaticPopup = true
	GameTooltip:Hide()
	self:Hide()
	self.hidingForStaticPopup = nil
end

function WildCardDiceMixin:OnStaticPopupShow(activeCount)
	self:HideForStaticPopup(activeCount)
end

function WildCardDiceMixin:OnStaticPopupHide(activeCount)
	self.staticPopupActiveCount = activeCount or 0

	if self:IsStaticPopupVisible() or self.isRapidRolling then
		return
	end

	if self.hiddenByStaticPopup then
		self.hiddenByStaticPopup = nil
		self.restoringFromStaticPopup = true
		self:Show()
		self.restoringFromStaticPopup = nil
		self:ResumePendingReveal()
		return
	end

	if self.staticPopupDeferredStartingChoiceReason then
		local reason = self.staticPopupDeferredStartingChoiceReason
		self.staticPopupDeferredStartingChoiceReason = nil
		self.showDeferredByStaticPopup = nil
		self.staticPopupDeferredReason = nil
		self:ShowStartingChoicePanel(reason)
		return
	end

	if self.showDeferredByStaticPopup then
		self.showDeferredByStaticPopup = nil
		self.staticPopupDeferredReason = nil
		if self.pendingReveal then
			self:Show()
			self:ResumePendingReveal()
			return
		end
		if WildCard and WildCard.CheckForRolls then
			WildCard:CheckForRolls()
		end
	end
end

-- Replay an interrupted reveal from the crack. The dice went away mid-flight --
-- a static popup hid it, or an ancestor did -- with the learn result still sitting
-- in pendingReveal. The crack/roulette/collapse chain it was running is gone, so
-- restart it instead of waiting on callbacks that will never arrive.
function WildCardDiceMixin:ResumePendingReveal()
	if not self.pendingReveal then
		return false
	end

	if self.Core then
		self.Core:PrepareForRestoredReveal()
	end

	self:PlayFlipBook("DiceCrackFlipBook")
	return true
end

function WildCardDiceMixin:OnRouletteFinished()
	self:PlayFlipBook("DiceCollapseFlipBook")
end

-- Drop the affordances the player's pending decision is made through: the reroll
-- button and any unlearn-confirm popup it raised. Both outlive the dice visually --
-- the button is a child of the dice rather than the fading NameFrame, so it stays
-- opaque and clickable for the whole of a BaseFrameFadeOut, and the popup is a
-- detached frame whose OnAccept unlearns regardless of dice state. A click landing
-- in that window unlearns a spell the dice has already finished with, which strands
-- the reveal chain and wipes the dice.
function WildCardDiceMixin:DismissDecision()
	self.RollButton:Hide()

	-- Scope the dismiss to this spell; a nil id would match every CONFIRM_UNLEARN_S
	-- and close an unrelated Character Advancement popup.
	local internalID = self:GetInternalID()
	if internalID then
		StaticPopup_Hide("CONFIRM_UNLEARN_S", internalID)
	end
end

-- Every teardown path -- each BaseFrameFadeOut site here, WildCard:HideDices, and
-- every PlayFlipBook -- funnels through this first, so it is the one choke point
-- that reliably precedes the dice going away.
function WildCardDiceMixin:UnregisterOnClick()
	AnimatedDiceMixin.UnregisterOnClick(self)
	self:DismissDecision()
end

function WildCardDiceMixin:OnPlayRoll()
	self.DiceEmptyEnter:Hide()

	self:DismissDecision()

	if self.RewardingBGGlow:IsVisible() then
		BaseFrameFadeOut(self.RewardingBGGlow)
	end

	BaseFrameFadeOut(self.NameFrame)

	if (self.RankFrame:IsVisible()) then
		BaseFrameFadeOut(self.RankFrame)
	end

	if (self.QualityGlowFrame:IsVisible()) then
		BaseFrameFadeOut(self.QualityGlowFrame)
	end

	self.Visuals:PlayShockWave()
end

function WildCardDiceMixin:OnFinishedRoll()
	if self:IsStartingChoiceRerollWaitActive() then
		if self.startingChoiceRerollResult or self.startingChoiceRestorePending then
			self:RestoreStartingChoicePanelAfterReroll("reroll-result")
		else
			self:PlayStartingChoiceRerollWait()
		end
		return
	end

	if self.startingChoiceRerolling then
		self.startingChoiceRerollRollFinished = true

		if self.startingChoiceRerollResult then
			self:RestoreStartingChoicePanelAfterReroll("reroll-result")
		end
		return
	end

	self:ResetVisual()

	if self:GetForceFinishByClick() then -- reveal next abilitiy because you already clicked at the dice in prevous phase
		self:RegisterOnClick()
		self:OnClick()
		self:SetForceFinishByClick(false)
	else -- make dice ready for clicks
		self:OnFinishedAppear()
	end
end

function WildCardDiceMixin:OnPlayCollapse()
	if self.startingChoiceRerolling then
		if self.StartingChoice then
			self.StartingChoice:SetActionsShown(false)
		end
		self.GlowFrame.Energy.Exit:Play()
		return
	end

	self.Visuals:PlayExplosion()

	self.GlowFrame.Energy.Exit:Play()

	self.ScrollFrame.time = 0.1 -- for faster fade out
	BaseFrameFadeOut(self.ScrollFrame)
end

function WildCardDiceMixin:OnFinishedCollapse()
	if self.startingChoiceRerolling then
		self.Visuals:PlayShockWave()
		self:PlayFlipBook("DiceRollFlipBook")
		return
	end

	self:UnregisterOnClick()
	self.Icon:Show()
	self.Hover:Stop() -- stop hover before rolling internalID for not to mess up animations

	local data = self.pendingReveal
	self.pendingReveal = nil

	if not(data) or not(next(data)) then
		dprint("WildCardDiceMixin:OnFinishedCollapse no pendingReveal")
		BaseFrameFadeOut(self)
		return
	end

	self:SetInternalID(data)
	if self.Core then
		self.Core:TransitionTo(self.Core.State.DECISION_PENDING, data)
	end
end

function WildCardDiceMixin:OnPlayCrack()
	if self.startingChoiceReveal then
		self:SetSoFRoll(WildCard.isSoFRoll)
		self:ResetVisual()
		if self.StartingChoice then
			self.StartingChoice:PrepareReveal(self.startingChoiceRevealReason)
		end
		self.Visuals:PlayShockWave()
		self.GlowFrame.Energy.Grow:Play()
		return
	end

	self:SetSoFRoll(WildCard.isSoFRoll)
	AnimatedDiceMixin.OnPlayCrack(self)
end

function WildCardDiceMixin:OnFinishedCrack()
	if self.startingChoiceReveal then
		self.Visuals:PlayExplosion()
		if self.StartingChoice then
			self.StartingChoice:FinishReveal()
		end
		self.startingChoiceReveal = nil
		self.startingChoiceRevealReason = nil
		self:UnregisterOnClick()
		if self.Core then
			self.Core:TransitionTo(self.Core.State.STARTING_CHOICE)
		end
		return
	end

	local data = self.pendingReveal
	if self.Core then
		self.Core:TransitionTo(self.Core.State.REVEALING, data)
	else
		AnimatedDiceMixin.OnFinishedCrack(self)
	end
end

function WildCardDiceMixin:OnHide()
	if self.hidingForStaticPopup then
		GameTooltip:Hide()
		return
	end

	-- Hiding an ancestor fires OnHide on every descendant while the descendant's
	-- own shown flag stays set, and the fullscreen world map does exactly that by
	-- hiding UIParent (so does Alt+Z). That is not a teardown: the roll is still
	-- in flight and the dice comes back the moment the map closes, so keep the
	-- state and let OnShow pick the reveal back up. Scoped to the standalone
	-- dice -- while rapid rolling the dice is reparented, and its parent going
	-- away there really does end the session.
	if self:IsShown() and self:GetParent() == UIParent then
		self.hiddenByAncestor = true
		AnimatedDiceMixin.OnLeave(self)
		return
	end

	self.hiddenByAncestor = nil
	self.pendingReveal = nil
	self.startingChoiceRerolling = nil
	self.startingChoiceRerollRollFinished = nil
	self.startingChoiceRerollResult = nil
	self.startingChoiceRerollFromDice = nil
	self.startingChoiceRerollWaitForReveal = nil
	self.startingChoiceRestorePending = nil
	self.startingChoiceRestoreAttempts = nil
	self.startingChoiceReveal = nil
	self.startingChoiceRevealReason = nil

	if self.Core then
		self.Core:TransitionTo(self.Core.State.IDLE)
	end

	self:UnhookEvent("WILDCARD_ROLL_ABILITIES_RESULT")
	self:UnhookEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
	self:UnhookEvent("WILDCARD_DESIRED_ENTRIES_CHANGED")
	self:UnhookEvent("WILDCARD_UNDESIRED_ENTRIES_CHANGED")
	self:UnregisterEvent("SCROLL_OF_FORTUNE_LIMITS_UPDATED")
	self:UnregisterEvent("SCROLL_OF_FORTUNE_REWARDS_LIST_UPDATED")
	self:UnregisterEvent("WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT")
	if self.StartingChoice then
		self.StartingChoice:HideChoice()
	end
	if self.isRapidRolling and self:GetParent().Dice then
		self:GetParent().Dice:Show()
		WildCardRapidRollingFrame:UpdateRollButton()
	end
end

function WildCardDiceMixin:OnShow()
	if self.restoringFromStaticPopup then
		return
	end

	-- Coming back from an ancestor hide (see OnHide): nothing was torn down, the
	-- events are still hooked, so only the animation that was cut off needs
	-- restarting.
	if self.hiddenByAncestor then
		self.hiddenByAncestor = nil
		self:ResumePendingReveal()
		return
	end

	if self:DeferShowForStaticPopup("dice-show") then
		self.hidingForStaticPopup = true
		self:Hide()
		self.hidingForStaticPopup = nil
		return
	end

	self:HookEvent("WILDCARD_ROLL_ABILITIES_RESULT")
	self:HookEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
	self:HookEvent("WILDCARD_DESIRED_ENTRIES_CHANGED")
	self:RegisterEvent("SCROLL_OF_FORTUNE_LIMITS_UPDATED")
	self:RegisterEvent("SCROLL_OF_FORTUNE_REWARDS_LIST_UPDATED")
	if self.isRapidRolling and self:GetParent().Dice then
		self:GetParent().Dice:Hide()
	end
end

function WildCardDiceMixin:OnEnter()
	AnimatedDiceMixin.OnEnter(self)
	
	if self.NameFrame:IsVisible() then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self:GetSpellID()))
		GameTooltip:Show()

		if (self.NameFrame:IsPlaying()) then
			self.NameFrame:Pause()
		end
	end
end

function WildCardDiceMixin:OnLeave()
	AnimatedDiceMixin.OnLeave(self)

	if self.NameFrame:IsVisible() and not(self.NameFrame:IsPlaying()) then
		self.NameFrame:Play()
	end
end

function WildCardDiceMixin:RollButtonOnEnter()
	if (self.NameFrame:IsPlaying()) then
		self.NameFrame:Pause()
	end

	GameTooltip:SetOwner(self.RollButton, "ANCHOR_RIGHT")

	local reason = self:GetCannotUnlearn()

    if reason then
		if (reason == CA_UNLEARN_NO_SCROLL_OF_FORTUNE) then
			GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(WILDCARD_SOF_HELP_TITLE), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
			GameTooltip:AddLine(WILDCARD_SOF_HELP, 1, 0.82, 0, 1, true)
		elseif (reason == (CA_UNLEARN_SCROLL_OF_FORTUNE_LIMIT or "CA_UNLEARN_SCROLL_OF_FORTUNE_LIMIT")) then
			GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(reason), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
			local entry = C_CharacterAdvancement.GetEntryByInternalID(self:GetInternalID())
			if entry then
				local available, total = WildCardUtil.GetAvailableRerolls(entry.Type)
				GameTooltip:AddLine((WILDCARD_SOF_REROLL_LIMIT_DESC or "WILDCARD_SOF_REROLL_LIMIT_DESC"):format(available, total), 1, 0.82, 0, true)
			end
		else
			GameTooltip:AddLine(CA_CANNOT_UNLEARN_S:format(reason), RED_FONT_COLOR.r , RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
		end
    end

    GameTooltip:Show()
end

function WildCardDiceMixin:ScrollCountOnEnter()
	if (self.NameFrame:IsPlaying()) then
		self.NameFrame:Pause()
	end

	local entry = C_CharacterAdvancement.GetEntryByInternalID(self:GetInternalID())
	if not entry then
		return
	end

	local available, total, isLimited = WildCardUtil.GetAvailableRerolls(entry.Type)

	GameTooltip:SetOwner(self.RollButton.ScrollCount, "ANCHOR_RIGHT")
	GameTooltip:AddLine((WILDCARD_SOF_REROLLS_AVAILABLE or "WILDCARD_SOF_REROLLS_AVAILABLE"):format(available), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	if isLimited and available < total then
		GameTooltip:AddLine((WILDCARD_SOF_REROLL_LIMIT_DESC or "WILDCARD_SOF_REROLL_LIMIT_DESC"):format(available, total), 1, 0.82, 0, true)
		if available == 0 then
			GameTooltip:AddLine(CA_UNLEARN_SCROLL_OF_FORTUNE_LIMIT or "CA_UNLEARN_SCROLL_OF_FORTUNE_LIMIT", RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
		end
	elseif total == 0 then
		GameTooltip:AddLine(WILDCARD_SOF_HELP, 1, 0.82, 0, true)
	end
	GameTooltip:Show()
end

function WildCardDiceMixin:RollButtonOnClick()
	if self.isRapidRolling then
		self:Hide()
		self:HookEvent("WILDCARD_UNDESIRED_ENTRIES_CHANGED")
		local ID = self:GetInternalID()
		local entry = C_CharacterAdvancement.GetEntryByInternalID(ID)
		C_Wildcard.AddUndesiredID(ID, entry.Type)
		PlaySound(SOUNDKIT.UI_SHIPYARD_SHIP_DESTROYED_FLAME_01)
	else
		-- A click captured while the button was up can still dispatch after the
		-- result starts rolling away (the button is hidden in OnPlayRoll). Acting
		-- then would unlearn a spell that's already being rerolled and strand the
		-- dice, so ignore the click unless the button is actually being offered.
		if not self.RollButton:IsShown() then
			return
		end
		CharacterAdvancementUtil.ConfirmOrUnlearnID(self:GetInternalID())
	end
end

function WildCardDiceMixin:ToggleLocked()
	local internalID = self:GetInternalID()
	local locked = C_CharacterAdvancement.IsLockedID(internalID)

	if locked then
		StaticPopup_Show("UNLOCK_SPELL_CONFIRM", LinkUtil:GetSpellLink(self:GetSpellID()), nil, internalID)
	else
		C_CharacterAdvancement.LockID(internalID)
	end
end

function WildCardDiceMixin:ResetVisual()
	AnimatedDiceMixin.ResetVisual(self)

	if self.StartingChoice then
		self.StartingChoice:HideChoice()
	end

	if self.LayoutEngine then
		self.LayoutEngine:Reset()
	end
	
	self:SetSpellID(nil)
	self:SetSparklesQualityColor(nil)
	
	self.ScrollFrame:SetAlpha(0)
	self.NameFrame:SetAlpha(0)
	self.RewardingBGGlow:SetAlpha(0)

	self.RewardingBGGlow:Hide()
	self.NameFrame:Hide()
	self.ScrollFrame:Hide()
	self.Icon:Hide()
	self.QualityGlowFrame:Hide()
	self.RankFrame:Hide()
	self.RollButton:Hide()

	self.ExplosionShockWave:SetVertexColor(AnimatedDiceMixin.color:GetRGB())
	self.ExplosionTexture2:SetVertexColor(AnimatedDiceMixin.color:GetRGB())
	self.ExplosionGlow:SetVertexColor(AnimatedDiceMixin.color:GetRGB())

	self.ScrollFrame.Content.AnimationGroup:Stop()

	self.GlowFrame.GlowTex:SetVertexColor(AnimatedDiceMixin.color:GetRGB())
	self.DiceEmptyEnter:Hide()

	self:SetNextRank(nil)
	self.RankFrame:StopAnim()

	WildCard.lastRapidRollResult = nil

	self.CoreIcon:SetShown(false)
	self.OptimalIcon:SetShown(false)
	self.EmpoweringIcon:SetShown(false)
	self.SynergisticIcon:SetShown(false)
end

function WildCardDiceMixin:OnFinished()
	if self:ShowStartingChoicePanel("finished") then
		return
	end

	if (C_Wildcard.CanRollAbilities()) then
		self:PlayFlipBook("DiceRollFlipBook")
	else
		self:UnregisterOnClick()
		BaseFrameFadeOut(self)
		ShowForcedPrimaryStat()
	end
end

function WildCardDiceMixin:SetSoFRoll(value)
	dprint("WildCardDiceMixin:SetSoFRoll: "..(value and "TRUE" or "FALSE"))
	self.isSoFRoll = value
end

function WildCardDiceMixin:GetSoFRoll(value)
	return self.isSoFRoll
end

function WildCardDiceMixin:GetInternalID()
	return self.internalID
end

function WildCardDiceMixin:SetInternalID(data)
	local internalID, rank, oldRank = unpack(data)

	if not(rank) or (rank == 0) then
		dprint("WildCardDiceMixin: Recieved nil or 0 rank")
		rank = 1
	end

	if not(internalID) or (internalID == 0) then
		dprint("WildCardDiceMixin: Recieved nil or 0 internalID")
		internalID = 1
	end

	local displayedRank = oldRank or rank

	self.internalID = internalID

	if self.isRapidRolling and type(C_Wildcard.GetRapidRollingState) == "function" then
		local state = C_Wildcard.GetRapidRollingState()
		if state and state.LearnedEntryID == internalID and state.IsDesired ~= nil then
			self:SetRapidRollIsDesired(state.IsDesired)
		end
	end

	local spellID = CharacterAdvancementUtil.GetTalentRankSpellByID(internalID, displayedRank)

	if not(spellID) then
		spellID = 1
	end

	self:SetSpellID(spellID)

	local icon = select(3, GetSpellInfo(spellID))
	self.Icon:SetTexture(icon)

	if displayedRank and (displayedRank > 1) then
		self:SetQuality(displayedRank)
	else
		local quality = C_CharacterAdvancement.GetQualityInfo(spellID)
		self:SetQuality(quality or 1)
	end

	self:HideFlipBooks()
	self.DiceEmptyEnter:Show()
	self:RegisterOnClick()

	if C_CharacterAdvancement.IsTalentID(internalID) or C_CharacterAdvancement.IsTalentAbilityID(internalID) then
		local _, maxRank = C_CharacterAdvancement.GetTalentRankByID(internalID)

		BaseFrameFadeIn(self.RankFrame)
		dprint("WildCardDiceMixin:SetRank "..(displayedRank or "NO RANK").." "..(maxRank or "NO MAX RANK"))
		self:SetRank(displayedRank, maxRank)

		if (oldRank) then
			self:SetNextRank(rank)
			self:PlayRankChange()
		else
			self:ShowNameFrame(internalID, displayedRank)
		end
	else
		self:ShowNameFrame(internalID, displayedRank)
	end

	if self.isRapidRolling and WildCardRapidRollingFrame and WildCardRapidRollingFrame.savedBuild then
        local spell = C_BuildCreator.GetSpell(WildCardRapidRollingFrame.savedBuild.ID, self:GetSpellID()) 

        if spell then
            self.CoreIcon:SetShown(spell.IsCoreAbility)
            self.OptimalIcon:SetShown(spell.IsOptimalAbility)
            self.EmpoweringIcon:SetShown(spell.IsEmpoweringAbility)
            self.SynergisticIcon:SetShown(spell.IsSynergisticAbility)
        end
	end
end

function WildCardDiceMixin:UpdateRollButton()
	local canUnlearn, reason

	canUnlearn, reason = C_CharacterAdvancement.CanRemoveByEntryID(self:GetInternalID())
	self.RollButton:SetText(WILDCARD_UNLEARN_AND_ROLL)
	if not(canUnlearn) then
		reason = _G[reason] or reason
		self:SetCannotUnlearn(reason)
		self.RollButton:Disable()
	else
		self:SetCannotUnlearn()
		self.RollButton:Enable()
	end

	self:UpdateScrollCount()
end

function WildCardDiceMixin:UpdateScrollCount()
	local entry = C_CharacterAdvancement.GetEntryByInternalID(self:GetInternalID())
	local scrollCount = self.RollButton.ScrollCount

	if not entry then
		scrollCount:Hide()
		return
	end

	local available, total, isLimited = WildCardUtil.GetAvailableRerolls(entry.Type)
	local token = TokenUtil.CreateFromTokenType(TokenUtil.GetScrollOfFortuneForSpec())

	scrollCount.Icon:SetTexture(token:GetIcon())
	scrollCount.Count:SetText("x" .. available)
	scrollCount:SetWidth(scrollCount.Icon:GetWidth() + 2 + scrollCount.Count:GetStringWidth())
	if available > 0 then
		scrollCount.Count:SetTextColor(GREEN_FONT_COLOR:GetRGB())
	elseif isLimited and total > 0 then
		scrollCount.Count:SetTextColor(RED_FONT_COLOR:GetRGB())
	else
		scrollCount.Count:SetTextColor(GRAY_FONT_COLOR:GetRGB())
	end
	scrollCount:Show()
end

function WildCardDiceMixin:RefreshScrollOfFortuneRerollDisplay()
	if not self.RollButton:IsVisible() then
		return
	end

	self:UpdateRollButton()

	if self.RollButton.ScrollCount:IsMouseOver() then
		self:ScrollCountOnEnter()
	elseif self.RollButton:IsMouseOver() then
		self:RollButtonOnEnter()
	end
end

function WildCardDiceMixin:Expand()
	if self.LayoutEngine then
		self.LayoutEngine:Expand()
	end
end

function WildCardDiceMixin:ShowNameFrame(internalID, displayedRank)
	if self.StartingChoice then
		self.StartingChoice:HideChoice()
	end

	self:Expand()

	self.NameFrame:SetInternalID(internalID, displayedRank, (self.isRapidRolling and self.isDesiredSpell))
	self.NameFrame:FadeIn()

	if self.isRapidRolling and self.isDesiredSpell then
		BaseFrameFadeIn(self.RewardingBGGlow)
		self.RewardingBGGlow.RingTexture.AnimationGroup:Play()
	end

	self.isDesiredSpell = nil

	if not self.isRapidRolling then
		self:UpdateRollButton()
		self.RollButton:Show()
	end

	if self:IsMouseOver() and self:IsVisible() then
		self:OnEnter()
	end
end

function WildCardDiceMixin:OnClick()
	dprint("WildCardDiceMixin:OnClick")

	if self.StartingChoice and self.StartingChoice:IsShown() then
		return
	end

	if self.isRapidRolling then
		return
	end

	if C_Wildcard.IsRollRequestBlocked() then
		return
	end

	if not WildCard:CanRoll() then
		self:UnregisterOnClick()
		BaseFrameFadeOut(self)
		return
	end

	if self:ShouldRerollStartingAbilities() then
		self:RequestStartingAbilityReroll()
		return
	end

	if self.DiceEmptyEnter:IsVisible() then
		self:OnFinished(true)
		self:SetForceFinishByClick(true)
	elseif C_Wildcard.CanRollAbilities() then
		if WildCard:WillRollFirstNonStartingAbility() and (C_CharacterAdvancement.GetLearnedTE() == 0) and not(WildCard:IsSoFRoll()) then
			dprint("WildCardDiceMixin: Confirmation Dialogue")
			StaticPopup_Show("CONFIRM_WILDCARD_LEVELING")
			return
		end

		dprint("WildCardDiceMixin: Request roll")
		if not C_Wildcard.RollAbilities() then
			aprint("|cffFF0000[WILDCARD] Roll request dropped by client (reveal pending). Try again in a moment.|r")
			return
		end

		self.Core:TransitionTo(self.Core.State.AWAITING_SERVER)
	else
		dprint("WildCardDiceMixin: exit, can't roll")
		self:UnregisterOnClick()
		BaseFrameFadeOut(self)
	end
end

function WildCardDiceMixin:ShouldRerollStartingAbilities()
	local willRollStartingAbilities
	if type(C_Wildcard.WillRollStartingAbilities) == "function" then
		willRollStartingAbilities = C_Wildcard.WillRollStartingAbilities()
	else
		local level = C_Player and C_Player.GetLevel and C_Player:GetLevel()
		willRollStartingAbilities = level
			and level >= 1
			and level <= WILDCARD_STARTING_ABILITY_REROLL_MAX_LEVEL
	end

	return willRollStartingAbilities
		and not self.isRapidRolling
		and not WildCard:IsSoFRoll()
		and C_Wildcard.CanRollAbilities()
		and type(C_Wildcard.RerollUnlockedStartingAbilities) == "function"
end

function WildCardDiceMixin:RequestStartingAbilityReroll()
	dprint("WildCardDiceMixin: Request starting ability reroll")

	self:ClearStartingChoiceKept()
	if self.StartingChoice then
		self.StartingChoice.rerolling = true
		self.StartingChoice.pendingRefresh = nil
		-- The orb-driven reroll skips the collapse flipbook, so OnPlayCollapse never
		-- runs to pull the Roll/Keep actions down. Take them out here or they stay
		-- live for the whole reroll -- clicking Keep mid-flight clears the reroll
		-- state and the panel vanishes when the result lands.
		self.StartingChoice:SetControlsEnabled(false)
		self.StartingChoice:SetActionsShown(false)
	end

	self:RegisterEvent("WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT")
	self:StartStartingChoiceReroll(true)

	if not C_Wildcard.RerollUnlockedStartingAbilities() then
		self:UnregisterEvent("WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT")
		if self.StartingChoice then
			self.StartingChoice.rerolling = false
			self.StartingChoice:SetControlsEnabled(true)
			self.StartingChoice:SetActionsShown(true)
		end
		self:CancelStartingChoiceReroll(true)
		self:OnFinishedAppear()
		return false
	end

	self:PlayStartingChoiceRerollWait()
	return true
end

function WildCardDiceMixin:OnDragStart()
	ClearCursor()
	local spellID = self:GetSpellID()

	if not(spellID) or (spellID == 0) then
		return
	end

	local name = GetSpellInfo(self:GetSpellID())

	if (name) then
		PickupSpell(name)
	end
end

function WildCardDiceMixin:SetQuality(quality)
	if self.Visuals then
		self.Visuals:SetQuality(quality)
	end
end

function WildCardDiceMixin:SetCannotUnlearn(value)
	self.cannotUnlearn = value
end

function WildCardDiceMixin:GetCannotUnlearn()
	return self.cannotUnlearn
end

function WildCardDiceMixin:SetSpellID(value)
	self.spellID = value
end

function WildCardDiceMixin:GetSpellID()
	return self.spellID
end

function WildCardDiceMixin:SetForceFinishByClick(value)
	self.forceFinishByClick = value
end

function WildCardDiceMixin:GetForceFinishByClick()
	return self.forceFinishByClick or self.isRapidRolling
end

function WildCardDiceMixin:SetRank(rank, maxRank)
	if (rank) then
		self.RankFrame:SetRank(rank)
		self.RankFrame:SetMaxRank(maxRank)
		self.RankFrame:UpdateVisual()
	end
end

function WildCardDiceMixin:SetNextRank(value)
	self.RankFrame:SetNextRank(value)
end

function WildCardDiceMixin:PlayRankChange()
	self.RankFrame:PlayAnim()
end

function WildCardDiceMixin:IsRankUpdatePlaying()
	return self.RankFrame.Reveal:IsPlaying()
end

function WildCardDiceMixin:OnRankChange(oldRank, newRank)
	local internalID = self:GetInternalID()

	if (internalID) then
		self:SetInternalID({internalID, newRank})
	end
end

function WildCardDiceMixin:WILDCARD_ROLL_ABILITIES_RESULT(result)
	if (result ~= "ROLL_ABILITIES_OK") then
		self.Core:TransitionTo(self.Core.State.READY_TO_ROLL)
		
		local errorMsg = ({
			ROLL_ABILITIES_NO_ROLL = "No eligible Wildcard roll is available.",
			CAN_START_RAPID_ROLLING_NO_ROLL = "No eligible Wildcard rapid roll is available.",
		})[result] or _G[result] or result
		UIErrorsFrame:AddMessage(errorMsg, 1, 0, 0)
		SendSystemMessage("|cffFF0000"..errorMsg.."|r")
	end
end

function WildCardDiceMixin:WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT(result)
	self:UnregisterEvent("WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT")

	if not self.startingChoiceRerolling then
		return
	end

	if self.StartingChoice then
		self.StartingChoice.rerolling = false
		self.StartingChoice.pendingRefresh = nil
	end

	local isOK = IsStartingChoiceRerollOK(result)
	self:FinishStartingChoiceReroll(result)

	if not isOK then
		self:OnFinishedAppear()

		if result then
			local errorMsg = _G[result] or result
			UIErrorsFrame:AddMessage(errorMsg, 1, 0, 0)
			SendSystemMessage("|cffFF0000"..errorMsg.."|r")
		end
	end
end

function WildCardDiceMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
	if self.RollButton:IsVisible() then
		self:UpdateRollButton()
	end
end

function WildCardDiceMixin:SCROLL_OF_FORTUNE_LIMITS_UPDATED()
	self:RefreshScrollOfFortuneRerollDisplay()
end

function WildCardDiceMixin:SCROLL_OF_FORTUNE_REWARDS_LIST_UPDATED()
	self:RefreshScrollOfFortuneRerollDisplay()
end

function WildCardDiceMixin:WILDCARD_UNDESIRED_ENTRIES_CHANGED()
	WildCardRapidRollingFrame:Refresh()
	self:UnhookEvent("WILDCARD_UNDESIRED_ENTRIES_CHANGED")
end

function WildCardDiceMixin:ShowStartingChoicePanel(reason)
	if not self.StartingChoice then
		return false
	end

	if self.isRapidRolling then
		return false
	end

	if (self.StartingChoice:IsShown() and not self.startingChoiceRestorePending) or self.startingChoiceReveal then
		return true
	end

	if not self.StartingChoice:CanShow() then
		return false
	end

	if not self.StartingChoice:HasEntries() then
		return false
	end

	if self:IsStartingChoiceKeptForActiveSpec() and reason ~= "popup-cancel" then
		return false
	end

	if self:DeferShowForStaticPopup("starting-choice") then
		self.staticPopupDeferredStartingChoiceReason = reason
		return true
	end

	self.startingChoiceRestorePending = nil
	self.startingChoiceRestoreAttempts = nil
	self:SetAlpha(1)
	self:Show()

	self.startingChoiceReveal = true
	self.startingChoiceRevealReason = reason
	self:PlayFlipBook("DiceCrackFlipBook")
	return true
end

function WildCardDiceMixin:HideStartingChoicePanel()
	self.startingChoiceRestorePending = nil
	self.startingChoiceRestoreAttempts = nil
	if self.StartingChoice then
		self.StartingChoice:HideChoice()
	end
end

function WildCardDiceMixin:KeepStartingChoice()
	self:SetStartingChoiceKept()
	self.startingChoiceRerolling = nil
	self.startingChoiceRerollRollFinished = nil
	self.startingChoiceRerollResult = nil
	self.startingChoiceRerollFromDice = nil
	self.startingChoiceRerollWaitForReveal = nil
	self.startingChoiceRestorePending = nil
	self.startingChoiceRestoreAttempts = nil
	self.startingChoiceReveal = nil
	self.startingChoiceRevealReason = nil

	if self.StartingChoice then
		self.StartingChoice:HideChoice()
	end

	if WildCard:CanRoll() then
		self:PlayFlipBook("DiceAppearFlipBook")
	else
		self:UnregisterOnClick()
		BaseFrameFadeOut(self)
		if ShowForcedPrimaryStat then
			ShowForcedPrimaryStat()
		end
	end
end

function WildCardDiceMixin:SetStartingChoiceKept()
	self.startingChoiceKept = true
	self.startingChoiceKeptSpec = GetActiveWildcardSpec()
end

function WildCardDiceMixin:ClearStartingChoiceKept()
	self.startingChoiceKept = nil
	self.startingChoiceKeptSpec = nil
end

function WildCardDiceMixin:IsStartingChoiceKeptForActiveSpec()
	if not self.startingChoiceKept then
		return false
	end

	local activeSpec = GetActiveWildcardSpec()
	if self.startingChoiceKeptSpec and activeSpec and self.startingChoiceKeptSpec ~= activeSpec then
		self:ClearStartingChoiceKept()
		return false
	end

	return true
end

function WildCardDiceMixin:HandleStartingChoiceLearned(...)
	if self.startingChoiceRerolling or self.startingChoiceReveal or self.startingChoiceRestorePending then
		if self.StartingChoice then
			self.StartingChoice.pendingRefresh = true
		end
		return true
	end

	return self.StartingChoice and self.StartingChoice:HandleEntryLearned(...)
end

function WildCardDiceMixin:StartStartingChoiceReroll(waitForResultOnly)
	self.startingChoiceRerolling = true
	self.startingChoiceRerollRollFinished = nil
	self.startingChoiceRerollResult = nil
	self.startingChoiceRerollFromDice = waitForResultOnly or nil
	self.startingChoiceRerollWaitForReveal = true
	self.startingChoiceRestorePending = nil
	self.startingChoiceRestoreAttempts = nil
	self.startingChoiceReveal = nil
	self.startingChoiceRevealReason = nil

	if waitForResultOnly then
		self:UnregisterOnClick()
		return
	end

	self:PlayFlipBook("DiceCollapseFlipBook")
end

function WildCardDiceMixin:IsStartingChoiceRerollWaitActive()
	return self.startingChoiceRerollWaitForReveal
		and (self.startingChoiceRerolling or self.startingChoiceRestorePending)
		and not self.startingChoiceReveal
end

function WildCardDiceMixin:PlayStartingChoiceRerollWait()
	if not self:IsStartingChoiceRerollWaitActive() then
		return
	end

	if self.startingChoiceRerollResult and not self.startingChoiceRestorePending then
		return
	end

	self:PlayFlipBook("DiceRollFlipBook")
end

function WildCardDiceMixin:CancelStartingChoiceReroll(suppressChoiceRestore)
	self.startingChoiceRerolling = nil
	self.startingChoiceRerollRollFinished = nil
	self.startingChoiceRerollResult = nil
	self.startingChoiceRerollFromDice = nil
	self.startingChoiceRerollWaitForReveal = nil
	self.startingChoiceRestorePending = nil
	self.startingChoiceRestoreAttempts = nil
	if not suppressChoiceRestore then
		self:HideFlipBooks()
	end
	if self.StartingChoice and not suppressChoiceRestore then
		self.StartingChoice:ShowChoice("reroll-cancel")
	end
end

function WildCardDiceMixin:RestoreStartingChoicePanelAfterReroll(reason)
	local keepRollingUntilReveal = self.startingChoiceRerollWaitForReveal
	self.startingChoiceRerolling = nil
	self.startingChoiceRerollRollFinished = nil
	self.startingChoiceRerollResult = nil
	self.startingChoiceRestorePending = true
	self.startingChoiceRestoreAttempts = self.startingChoiceRestoreAttempts or 0

	if self:ShowStartingChoicePanel(reason) then
		self.startingChoiceRerollFromDice = nil
		self.startingChoiceRerollWaitForReveal = nil
		return
	end

	self.startingChoiceRestoreAttempts = self.startingChoiceRestoreAttempts + 1
	if self.startingChoiceRestoreAttempts > 30 then
		self.startingChoiceRestorePending = nil
		self.startingChoiceRestoreAttempts = nil
		self.startingChoiceRerollFromDice = nil
		self.startingChoiceRerollWaitForReveal = nil
		self:ResetVisual()
		self:OnFinishedAppear()
		return
	end

	if keepRollingUntilReveal then
		self:PlayStartingChoiceRerollWait()
		return
	end

	Timer.After(0.1, function()
		if self.startingChoiceRestorePending then
			self:RestoreStartingChoicePanelAfterReroll(reason)
		end
	end)
end

function WildCardDiceMixin:FinishStartingChoiceReroll(result)
	local isOK = result == "OK" or result == "REROLL_UNLOCKED_STARTING_ABILITIES_OK"

	if not isOK then
		self:CancelStartingChoiceReroll(self.startingChoiceRerollFromDice)
		return
	end

	self.startingChoiceRerollResult = true
	if self.startingChoiceRerollRollFinished
		or (self:IsStartingChoiceRerollWaitActive() and not self.DiceRollFlipBook:IsPlaying() and not self.DiceCollapseFlipBook:IsPlaying())
	then
		self:RestoreStartingChoicePanelAfterReroll("reroll-result")
	end
end

function WildCardDiceMixin:Layout()
	self.DiceEmptyEnter = self:CreateTexture(nil, "ARTWORK")
	self.DiceEmptyEnter:SetAtlas("WildCardDiceEmptyCenter", Const.TextureKit.UseAtlasSize)
	self.DiceEmptyEnter:SetPoint("CENTER")
	self.DiceEmptyEnter:Hide()

	self.DiceRollFlipBook:AddFlipBook("WildCardDiceAppearFlipBook3", 371, 375, 25, 60)
	self.DiceRollFlipBook:GetTextureIndex(2):SetAtlas("WildCardDiceAppearFlipBook2", Const.TextureKit.IgnoreAtlasSize)

	self.Icon = self:CreateTexture(nil, "BORDER")
	self.Icon:SetPoint("CENTER", 0, 0)
	self.Icon:SetSize(42, 42)

	self.CoreIcon = CreateFrame("BUTTON", "$parentCoreIcon", self, "SpellButtonCoreIcon")
	self.CoreIcon:SetPoint("CENTER", self.Icon, "TOPLEFT")
	self.CoreIcon:SetScale(1.5)

	self.OptimalIcon = CreateFrame("BUTTON", "$parentOptimalIcon", self, "SpellButtonOptimalIcon")
	self.OptimalIcon:SetPoint("CENTER", self.Icon, "TOPLEFT")
	self.OptimalIcon:SetScale(1.5)

	self.EmpoweringIcon = CreateFrame("BUTTON", "$parentEmpoweringIcon", self, "SpellButtonEmpoweringIcon")
	self.EmpoweringIcon:SetPoint("CENTER", self.Icon, "TOPLEFT")
	self.EmpoweringIcon:SetScale(1.5)

	self.SynergisticIcon = CreateFrame("BUTTON", "$parentSynergisticIcon", self, "SpellButtonSynergisticIcon")
	self.SynergisticIcon:SetPoint("CENTER", self.Icon, "TOPLEFT")
	self.SynergisticIcon:SetScale(1.5)

	self.RankFrame = CreateFrame("FRAME", "$parent.RankFrame", self, "AnimatedRankTemplate")
	self.RankFrame:SetPoint("CENTER", self.Icon, "BOTTOMRIGHT", -5, 3)
	self.RankFrame.time = 0.3
	self.RankFrame:Hide()
	
	-- frames
	self.NameFrame = CreateFrame("FRAME", "$parent.NameFrame", self)
	self.NameFrame:SetPoint("CENTER")
	self.NameFrame:SetSize(self:GetSize())
	self.NameFrame.time = 1
	MixinAndLoadScripts(self.NameFrame, WildCardNameFrameMixin)
	self.NameFrame:SetFrameLevel(self:GetFrameLevel()-1)
	self.NameFrame:SetAlpha(0)
	self.NameFrame:Hide()

	self.NameFrame.LineUp:SetPoint("TOP", self.Icon, "BOTTOM", 0, -12)

	self.ScrollFrame = CreateFrame("ScrollFrame", "$parent.ScrollFrame", self)
	self.ScrollFrame:SetFrameLevel(self:GetFrameLevel()-1)
	self.ScrollFrame:SetSize(320, 60)
	self.ScrollFrame:SetPoint("CENTER", 0, 0)
	self.ScrollFrame:SetAlpha(0)
	self.ScrollFrame:EnableMouse(false)
	MixinAndLoadScripts(self.ScrollFrame, WildCardScrollFrameRouletteMixin)

	self.GlowFrame:SetFrameLevel(self.ScrollFrame:GetFrameLevel()-1)

	self.RollButton = CreateFrame("Button", "$parent.RollButton", self, "StaticPopupButtonTemplate")
	self.RollButton:SetSize(131, 22)
	self.RollButton:SetText(WILDCARD_UNLEARN_AND_ROLL)
	self.RollButton:SetPoint("CENTER", self.NameFrame.LineDown, "CENTER", 0, -4)
	self.RollButton:SetMotionScriptsWhileDisabled(true)
	self.RollButton:Hide()
	self.RollButton:SetFrameLevel(self:GetFrameLevel()+1)

	self.RollButton.BG = self.RollButton:CreateTexture(nil, "BACKGROUND")
	self.RollButton.BG:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.RollButton.BG:SetSize(192, 32)
	self.RollButton.BG:SetPoint("CENTER", 0, 0)

	self.RollButton.ScrollCount = CreateFrame("Frame", "$parent.ScrollCount", self.RollButton)
	self.RollButton.ScrollCount:SetSize(44, 18)
	self.RollButton.ScrollCount:SetPoint("TOP", self.RollButton, "BOTTOM", 0, -3)
	self.RollButton.ScrollCount:EnableMouse(true)

	self.RollButton.ScrollCount.Icon = self.RollButton.ScrollCount:CreateTexture(nil, "ARTWORK")
	self.RollButton.ScrollCount.Icon:SetSize(16, 16)
	self.RollButton.ScrollCount.Icon:SetPoint("LEFT", 0, 0)
	self.RollButton.ScrollCount.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	self.RollButton.ScrollCount.Count = self.RollButton.ScrollCount:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	self.RollButton.ScrollCount.Count:SetPoint("LEFT", self.RollButton.ScrollCount.Icon, "RIGHT", 2, 0)

	self.StartingChoice = CreateFrame("FRAME", "$parent.StartingChoice", self)
	MixinAndLoadScripts(self.StartingChoice, WildCardStartingChoiceMixin)
	self.StartingChoice:Hide()
end
