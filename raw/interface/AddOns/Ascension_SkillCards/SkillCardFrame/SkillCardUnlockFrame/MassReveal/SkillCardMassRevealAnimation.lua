--
-- Texture animation rays
--
SkillCardMassRevealGlowPreCastMixin = {}

function SkillCardMassRevealGlowPreCastMixin:OnLoad()
	self:Layout()
end

function SkillCardMassRevealGlowPreCastMixin:Layout()
	self:SetBlendMode("ADD")
	self:SetAlpha(0)

	self.AnimationGroup = self:CreateAnimationGroup()

	self.AnimationGroup.FadeOutStart = self.AnimationGroup:CreateAnimation("ALPHA")
	self.AnimationGroup.FadeOutStart:SetChange(-1)
	self.AnimationGroup.FadeOutStart:SetDuration(0)
	self.AnimationGroup.FadeOutStart:SetOrder(1)
	self.AnimationGroup.FadeOutStart:SetStartDelay(0.2)

	self.AnimationGroup.ScaleDownStart = self.AnimationGroup:CreateAnimation("SCALE")
	self.AnimationGroup.ScaleDownStart:SetScale(0.25, 0.25)
	self.AnimationGroup.ScaleDownStart:SetDuration(0)
	self.AnimationGroup.ScaleDownStart:SetOrder(1)

	self.AnimationGroup.FadeIn = self.AnimationGroup:CreateAnimation("ALPHA")
	self.AnimationGroup.FadeIn:SetChange(1)
	self.AnimationGroup.FadeIn:SetDuration(0.5)
	self.AnimationGroup.FadeIn:SetOrder(2)
	self.AnimationGroup.FadeIn:SetSmoothing("OUT")

	self.AnimationGroup.ScaleUp = self.AnimationGroup:CreateAnimation("SCALE")
	self.AnimationGroup.ScaleUp:SetScale(4, 4)
	self.AnimationGroup.ScaleUp:SetDuration(0.5)
	self.AnimationGroup.ScaleUp:SetOrder(2)

	self.AnimationGroup.FadeOut = self.AnimationGroup:CreateAnimation("ALPHA")
	self.AnimationGroup.FadeOut:SetChange(-1)
	self.AnimationGroup.FadeOut:SetDuration(0.3)
	self.AnimationGroup.FadeOut:SetOrder(3)
	self.AnimationGroup.FadeOut:SetSmoothing("IN")

	self.AnimationGroup.ScaleDown = self.AnimationGroup:CreateAnimation("SCALE")
	self.AnimationGroup.ScaleDown:SetScale(0.25, 0.25)
	self.AnimationGroup.ScaleDown:SetDuration(0.3)
	self.AnimationGroup.ScaleDown:SetOrder(3)
end

--
-- Texture animation card
--
SkillCardCoverMassRevealAnimationMixin = {}

function SkillCardCoverMassRevealAnimationMixin:OnLoad()
	self:Layout()
	self:SetCardStyle(false)
end

function SkillCardCoverMassRevealAnimationMixin:SetCardStyle(isGolden)
	if (isGolden) then
		self:SetTexCoord(0.5, 0.625, 0.5, 0.625)
	else
		self:SetTexCoord(0, 0.125, 0, 0.125)
	end
end

function SkillCardCoverMassRevealAnimationMixin:Layout()
	self:SetSize(256, 256)
	self:SetAlpha(0)

	self:SetTexture("Interface\\skillCards\\flip_common")

	self.AnimationGroupAppear = self:CreateAnimationGroup()

	self.AnimationGroupAppear.FadeOutStart = self.AnimationGroupAppear:CreateAnimation("ALPHA")
	self.AnimationGroupAppear.FadeOutStart:SetChange(-1)
	self.AnimationGroupAppear.FadeOutStart:SetDuration(0)
	self.AnimationGroupAppear.FadeOutStart:SetOrder(1)

	self.AnimationGroupAppear.ScaleUpStart = self.AnimationGroupAppear:CreateAnimation("SCALE")
	self.AnimationGroupAppear.ScaleUpStart:SetScale(2, 2)
	self.AnimationGroupAppear.ScaleUpStart:SetDuration(0)
	self.AnimationGroupAppear.ScaleUpStart:SetOrder(1)

	self.AnimationGroupAppear.Rotation = self.AnimationGroupAppear:CreateAnimation("ROTATION")
	self.AnimationGroupAppear.Rotation:SetDegrees(45)
	self.AnimationGroupAppear.Rotation:SetDuration(0)
	self.AnimationGroupAppear.Rotation:SetOrder(2)
	self.AnimationGroupAppear.Rotation:SetEndDelay(16)

	self.AnimationGroupAppear.ScaleDown = self.AnimationGroupAppear:CreateAnimation("SCALE")
	self.AnimationGroupAppear.ScaleDown:SetScale(0.5, 0.5)
	self.AnimationGroupAppear.ScaleDown:SetDuration(0.3)
	self.AnimationGroupAppear.ScaleDown:SetOrder(2)
	self.AnimationGroupAppear.ScaleDown:SetSmoothing("IN")

	self.AnimationGroupAppear.FadeIn = self.AnimationGroupAppear:CreateAnimation("ALPHA")
	self.AnimationGroupAppear.FadeIn:SetChange(1)
	self.AnimationGroupAppear.FadeIn:SetDuration(0.2)
	self.AnimationGroupAppear.FadeIn:SetOrder(2)
	self.AnimationGroupAppear.FadeIn:SetSmoothing("OUT")

	self.AnimationGroupFadeOut = self:CreateAnimationGroup()

	self.AnimationGroupFadeOut.Rotation = self.AnimationGroupFadeOut:CreateAnimation("ROTATION")
	self.AnimationGroupFadeOut.Rotation:SetDegrees(45)
	self.AnimationGroupFadeOut.Rotation:SetDuration(0)
	self.AnimationGroupFadeOut.Rotation:SetOrder(1)

	self.AnimationGroupFadeOut.FadeInStart = self.AnimationGroupFadeOut:CreateAnimation("ALPHA")
	self.AnimationGroupFadeOut.FadeInStart:SetChange(1)
	self.AnimationGroupFadeOut.FadeInStart:SetDuration(0)
	self.AnimationGroupFadeOut.FadeInStart:SetOrder(1)

	self.AnimationGroupFadeOut.MoveOut = self.AnimationGroupFadeOut:CreateAnimation("Translation")
	self.AnimationGroupFadeOut.MoveOut:SetDuration(0.7)
	self.AnimationGroupFadeOut.MoveOut:SetOrder(2)

	self.AnimationGroupFadeOut.FadeOut = self.AnimationGroupFadeOut:CreateAnimation("ALPHA")
	self.AnimationGroupFadeOut.FadeOut:SetStartDelay(0.2)
	self.AnimationGroupFadeOut.FadeOut:SetChange(-1)
	self.AnimationGroupFadeOut.FadeOut:SetDuration(0.3)
	self.AnimationGroupFadeOut.FadeOut:SetOrder(2)
end

--
-- FRAME
--
SkillCardMassRevealAnimationMixin = {}

function SkillCardMassRevealAnimationMixin:OnLoad()
	self.AnimatedCards = {}
	self.AnimatedPreExposion = {}

	self.animTime = 2

	self:Layout()
	self:AquireCards()

	self.AnimatedCards[17].AnimationGroupAppear.FadeIn:SetScript("OnPlay", GenerateClosure(self.PlayPreExplosion, self))
end

function SkillCardMassRevealAnimationMixin:SetCardStyle(isGolden)
	for _, card in pairs(self.AnimatedCards) do
		card:SetCardStyle(isGolden)
	end
end

function SkillCardMassRevealAnimationMixin:PlayCardsAnimation()
	PlaySound(SOUNDKIT.UI_82_HEARTOFAZEROTH_SLOTFIRSTESSENCE)

	for _, card in pairs(self.AnimatedCards) do
		card.AnimationGroupAppear:Stop()
		card.AnimationGroupAppear:Play()
	end
end

function SkillCardMassRevealAnimationMixin:PlayExplosion()
	PlaySound(SOUNDKIT.FX_80_AZERITEKIT_EXPLOSION_01)

	self.explosionShine.AG:Stop()
	self.explosionShockWave.AnimSplash:Stop()
	self.explosionShockWave2.AnimSplash:Stop()
	self.explosionShineColored.AG:Stop()
	self.explosionShineColored2.AG:Stop()

	self.explosionShockWave2.AnimSplash:Play()
	self.explosionShine.AG:Play()
	self.explosionShineColored.AG:Play()
	self.explosionShockWave.AnimSplash:Play()
	self.explosionShineColored2.AG:Play()

	for _, card in pairs(self.AnimatedCards) do
		card.AnimationGroupAppear:Stop()
		card.AnimationGroupFadeOut:Stop()
		card.AnimationGroupFadeOut:Play()
	end
end

function SkillCardMassRevealAnimationMixin:PlayPreExplosion()
	PlaySound(SOUNDKIT.FX_80_AZERITEKIT_CAST_LARGE_05)
	for _, texture in pairs(self.AnimatedPreExposion) do
		texture.AnimationGroup:Stop()
		texture.AnimationGroup:Play()
	end
end

function SkillCardMassRevealAnimationMixin:Layout()
	self.preExplosionRaysOuter1 = self:CreateTexture(nil, "BORDER")
	self.preExplosionRaysOuter1:SetPoint("CENTER", 128, 128)
	self.preExplosionRaysOuter1:SetTexture("spells\\shockwave_fullrays3")
	self.preExplosionRaysOuter1:SetSize(320, 320)
	self.preExplosionRaysOuter1:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Epic]:GetRGB())
	MixinAndLoadScripts(self.preExplosionRaysOuter1, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionRaysOuter1)

	self.preExplosionGlowOuter1 = self:CreateTexture(nil, "BORDER")
	self.preExplosionGlowOuter1:SetPoint("CENTER", 128, 128)
	self.preExplosionGlowOuter1:SetTexture("spells\\t_vfx_glow01")
	self.preExplosionGlowOuter1:SetSize(512, 512)
	self.preExplosionGlowOuter1:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Epic]:GetRGB())
	MixinAndLoadScripts(self.preExplosionGlowOuter1, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionGlowOuter1)

	self.preExplosionRaysOuter2 = self:CreateTexture(nil, "BORDER")
	self.preExplosionRaysOuter2:SetPoint("CENTER", -128, -64)
	self.preExplosionRaysOuter2:SetTexture("spells\\shockwave_fullrays3")
	self.preExplosionRaysOuter2:SetSize(320, 320)
	self.preExplosionRaysOuter2:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Uncommon]:GetRGB())
	MixinAndLoadScripts(self.preExplosionRaysOuter2, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionRaysOuter2)

	self.preExplosionGlowOuter2 = self:CreateTexture(nil, "BORDER")
	self.preExplosionGlowOuter2:SetPoint("CENTER", -128, -64)
	self.preExplosionGlowOuter2:SetTexture("spells\\t_vfx_glow01")
	self.preExplosionGlowOuter2:SetSize(512, 512)
	self.preExplosionGlowOuter2:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Uncommon]:GetRGB())
	MixinAndLoadScripts(self.preExplosionGlowOuter2, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionGlowOuter2)

	self.preExplosionRaysOuter3 = self:CreateTexture(nil, "BORDER")
	self.preExplosionRaysOuter3:SetPoint("CENTER", -192, 0)
	self.preExplosionRaysOuter3:SetTexture("spells\\shockwave_fullrays3")
	self.preExplosionRaysOuter3:SetSize(256, 256)
	self.preExplosionRaysOuter3:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Rare]:GetRGB())
	MixinAndLoadScripts(self.preExplosionRaysOuter3, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionRaysOuter3)

	self.preExplosionGlowOuter3 = self:CreateTexture(nil, "BORDER")
	self.preExplosionGlowOuter3:SetPoint("CENTER", -192, 0)
	self.preExplosionGlowOuter3:SetTexture("spells\\t_vfx_glow01")
	self.preExplosionGlowOuter3:SetSize(512, 512)
	self.preExplosionGlowOuter3:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Rare]:GetRGB())
	MixinAndLoadScripts(self.preExplosionGlowOuter3, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionGlowOuter3)

	self.preExplosionRaysOuter4 = self:CreateTexture(nil, "BORDER")
	self.preExplosionRaysOuter4:SetPoint("CENTER", 192, 0)
	self.preExplosionRaysOuter4:SetTexture("spells\\shockwave_fullrays3")
	self.preExplosionRaysOuter4:SetSize(256, 256)
	self.preExplosionRaysOuter4:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Epic]:GetRGB())
	MixinAndLoadScripts(self.preExplosionRaysOuter4, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionRaysOuter4)

	self.preExplosionGlowOuter4 = self:CreateTexture(nil, "BORDER")
	self.preExplosionGlowOuter4:SetPoint("CENTER", 192, 0)
	self.preExplosionGlowOuter4:SetTexture("spells\\t_vfx_glow01")
	self.preExplosionGlowOuter4:SetSize(512, 512)
	self.preExplosionGlowOuter4:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Epic]:GetRGB())
	MixinAndLoadScripts(self.preExplosionGlowOuter4, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionGlowOuter4)

	self.preExplosionRaysInner = self:CreateTexture(nil, "ARTWORK")
	self.preExplosionRaysInner:SetTexture("spells\\shockwave_fullrays4")
	self.preExplosionRaysInner:SetPoint("CENTER")
	self.preExplosionRaysInner:SetSize(328, 328)
	self.preExplosionRaysInner:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]:GetRGB())
	MixinAndLoadScripts(self.preExplosionRaysInner, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionRaysInner)

	self.preExplosionGlowInner = self:CreateTexture(nil, "ARTWORK")
	self.preExplosionGlowInner:SetPoint("CENTER", 0, 0)
	self.preExplosionGlowInner:SetTexture("spells\\t_vfx_glow01")
	self.preExplosionGlowInner:SetSize(512, 512)
	self.preExplosionGlowInner:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]:GetRGB())
	MixinAndLoadScripts(self.preExplosionGlowInner, SkillCardMassRevealGlowPreCastMixin)
	table.insert(self.AnimatedPreExposion, self.preExplosionGlowInner)

	self.explosionShine = self:CreateTexture(nil, "OVERLAY")
	self.explosionShine:SetSize(32, 32)
	self.explosionShine:SetTexture("SPELLS\\starburst_blue")
	self.explosionShine:SetPoint("CENTER")
	--self.shine:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.explosionShine:SetAlpha(0)
	self.explosionShine:SetBlendMode("ADD")

	self.explosionShine.AG = self.explosionShine:CreateAnimationGroup()

	self.explosionShine.AG.Scale = self.explosionShine.AG:CreateAnimation("SCALE")
	self.explosionShine.AG.Scale:SetDuration(0.15)
	self.explosionShine.AG.Scale:SetOrder(1)
	self.explosionShine.AG.Scale:SetSmoothing("IN_OUT")
	self.explosionShine.AG.Scale:SetScale(10, 10)

	self.explosionShine.AG.Alpha = self.explosionShine.AG:CreateAnimation("ALPHA")
	self.explosionShine.AG.Alpha:SetDuration(0.1)
	self.explosionShine.AG.Alpha:SetOrder(1)
	self.explosionShine.AG.Alpha:SetSmoothing("IN_OUT")
	self.explosionShine.AG.Alpha:SetChange(1)

	self.explosionShine.AG.Scale2 = self.explosionShine.AG:CreateAnimation("SCALE")
	self.explosionShine.AG.Scale2:SetDuration(self.animTime/8)
	self.explosionShine.AG.Scale2:SetOrder(2)
	self.explosionShine.AG.Scale2:SetSmoothing("OUT")
	self.explosionShine.AG.Scale2:SetScale(0.5, 0.5)

	self.explosionShine.AG.Alpha2 = self.explosionShine.AG:CreateAnimation("ALPHA")
	self.explosionShine.AG.Alpha2:SetDuration(self.animTime/8)
	self.explosionShine.AG.Alpha2:SetOrder(3)
	self.explosionShine.AG.Alpha2:SetSmoothing("OUT")
	self.explosionShine.AG.Alpha2:SetChange(-1)

	self.explosionShineColored = self:CreateTexture(nil, "ARTWORK")
	self.explosionShineColored:SetSize(116, 116)
	self.explosionShineColored:SetTexture("SPELLS\\glow_256")
	self.explosionShineColored:SetPoint("CENTER")
	--self.explosionShineColored:SetVertexColor(EnchantCollectionUtil.unknownEnchantColor:GetRGBA())
	self.explosionShineColored:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Epic]:GetRGB())
	self.explosionShineColored:SetAlpha(0)
	self.explosionShineColored:SetBlendMode("ADD")

	self.explosionShineColored.AG = self.explosionShineColored:CreateAnimationGroup()

	self.explosionShineColored.AG.Scale = self.explosionShineColored.AG:CreateAnimation("SCALE")
	self.explosionShineColored.AG.Scale:SetDuration(0.2)
	self.explosionShineColored.AG.Scale:SetOrder(1)
	self.explosionShineColored.AG.Scale:SetSmoothing("IN_OUT")
	self.explosionShineColored.AG.Scale:SetScale(10, 10)

	self.explosionShineColored.AG.Alpha = self.explosionShineColored.AG:CreateAnimation("ALPHA")
	self.explosionShineColored.AG.Alpha:SetDuration(0.1)
	self.explosionShineColored.AG.Alpha:SetOrder(1)
	self.explosionShineColored.AG.Alpha:SetSmoothing("IN_OUT")
	self.explosionShineColored.AG.Alpha:SetChange(1)

	self.explosionShineColored.AG.Scale2 = self.explosionShineColored.AG:CreateAnimation("SCALE")
	self.explosionShineColored.AG.Scale2:SetDuration(self.animTime/2)
	self.explosionShineColored.AG.Scale2:SetOrder(2)
	self.explosionShineColored.AG.Scale2:SetSmoothing("OUT")
	self.explosionShineColored.AG.Scale2:SetScale(0.5, 0.5)

	self.explosionShineColored.AG.Alpha2 = self.explosionShineColored.AG:CreateAnimation("ALPHA")
	self.explosionShineColored.AG.Alpha2:SetDuration(self.animTime/2)
	self.explosionShineColored.AG.Alpha2:SetOrder(3)
	self.explosionShineColored.AG.Alpha2:SetSmoothing("OUT")
	self.explosionShineColored.AG.Alpha2:SetChange(-1)

	self.explosionShineColored2 = self:CreateTexture(nil, "OVERLAY")
	self.explosionShineColored2:SetSize(64, 64)
	self.explosionShineColored2:SetTexture("SPELLS\\starburst_blue")
	self.explosionShineColored2:SetPoint("CENTER")
	self.explosionShineColored2:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Rare]:GetRGB())
	self.explosionShineColored2:SetAlpha(0)
	self.explosionShineColored2:SetBlendMode("ADD")

	self.explosionShineColored2.AG = self.explosionShineColored2:CreateAnimationGroup()

	self.explosionShineColored2.AG.Scale = self.explosionShineColored2.AG:CreateAnimation("SCALE")
	self.explosionShineColored2.AG.Scale:SetDuration(0.15)
	self.explosionShineColored2.AG.Scale:SetOrder(1)
	self.explosionShineColored2.AG.Scale:SetSmoothing("IN_OUT")
	self.explosionShineColored2.AG.Scale:SetScale(10, 10)

	self.explosionShineColored2.AG.Alpha = self.explosionShineColored2.AG:CreateAnimation("ALPHA")
	self.explosionShineColored2.AG.Alpha:SetDuration(0.1)
	self.explosionShineColored2.AG.Alpha:SetOrder(1)
	self.explosionShineColored2.AG.Alpha:SetSmoothing("IN_OUT")
	self.explosionShineColored2.AG.Alpha:SetChange(1)

	self.explosionShineColored2.AG.Scale2 = self.explosionShineColored2.AG:CreateAnimation("SCALE")
	self.explosionShineColored2.AG.Scale2:SetDuration(self.animTime/4)
	self.explosionShineColored2.AG.Scale2:SetOrder(2)
	self.explosionShineColored2.AG.Scale2:SetSmoothing("OUT")
	self.explosionShineColored2.AG.Scale2:SetScale(0.5, 0.5)

	self.explosionShineColored2.AG.Alpha2 = self.explosionShineColored2.AG:CreateAnimation("ALPHA")
	self.explosionShineColored2.AG.Alpha2:SetDuration(self.animTime/4)
	self.explosionShineColored2.AG.Alpha2:SetOrder(3)
	self.explosionShineColored2.AG.Alpha2:SetSmoothing("OUT")
	self.explosionShineColored2.AG.Alpha2:SetChange(-1)

	self.explosionShockWave = self:CreateTexture(nil, "OVERLAY")
	self.explosionShockWave:SetSize(600, 600)
	self.explosionShockWave:SetTexture("SPELLS\\7fx_alphamask_shockwavesoft_contrast_256")
	self.explosionShockWave:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]:GetRGB())
	self.explosionShockWave:SetAlpha(0)
	self.explosionShockWave:SetPoint("CENTER")
	self.explosionShockWave:SetBlendMode("ADD")

	self.explosionShockWave.AnimSplash = self.explosionShockWave:CreateAnimationGroup()

	self.explosionShockWave.AnimSplash.Alpha = self.explosionShockWave.AnimSplash:CreateAnimation("Alpha")
	self.explosionShockWave.AnimSplash.Alpha:SetDuration(0.2)
	self.explosionShockWave.AnimSplash.Alpha:SetOrder(1)
	self.explosionShockWave.AnimSplash.Alpha:SetEndDelay(0)
	self.explosionShockWave.AnimSplash.Alpha:SetSmoothing("IN")
	self.explosionShockWave.AnimSplash.Alpha:SetChange(1)

	self.explosionShockWave.AnimSplash.Rotation = self.explosionShockWave.AnimSplash:CreateAnimation("ROTATION")
	self.explosionShockWave.AnimSplash.Rotation:SetOrder(1)
	self.explosionShockWave.AnimSplash.Rotation:SetDegrees(-180)

	self.explosionShockWave.AnimSplash.Scale2 = self.explosionShockWave.AnimSplash:CreateAnimation("Scale")
	self.explosionShockWave.AnimSplash.Scale2:SetScale(2, 2)
	self.explosionShockWave.AnimSplash.Scale2:SetDuration(self.animTime)
	self.explosionShockWave.AnimSplash.Scale2:SetOrder(2)
	self.explosionShockWave.AnimSplash.Scale2:SetSmoothing("OUT")

	self.explosionShockWave.AnimSplash.Rotation2 = self.explosionShockWave.AnimSplash:CreateAnimation("ROTATION")
	self.explosionShockWave.AnimSplash.Rotation2:SetDuration(self.animTime)
	self.explosionShockWave.AnimSplash.Rotation2:SetOrder(2)
	self.explosionShockWave.AnimSplash.Rotation2:SetDegrees(-90)

	self.explosionShockWave.AnimSplash.Alpha2 = self.explosionShockWave.AnimSplash:CreateAnimation("Alpha")
	self.explosionShockWave.AnimSplash.Alpha2:SetDuration(self.animTime)
	self.explosionShockWave.AnimSplash.Alpha2:SetOrder(2)
	self.explosionShockWave.AnimSplash.Alpha2:SetEndDelay(0)
	self.explosionShockWave.AnimSplash.Alpha2:SetSmoothing("OUT")
	self.explosionShockWave.AnimSplash.Alpha2:SetChange(-1)

	self.explosionShockWave2 = self:CreateTexture(nil, "OVERLAY")
	self.explosionShockWave2:SetSize(400, 400)
	self.explosionShockWave2:SetTexture("SPELLS\\7fx_alphamask_shockwaveshadow_ba")
	self.explosionShockWave2:SetVertexColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Rare]:GetRGB())
	self.explosionShockWave2:SetAlpha(0)
	self.explosionShockWave2:SetPoint("CENTER")
	self.explosionShockWave2:SetBlendMode("ADD")

	self.explosionShockWave2.AnimSplash = self.explosionShockWave2:CreateAnimationGroup()

	self.explosionShockWave2.AnimSplash.Alpha = self.explosionShockWave2.AnimSplash:CreateAnimation("Alpha")
	self.explosionShockWave2.AnimSplash.Alpha:SetDuration(0.2)
	self.explosionShockWave2.AnimSplash.Alpha:SetOrder(1)
	self.explosionShockWave2.AnimSplash.Alpha:SetEndDelay(0)
	self.explosionShockWave2.AnimSplash.Alpha:SetSmoothing("IN")
	self.explosionShockWave2.AnimSplash.Alpha:SetChange(1)

	self.explosionShockWave2.AnimSplash.Scale2 = self.explosionShockWave2.AnimSplash:CreateAnimation("Scale")
	self.explosionShockWave2.AnimSplash.Scale2:SetScale(2, 2)
	self.explosionShockWave2.AnimSplash.Scale2:SetDuration(2)
	self.explosionShockWave2.AnimSplash.Scale2:SetOrder(2)
	self.explosionShockWave2.AnimSplash.Scale2:SetSmoothing("OUT")

	self.explosionShockWave2.AnimSplash.Rotation = self.explosionShockWave2.AnimSplash:CreateAnimation("ROTATION")
	self.explosionShockWave2.AnimSplash.Rotation:SetDuration(2)
	self.explosionShockWave2.AnimSplash.Rotation:SetOrder(2)
	self.explosionShockWave2.AnimSplash.Rotation:SetDegrees(-90)

	self.explosionShockWave2.AnimSplash.Alpha2 = self.explosionShockWave2.AnimSplash:CreateAnimation("Alpha")
	self.explosionShockWave2.AnimSplash.Alpha2:SetDuration(2)
	self.explosionShockWave2.AnimSplash.Alpha2:SetOrder(2)
	self.explosionShockWave2.AnimSplash.Alpha2:SetEndDelay(0)
	self.explosionShockWave2.AnimSplash.Alpha2:SetSmoothing("OUT")
	self.explosionShockWave2.AnimSplash.Alpha2:SetChange(-1)
end

function SkillCardMassRevealAnimationMixin:AquireCards()
	for i = 1, 17 do
		local card = self:CreateTexture(nil, "BACKGROUND")
		MixinAndLoadScripts(card, SkillCardCoverMassRevealAnimationMixin)
		table.insert(self.AnimatedCards, card)
	end

	-- first "layer" of cards
	for i = 1, 10 do
		local scaleModifier = math.random(8, 9)/10
		self.AnimatedCards[i]:SetSize(256*scaleModifier, 256*scaleModifier)

		local angle = math.random(-20, 20)
		self.AnimatedCards[i].AnimationGroupAppear.Rotation:SetDegrees(angle)
		self.AnimatedCards[i].AnimationGroupFadeOut.Rotation:SetDegrees(angle)
	end

	-- properly place cards for a good looking animation
	self.AnimatedCards[1].AnimationGroupAppear.FadeOutStart:SetEndDelay(0)
	self.AnimatedCards[1]:SetPoint("CENTER", -256, 64)
	self.AnimatedCards[2].AnimationGroupAppear.FadeOutStart:SetEndDelay(0.4)
	self.AnimatedCards[2]:SetPoint("CENTER", -128, 128)
	self.AnimatedCards[3].AnimationGroupAppear.FadeOutStart:SetEndDelay(0.2)
	self.AnimatedCards[3]:SetPoint("CENTER", 0, 128)
	self.AnimatedCards[4].AnimationGroupAppear.FadeOutStart:SetEndDelay(0.3)
	self.AnimatedCards[4]:SetPoint("CENTER", 128, 128)
	self.AnimatedCards[5].AnimationGroupAppear.FadeOutStart:SetEndDelay(0.4)
	self.AnimatedCards[5]:SetPoint("CENTER", 256, 64)
	self.AnimatedCards[6].AnimationGroupAppear.FadeOutStart:SetEndDelay(0)
	self.AnimatedCards[6]:SetPoint("CENTER", -256, -64)
	self.AnimatedCards[7].AnimationGroupAppear.FadeOutStart:SetEndDelay(0.1)
	self.AnimatedCards[7]:SetPoint("CENTER", -128, -128)
	self.AnimatedCards[8].AnimationGroupAppear.FadeOutStart:SetEndDelay(0.2)
	self.AnimatedCards[8]:SetPoint("CENTER", 0, -128)
	self.AnimatedCards[9].AnimationGroupAppear.FadeOutStart:SetEndDelay(0.1)
	self.AnimatedCards[9]:SetPoint("CENTER", 128, -128)
	self.AnimatedCards[10].AnimationGroupAppear.FadeOutStart:SetEndDelay(0.2)
	self.AnimatedCards[10]:SetPoint("CENTER", 256, -64)

	-- second "layer" of cards
	for i = 11, 16 do
		local scaleModifier = math.random(8, 10)/10
		self.AnimatedCards[i]:SetSize(256*scaleModifier, 256*scaleModifier)
		self.AnimatedCards[i]:SetDrawLayer("ARTWORK")
		self.AnimatedCards[i].AnimationGroupAppear.FadeOutStart:SetEndDelay(math.random(4, 8)/10)
		local angle = math.random(-15, 15)
		self.AnimatedCards[i].AnimationGroupAppear.Rotation:SetDegrees(angle)
		self.AnimatedCards[i].AnimationGroupFadeOut.Rotation:SetDegrees(angle)
	end

	self.AnimatedCards[11]:SetPoint("CENTER", -192, 0)
	self.AnimatedCards[12]:SetPoint("CENTER", -64, 64)
	self.AnimatedCards[13]:SetPoint("CENTER", 64, 64)
	self.AnimatedCards[14]:SetPoint("CENTER", 196, 0)
	self.AnimatedCards[15]:SetPoint("CENTER", -64, -64)
	self.AnimatedCards[16]:SetPoint("CENTER", 64, -64)

	-- 3rd "layer"
	self.AnimatedCards[17]:SetDrawLayer("OVERLAY")
	self.AnimatedCards[17].AnimationGroupAppear.FadeOutStart:SetEndDelay(1)
	self.AnimatedCards[17].AnimationGroupAppear.Rotation:SetDegrees(5)
	self.AnimatedCards[17].AnimationGroupFadeOut.Rotation:SetDegrees(5)
	self.AnimatedCards[17]:SetPoint("CENTER", 0, 0)
	self.AnimatedCards[17].AnimationGroupFadeOut.MoveOut:SetOffset(64, 196)
	self.AnimatedCards[17].AnimationGroupAppear.FadeIn:SetEndDelay(0.8)

	-- nice looking "explosion"
	for i = 1, 16 do
		local _, _, _, xOffset, yOffset = self.AnimatedCards[i]:GetPoint()
		self.AnimatedCards[i].AnimationGroupFadeOut.MoveOut:SetOffset(2*xOffset, 2*yOffset)
		self.AnimatedCards[i].AnimationGroupFadeOut.MoveOut:SetDuration(math.random(3, 8)/10)
	end
end