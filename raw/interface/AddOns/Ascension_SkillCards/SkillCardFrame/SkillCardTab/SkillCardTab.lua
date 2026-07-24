-------------------------------------------------------------------------------
--                                   Tab                                     --
-------------------------------------------------------------------------------
SkillCardTabMixin = {}
SkillCardTabMixin.maxCardsPerPage = 4

function SkillCardTabMixin:OnLoad()
	self:Layout()

	self.cardIDToButtonNormal = {}
	self.cardIDToButtonGolden = {}
	self.cardsCollection = CreateFramePoolCollection()

	self.cardHalfWidth = nil
	self.cardSpacing = 24

	self.preloadedNormal = {}
	self.preloadedGolden = {}

	self.PageLeftButton:SetScript("OnClick", GenerateClosure(self.PreviousPage, self))
	self.PageRightButton:SetScript("OnClick", GenerateClosure(self.NextPage, self))

	self:HookEvent("SKILL_CARD_UPDATED")

	self.ReplaceDialog.Button:SetScript("OnClick", function() self:SetReplace(false) end)
end

function SkillCardTabMixin:RefreshCurrentPage()
	self:OnPageChanged(self.page or 1)
	self:SetReplace(false)
end

function SkillCardTabMixin:OnShow()
	self:HookEvent("SKILL_CARD_UPDATED")
	self:HookEvent("SKILL_CARD_BLOCKED")
	self:HookEvent("SKILL_CARD_UNBLOCKED")

	self:RefreshCurrentPage()
end

function SkillCardTabMixin:OnHide()
	self:UnhookEvent("SKILL_CARD_UPDATED")
	self:UnhookEvent("SKILL_CARD_BLOCKED")
	self:UnhookEvent("SKILL_CARD_UNBLOCKED")
end

function SkillCardTabMixin:ClearPreloadedCards()
	wipe(self.preloadedNormal)
	wipe(self.preloadedGolden)

	self:DisplayResults()
end

function SkillCardTabMixin:ReleaseAllCards()
	self.cardIDToButtonNormal = {}
	self.cardIDToButtonGolden = {}
	self.cardsCollection:ReleaseAll()
end

function SkillCardTabMixin:AcquireCard(index, isGolden)
	local pool, isNewPool = self.cardsCollection:GetOrCreatePool("BUTTON", self, "SkillCardTemplate", nil)

	local card, isNew = pool:Acquire()

	if (isNew) then
		card:RegisterCallback("OnCardActivated", self.OnCardActivated, self)
		card:RegisterCallback("OnCardDeactivated", self.OnCardDeactivated, self)
	end

	card:Init(index, self.cardAtlasNormal, self.cardAtlasGolden)
	card:Show()

	if not(self.cardHalfWidth) then
		self.cardHalfWidth = card:GetWidth()/2+(self.cardSpacing/2)
	end

	card:SetGolden(isGolden)

	return card
end

function SkillCardTabMixin:OnCardActivated(index, isGolden)
	local preloadedCardID = self:IsPreloaded(index, isGolden)
	local replaceCardID = self:GetReplace(isGolden)

	self:ClearPreloadedCards()
	self:SetReplace(false)

	if preloadedCardID then
		SkillCardUtil.SetCardAtIndex(isGolden and self.cardTypeGolden or self.cardTypeNormal, index, preloadedCardID)
		return
	elseif replaceCardID then
		SkillCardUtil.SetCardAtIndex(isGolden and self.cardTypeGolden or self.cardTypeNormal, index, replaceCardID)
		return
	end

end

function SkillCardTabMixin:GetCardButtonAtIndex(index, isGolden)
	if isGolden then
		return self.cardIDToButtonGolden[index]
	end

	return self.cardIDToButtonNormal[index]
end

function SkillCardTabMixin:PlayCardActivationAnimation(index, isGolden, cardID)
	local card = self:GetCardButtonAtIndex(index, isGolden)

	if not card then
		return
	end

	local cardData = isGolden and self:GetCardInfoGoldenAtIndex(index) or self:GetCardInfoNormalAtIndex(index)
	if not cardData or cardData.CardID ~= cardID then
		cardData = SkillCardUtil.GetSkillCardInfo(cardID)
	end

	card:ActivateCard(cardID, cardData)
end

function SkillCardTabMixin:OnCardDeactivated(index, isGolden)
	local preloadedCardID = self:IsPreloaded(index, isGolden)

	if (preloadedCardID) then
		self:ClearPreloadedCards()
		return
	end

	-- TODO: Dialogue
	local data = {isGolden and self.cardTypeGolden or self.cardTypeNormal, index}

	if self:IsStarterSkillCardSlotType() then
		SkillCardUtil.RemoveCardAtIndex(unpack(data))
	elseif (C_CharacterAdvancement.GetLearnedAE() > 8) or (C_CharacterAdvancement.GetLearnedTE() > 0) then
		StaticPopup_Show("SKILL_CARD_REMOVAL", nil, nil, data)
	else
		SkillCardUtil.RemoveCardAtIndex(unpack(data))
	end
end

function SkillCardTabMixin:SelectCard(cardID, rank)
	local cardData = SkillCardUtil.GetSkillCardInfo(cardID, rank or 1)
	local isGolden = SkillCardUtil.IsCardTypeGolden(cardData.Type)
	local newIndex = nil

	if not(cardData.IsCollected) then
		SkillCardUtil.HandleError(SET_SKILL_CARD_NOT_COLLECTED)
		return
	end

	self:SetReplace(false)
	self:ClearPreloadedCards()

	if not(self:IsStarterSkillCardSlotType()) and C_CharacterAdvancement.IsKnownSpellID(cardData.SpellID) then
		SkillCardUtil.HandleError(SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED)
		return false
	end

	if self:HasOppositeStarterDefaultSpellConflict(cardData.SpellID) then
		SkillCardUtil.HandleError(SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED)
		return false
	end

	-- TODO: Probably rework or even replace with helpers
	for index = 1, self:GetMaxNormalCards() do
		local cardDataExisting = self:GetCardInfoNormalAtIndex(index)
		local isBlocked = self:IsCardAtIndexBlocked(index, false)

		if not(cardDataExisting) and not(isBlocked) then
			if not(isGolden) and not(newIndex) then
				newIndex = index
			end
		elseif cardDataExisting and (cardDataExisting.SpellID == cardData.SpellID) then
			SkillCardUtil.HandleError(SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED)
			return
		end
	end

	for index = 1, self:GetMaxGoldenCards() do
		local cardDataExisting = self:GetCardInfoGoldenAtIndex(index)
		local isBlocked = self:IsCardAtIndexBlocked(index, true)

		if not(cardDataExisting) and not(isBlocked) then
			if isGolden and not(newIndex) then
				newIndex = index
			end
		elseif cardDataExisting and (cardDataExisting.SpellID == cardData.SpellID) then
			SkillCardUtil.HandleError(SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED)
			return
		end
	end

	self:PreloadCard(newIndex, isGolden, cardData)
end

function SkillCardTabMixin:PreloadCard(index, isGolden, cardData)
	if (index) then
		self:ClearPreloadedCards()
		self:SetReplace(false)
		SkillCardUtil.SetCardAtIndex(isGolden and self.cardTypeGolden or self.cardTypeNormal, index, cardData.CardID)
	else
		self:SetReplace(cardData.CardID, isGolden, cardData.SpellID)
	end
end

function SkillCardTabMixin:SetReplace(cardID, isGolden, spellID)
	local isReplace = true

	if not(cardID) then
		self.replaceCardGolden = false
		self.replaceCardNormal = false
		isReplace = false
	else
		if isGolden then
			self.replaceCardGolden = cardID
			self.replaceCardNormal = nil
		else
			self.replaceCardGolden = nil
			self.replaceCardNormal = cardID
		end
	end

	if isReplace then
		if (spellID) then
			self.ReplaceDialog.Tip:SetText(string.format(CHOOSE_SKILLCARD_TO_REPLACE, LinkUtil:GetSpellLink(spellID)))
		end
		BaseFrameFadeIn(self.ReplaceDialog)
	elseif not(isReplace) and self.ReplaceDialog:IsVisible() then
		BaseFrameFadeOut(self.ReplaceDialog)
	end

	self:DisplayResults()
end

function SkillCardTabMixin:GetReplace(isGolden)
	if (isGolden) then
		return self.replaceCardGolden
	else
		return self.replaceCardNormal
	end
end

function SkillCardTabMixin:IsPreloaded(index, isGolden) 
	if (isGolden) then
		return self.preloadedGolden[index]
	else
		return self.preloadedNormal[index]
	end
end

function SkillCardTabMixin:SetCardAtlases(atlasNormal, atlasGolden)
	self.cardAtlasNormal = atlasNormal
	self.cardAtlasGolden = atlasGolden
end

function SkillCardTabMixin:SetCardTypes(cardTypeNormal, cardTypeGolden)
	self.cardTypeNormal = cardTypeNormal
	self.cardTypeGolden = cardTypeGolden

	self.maxPage = 1

	self.PageText:Hide()
	self.PageLeftButton:Hide()
	self.PageRightButton:Hide()
	
	self:OnPageChanged(1)
	self:SetReplace(false)
end

function SkillCardTabMixin:GetMaxNormalCards()
	return SkillCardUtil.GetMaxCards(self.cardTypeNormal)
end

function SkillCardTabMixin:GetMaxGoldenCards()
	return SkillCardUtil.GetMaxCards(self.cardTypeGolden)
end

function SkillCardTabMixin:GetCardInfoNormalAtIndex(index)
	return SkillCardUtil.GetCardInfoAtIndex(self.cardTypeNormal, index)
end

function SkillCardTabMixin:GetCardInfoGoldenAtIndex(index)
	return SkillCardUtil.GetCardInfoAtIndex(self.cardTypeGolden, index)
end

function SkillCardTabMixin:GetCardNormalAtIndex(index)
	return self.preloadedNormal[index] or self:GetCardInfoNormalAtIndex(index) -- return preloaded card ID or card info at slot
end

function SkillCardTabMixin:GetCardGoldenAtIndex(index)
	return self.preloadedGolden[index] or self:GetCardInfoGoldenAtIndex(index) -- return preloaded card ID or card info at slot
end

function SkillCardTabMixin:IsCardAtIndexActive(index, isGolden)
	return SkillCardUtil.IsCardAtIndexActive(isGolden and self.cardTypeGolden or self.cardTypeNormal, index)
end

function SkillCardTabMixin:IsCardAtIndexBlocked(index, isGolden)
	return C_SkillCard.IsCardAtIndexBlocked(isGolden and self.cardTypeGolden or self.cardTypeNormal, index)
end

function SkillCardTabMixin:IsDefaultSkillCardSlotType()
	return self.cardTypeNormal == Enum.SkillCardType.SkillNormal and self.cardTypeGolden == Enum.SkillCardType.SkillGolden
end

function SkillCardTabMixin:IsStarterSkillCardSlotType()
	return self.cardTypeNormal == Enum.SkillCardType.StarterNormal and self.cardTypeGolden == Enum.SkillCardType.StarterGolden
end

function SkillCardTabMixin:HasSpellInSlotTypes(spellID, cardTypeNormal, cardTypeGolden)
	for index = 1, SkillCardUtil.GetMaxCards(cardTypeNormal) do
		local cardDataExisting = SkillCardUtil.GetCardInfoAtIndex(cardTypeNormal, index)
		if cardDataExisting and cardDataExisting.SpellID == spellID then
			return true
		end
	end

	for index = 1, SkillCardUtil.GetMaxCards(cardTypeGolden) do
		local cardDataExisting = SkillCardUtil.GetCardInfoAtIndex(cardTypeGolden, index)
		if cardDataExisting and cardDataExisting.SpellID == spellID then
			return true
		end
	end

	return false
end

function SkillCardTabMixin:HasOppositeStarterDefaultSpellConflict(spellID)
	if self:IsDefaultSkillCardSlotType() then
		return self:HasSpellInSlotTypes(spellID, Enum.SkillCardType.StarterNormal, Enum.SkillCardType.StarterGolden)
	end

	if self:IsStarterSkillCardSlotType() then
		return self:HasSpellInSlotTypes(spellID, Enum.SkillCardType.SkillNormal, Enum.SkillCardType.SkillGolden)
	end

	return false
end

function SkillCardTabMixin:ShouldShowSlotUnlockLabels()
	return self:IsStarterSkillCardSlotType() and C_Player:IsPrestiged()
end

function SkillCardTabMixin:GetSlotUnlockLabel()
	if self:ShouldShowSlotUnlockLabels() then
		return STARTER_SKILL_CARD_ON_NEXT_ROLL or "STARTER_SKILL_CARD_ON_NEXT_ROLL"
	end
end

function SkillCardTabMixin:HideSlotUnlockLabels()
	if not(self.slotUnlockLabelsNormal) or not(self.slotUnlockLabelsGolden) then
		return
	end

	for _, label in ipairs(self.slotUnlockLabelsNormal) do
		label:Hide()
	end

	for _, label in ipairs(self.slotUnlockLabelsGolden) do
		label:Hide()
	end
end

function SkillCardTabMixin:OnMouseWheel(delta)
	if (delta > 0) then
		self:NextPage()
	else
		self:PreviousPage()
	end
end

function SkillCardTabMixin:NextPage()
	PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA)

	if self.page >= self.maxPage then
		self.page = self.maxPage
	else
		self.page = self.page + 1
	end

	self:OnPageChanged()
end

function SkillCardTabMixin:PreviousPage()
	PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA)

	if self.page <= 1 then
		self.page = 1
	else
		self.page = self.page - 1
	end

	self:OnPageChanged()
end

function SkillCardTabMixin:OnPageChanged(page)
	if (page) then
		self.page = page
	end

	self:ClearPreloadedCards()

	self:DisplayResults()

	self.PageText:Hide()
	self.PageLeftButton:Hide()
	self.PageRightButton:Hide()
end

function SkillCardTabMixin:DisplayResults()
	self:ReleaseAllCards()
	self:HideSlotUnlockLabels()

	local maxNormal = self:GetMaxNormalCards() or 0
	local maxGolden = self:GetMaxGoldenCards() or 0

	local cardWidth = 162
	local cardSpacing = self.cardSpacing or 24

	-- Layout Normal Cards row dynamically centered
	local totalWidthNormal = maxNormal * cardWidth + (maxNormal - 1) * cardSpacing
	local startXNormal = - (totalWidthNormal / 2) + (cardWidth / 2)

	for i = 1, maxNormal do
		local cardNormal = self:AcquireCard(i, false)
		cardNormal:SetCard(self:GetCardNormalAtIndex(i), self:IsPreloaded(i, false), self:GetReplace(false), self:IsCardAtIndexActive(i, false), nil, self:IsCardAtIndexBlocked(i, false))
		self.cardIDToButtonNormal[i] = cardNormal

		cardNormal:ClearAllPoints()
		local xOffset = startXNormal + (i - 1) * (cardWidth + cardSpacing)
		cardNormal:SetPoint("CENTER", self, "CENTER", xOffset, 120)

		if self:ShouldShowSlotUnlockLabels() then
			local normalLabel = self.slotUnlockLabelsNormal[i]
			if not normalLabel then
				normalLabel = self.SlotUnlockLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				normalLabel:SetTextColor(1, 0.82, 0, 1)
				normalLabel:SetJustifyH("CENTER")
				normalLabel:SetJustifyV("BOTTOM")
				normalLabel:Hide()
				self.slotUnlockLabelsNormal[i] = normalLabel
			end
			local normalLabelText = self:GetSlotUnlockLabel()
			if normalLabelText then
				normalLabel:ClearAllPoints()
				normalLabel:SetPoint("BOTTOM", cardNormal, "TOP", 0, 8)
				normalLabel:SetText(normalLabelText)
				normalLabel:Show()
			end
		end
	end

	-- Layout Golden Cards row dynamically centered
	local totalWidthGolden = maxGolden * cardWidth + (maxGolden - 1) * cardSpacing
	local startXGolden = - (totalWidthGolden / 2) + (cardWidth / 2)

	for i = 1, maxGolden do
		local cardGolden = self:AcquireCard(i, true)
		cardGolden:SetCard(self:GetCardGoldenAtIndex(i), self:IsPreloaded(i, true), self:GetReplace(true), self:IsCardAtIndexActive(i, true), nil, self:IsCardAtIndexBlocked(i, true))
		self.cardIDToButtonGolden[i] = cardGolden

		cardGolden:ClearAllPoints()
		local xOffset = startXGolden + (i - 1) * (cardWidth + cardSpacing)
		cardGolden:SetPoint("CENTER", self, "CENTER", xOffset, -120)

		if self:ShouldShowSlotUnlockLabels() then
			local goldenLabel = self.slotUnlockLabelsGolden[i]
			if not goldenLabel then
				goldenLabel = self.SlotUnlockLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				goldenLabel:SetTextColor(1, 0.82, 0, 1)
				goldenLabel:SetJustifyH("CENTER")
				goldenLabel:SetJustifyV("BOTTOM")
				goldenLabel:Hide()
				self.slotUnlockLabelsGolden[i] = goldenLabel
			end
			local goldenLabelText = self:GetSlotUnlockLabel()
			if goldenLabelText then
				goldenLabel:ClearAllPoints()
				goldenLabel:SetPoint("BOTTOM", cardGolden, "TOP", 0, 8)
				goldenLabel:SetText(goldenLabelText)
				goldenLabel:Show()
			end
		end
	end
end

function SkillCardTabMixin:SKILL_CARD_UPDATED(...)
	local _, cardType, index, cardIDDeactivated, deactivated, cardIDActivated, activated = ...
	local isGolden = (cardType == self.cardTypeGolden)

	if not(isGolden) and (cardType ~= self.cardTypeNormal) then
		return
	end

	self:SetReplace(false)
	self:ClearPreloadedCards()

	if cardIDActivated and (cardIDActivated ~= 0) then
		self:PlayCardActivationAnimation(index, isGolden, cardIDActivated)
	elseif cardIDDeactivated and (cardIDDeactivated ~= 0) then
		self:DisplayResults()
	end
	
end

function SkillCardTabMixin:SKILL_CARD_BLOCKED()
	self:RefreshCurrentPage()
end

function SkillCardTabMixin:SKILL_CARD_UNBLOCKED()
	self:RefreshCurrentPage()
end

function SkillCardTabMixin:Layout()
	self:EnableMouse(true)

	self.PageText = self:CreateFontString(nil, "OVERLAY")
	self.PageText:SetFontObject(GameFontHighlight)
	self.PageText:SetPoint("BOTTOMRIGHT", self, "BOTTOM", -12, 36)

	self.SlotUnlockLabelFrame = CreateFrame("FRAME", nil, self)
	self.SlotUnlockLabelFrame:SetAllPoints()
	self.SlotUnlockLabelFrame:SetFrameLevel(self:GetFrameLevel()+6)

	self.slotUnlockLabelsNormal = {}
	self.slotUnlockLabelsGolden = {}
	for i = 1, SkillCardTabMixin.maxCardsPerPage do
		local normalLabel = self.SlotUnlockLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		normalLabel:SetTextColor(1, 0.82, 0, 1)
		normalLabel:SetJustifyH("CENTER")
		normalLabel:SetJustifyV("BOTTOM")
		normalLabel:Hide()
		self.slotUnlockLabelsNormal[i] = normalLabel

		local goldenLabel = self.SlotUnlockLabelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		goldenLabel:SetTextColor(1, 0.82, 0, 1)
		goldenLabel:SetJustifyH("CENTER")
		goldenLabel:SetJustifyV("BOTTOM")
		goldenLabel:Hide()
		self.slotUnlockLabelsGolden[i] = goldenLabel
	end

	--[[self.TotalNormal = self:CreateFontString(nil, "OVERLAY")
	self.TotalNormal:SetFontObject(GameFontHighlightMedium)
	self.TotalNormal:SetVertexColor(1, 0.82, 0, 1)
	self.TotalNormal:SetJustifyH("CENTER")
	self.TotalNormal:SetJustifyV("CENTER")
	self.TotalNormal:SetText(UNLOCK_SKILL_CARDS_TITLE)

	self.TotalGold = self:CreateFontString(nil, "OVERLAY")
	self.TotalGold:SetFontObject(GameFontHighlightMedium)
	self.TotalGold:SetVertexColor(1, 0.82, 0, 1)
	self.TotalGold:SetJustifyH("CENTER")
	self.TotalGold:SetJustifyV("CENTER")
	self.TotalGold:SetText(UNLOCK_GOLDEN_CARDS_TITLE)]]--

	self.PageLeftButton = CreateFrame("BUTTON", "$parent.PageLeftButton", self, "LeftButtonTemplate")
	self.PageLeftButton:SetPoint("LEFT", self.PageText, "RIGHT", 12, 0)

	self.PageRightButton = CreateFrame("BUTTON", "$parent.PageRightButton", self, "RightButtonTemplate")
	self.PageRightButton:SetPoint("LEFT", self.PageLeftButton, "RIGHT", 8, 0)

	self.ReplaceDialog = CreateFrame("FRAME", "$parent.ReplaceDialog", self)
	self.ReplaceDialog:SetSize(self:GetWidth()*0.9,64)
	self.ReplaceDialog:SetPoint("CENTER", 0, 0)
	self.ReplaceDialog:SetFrameLevel(self:GetFrameLevel()+8)

	self.ReplaceDialog.BG = self.ReplaceDialog:CreateTexture(nil, "BORDER")
	self.ReplaceDialog.BG:SetSize(1200, 150)
	self.ReplaceDialog.BG:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.ReplaceDialog.BG:SetPoint("CENTER", 0, 0)

	self.ReplaceDialog.Tip = self.ReplaceDialog:CreateFontString(nil, "ARTWORK")
	self.ReplaceDialog.Tip:SetFontObject(GameFontNormalLarge)
	self.ReplaceDialog.Tip:SetPoint("CENTER", 0,0)
	self.ReplaceDialog.Tip:SetText(CHOOSE_SKILLCARD_TO_REPLACE)
	self.ReplaceDialog.Tip:SetWidth(self.ReplaceDialog:GetWidth())

	self.ReplaceDialog.Button = CreateFrame("BUTTON", "$parent.button", self.ReplaceDialog, "StaticPopupButtonTemplate")
	self.ReplaceDialog.Button:SetPoint("TOP", self.ReplaceDialog.Tip, "BOTTOM", 0, -12)
	self.ReplaceDialog.Button:SetText(CANCEL)

	self.ReplaceDialog:Hide()
end

