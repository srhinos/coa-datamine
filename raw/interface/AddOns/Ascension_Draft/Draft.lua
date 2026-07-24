Draft = select(2, ...)

Draft.Cards = {}
Draft.RevealedCards = {}

Draft.CardLayouts = {
	[1] = { { "CENTER", 0, -30 } },
	[2] = { { "CENTER", -175, -30 }, { "CENTER", 175, -30 }},
	[3] = { { "CENTER", -350, -30 }, { "CENTER", 0, -30 }, { "CENTER", 350, -30 }},
}

function Draft:SetRevealedCard(cardID)
	self.RevealedCards[cardID] = true
end

function Draft:IsCardRevealed(cardID)
	return self.RevealedCards[cardID]
end

function Draft:ResetRevealedCards()
	wipe(self.RevealedCards)
end

function Draft:InvalidateAllCards()
	Draft:HideCards(true)
	self:ResetRevealedCards()
end

function Draft:RestoreCards(numCards)
	HideUIPanel(Collections)
	local expectedCount = numCards or DraftUtil.GetNumPicks() or 0
	local layout = Draft.CardLayouts[expectedCount]
	local shownCount = 0
	for index, card in ipairs(self.Cards) do
		if card:IsValid() and layout and layout[index] then
			card:ResetPointsOffset()
			card:SetPoint(unpack(layout[index]))
			card:Show()
			shownCount = shownCount + 1
			card:PlaySlideInAnimation()
			if not self:IsCardRevealed(index) then
				card:ShowCover()
			else
				card:HideCover()
			end
		else
			card:Hide()
		end
	end
	self:UpdateMissingCardsWarning(shownCount, expectedCount)
end

function Draft:ShowMissingCardsWarning()
	if not DraftMissingCardsWarning then
		return
	end
	DraftMissingCardsWarning.Text:SetText(DRAFT_MISSING_CARDS_WARNING or "We couldn't load your draft picks. Please relog or contact support.")
	DraftMissingCardsWarning:Show()
end

function Draft:HideMissingCardsWarning()
	if DraftMissingCardsWarning then
		DraftMissingCardsWarning:Hide()
	end
end

function Draft:UpdateMissingCardsWarning(shownCount, expectedCount)
	if expectedCount and expectedCount > 0 and shownCount == 0 then
		self:ShowMissingCardsWarning()
	else
		self:HideMissingCardsWarning()
	end
end

function Draft:ShowSacrificePicks()
	HideUIPanel(Collections)
	local numPicks = GetHandOfFateSacrificePickCount()
	local layout = Draft.CardLayouts[numPicks]
	local shownCount = 0
	for index, card in ipairs(self.Cards) do
		if layout and layout[index] then
			local internalID = DraftUtil.GetSacrificePick(index)
			if internalID and internalID > 0 then
				card:SetCharacterAdvancementSpell(internalID)
				card:SetCardAction(DraftCardMixin.Action.Sacrifice)
				card:ResetPointsOffset()
				card:SetPoint(unpack(layout[index]))
				card:Show()
				shownCount = shownCount + 1
				card:HideCover()
			else
				card:SetCharacterAdvancementSpell(nil)
				card:Hide()
			end
		else
			card:Hide()
		end
	end
	self:UpdateMissingCardsWarning(shownCount, numPicks)
	PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA)
end

function Draft:ShowHandOfFatePicks()
	HideUIPanel(Collections)
	local numPicks = GetHandOfFatePickCount()
	local layout = Draft.CardLayouts[numPicks]
	local shownCount = 0
	for index, card in ipairs(self.Cards) do
		if layout and layout[index] then
			local internalID = DraftUtil.GetHandOfFatePick(index)
			if internalID and internalID > 0 then
				card:SetCharacterAdvancementSpell(internalID)
				card:SetCardAction(DraftCardMixin.Action.Swap)
				card:ResetPointsOffset()
				card:SetPoint(unpack(layout[index]))
				card:Show()
				shownCount = shownCount + 1
				if not self:IsCardRevealed(index) then
					card:PlaySlideInAnimation()
					card:ShowCover()
				else
					card:HideCover()
				end
			else
				card:SetCharacterAdvancementSpell(nil)
				card:Hide()
			end
		else
			card:Hide()
		end
	end
	self:UpdateMissingCardsWarning(shownCount, numPicks)
	PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA)
end

function Draft:ShowDraftPicks()
	HideUIPanel(Collections)
	local numPicks = GetDraftModePickCount()
	dprint("GetNumPicks", numPicks)
	local layout = Draft.CardLayouts[numPicks]
	local shownCount = 0
	for index, card in ipairs(self.Cards) do
		if layout and layout[index] then
			local internalID = DraftUtil.GetDraftPick(index)
			if internalID and internalID > 0 then
				card:SetCharacterAdvancementSpell(internalID)
				card:SetCardAction(DraftCardMixin.Action.Learn)
				card:ResetPointsOffset()
				card:SetPoint(unpack(layout[index]))
				card:Show()
				shownCount = shownCount + 1
				if not self:IsCardRevealed(index) then
					card:PlaySlideInAnimation()
					card:ShowCover()
				else
					card:HideCover()
				end
			else
				card:SetCharacterAdvancementSpell(nil)
				card:Hide()
			end
		else
			card:Hide()
		end
	end
	self:UpdateMissingCardsWarning(shownCount, numPicks)
end

function Draft:CheckForPicks(bypassCVar)
	UpdateDraftMicroButton()
	if C_Player:InCombat() then
		if not self.CheckAfterCombat then
			self.CheckAfterCombat = Timer.AfterCombat(function()
				self:CheckForPicks()
				self.CheckAfterCombat = nil
			end)
		end
		return
	end
	if DraftUtil.HasSacrificePicks() then
		self:ShowSacrificePicks()
		DraftHelpFrame:ShowSacrificeTip(GetSelectedHandOfFateSpell())
		return
	elseif DraftUtil.HasHandOfFatePicks() then
		self:ShowHandOfFatePicks()
		if IsCardSwap() then
			--DraftHelpFrame:ShowCardSwapTip()
			DraftHelpFrame:ShowHandOfFateTip()
			Timer.After(0.5, function()
				if Card2:IsShown() then
					DraftUnlockAnimation:Show()
					DraftUnlockAnimation:Play()
				end
			end)
		else
			DraftHelpFrame:ShowHandOfFateTip()
		end
		return
	elseif DraftUtil.HasDraftPicks() then
		if C_Player:GetLevel() >= 10 and not C_Player:IsMaxLevel() and not C_CVar.GetBool("autoPopupDraft") and not bypassCVar then
			return
		end
		self:ShowDraftPicks()
		if C_Player:GetLevel() < 10 then
			DraftHelpFrame:ShowDraftHint()
		end
		DraftActionContainer:SetupActions()
		return
	end
	self:InvalidateAllCards()
end

function Draft:HideCards(invalidate)
	for _, card in ipairs(self.Cards) do
		card:Hide()
		if invalidate then
			card:MarkCardInvalid()
		end
	end
	self:HideMissingCardsWarning()
	self:HideDraftStaticPopups()
	DraftActionContainer:ClearActions()
	DraftUnlockAnimation:Hide()
	DraftHelpFrame:Hide()
	UpdateDraftMicroButton()
end

function Draft:IsDraftShown()
	for _, card in ipairs(self.Cards) do
		if card:IsShown() then
			return true
		end
	end
end

function Draft:ToggleVisible()
	self:HideDraftStaticPopups()
	if self:IsDraftShown() then
		PlaySound(SOUNDKIT.ABILITIES_CLOSEA)
		self:HideCards()
	else
		self:CheckForPicks(true)
	end
end

function Draft:HideDraftStaticPopups()
	StaticPopup_Hide("DRAFT_CANT_CHOOSE_IMMUNE")
	StaticPopup_Hide("DRAFT_CHOICE_CONFIRM")
	StaticPopup_Hide("DRAFT_UNLEARN_CONFIRM")
	StaticPopup_Hide("DRAFT_CANCEL_SWAP_CONFIRM")
	StaticPopup_Hide("DRAFT_CANCEL_HOF_CONFIRM")
	StaticPopup_Hide("DRAFT_MISSING_SKILLCARD_CONFIRM")
end 

function Draft:GetNumCardsShown()
	local numShown = 0
	for _, card in ipairs(self.Cards) do
		if card:IsValid() and card:IsShown() then
			numShown = numShown + 1
		end
	end
	return numShown
end

function Draft:EnqueueCardDisplay(func)
	if not Draft.PopupQueue then
		Draft.PopupQueue = {}
	end
	tinsert(Draft.PopupQueue, func)
end

function Draft:DequeueCardDisplay()
	if not Draft.PopupQueue then
		return
	end
	local func = tremove(Draft.PopupQueue, 1)
	if func then
		func()
	end
end

function Draft:ShowLearnedSpell(internalID, rank)
	self:HideMissingCardsWarning()
	if C_Player:InCombat() then
		Timer.AfterCombat(function()
			self:ShowLearnedSpell(internalID, rank)
		end)
		return
	end
	local numCardsShown = Draft:GetNumCardsShown()
	if numCardsShown >= #self.Cards then
		self:EnqueueCardDisplay(GenerateClosure(self.ShowLearnedSpell, self, internalID, rank))
		return
	end

	HideUIPanel(Collections)

	local layout = Draft.CardLayouts[numCardsShown + 1]
	for index, card in ipairs(self.Cards) do
		if layout and layout[index] then
			if not card:IsShown() then
				local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)
				if not entry then -- happens if we recieve just spellID via CARD_SPELL_LEARNED
					local spellID = internalID
					card:SetSpellID(spellID)
					if IsPassiveSpellID(spellID) then
						card:SetArtwork(DraftCardMixin.ArtworkStyle.Metal)
					end
					card:SetTitleDisplay(NEW_SPELL_LEARNED, "PTFontHighlightLarge") -- TODO: event don't support talents and ranks yet
				else -- we received internalID
					local title = C_CharacterAdvancement.IsTalentID(internalID) and NEW_TALENT_RANK_LEARNED or NEW_SPELL_LEARNED
					card:SetCharacterAdvancementSpell(internalID, rank)
					local spellID = entry.Spells[1]
					if IsPassiveSpellID(spellID) then
						card:SetArtwork(DraftCardMixin.ArtworkStyle.Metal)
					end
					card:SetTitleDisplay(title:format(rank or 1), "PTFontHighlightLarge")
				end

				card:SetCardAction(DraftCardMixin.Action.Dismiss)
				card:Show()
				card:HideCover()
			end
			card:ResetPointsOffset()
			card:SetPoint(unpack(layout[index]))
		else
			card:Hide()
		end
	end
end

function Draft:ShowMysticEnchant(enchantID)
	self:HideMissingCardsWarning()
	if C_Player:InCombat() then
		Timer.AfterCombat(function()
			self:ShowMysticEnchant(enchantID)
		end)
		return
	end
	local numCardsShown = Draft:GetNumCardsShown()
	if numCardsShown >= #self.Cards then
		self:EnqueueCardDisplay(GenerateClosure(self.ShowMysticEnchant, self, enchantID))
		return
	end

	HideUIPanel(Collections)

	local layout = Draft.CardLayouts[numCardsShown + 1]
	for index, card in ipairs(self.Cards) do
		if layout and layout[index] then
			if not card:IsShown() then
				card:SetMysticEnchant(enchantID)
				card:SetCardAction(DraftCardMixin.Action.Dismiss)
				card:Show()
				card:HideCover()
			end
			card:ResetPointsOffset()
			card:SetPoint(unpack(layout[index]))
		else
			card:Hide()
		end
	end
end

local draftEventFrame = CreateFrame("Frame")
draftEventFrame:RegisterEvent("ITEM_USED")
draftEventFrame:SetScript("OnEvent", function(_, _, itemID)
	if itemID == ItemData.SPELL_DRAFT_DECK then
		RedraftAbilities()
	end
end)
