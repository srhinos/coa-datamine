-------------------------------------------------------------------------------
--                        Wildcard Dice Visuals Presenter                    --
-------------------------------------------------------------------------------
WildCardDiceVisuals = {}

WildCardDiceVisuals.color = CreateColorFromCode("|cff01b2ff")
WildCardDiceVisuals.explosionDelay = 0.0

WildCardDiceVisuals.qualitySounds = {
	[0] = SOUNDKIT.COMMON_UI_MISSION_SELECT,
	[1] = SOUNDKIT.COMMON_UI_MISSION_SELECT,
	[2] = SOUNDKIT.RARE_UI_ORDERHALL_TALENT_READY_TOAST,
	[3] = SOUNDKIT.RARE_UI_ORDERHALL_TALENT_READY_TOAST,
	[4] = SOUNDKIT.EPIC_UI_MISSION_200PERCENT,
	[5] = SOUNDKIT.LEGENDARY_UI_LEGENDARY_ITEM_TOAST,
}

function WildCardDiceVisuals:Initialize(diceFrame)
	self.frame = diceFrame
	self.flipBooks = {
		diceFrame.DiceAppearFlipBook,
		diceFrame.DiceCrackFlipBook,
		diceFrame.DiceCollapseFlipBook,
		diceFrame.DiceRollFlipBook
	}
end

function WildCardDiceVisuals:ResetVisual()
	if not self.frame.Hover:IsPlaying() then
		self.frame.Hover:Play()
	end

	self.frame.HintFrame:SetAlpha(0)
	self.frame.HintFrame:Hide()

	self:StopShockWave()
	self:StopExplosion()
	
	self.frame.GlowFrame.Energy.Grow:Stop()
	self.frame.GlowFrame.Energy.Exit:Stop()
end

function WildCardDiceVisuals:HideFlipBooks()
	for _, flipbook in pairs(self.flipBooks) do
		if flipbook then
			flipbook:Stop()
			flipbook:Hide()
		end
	end
end

function WildCardDiceVisuals:PlayFlipBook(flipBookName)
	-- Check for interruptions of crack, collapse, or roll
	for _, name in ipairs({ "DiceCrackFlipBook", "DiceCollapseFlipBook", "DiceRollFlipBook" }) do
		local fb = self.frame[name]
		if fb and name ~= flipBookName and fb:IsPlaying() then
			dprint(string.format("[WILDCARD VISUALS] Interrupted animation: %s while playing %s", name, flipBookName))
		end
	end

	self:HideFlipBooks()
	self.frame:UnregisterOnClick()
	
	local fb = self.frame[flipBookName]
	if fb then
		fb:Play()
	end
end

function WildCardDiceVisuals:PlayQualitySound(quality)
	local soundKitId = self.qualitySounds[quality or 0] or self.qualitySounds[0]
	PlaySound(soundKitId)
end

function WildCardDiceVisuals:ReleaseSparkles()
	self.frame.sparklePool:ReleaseAll()
end

function WildCardDiceVisuals:AcquireSparkles(color)
	self:ReleaseSparkles()

	color = color or self.color

	for i = 1, 16 do
		local size = math.random(8, 46)
		local sparkle = self.frame.sparklePool:Acquire()
		if sparkle then
			sparkle:SetSize(size, size)
			sparkle.Anim:SetTranslationRange(-96, 96, -96, 96)
			sparkle:SetParent(self.frame.GlowFrame)
			sparkle:ClearAndSetPoint("CENTER", math.sin(i) * 8, math.cos(i) * 8)
			sparkle.Anim:SetLifetimeRange(6, 16)
			sparkle:SetVertexColor(color:GetRGBA())
			sparkle:Show()
			sparkle.Anim:Refresh()
		end
	end
end

function WildCardDiceVisuals:SetSparklesQualityColor(color)
	color = color or self.color

	for sparkle in self.frame.sparklePool:EnumerateActive() do
		sparkle:SetVertexColor(color:GetRGBA())
	end
end

function WildCardDiceVisuals:PlayExplosion()
	self.frame.ExplosionShockWave.AnimSplash:Play()
	self.frame.ExplosionTexture2.AG:Play()
	self.frame.ExplosionGlow.AG:Play()
	self.frame.ExplosionTexture.AG:Play()
end

function WildCardDiceVisuals:StopExplosion()
	self.frame.ExplosionShockWave.AnimSplash:Stop()
	self.frame.ExplosionTexture2.AG:Stop()
	self.frame.ExplosionGlow.AG:Stop()
	self.frame.ExplosionTexture.AG:Stop()
end

function WildCardDiceVisuals:PlayShockWave()
	self.frame.PreCastShockWave.AnimSplash:Play()
	self.frame.PreCastGlow.AnimSplash:Play()
end

function WildCardDiceVisuals:StopShockWave()
	self.frame.PreCastShockWave.AnimSplash:Stop()
	self.frame.PreCastGlow.AnimSplash:Stop()
end

function WildCardDiceVisuals:SetQuality(quality)
	self:PlayQualitySound(quality)

	if quality and (quality > 1) then
		local color = ITEM_QUALITY_COLORS[quality]
		self.frame.GlowFrame.GlowTex:SetVertexColor(color:GetRGB())

		self.frame.ExplosionShockWave:SetVertexColor(color:GetRGB())
		self.frame.ExplosionTexture2:SetVertexColor(color:GetRGB())
		self.frame.ExplosionGlow:SetVertexColor(color:GetRGB())

		self.frame.QualityGlowFrame:SetQuality(quality) 
		BaseFrameFadeIn(self.frame.QualityGlowFrame)
	else
		self.frame.GlowFrame.GlowTex:SetVertexColor(self.color:GetRGB())
		self.frame.QualityGlowFrame:Hide()
		quality = nil
	end

	if self.lastQuality ~= quality then
		if quality then
			self:SetSparklesQualityColor(ITEM_QUALITY_COLORS[quality])
		else
			self:SetSparklesQualityColor()
		end
	end

	self.lastQuality = quality
end

function WildCardDiceVisuals:PlayAppear()
	self:ResetVisual()
	BaseFrameFadeIn(self.frame)
end

function WildCardDiceVisuals:ShowHint()
	BaseFrameFadeIn(self.frame.HintFrame)
end

function WildCardDiceVisuals:PlayReveal(data)
	-- Start roulette/rolling animations
	self.frame.ScrollFrame:RandomizeIcons()
	self.frame.ScrollFrame:UpdateInternalIDs()
	self.frame.ScrollFrame:Play(self.frame:GetSoFRoll())
end

function WildCardDiceVisuals:ShowDecision(data)
	-- Render details for revealed ability or spell
	local internalID, rank = data[1], data[2]
	self.frame:ShowNameFrame(internalID, rank)
end
