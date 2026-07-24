MASS_REVEAL_TITLE = MASS_REVEAL_TITLE or "REVEAL NEW CARDS: %d" -- TODO: Remove
REVEAL_CARDS_BUTTON_TEXT = REVEAL_CARDS_BUTTON_TEXT or "Reveal Cards"

local NUM_CARDS_PER_BOOSTER = 3

local goldenBoosterPurchaseOptions = {
	{	
		cardType = Enum.SkillCardPurchaseCardTypes.GOLDEN_RARE_TALENTS, 
		icon = "Interface\\skillCards\\inv_misc_plus_rare", 
		tooltipTitle = SKILL_CARD_PURCHASE_GOLDEN_TALENT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Rare)),
		tooltipText = SKILL_CARD_PURCHASE_GOLDEN_TALENT_TEXT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Rare)),
		dialogueTextArg2 = PURCHASE_TALENT_CARD_TOTAL_GOLDEN:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Rare))
	},

	{
		cardType = Enum.SkillCardPurchaseCardTypes.GOLDEN_EPIC_TALENTS, 
		icon = "Interface\\skillCards\\inv_misc_plus_purple", 
		tooltipTitle = SKILL_CARD_PURCHASE_GOLDEN_TALENT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Epic)), 
		tooltipText = SKILL_CARD_PURCHASE_GOLDEN_TALENT_TEXT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Epic)),
		dialogueTextArg2 = PURCHASE_TALENT_CARD_TOTAL_GOLDEN:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Epic))
	},

	{	
		cardType = Enum.SkillCardPurchaseCardTypes.GOLDEN_LEGENDARY_TALENTS, 
		icon = "Interface\\skillCards\\inv_misc_plus_legendary", 
		tooltipTitle = SKILL_CARD_PURCHASE_GOLDEN_TALENT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Legendary)),
		tooltipText = SKILL_CARD_PURCHASE_GOLDEN_TALENT_TEXT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Legendary)),
		dialogueTextArg2 = PURCHASE_TALENT_CARD_TOTAL_GOLDEN:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Legendary))
	},
}

local normalBoosterPurchaseOptions = {
	{
		cardType = Enum.SkillCardPurchaseCardTypes.NORMAL_RARE_TALENTS,
		icon = "Interface\\skillCards\\inv_misc_plus_rare",
		tooltipTitle = SKILL_CARD_PURCHASE_TALENT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Rare)),
		tooltipText = SKILL_CARD_PURCHASE_TALENT_TEXT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Rare)),
		dialogueTextArg2 = PURCHASE_TALENT_CARD_TOTAL:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Rare))
	},

	{
		cardType = Enum.SkillCardPurchaseCardTypes.NORMAL_EPIC_TALENTS,
		icon = "Interface\\skillCards\\inv_misc_plus_purple",
		tooltipTitle = SKILL_CARD_PURCHASE_TALENT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Epic)),
		tooltipText = SKILL_CARD_PURCHASE_TALENT_TEXT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Epic)),
		dialogueTextArg2 = PURCHASE_TALENT_CARD_TOTAL:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Epic))
	},

	{
		cardType = Enum.SkillCardPurchaseCardTypes.NORMAL_LEGENDARY_TALENTS,
		icon = "Interface\\skillCards\\inv_misc_plus_legendary",
		tooltipTitle = SKILL_CARD_PURCHASE_TALENT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Legendary)),
		tooltipText = SKILL_CARD_PURCHASE_TALENT_TEXT:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Legendary)),
		dialogueTextArg2 = PURCHASE_TALENT_CARD_TOTAL:format(NUM_CARDS_PER_BOOSTER, GetColoredItemQualityText(Enum.ItemQuality.Legendary))
	},
}

-------------------------------------------------------------------------------
--                         SkillCardUnlockFrameMixin                         --
-------------------------------------------------------------------------------
SkillCardAnimatedCurrencyMixin = {}

function SkillCardAnimatedCurrencyMixin:OnLoad()
	self.padding = 30
	self.itemCount = nil

	self:Layout()

	local _, fontHeight = GameFontHighlight:GetFont()
	AnimatedFontChildMixin.InitAnimation(self, 0.5, self.Count, fontHeight)
end

function SkillCardAnimatedCurrencyMixin:SetItem(itemID)
	if self.cancelItemLoad then
		self.cancelItemLoad()
		self.cancelItemLoad = nil
	end

	self.item = Item:CreateFromID(itemID)
	local item = self.item
	if not item or item:IsEmpty() then
		return
	end

	self.cancelItemLoad = item:CancelableContinueOnLoad(function(loadedItemID)
		if self.item ~= item or item:GetItemID() ~= loadedItemID then
			return
		end

		self.cancelItemLoad = nil
		self:UpdateDisplay(true)
	end)
end

function SkillCardAnimatedCurrencyMixin:OnEnter()
   GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if self.item then
        GameTooltip:SetHyperlink(self.item:GetLink())
    end
end

function SkillCardAnimatedCurrencyMixin:OnLeave()
    GameTooltip:Hide()
end

function SkillCardAnimatedCurrencyMixin:UpdateDisplay(force)
	if not(self.item) then
		return
	end

	local name = self.item:GetName()

	if not(name) then
		return
	end

	local count = GetItemCount(self.item:GetItemID())

	if force or count ~= self.itemCount or not(self.itemCount) then
		self.itemCount = count

		self.Name:SetText(name)
		self.Count:SetText(" "..SeparateBigNumber(count))
		self.Icon:SetPoint("LEFT", self.Name, "RIGHT", self.Count:GetWidth()+4, 0) -- for icon not to jump together with the count
		AnimatedFontChildMixin.PlayFontObjectAnimation(self)

		local width = self.Name:GetWidth()+self.Count:GetWidth()+self.Icon:GetWidth()+4

		self.Icon:SetTexture(self.item:GetIcon())

		self:SetWidth(width+self.padding)
		self.Shadow:SetWidth(width*1.5)
	end
end

function SkillCardAnimatedCurrencyMixin:Layout()
	self:SetHeight(24)

	self.Shadow = self:CreateTexture(nil, "BACKGROUND")
	self.Shadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.Shadow:SetHeight(32)
	self.Shadow:SetPoint("CENTER")
	self.Shadow:SetAlpha(0.7)

	self.Name = self:CreateFontString(nil, "OVERLAY")
	self.Name:SetJustifyH("LEFT")
	self.Name:SetFontObject(GameFontNormal)
	self.Name:SetPoint("LEFT", self.padding/2, 0)

	self.Count = self:CreateFontString(nil, "OVERLAY")
	self.Count:SetFontObject(GameFontHighlight)
	self.Count:SetJustifyH("LEFT")
	self.Count:SetPoint("LEFT", self.Name, "RIGHT")

	self.Icon = self:CreateTexture(nil, "OVERLAY")
	self.Icon:SetSize(16, 16)
	--self.Icon:SetPoint("LEFT", self.Count, "RIGHT", 4, 0)
end
-------------------------------------------------------------------------------
--                         SkillCardUnlockFrameMixin                         --
-------------------------------------------------------------------------------
--SkillCardUnlockFrameMixin = CreateFromMixins(CallbackRegistryMixin)
SkillCardUnlockFrameMixin = {}
SkillCardUnlockFrameMixin.maxCardsPerPage = 5
SkillCardUnlockFrameMixin.cardsPerRow = 3

function SkillCardUnlockFrameMixin:OnLoad()
	self.cardHalfWidth = nil
	self.cardSpacing = 12
	self.cardIDToButton = {}

	self.cardsCollection = CreateFramePoolCollection()
	self.duplicateGlowCollection = CreateFramePoolCollection()

	self.fadeOutTimer = 0
	self.timeToFadeOut = 0.3

	self.forcedUpdate = false -- used to skip currently viewed cards and go to last pending index

	self.statisticsRewardItems = {}

	self:Layout()

	self.BoosterActionBar:SetBoosters(BoostersAndCardsNormal)
	self.BoosterActionBar:RegisterCallback("OnResultsDisplayed", self.OnBoosterResultsDisplayed, self)

	self.GoldenBoosterActionBar:SetBoosters(BoostersAndCardsGolden)
	self.GoldenBoosterActionBar:RegisterCallback("OnResultsDisplayed", self.OnBoosterResultsDisplayed, self)

	if not C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
		self.BoosterActionBar:AddPurchaseOption(normalBoosterPurchaseOptions[1])
		self.BoosterActionBar:AddPurchaseOption(normalBoosterPurchaseOptions[2])
		self.BoosterActionBar:AddPurchaseOption(normalBoosterPurchaseOptions[3])

		self.GoldenBoosterActionBar:AddPurchaseOption(goldenBoosterPurchaseOptions[1])
		self.GoldenBoosterActionBar:AddPurchaseOption(goldenBoosterPurchaseOptions[2])
		self.GoldenBoosterActionBar:AddPurchaseOption(goldenBoosterPurchaseOptions[3])
	end

	self.GoldenTickets:SetItem(ItemData.GOLDEN_DARKMOON_TICKET, true)
	self.NormalTickets:SetItem(ItemData.DARKMOON_TICKET, true)

	--[[self.AutoRevealCheckButton:SetScript("OnClick", function()
		SkillCardsUI:SetAutoReveal(self.AutoRevealCheckButton:GetChecked())
	end)

	self.AutoRevealCheckButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(SKILL_CARD_AUTO_REVEAL_TOOLTIP, nil, nil, nil, true)
		GameTooltip:Show()
	end)

	self.AutoRevealCheckButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)]]--

	self.MassRevealStatisticsFrame:RegisterCallback("OnStatisticsExit", GenerateClosure(self.OnStatisticsExit, self))
	self.MassRevealStatisticsFrame:RegisterCallback("OnMassRevealAnimationFinished", GenerateClosure(self.OnMassRevealAnimationFinished, self))
	self.MassRevealNextButton:SetScript("OnClick", GenerateClosure(self.OnClickStatisticsNext, self))
end

function SkillCardUnlockFrameMixin:ReleaseCards()
	wipe(self.cardIDToButton)
	self.cardsCollection:ReleaseAll()
end

function SkillCardUnlockFrameMixin:ReleaseGlows()
	self.duplicateGlowCollection:ReleaseAll()
end

function SkillCardUnlockFrameMixin:OnHide()
	self:RegisterOnUpdate()
	self:UnhookAllEvents()
end

function SkillCardUnlockFrameMixin:OnShow()
	for _, itemID in pairs(SkillCardsMassRevealStatisticsMixin.rewardItemIDs) do
		self.statisticsRewardItems[itemID] = GetItemCount(itemID)
	end

	self:UpdateCardsTotal()
	self.GoldenTickets:UpdateDisplay()
	self.NormalTickets:UpdateDisplay()
	self:HookBucketEvent("BAG_UPDATE", 0.2)
	--self.AutoRevealCheckButton:SetChecked(SkillCardsUI:GetAutoReveal())
	self:OnClickDoneButton() -- to always keep up to date info
end

function SkillCardUnlockFrameMixin:AcquireGlow()
	local pool, isNewPool = self.duplicateGlowCollection:GetOrCreatePool("BUTTON", self, "SkillCardGlowTemplate", nil)

	local glow, isNew = pool:Acquire()

	if (isNew) then
		glow:RegisterCallback("OnRelease", function() self:OnReleaseGlow(glow) end)
		glow:SetDestinationPoint(self.FreeBooster)
	end

	glow:Show()

	return glow
end

function SkillCardUnlockFrameMixin:AcquireCard()
	local pool, isNewPool = self.cardsCollection:GetOrCreatePool("BUTTON", self, "SkillCardUnlockTemplate", nil)

	local card, isNew = pool:Acquire()

	if (isNew) then
		card:RegisterCallback("OnFlip", self.OnFlipCard, self)
		--[[card:RegisterCallback("OnEnter", self.ClearOnUpdate, self)
		card:RegisterCallback("OnLeave", self.RegisterOnUpdate, self)
		card:RegisterCallback("OnRankChangeFinished", self.RegisterOnUpdate, self)
		card:RegisterCallback("OnProgressUpdateFinished", self.RegisterOnUpdate, self)]]--
	end

	card:Show()

	if not(self.cardHalfWidth) then
		self.cardHalfWidth = card:GetWidth()/2+(self.cardSpacing/2)
	end

	return card
end

function SkillCardUnlockFrameMixin:GetNextFreeCardIndex()
	return (#self.cardIDToButton) + 1
end

function SkillCardUnlockFrameMixin:TryAddCard(UUID, cardID, rank)
	local total_cards = self:GetNextFreeCardIndex()

	if (total_cards > self.maxCardsPerPage) then
		dprint("SkillCardUnlockFrameMixin:TryAddCard ERROR. Attempt to add skill cards at index "..total_cards)
		return
	end

	if not(cardID) then
		SendSystemMessage("|cffFF0000ERROR. Can't find cardID for pendingIndex "..(pendingIndex or "NO PENDING INDEX"))
		return 
	end

	local card = self:AcquireCard()
	card:SetCard(cardID, rank)
	card:SetIndex(total_cards)
	card:SetUUID(UUID)

	self.cardIDToButton[total_cards] = card

	self:AllocateCard(card, total_cards)

	return total_cards
end

function SkillCardUnlockFrameMixin:AllocateCard(card, total_cards)
	local YShift = 0

	if (total_cards <= self.cardsPerRow) then -- row 1
		if (total_cards == 1) then
			card:SetPoint("CENTER", -(self.cardHalfWidth*(total_cards-1)), 0+YShift)
		else
			self.cardIDToButton[1]:ClearAndSetPoint("CENTER", -(self.cardHalfWidth*(total_cards-1)), 0+YShift)
			card:SetPoint("LEFT", self.cardIDToButton[total_cards-1], "RIGHT", self.cardSpacing, 0)
		end
	else -- row 2
		if (total_cards == (self.cardsPerRow+1)) then
			self.cardIDToButton[1]:ClearAndSetPoint("BOTTOM", self, "CENTER", -(self.cardHalfWidth*(self.cardsPerRow-1)), (self.cardSpacing/2.5)+YShift)
			card:ClearAndSetPoint("TOP", self, "CENTER", -(self.cardHalfWidth*((total_cards-self.cardsPerRow)-1)), -(self.cardSpacing/2.5)+YShift)
		else
			self.cardIDToButton[self.cardsPerRow+1]:ClearAndSetPoint("TOP", self, "CENTER", -(self.cardHalfWidth*((total_cards-self.cardsPerRow)-1)), -(self.cardSpacing/2.5)+YShift)
			card:SetPoint("LEFT", self.cardIDToButton[total_cards-1], "RIGHT", self.cardSpacing, 0)
		end
	end
end

function SkillCardUnlockFrameMixin:SetForcedUpdate(value)
	self.forcedUpdate = value
end

function SkillCardUnlockFrameMixin:GetForcedUpdate()
	return self.forcedUpdate
end

function SkillCardUnlockFrameMixin:RegisterOnUpdate()
	self.fadeOutTimer = 0
	self:SetScript("OnUpdate", self.OnUpdateCardCheck)
end

function SkillCardUnlockFrameMixin:SetBoosterBarsEnabled(value)
	value = not(value)
	self.BoosterActionBar:SetHasPendingCards(value)
	self.GoldenBoosterActionBar:SetHasPendingCards(value)
end

function SkillCardUnlockFrameMixin:ClearOnUpdate()
	for card in self.cardsCollection:EnumerateActive() do
		card:SetAlpha(1)
	end

	self:SetScript("OnUpdate", nil)
end

function SkillCardUnlockFrameMixin:OnClickDoneButton()
	if self:GetForcedUpdate() then
		return
	end
	
	self:SetForcedUpdate(true)
	self:SetBoosterBarsEnabled(false)
	self:RegisterOnUpdate()
end

function SkillCardUnlockFrameMixin:OnUpdateCardCheck(elapsed)
	if not(self:GetForcedUpdate()) then
		for card in self.cardsCollection:EnumerateActive() do

			if not(card:IsUncovered()) then 
				self:ClearOnUpdate()
				self:SetBoosterBarsEnabled(false)

				self.MassRevealNextButton:SetText(REVEAL_CARDS_BUTTON_TEXT)
				
				if card:IsForceRevealed() then
					self.MassRevealNextButton:Disable()
				else
					-- we have uncovered card and ready to mass reveal, don't wait for input and just reveal
					--if self.MassRevealNextButton:IsVisible() then
						self:OnClickStatisticsNext()
					--end
					--self.MassRevealNextButton:Enable()
				end
				return
			end

			if card:IsProgressUpdatePlaying() or card:IsRankUpdatePlaying() then
				self.MassRevealNextButton:Disable()
				self:SetBoosterBarsEnabled(false)
				return
			end
		end

		if self.duplicateGlowCollection:GetNumActive() > 0 then
			self.MassRevealNextButton:Disable()
			self:SetBoosterBarsEnabled(false)
			return
		end

		-- auto reveals next set of cards
		if SkillCardUtil.GetNumPendingCards() and (SkillCardUtil.GetNumPendingCards() > 0) then

			self:SetBoosterBarsEnabled(false)
			self.MassRevealNextButton:Disable()

			if (self.fadeOutTimer < (self.timeToFadeOut*4)) then
				self.fadeOutTimer = self.fadeOutTimer + elapsed
				return
			end

			if SkillCardsUI:IsMassRevealProcessing() then -- in mass reveal just enable next button
				self.MassRevealNextButton:SetText(NEXT)
				self.MassRevealNextButton:Enable()
				self:ClearOnUpdate()
			else -- auto reveal next cards if in normal mode
				self:OnClickDoneButton()
			end

			return
		else
			self:SetBoosterBarsEnabled(true)
		end

		if SkillCardsUI:IsMassRevealProcessing() then
			self.MassRevealNextButton:SetText(NEXT)
			self.MassRevealNextButton:Enable()
			self:ClearOnUpdate()
			--self:MassRevealFinish()
			return
		end

		self:ClearOnUpdate()
	else

		if (self.fadeOutTimer < self.timeToFadeOut) then
			self.fadeOutTimer = self.fadeOutTimer + elapsed

			for card in self.cardsCollection:EnumerateActive() do
				card:SetAlpha(1 - (self.fadeOutTimer/self.timeToFadeOut))
			end

			return
		end
	
		self:ReleaseGlows()
		self:ReleaseCards()

		self:SetForcedUpdate(false)
		self:ClearOnUpdate()
		self:LoadPendingCards()
	end
end

function SkillCardUnlockFrameMixin:OnFlipCard(index) 
	local card = self.cardIDToButton[index]

	if not(card:IsForceRevealed()) then
		local UUID = card:GetUUID()

		if not(card) or not(UUID) then
			SendSystemMessage("|cffFF0000ERROR: No card or UUID found for index "..(index or "NO INDEX"))
			return
		end

		SkillCardUtil.ClaimSkillCard(UUID)
	end

	self:RegisterOnUpdate()
end

function SkillCardUnlockFrameMixin:OnDuplicateUnlocked(card, index)
	local glow = self:AcquireGlow()
	card = card or self.cardIDToButton[index]

	glow:SetFrameLevel(card:GetFrameLevel()+10)
	glow:ClearAndSetPoint("CENTER", card, 0, 0)
	glow:SetQuality(card:GetQuality())
	Timer.After(0.5, function() glow:PlayMove() end)
end

function SkillCardUnlockFrameMixin:OnReleaseGlow(glow)
	self.FreeBooster:UpdateProgressBar()

	self.duplicateGlowCollection:Release(glow)
	self:RegisterOnUpdate()
end

function SkillCardUnlockFrameMixin:UpdateCardsTotal()
	--local value = SkillCardUtil.GetNumPendingCards()

	--[[if value <= 0 then
		self.CardCounter:Hide()
	else
		self.CardCounter:Show()
		self.CardCounter:SetText(REVEAL_CARDS_LABEL..": "..value)
	end]]--

	dprint("UpdateCardsTotal")

	if SkillCardsUI:IsMassRevealProcessing() then
		local count = self:GetNewCardsCount()
		dprint("Setup new text for MassRevealNewPendingText")
		self.MassRevealNewPendingText:SetText(string.format(MASS_REVEAL_TITLE, count))
	end
end

--
-- Auto reveal specific skill card (duplicate)
--
function SkillCardUnlockFrameMixin:SetAutoRevealCard(cardID, rank)
	self.autoRevealCard = {cardID = cardID, rank = rank}
end

function SkillCardUnlockFrameMixin:SetAutoRevealDuplicate(value)
	self.autoRevealDuplicate = value
end

function SkillCardUnlockFrameMixin:GetAutoRevealDuplicate()
	return self.autoRevealDuplicate
end

function SkillCardUnlockFrameMixin:GetAutoRevealCard()
	if not(self.autoRevealCard) then
		return
	end

	return self.autoRevealCard.cardID, self.autoRevealCard.rank
end

function SkillCardUnlockFrameMixin:LoadAutoRevealCard()
	local cardID, rank = self:GetAutoRevealCard()

	if not(cardID) then 
		return false
	end

	local total_cards = self:TryAddCard(nil, cardID, rank)

	if not(total_cards) then
		return
	end

	self.cardIDToButton[total_cards]:ForceReveal()

	self:SetAutoRevealCard(nil)

	if (self:GetAutoRevealDuplicate()) then
		self:BONUS_SEALED_CARD_PACK_PROGRESS_UPDATE(cardID)
	end

	self:SetAutoRevealDuplicate(nil)
	self:RegisterOnUpdate()
	return true
end

--
-- Mass reveal
--

function SkillCardUnlockFrameMixin:GetMassRevealStatistics()
	return self.MassRevealStatisticsFrame
end

function SkillCardUnlockFrameMixin:OnStatisticsExit()
	BaseFrameFadeOut(self.MassRevealStatisticsFrame)
	SkillCardsUI:SetMassRevealProcessing(false)
	self:OnClickDoneButton()
	self.FreeBooster:UpdateProgressBar()
	self.GoldenBoosterActionBar:ScanBags()
	self.BoosterActionBar:ScanBags()
end

function SkillCardUnlockFrameMixin:OnMassRevealAnimationFinished()
	dprint("SkillCardUnlockFrameMixin:OnMassRevealAnimationFinished")
	BaseFrameFadeOut(self.MassRevealStatisticsFrame)
	self:OnClickDoneButton()
	self:UpdateCardsTotal()
end

function SkillCardUnlockFrameMixin:InitStatistics()
	if not(self.MassRevealStatisticsFrame:IsVisible()) then 
		self.MassRevealStatisticsFrame:Init() 
		BaseFrameFadeIn(self.MassRevealStatisticsFrame) 
	end
end

function SkillCardUnlockFrameMixin:GetNewCardsCount()
	local count = 0

	local cardIDs = {} -- to avoid duplicates in new cards count

	for pendingIndex = 1, SkillCardUtil.GetNumPendingCards() do
		local _, cardID = SkillCardUtil.GetPendingSkillCardAtIndex(pendingIndex)

		if not(C_SkillCardCollection.IsCollected(cardID)) then
			if not(cardIDs[cardID]) then
				count = count + 1
				cardIDs[cardID] = pendingIndex
			end
		end
	end

	return count, cardIDs
end

function SkillCardUnlockFrameMixin:MassRevealFinish()
	if not(self.MassRevealStatisticsFrame.StatisticsFrame:IsVisible()) then 
		SkillCardsUI:SetMassRevealDuplicates(SkillCardUtil.GetNumPendingCards())

		self:GetMassRevealStatistics():ShowStatistics()
		self:HideMassRevealControls()
		BaseFrameFadeIn(self.MassRevealStatisticsFrame) 

		self.MassRevealStatisticsFrame:RegisterOnUpdate()
	end
end

function SkillCardUnlockFrameMixin:GetNewCardsPendingIndexes()
	local indexes = {}
	local _, cardIDs = self:GetNewCardsCount()

	if next(cardIDs) then
		for _, v in pairs(cardIDs) do
			table.insert(indexes, v)
		end
	end

	return #indexes, indexes
end

function SkillCardUnlockFrameMixin:OnClickStatisticsNext()
	local UUIDs = {}

	for card in self.cardsCollection:EnumerateActive() do
		if not(card:IsUncovered()) and not(card:IsForceRevealed()) then 
			table.insert(UUIDs, card:GetUUID())
			card:ForceReveal()
		end
	end

	if next(UUIDs) then
		SkillCardUtil.ClaimSkillCard(UUIDs)
		self.MassRevealNextButton:Disable()
		return
	else
		self:OnClickDoneButton()
	end
end
--
-- Events and load pending
--
function SkillCardUnlockFrameMixin:ShowMassRevealControls()
	self.FreeBooster:SetAlpha(0) -- crutch, for not to break progress updates
	self.GoldenTickets:Hide()
	self.NormalTickets:Hide()

	self.MassRevealNewPendingShadow:Show()
	self.MassRevealNewPendingText:Show()
	self.MassRevealNextButton:Show()
end

function SkillCardUnlockFrameMixin:HideMassRevealControls()
	self.FreeBooster:SetAlpha(1) -- crutch, for not to break progress updates
	self.GoldenTickets:Show()
	self.NormalTickets:Show()

	self.MassRevealNewPendingShadow:Hide()
	self.MassRevealNewPendingText:Hide()
	self.MassRevealNextButton:Hide()
end

function SkillCardUnlockFrameMixin:LoadPendingCards() -- loads last pending cards in list
	if self:GetAutoRevealCard() and self:LoadAutoRevealCard() then
		return
	end

	if SkillCardsUI:IsMassRevealProcessing() then -- load only new cards
		local newCardsCount, pendingIndexes = self:GetNewCardsPendingIndexes()

		if newCardsCount > 0 then
			local nextSkillCardIndex = self:GetNextFreeCardIndex()
			local pendingIndex = 1

			for i = nextSkillCardIndex, math.min(#pendingIndexes, self.maxCardsPerPage) do
				self:TryAddCard(SkillCardUtil.GetPendingSkillCardAtIndex(pendingIndexes[pendingIndex]))
				pendingIndex = pendingIndex + 1
			end

			self:ShowMassRevealControls()
		else
			self:MassRevealFinish()
		end
	else -- regular pending cards loading
		self:HideMassRevealControls()
		local pendingCards = SkillCardUtil.GetNumPendingCards()
		
		if pendingCards and (pendingCards > 0) then
			local nextSkillCardIndex = self:GetNextFreeCardIndex()
			local pendingIndex = pendingCards - (math.min(pendingCards, self.maxCardsPerPage) - nextSkillCardIndex) -- to load pedning cards in ascending order

			for i = nextSkillCardIndex, math.min(pendingCards, self.maxCardsPerPage) do
				self:TryAddCard(SkillCardUtil.GetPendingSkillCardAtIndex(pendingIndex))
				pendingIndex = pendingIndex + 1
			end
		end
	end

	self:RegisterOnUpdate()
end

function SkillCardUnlockFrameMixin:OnBoosterResultsDisplayed(hasResults)
	if not(self.BoosterActionBar:HasActive()) and not(self.GoldenBoosterActionBar:HasActive()) then
		self.NoResultsText:Show()
		self.NoResultsShadow:Show()
	else
		self.NoResultsText:Hide()
		self.NoResultsShadow:Hide()
	end
end

function SkillCardUnlockFrameMixin:PENDING_SKILL_CARD_ADDED(pendingIndex, cardID, rank)
	--dprint("SkillCardUnlockFrameMixin:PENDING_SKILL_CARD_ADDED ("..pendingIndex..", "..cardID..", "..rank..")")

	if self.MassRevealStatisticsFrame:IsVisible() or SkillCardsUI:IsWaitingToRevealMultiplePacks() then
		return
	end

	self:UpdateCardsTotal()
	self:OnClickDoneButton()
end

function SkillCardUnlockFrameMixin:SKILL_CARD_COLLECTION_ITEM_USED(...)
	local itemID = ...

	local cardType = SkillCardUtil.DefineCardType(itemID)

	if cardType then
		if not self.BoosterActionBar:UseItemID(itemID) then
			self.GoldenBoosterActionBar:UseItemID(itemID)
		end
	end
end

function SkillCardUnlockFrameMixin:SKILL_CARD_AUTO_REVEALED(cardID, rank)
	self:UpdateCardsTotal()
	self:SetAutoRevealCard(cardID, rank)
	self:OnClickDoneButton()
end

function SkillCardUnlockFrameMixin:CLAIM_SKILL_CARD_RESULT()
	self:UpdateCardsTotal()
end

function SkillCardUnlockFrameMixin:PENDING_SKILL_CARD_REMOVED(pendingIndex, cardID)
	--dprint("SkillCardUnlockFrameMixin:PENDING_SKILL_CARD_REMOVED "..pendingIndex)
	for card in self.cardsCollection:EnumerateActive() do
		if cardID == card:GetCardID() then
			card:RefreshProgress()
		end
	end
end

function SkillCardUnlockFrameMixin:BONUS_SEALED_CARD_PACK_PROGRESS_UPDATE(cardID)
	for card in self.cardsCollection:EnumerateActive() do
		if cardID == card:GetCardID() then
			self:OnDuplicateUnlocked(card)
		end
	end

	-- exception for SKILL_CARD_AUTO_REVEALED. BONUS_SEALED_CARD_PACK_PROGRESS_UPDATE happends so fast that it doesn't update collection
	if self:GetAutoRevealCard() and (self:GetAutoRevealCard() == cardID) then
		self:SetAutoRevealDuplicate(true)
	end
end

function SkillCardUnlockFrameMixin:BAG_UPDATE()
	self.GoldenTickets:UpdateDisplay()
	self.NormalTickets:UpdateDisplay()

	-- track how many new reward items we get while frame is open
	if SkillCardsUI:IsMassRevealProcessing() then
		for itemID, total in pairs(self.statisticsRewardItems) do
			local count = GetItemCount(itemID)
			local diff = count - total

			if diff > 0 then
				SkillCardsUI:AddMassRevealRewardItem(itemID, diff)
			end

			self.statisticsRewardItems[itemID] = count
		end
	end
end

function SkillCardUnlockFrameMixin:Layout()
	self.Background:ClearAllPoints()
	self.Background:SetAtlas("SkillCardBoosterBG", Const.TextureKit.UseAtlasSize)
	self.Background:SetPoint("TOP", 0, -2)

	self.ShadowGradient:Hide()

	self.FreeBooster = CreateFrame("FRAME", "$parent.FreeBooster", self, nil)
	self.FreeBooster:SetPoint("TOP", 0, -24)
	MixinAndLoadScripts(self.FreeBooster, SkillCardFreeBoosterMixin)

	self.GoldenTickets = CreateFrame("BUTTON", "$parent.GoldenTickets", self)
	self.GoldenTickets:SetPoint("TOP", self.FreeBooster, "BOTTOM", 0, 0)
	MixinAndLoadScripts(self.GoldenTickets, SkillCardAnimatedCurrencyMixin)

	self.NormalTickets = CreateFrame("BUTTON", "$parent.NormalTickets", self)
	self.NormalTickets:SetPoint("TOP", self.GoldenTickets, "BOTTOM", 0, 6)
	MixinAndLoadScripts(self.NormalTickets, SkillCardAnimatedCurrencyMixin)

	self.BoosterActionBar = CreateFrame("FRAME", "$parent.BoosterActionBar", self, nil)
	self.BoosterActionBar:SetPoint("BOTTOMLEFT", 0, 8)
	MixinAndLoadScripts(self.BoosterActionBar, SkillCardBoosterActionBarMixin)
	self.BoosterActionBar:SetJustifyH("LEFT")
	self.BoosterActionBar.Title:SetText(UNLOCK_SKILL_CARDS_TITLE)
	self.BoosterActionBar.Art:SetAtlas("SkillCardBoosterArt1", Const.TextureKit.UseAtlasSize)
	self.BoosterActionBar.Art:SetPoint("BOTTOMLEFT", self, 0, 0)

	self.GoldenBoosterActionBar = CreateFrame("FRAME", "$parent.GoldenBoosterActionBar", self, nil)
	self.GoldenBoosterActionBar:SetPoint("BOTTOMRIGHT", 0, 8)
	MixinAndLoadScripts(self.GoldenBoosterActionBar, SkillCardBoosterActionBarMixin)
	self.GoldenBoosterActionBar:SetJustifyH("RIGHT")
	self.GoldenBoosterActionBar.Title:SetText(UNLOCK_GOLDEN_CARDS_TITLE)
	self.GoldenBoosterActionBar.Art:SetAtlas("SkillCardBoosterArt2", Const.TextureKit.UseAtlasSize)
	self.GoldenBoosterActionBar.Art:SetPoint("BOTTOMRIGHT", self, 0, 0)

	self.NoResultsText = self:CreateFontString(nil, "OVERLAY")
	self.NoResultsText:SetPoint("BOTTOM", 0, 24)
	self.NoResultsText:SetFontObject(GameFontDisableLarge)
	self.NoResultsText:SetText(SKILL_CARD_NO_BOOSTERS)
	self.NoResultsText:SetWidth(300)
	self.NoResultsText:Hide()

	self.NoResultsShadow = self:CreateTexture(nil, "ARTWORK")
	self.NoResultsShadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.NoResultsShadow:SetHeight(64)
	self.NoResultsShadow:SetWidth(600)
	self.NoResultsShadow:SetPoint("CENTER", self.NoResultsText, "TOP", 0, -8)
	self.NoResultsShadow:SetAlpha(1)
	self.NoResultsShadow:Hide()

	--[[self.AutoRevealCheckButton = CreateFrame("CheckButton", "$parent.AutoRevealCheckButton", self, "UICheckButtonTemplate")
	self.AutoRevealCheckButton.Text:SetFontObject(GameFontNormal)
	self.AutoRevealCheckButton.Text:SetText(SKILL_CARD_QUICK_REVEAL_TITLE)
	self.AutoRevealCheckButton:SetPoint("LEFT", self.GoldenTickets, "RIGHT", 172, 0)
	
	self.CardCounter = self:CreateFontString(nil, "OVERLAY")
	self.CardCounter:SetPoint("TOPLEFT", self.AutoRevealCheckButton.Text, "BOTTOMLEFT", 0, -8)
	self.CardCounter:SetFontObject(GameFontHighlight)]]--

	self.MassRevealStatisticsFrame = CreateFrame("FRAME", "$parent.MassRevealStatisticsFrame", self, nil)
	self.MassRevealStatisticsFrame:SetPoint("CENTER", 0, 0)
	self.MassRevealStatisticsFrame:SetFrameLevel(self:GetFrameLevel()+15)
	self.MassRevealStatisticsFrame:Hide()
	MixinAndLoadScripts(self.MassRevealStatisticsFrame, SkillCardMassRevealStatsMixin)

	self.MassRevealNewPendingText = self:CreateFontString(nil, "OVERLAY")
	self.MassRevealNewPendingText:SetPoint("CENTER", self.GoldenTickets, 0, 0)
	self.MassRevealNewPendingText:SetFontObject(GameFontHighlightLarge)
	self.MassRevealNewPendingText:SetWidth(300)
	self.MassRevealNewPendingText:SetText(MASS_REVEAL_TITLE)
	self.MassRevealNewPendingText:Hide()

	self.MassRevealNewPendingShadow = self:CreateTexture(nil, "ARTWORK")
	self.MassRevealNewPendingShadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.MassRevealNewPendingShadow:SetHeight(64)
	self.MassRevealNewPendingShadow:SetWidth(600)
	self.MassRevealNewPendingShadow:SetPoint("CENTER", self.MassRevealNewPendingText, "TOP", 0, -8)
	self.MassRevealNewPendingShadow:SetAlpha(1)
	self.MassRevealNewPendingShadow:Hide()

	self.MassRevealNextButton = CreateFrame("BUTTON", "$parent.MassRevealNextButton", self, "RedButtonTemplate")
	self.MassRevealNextButton:SetSize(128, 44)
	self.MassRevealNextButton:SetText(NEXT)
	self.MassRevealNextButton:SetPoint("BOTTOMRIGHT", -196, 128)
	self.MassRevealNextButton:Hide()
end
