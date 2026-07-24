local DEFAULT_REQUIRED_LEVEL = 1
CARD_SLOT_IS_LOCKED = CARD_SLOT_IS_LOCKED or "Card used"
SKILLCARD_AVAILABLE = SKILLCARD_AVAILABLE or "SKILLCARD_AVAILABLE"
-------------------------------------------------------------------------------
--                                Actual card                                --
-------------------------------------------------------------------------------
SkillCardKnownCardMixin = CreateFromMixins(CallbackRegistryMixin)

function SkillCardKnownCardMixin:OnLoad()
	self:Layout()

	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({
		"OnRankChange",
		"OnRankChangeFinished"
	})

	self.IconFrame.RankFrame:RegisterCallback("OnRankChangeFinished", function() self:TriggerEvent("OnRankChangeFinished") end, self)
	self.IconFrame.RankFrame:RegisterCallback("OnRankChange", self.OnRankChange, self)

	self:RegisterForDrag("LeftButton")
end

function SkillCardKnownCardMixin:OnDragStart()
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

function SkillCardKnownCardMixin:OnEnter()
	local spellID = self:GetSpellID()

	if (spellID) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, -self:GetHeight()/2)
		GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(spellID))

		if (IsGMClient) or (PTR_CLIENT) then
			GameTooltip:AddLine("CardID: "..self:GetParent():GetCardID())
		end

		GameTooltip:Show()
	end

	self.IconFrame.Highlight:Show()
end

function SkillCardKnownCardMixin:OnLeave()
	GameTooltip:Hide()
	self.IconFrame.Highlight:Hide()
end

function SkillCardKnownCardMixin:OnRankChange(oldRank, nextRank)
	self:TriggerEvent("OnRankChange", oldRank, nextRank)
end

-- overwrite
function SkillCardKnownCardMixin:GetBorderAtlas()
	return "SkillCardNormalQuality"
end

-- overwrite
function SkillCardKnownCardMixin:GetBorderGoldenAtlas()
	return "SkillCardGoldQuality"
end

function SkillCardKnownCardMixin:GetSpellID()
	return self:GetParent():GetSpellID() or 1
end

function SkillCardKnownCardMixin:IsGolden()
	return self:GetParent():IsGolden()
end

function SkillCardKnownCardMixin:GetQuality()
	return self:GetParent():GetQuality() or 1
end

function SkillCardKnownCardMixin:GetRequiredLevel()
	return self:GetParent():GetRequiredLevel() or DEFAULT_REQUIRED_LEVEL
end

function SkillCardKnownCardMixin:ShouldShowAvailableLevelText()
	return false
end

function SkillCardKnownCardMixin:GetReplace()
	return self:GetParent():GetReplace()
end

function SkillCardKnownCardMixin:GetPreloaded()
	return self:GetParent():GetPreloaded()
end

function SkillCardKnownCardMixin:GetTalentRank()
	return self:GetParent():GetTalentRank()
end

function SkillCardKnownCardMixin:GetMaxRank()
	return self:GetParent():GetMaxRank() or 1
end

function SkillCardKnownCardMixin:SetRank(value)
	if (value) then
		self.IconFrame.RankFrame:Hide()
		self.IconFrame.RankFrame:SetRank(value)
		self.IconFrame.RankFrame:SetMaxRank(self:GetMaxRank())
		self.IconFrame.RankFrame:UpdateVisual()
	else
		self.IconFrame.RankFrame:Hide()
	end
end

function SkillCardKnownCardMixin:SetNextRank(value)
	self.IconFrame.RankFrame:SetNextRank(value)
end

function SkillCardKnownCardMixin:GetNextRank()
	return self.IconFrame.RankFrame:GetNextRank()
end

function SkillCardKnownCardMixin:PlayRankChange()
	self.IconFrame.RankFrame:PlayAnim()
end

function SkillCardKnownCardMixin:IsRankUpdatePlaying()
	return self.IconFrame.RankFrame.Reveal:IsPlaying()
end

function SkillCardKnownCardMixin:UpdateVisual()
	local spellID = self:GetSpellID()
	local quality = self:GetQuality()
	local r, g, b, hex = GetItemQualityColor(quality)
	local requiredLevel = self:GetRequiredLevel()
	local talentRank = self:GetTalentRank()
	local name, _, icon = GetSpellInfo(spellID)

	self.IconFrame.Border:SetVertexColor(r, g, b)
	self.IconFrame.BorderAdd:SetVertexColor(r, g, b)

	local borderAtlasPrefix
	if self:IsGolden() then
		borderAtlasPrefix = self:GetBorderGoldenAtlas()
	else
		borderAtlasPrefix = self:GetBorderAtlas()
	end

	local borderAtlas = borderAtlasPrefix..quality
	if not AtlasUtil:AtlasExists(borderAtlas) then
		borderAtlas = borderAtlasPrefix..Enum.ItemQuality.Legendary
	end
	self.CardBorder:SetAtlas(borderAtlas)

	if self:ShouldShowAvailableLevelText() and UnitLevel("player") >= requiredLevel then
		self.Level:SetText(SKILLCARD_AVAILABLE)
	else
		self.Level:SetText(string.format(SKILLCARD_UNLOCK_MSG, requiredLevel))
	end
	self.IconFrame.Icon:SetTexture(icon)
	self.NameFrame.Name:SetText(name)

	if self:GetPreloaded() or self:GetReplace() then
		self.Level:Hide()
	else
		self.Level:Show()
	end

	self:SetRank(talentRank)

	self.ShinyGlow:UpdateVisual()

	if self:IsMouseOver() then
		self:OnEnter()
	end
end

function SkillCardKnownCardMixin:OnUpdateAnim()
	local scaleTimer = -0.15
	local alphaTimer = 0.05

	local alpha = self:GetAlpha()
	local scale = self:GetScale()
	local done = false

	if not(math.NearlyEquals(scale, 1, 0.01)) then
		self:SetScale(scale + (scale - 1)*scaleTimer)
	else
		done = true
	end

	if not(math.NearlyEquals(alpha, 1, 0.01)) then
		self:SetAlpha(alpha + math.abs(alpha - 1)*alphaTimer)
	elseif (done) then
		done = true
	end

	if done then
		self:StopAppear()
	end
end

function SkillCardKnownCardMixin:PlayAppear()
	self.ShinyGlow.AG:Play()

	self:SetScale(3)
	self:SetAlpha(0)
	self:SetScript("OnUpdate", self.OnUpdateAnim)
end

function SkillCardKnownCardMixin:StopAppear()
	self:SetScript("OnUpdate", nil)
	self:SetScale(1)
	self:SetAlpha(1)
end

function SkillCardKnownCardMixin:Layout()
	self.RemoveButton = CreateFrame("BUTTON", "$parent.RemoveButton", self, "UIPanelCloseButton")
	self.RemoveButton:SetPoint("TOPRIGHT", -11, -9) 

	self.CardBorder = self:CreateTexture(nil, "BORDER")
	self.CardBorder:SetSize(161, 213)
	self.CardBorder:SetPoint("CENTER", 0, 3)

	self.IconFrame = CreateFrame("FRAME", "$parent.IconFrame", self)
	self.IconFrame:SetSize(48,48)
	self.IconFrame:SetPoint("TOP", 0, -36)

	self.IconFrame.Icon = self.IconFrame:CreateTexture(nil, "ARTWORK")
	self.IconFrame.Icon:SetSize(48, 48)
	self.IconFrame.Icon:SetPoint("CENTER")

	self.IconFrame.Border = self.IconFrame:CreateTexture(nil, "BACKGROUND")
	self.IconFrame.Border:SetSize(80, 80)
	self.IconFrame.Border:SetTexture("Interface\\BUTTONS\\UI-EmptySlot-White")
	self.IconFrame.Border:SetPoint("CENTER")

	self.IconFrame.BorderAdd = self.IconFrame:CreateTexture(nil, "BORDER")
	self.IconFrame.BorderAdd:SetSize(80, 80)
	self.IconFrame.BorderAdd:SetTexture("Interface\\BUTTONS\\UI-EmptySlot-White")
	self.IconFrame.BorderAdd:SetPoint("CENTER")
	self.IconFrame.BorderAdd:SetBlendMode("ADD")

	self.IconFrame.Highlight = self.IconFrame:CreateTexture(nil, "OVERLAY")
	self.IconFrame.Highlight:SetSize(48, 48)
	self.IconFrame.Highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	self.IconFrame.Highlight:SetPoint("CENTER")
	self.IconFrame.Highlight:SetBlendMode("ADD")
	self.IconFrame.Highlight:Hide()

	self.IconFrame.RankFrame = CreateFrame("FRAME", "$parent.RankFrame", self.IconFrame, "AnimatedRankTemplate")
	self.IconFrame.RankFrame:SetPoint("CENTER", self.IconFrame, "BOTTOMRIGHT", -5, 3)
	self.IconFrame.RankFrame:Hide()

	self.NameFrame = CreateFrame("FRAME", "$parent.NameFrame", self, nil)
	self.NameFrame:SetPoint("TOP", self.IconFrame, "BOTTOM", 0, 0)
	MixinAndLoadScripts(self.NameFrame, SkillCardNameFrameMixin)

	self.Level = self:CreateFontString(nil, "OVERLAY")
	self.Level:SetFontObject(GameFontNormalLarge)
	self.Level:SetPoint("TOP", self.NameFrame, "BOTTOM",  0, 8)
	self.Level:SetJustifyH("CENTER")
	self.Level:SetJustifyV("TOP")
	self.Level:SetWidth(self:GetWidth()-48)

	self.ShinyGlow = CreateFrame("FRAME", "$parent.BackgroundFrame", self)
	self.ShinyGlow:SetPoint("TOPLEFT")
	self.ShinyGlow:SetPoint("BOTTOMRIGHT")
	self.ShinyGlow:SetAlpha(0)
	self.ShinyGlow:SetFrameLevel(self.IconFrame:GetFrameLevel()+1)
	MixinAndLoadScripts(self.ShinyGlow, SkillCardShinyGlowMixin)

    self.ShinyGlow.AG = self.ShinyGlow:CreateAnimationGroup()

    self.ShinyGlow.AG.Alpha0 = self.ShinyGlow.AG:CreateAnimation("Alpha")
    self.ShinyGlow.AG.Alpha0:SetChange(1)
    self.ShinyGlow.AG.Alpha0:SetDuration(0.1)
    self.ShinyGlow.AG.Alpha0:SetOrder(1)
    self.ShinyGlow.AG.Alpha0:SetEndDelay(0.5)

    self.ShinyGlow.AG.Alpha1 = self.ShinyGlow.AG:CreateAnimation("Alpha")
    self.ShinyGlow.AG.Alpha1:SetChange(-1)
    self.ShinyGlow.AG.Alpha1:SetDuration(1)
    self.ShinyGlow.AG.Alpha1:SetOrder(2)
    self.ShinyGlow.AG.Alpha1:SetSmoothing("IN_OUT")
end

-------------------------------------------------------------------------------
--                                Card + Slot                                --
-------------------------------------------------------------------------------
SkillCardMixin = CreateFromMixins(CallbackRegistryMixin)

function SkillCardMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:Layout()

	self:GenerateCallbackEvents({
		"OnCardActivated",
		"OnCardDeactivated",
	})

	self.Shine.OkButton:SetScript("OnClick", function() self:TriggerEvent("OnCardActivated", self.index, self:IsGolden()) end)
	self.KnownCard.RemoveButton:SetScript("OnClick", function() self:TriggerEvent("OnCardDeactivated", self.index, self:IsGolden()) end)

	self.KnownCard:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.KnownCard:SetScript("OnClick", function(_, button)
		if button == "RightButton" then
			self:TriggerEvent("OnCardDeactivated", self.index, self:IsGolden())
		else
			if self:GetReplace() then
				self:TriggerEvent("OnCardActivated", self.index, self:IsGolden())
			end
		end
	end)

	self:RegisterForDrag("LeftButton")
	self:SetScript("OnReceiveDrag", function() self:OnReceiveDrag() end)

	self.KnownCard:RegisterForDrag("LeftButton")
	self.KnownCard:SetScript("OnReceiveDrag", function() self:OnReceiveDrag() end)
end

function SkillCardMixin:OnReceiveDrag()
	if SkillCardUtil.DraggedCardID then
		local cardID = SkillCardUtil.DraggedCardID
		local rank = SkillCardUtil.DraggedCardRank or 1
		SkillCardUtil.DraggedCardID = nil
		SkillCardUtil.DraggedCardRank = nil
		ClearCursor()

		local cardData = SkillCardUtil.GetSkillCardInfo(cardID, rank)
		if not cardData then return end

		local isGolden = SkillCardUtil.IsCardTypeGolden(cardData.Type)
		if isGolden ~= self:IsGolden() then
			SkillCardUtil.HandleError("You cannot slot a " .. (isGolden and "golden" or "normal") .. " card into a " .. (self:IsGolden() and "golden" or "normal") .. " slot!")
			return
		end

		if self:IsBlocked() then
			SkillCardUtil.HandleError("This slot is locked!")
			return
		end

		local tab = self:GetParent()
		local isAlreadySlotted = false
		local maxNormal = tab:GetMaxNormalCards()
		local maxGolden = tab:GetMaxGoldenCards()

		for i = 1, maxNormal do
			local existing = tab:GetCardInfoNormalAtIndex(i)
			if existing and existing.SpellID == cardData.SpellID and (isGolden or i ~= self.index) then
				isAlreadySlotted = true
				break
			end
		end
		if not isAlreadySlotted then
			for i = 1, maxGolden do
				local existing = tab:GetCardInfoGoldenAtIndex(i)
				if existing and existing.SpellID == cardData.SpellID and (not isGolden or i ~= self.index) then
					isAlreadySlotted = true
					break
				end
			end
		end

		if isAlreadySlotted and not tab:IsStarterSkillCardSlotType() then
			SkillCardUtil.HandleError(SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED)
			return
		end

		local cardType = self:IsGolden() and tab.cardTypeGolden or tab.cardTypeNormal
		SkillCardUtil.SetCardAtIndex(cardType, self.index, cardID)
	end
end

function SkillCardMixin:Init(index, atlasNormal, atlasGolden)
	self.index = index

	self.KnownCard.GetBorderAtlas = function() return atlasNormal end
	self.KnownCard.GetBorderGoldenAtlas = function() return atlasGolden end
end

function SkillCardMixin:SetCard(cardData, isPreloaded, replaceCardID, isActive, displayedRank, isBlocked)
	self:ResetVisual()
	self:SetBlocked(isBlocked)

	-- if no cardData, but cardID found
	if cardData and (type(cardData) == "number") then
		cardData = SkillCardUtil.GetSkillCardInfo(cardData)
	end

	if self:IsGolden() then
		self.Slot:SetTexture("Interface\\Draft\\skillcardslotGolden")
	else
		self.Slot:SetTexture("Interface\\Draft\\skillcardslot")
	end

	if isBlocked then
		self.KnownOverlay.Text:SetText(CARD_SLOT_IS_LOCKED)
		self.KnownOverlay.CheckedTexture:Show()
		self.KnownOverlay:Show()
	end

	if not(cardData) or not(next(cardData)) then
		self.KnownCard:Hide()
		self.Shine:Hide()
		return
	end

	local entry = C_CharacterAdvancement.GetEntryBySpellID(cardData.SpellID)
	local isTalent = SkillCardUtil.IsCardTypeTalent(cardData.Type)
	displayedRank = displayedRank or (isPreloaded and cardData.CollectedRank or cardData.Rank)
	local quality = C_SkillCard.GetSkillCardQuality(cardData.CardID, displayedRank) or cardData.Quality

	-- refresh card data with proper card rank, may be needed when preloading/just activating card
	cardData = SkillCardUtil.GetSkillCardInfo(cardData.CardID, displayedRank)
	
	self:SetMaxRank(cardData.MaxRank)
	self:SetTalentRank(isTalent and displayedRank)
	self:SetCardID(cardData.CardID)
	self:SetSpellID(cardData.SpellID)
	self:SetQuality(Enum.SkillCardQuality[quality])
	self:SetRequiredLevel(entry and entry.RequiredLevel or DEFAULT_REQUIRED_LEVEL)
	self:SetReplace(replaceCardID)
	self:SetPreloaded(isPreloaded)
	self:SetActive(isActive)

	self:UpdateVisual()
end

function SkillCardMixin:ResetVisual()
	self.KnownCard.ShinyGlow.AG:Stop()
	self.KnownCard:StopAppear()
	self.KnownOverlay.CheckedTexture:Show()
	self.KnownOverlay:Hide()
	self:SetReplace(false)
	self:SetBlocked(false)
end

function SkillCardMixin:UpdateVisual()
	local name = GetSpellInfo(self:GetSpellID())
	local isRequiredLevelLocked = UnitLevel("player") < self:GetRequiredLevel()

	local showOverlay = false
	if self:IsBlocked() then
		self.KnownOverlay.Text:SetText(CARD_SLOT_IS_LOCKED)
		self.KnownOverlay.CheckedTexture:Show()
		showOverlay = true
	elseif not isRequiredLevelLocked then
		self.KnownOverlay.Text:SetText(string.format(UNLOCKED, (name or self:GetSpellID())))
		self.KnownOverlay.CheckedTexture:Show()
	end

	self.KnownCard:UpdateVisual()
	self.Shine:UpdateVisual()

	if (self:GetPreloaded() or self:GetReplace()) then
		self.KnownCard:SetAlpha(0.3)
		BaseFrameFadeIn(self.Shine)
	else
		if (self.Shine:IsVisible()) then
			BaseFrameFadeOut(self.Shine)
		end
		self.KnownCard:SetAlpha(1)
		if showOverlay then
			self.KnownOverlay:Show()
		end
	end

	self.KnownCard:Show()
end

function SkillCardMixin:ActivateCard(cardID, cardData)
	cardData = cardData or SkillCardUtil.GetSkillCardInfo(cardID)
	if not cardData then
		return
	end

	self:SetCard(cardData, false, false, true, cardData.CollectedRank)
	self.KnownCard:PlayAppear()
	PlaySound(SOUNDKITEXTRA.SKILL_CARD_ACTIVATE)
end

function SkillCardMixin:SetTalentRank(rank)
	self.talentRank = rank
end

function SkillCardMixin:GetTalentRank()
	return self.talentRank
end

function SkillCardMixin:SetMaxRank(rank)
	self.maxRank = rank
end

function SkillCardMixin:GetMaxRank()
	return self.maxRank
end

function SkillCardMixin:SetRequiredLevel(level)
	self.requiredLevel = level or DEFAULT_REQUIRED_LEVEL
end

function SkillCardMixin:SetActive(isActive)
	self.isActive = isActive
end

function SkillCardMixin:IsActive()
	return self.isActive
end

function SkillCardMixin:SetBlocked(isBlocked)
	self.isBlocked = isBlocked
end

function SkillCardMixin:IsBlocked()
	return self.isBlocked
end

function SkillCardMixin:SetPreloaded(preloaded)
	self.preloaded = preloaded
end

function SkillCardMixin:GetPreloaded()
	return self.preloaded
end

function SkillCardMixin:GetRequiredLevel()
	return self.requiredLevel
end

function SkillCardMixin:SetReplace(cardID)
	self.replaceCardID = cardID
end

function SkillCardMixin:GetReplace()
	return self.replaceCardID
end

function SkillCardMixin:SetSpellID(spellID)
	self.spellID = spellID
end

function SkillCardMixin:GetSpellID()
	return self.spellID
end

function SkillCardMixin:SetQuality(quality)
	self.quality = quality
end

function SkillCardMixin:GetQuality()
	return self.quality or 1
end

function SkillCardMixin:SetGolden(isGolden)
	self.isGolden = isGolden
end

function SkillCardMixin:IsGolden()
	return self.isGolden
end

function SkillCardMixin:SetCardID(cardID)
	self.cardID = cardID
end

function SkillCardMixin:GetCardID()
	return self.cardID
end

function SkillCardMixin:Layout()
	self:SetSize(162, 216)

	self.Slot = self:CreateTexture(nil, "BACKGROUND")
	self.Slot:SetSize(230, 230)
	self.Slot:SetTexture("Interface\\Draft\\skillcardslot")
	self.Slot:SetPoint("CENTER")

	self.KnownCard = CreateFrame("BUTTON", "$parent.KnownCard", self)
	self.KnownCard:SetSize(self:GetSize())
	self.KnownCard:SetPoint("CENTER")
	MixinAndLoadScripts(self.KnownCard, SkillCardKnownCardMixin)
	self.KnownCard.ShouldShowAvailableLevelText = function() return true end

	self.Shine = CreateFrame("FRAME", "$parent.Shine", self)
	self.Shine:SetPoint("CENTER", 0, 3)
	self.Shine:SetSize(self:GetWidth()*0.85, self:GetHeight()*0.89)
	self.Shine:SetFrameLevel(self.KnownCard:GetFrameLevel()+4)
	self.Shine:Hide()
	MixinAndLoadScripts(self.Shine, SkillCardShineMixin)

	self.KnownOverlay = CreateFrame("FRAME", "$parent.knownFrame", self)
	self.KnownOverlay:SetPoint("TOPLEFT")
	self.KnownOverlay:SetPoint("BOTTOMRIGHT")
	self.KnownOverlay:SetFrameLevel(self.KnownCard.IconFrame:GetFrameLevel()+2)
	--self.KnownOverlay:EnableMouse(true)
	self.KnownOverlay:Hide()

	self.KnownCard.RemoveButton:SetFrameLevel(self.KnownOverlay:GetFrameLevel()+1)

	self.KnownOverlay.ShadowOverlay = self.KnownOverlay:CreateTexture(nil, "BACKGROUND")
	self.KnownOverlay.ShadowOverlay:SetTexture(0, 0, 0, 0.6)
	self.KnownOverlay.ShadowOverlay:SetPoint("TOPLEFT", 4, -8)
	self.KnownOverlay.ShadowOverlay:SetPoint("BOTTOMRIGHT", -4, 8)

	self.KnownOverlay.CheckedTexture = self.KnownOverlay:CreateTexture(nil, "ARTWORK")
	self.KnownOverlay.CheckedTexture:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\BCNew\\GreenCheckMark")
	self.KnownOverlay.CheckedTexture:SetPoint("CENTER", 0, 32)
	self.KnownOverlay.CheckedTexture:SetSize(64, 64)

	self.KnownOverlay.Text = self.KnownOverlay:CreateFontString(nil, "OVERLAY")
	self.KnownOverlay.Text:SetFontObject(GameFontNormalLarge)
	self.KnownOverlay.Text:SetPoint("TOP", self.KnownOverlay.CheckedTexture, "BOTTOM", 0, 0)
	self.KnownOverlay.Text:SetJustifyH("CENTER")
	self.KnownOverlay.Text:SetJustifyV("TOP")
	self.KnownOverlay.Text:SetWidth(114)

	self.KnownOverlay.TextShadow = self.KnownOverlay:CreateTexture(nil, "BORDER")
	self.KnownOverlay.TextShadow:SetSize(200, 150)
	self.KnownOverlay.TextShadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.KnownOverlay.TextShadow:SetPoint("CENTER", self.KnownOverlay.Text, 0, 0)
end

-------------------------------------------------------------------------------
--                              Card for unlock                              --
-------------------------------------------------------------------------------
SkillCardUnlockMixin = CreateFromMixins(SkillCardMixin)

function SkillCardUnlockMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:Layout()

	self:GenerateCallbackEvents({
		"OnFlip",
		--"OnLeave",
		--"OnEnter",
		--"OnRankChangeFinished" -- NOT USED
		--"OnProgressUpdateFinished",
	})

	self.OnUpdateAnim = GenerateClosure(SkillCardKnownCardMixin.OnUpdateAnim, self)
	self.StopAppear = GenerateClosure(SkillCardKnownCardMixin.StopAppear, self)

	--self.KnownCard:HookScript("OnLeave", function() self:TriggerEvent("OnLeave") end)
	--self.KnownCard:HookScript("OnEnter", function() self:TriggerEvent("OnEnter") end)
	--self.KnownCard:RegisterCallback("OnRankChange", self.OnRankChange, self)
	--self.KnownCard:RegisterCallback("OnRankChangeFinished", function() self:TriggerEvent("OnRankChangeFinished") end, self)
	--self.KnownCard.ProgressBar:RegisterCallback("OnProgressUpdateFinished", function() self:TriggerEvent("OnProgressUpdateFinished") end, self)
	self.CoverFrame:RegisterCallback("OnFlip", self.OnFlip, self)
end

function SkillCardUnlockMixin:SetIndex(index)
	self.index = index
end

function SkillCardUnlockMixin:GetIndex()
	return self.index
end

function SkillCardUnlockMixin:SetUUID(index)
	self.UUID = index
end

function SkillCardUnlockMixin:GetUUID()
	return self.UUID
end

function SkillCardUnlockMixin:ResetVisual()
	self:SetForceRevealed(false)
	self:SetUncovered(false)

	self.KnownCard:SetAlpha(1)
	self.KnownCard:Hide()

	-- clean up fade status if we reveal new card while fade out is playing
	self.CoverFrame.ForceLeaveFade = true

	self.CoverFrame:SetAlpha(1)
	self.CoverFrame:Show()

	self.KnownCard.ProgressBar:GetScript("OnUpdate", nil)
end

function SkillCardUnlockMixin:SetCard(cardID, rank)
	PlaySound(SOUNDKITEXTRA.SKILL_CARD_APPEAR)

	self:ResetVisual()

	local cardData = SkillCardUtil.GetSkillCardInfo(cardID, rank)

	if not(cardData) then
		SendSystemMessage("|cffFF0000ERROR. No GetSkillCardInfo found for cardID: "..(cardID or "NULL"))
		return
	end
	-- it should be collected rank if pending rank is higher
	-- and pending rank if it is lower or equal to collected
	--local displayedRank = math.max( (rank > cardData.CollectedRank) and cardData.CollectedRank or rank, 1)

	local displayedRank = rank

	-- refresh cardData because if may be different for a new rank
	cardData = SkillCardUtil.GetSkillCardInfo(cardID, displayedRank)

	local entry = C_CharacterAdvancement.GetEntryBySpellID(cardData.SpellID)
	local isTalent = SkillCardUtil.IsCardTypeTalent(cardData.Type)
	local quality = C_SkillCard.GetSkillCardQuality(cardID, displayedRank) or cardData.Quality

	self:SetMaxRank(cardData.MaxRank)
	self:SetTalentRank(isTalent and displayedRank)
	self:SetCollectedProgress(isTalent and SkillCardUtil.GetCollectedProgress(cardID)) -- for some reason GetSkillCardInfo and GetProgress have different progress
	self:SetCardID(cardID)
	self:SetSpellID(cardData.SpellID)
	self:SetQuality(Enum.SkillCardQuality[quality])
	self:SetRequiredLevel(entry and entry.RequiredLevel or DEFAULT_REQUIRED_LEVEL)
	self:SetGolden(SkillCardUtil.IsCardTypeGolden(cardData.Type))

	self:UpdateVisual()
	self:PlayAppear()

	-- don't accidentely show new spell
	GameTooltip:Hide()
	
	--[[if (rank > displayedRank) and (rank > 1) and (displayedRank >= 1) then
		self.KnownCard:SetNextRank(rank)
	else
		self.KnownCard:SetNextRank(nil)
	end]]--
end

function SkillCardUnlockMixin:RefreshProgress()
	local cardData = SkillCardUtil.GetSkillCardInfo(self:GetCardID())
	local isTalent = SkillCardUtil.IsCardTypeTalent(cardData.Type)

	if (isTalent) then
		self:SetCollectedProgress(SkillCardUtil.GetCollectedProgress(self:GetCardID()))
		self:UpdateKnownCard()
	else
		return
	end
end

function SkillCardUnlockMixin:UpdateKnownCard()
	local quality = self:GetQuality()

	self.KnownCard:UpdateVisual()
	
	local collectedProgress = self:GetCollectedProgress()

	-- additional to known card visual update
	if collectedProgress and (collectedProgress ~= 100) or self.KnownCard:GetNextRank() then
		local progressValue = self.KnownCard:GetNextRank() and 99 or collectedProgress -- if we have next rank, play 0-100 first
		self.KnownCard.ProgressBar:Hide()
		self.KnownCard.ProgressBar:PlayUpdateValueAnim(0, progressValue)
	else
		self.KnownCard.ProgressBar:GetScript("OnUpdate", nil)
		self.KnownCard.ProgressBar:Hide()
	end

	if (quality and (quality > 1)) then
		self.KnownCard.CardHoverGlow:SetVertexColor(ITEM_QUALITY_COLORS[quality]:GetRGB())
		self.KnownCard.CardHoverGlow:Show()
	else
		self.KnownCard.CardHoverGlow:Hide()
	end
end

function SkillCardUnlockMixin:IsRankUpdatePlaying()
	return self.KnownCard:IsRankUpdatePlaying()
end

function SkillCardUnlockMixin:IsProgressUpdatePlaying()
	return self.KnownCard.ProgressBar:IsVisible() and self.KnownCard.ProgressBar:GetScript("OnUpdate")
end

function SkillCardUnlockMixin:UpdateVisual()
	local name = GetSpellInfo(self:GetSpellID())
	local quality = self:GetQuality()
	
	-- set up known card
	self:UpdateKnownCard()
	self.CoverFrame:UpdateVisual()
end

function SkillCardUnlockMixin:PlayAppear()
	self:SetScale(3)
	self:SetAlpha(0)
	self:SetScript("OnUpdate", self.OnUpdateAnim)
end

function SkillCardUnlockMixin:OnFlip()
	BaseFrameFadeOut(self.CoverFrame)
	Timer.After(0.3, function() if self:IsUncovered() then BaseFrameFadeIn(self.KnownCard) end end) -- to match anim speed

	self:SetUncovered(true)

	self:TriggerEvent("OnFlip", self:GetIndex())

	if self.KnownCard:GetNextRank() then
		self.KnownCard:PlayRankChange()
	end
end

function SkillCardUnlockMixin:OnRankChange(oldRank, newRank)
	local cardData = SkillCardUtil.GetSkillCardInfo(self:GetCardID(), newRank)
	local quality = C_SkillCard.GetSkillCardQuality(self:GetCardID(), newRank)

	self:SetSpellID(cardData.SpellID)
	self:SetQuality(Enum.SkillCardQuality[quality or 1])
	self:SetTalentRank(newRank)

	self:UpdateKnownCard()
	self:PlayGlowAnim()

	PlaySound(SkillCardUnlockCoverMixin.qualitySounds[self:GetQuality()] or SkillCardUnlockCoverMixin.qualitySounds[1])
end

function SkillCardUnlockMixin:ForceReveal()
	self:SetForceRevealed(true)
	self.CoverFrame:OnMouseUp()
end

function SkillCardUnlockMixin:SetForceRevealed(isForceRevealed)
	self.forceRevealed = isForceRevealed
end

function SkillCardUnlockMixin:IsForceRevealed()
	return self.forceRevealed
end

function SkillCardUnlockMixin:SetCollectedProgress(progress)
	self.collectedProgress = progress
end

function SkillCardUnlockMixin:GetCollectedProgress(progress)
	return self.collectedProgress
end

function SkillCardUnlockMixin:SetUncovered(status)
	self.isUncovered = status
end

function SkillCardUnlockMixin:IsUncovered()
	return self.isUncovered
end

function SkillCardUnlockMixin:PlayGlowAnim()
	self.KnownCard.ShinyGlow.AG:Stop()
	self.KnownCard.ShinyGlow.AG:Play()
end

function SkillCardUnlockMixin:Layout()
	self:SetSize(162, 216)

	self.KnownCard = CreateFrame("BUTTON", "$parent.KnownCard", self)
	self.KnownCard:SetSize(self:GetSize())
	self.KnownCard:SetPoint("CENTER")
	self.KnownCard.time = 0.5
	MixinAndLoadScripts(self.KnownCard, SkillCardKnownCardMixin)
	self.KnownCard:SetScale(1)
	self.KnownCard.RemoveButton:Hide()

	self.KnownCard.ProgressBar = CreateFrame("FRAME", "$parent.ProgressBar", self.KnownCard, "BetterStatusBarTemplate")
	self.KnownCard.ProgressBar:SetPoint("BOTTOM", 0, 10)
	MixinAndLoadScripts(self.KnownCard.ProgressBar, SkillCardProgressMinimizedBar)
	self.KnownCard.ProgressBar.Text:SetFontObject(GameFontHighlight)
	self.KnownCard.ProgressBar:SetWidth(72)
	self.KnownCard.ProgressBar:SetValue(50)
	self.KnownCard.ProgressBar:Hide()

	self.KnownCard.CardHoverGlow = self.KnownCard:CreateTexture(nil, "BACKGROUND")
	self.KnownCard.CardHoverGlow:SetBlendMode("ADD")
	self.KnownCard.CardHoverGlow:SetTexture("Interface\\Draft\\CardHover")
	self.KnownCard.CardHoverGlow:SetSize(275, 525)
	self.KnownCard.CardHoverGlow:SetPoint("CENTER", 1.5, 2)

	self.CoverFrame = CreateFrame("FRAME", "$parent.CoverFrame", self, nil)
	self.CoverFrame:SetFrameLevel(self.KnownCard:GetFrameLevel()+5)
	self.CoverFrame:SetPoint("TOPLEFT")
	self.CoverFrame:SetPoint("BOTTOMRIGHT")
	self.CoverFrame:EnableMouse(true)
	self.CoverFrame.time = 1.5
	MixinAndLoadScripts(self.CoverFrame, SkillCardUnlockCoverMixin)
end
