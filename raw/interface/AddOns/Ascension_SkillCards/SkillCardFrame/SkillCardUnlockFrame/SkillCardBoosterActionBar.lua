PURCHASE_SEALED_CARD_UNCLAIMED_CARDS = PURCHASE_SEALED_CARD_UNCLAIMED_CARDS or "You already have a pending Skill Card."
-------------------------------------------------------------------------------
--                               Action Button                               --
-------------------------------------------------------------------------------
SkillCardBoosterActionButtonMixin = CreateFromMixins(ExtraActionButtonMixin)

function SkillCardBoosterActionButtonMixin:OnLoad()
	ExtraActionButtonMixin.OnLoad(self)
	self:Layout()
end

function SkillCardBoosterActionButtonMixin:Init(index, itemID)
	self.index = index
	self:SetAction("ACTION_TYPE_ITEM", itemID, itemID)
end

function SkillCardBoosterActionButtonMixin:OnUpdate(elapsed)
	ExtraActionButtonMixin.OnUpdate(self, elapsed)

	-- display if count == 1
	local actionType = self:GetAttribute("type")
	local count = 0

	if actionType == "ACTION_TYPE_ITEM" then
		count = GetItemCount(self.actionID, false, true)
	end

	if count and count >= 1 then
		self.Count:SetText(count)

		self:SetEnabled(not(self:GetHasPendingCards()))

		if self:IsMouseOver() then
			self:OnEnter()
		end
	end
end

function SkillCardBoosterActionButtonMixin:OnClick()
	local cardType = SkillCardUtil.DefineCardType(self.actionID)

	if not(cardType) then
		ExtraActionButtonMixin.OnClick(self)
		return
	end

	local count = GetItemCount(self.actionID, false, true)

	if count <= 0 then
		return
	end

	local canPurchase, reason = C_SkillCardCollection.CanPurchaseSealedCard(cardType, 1)

	if not(canPurchase) then 
		SkillCardBoosterPurchaseButtonMixin.HandlePurchaseSkillCardError(nil, reason)
		return
	end

	if SkillCardsUI:GetAutoReveal() and (count > 1) then
		local massRevealStatistics = self:GetParent():GetParent():GetMassRevealStatistics()

		if massRevealStatistics:IsVisible() then
			massRevealStatistics:Hide()
		end

		count = math.min(count, 200)

		local function func()
			local canPurchase, reason = C_SkillCardCollection.CanPurchaseSealedCard(cardType, count)

			if canPurchase then
				massRevealStatistics:SetCardStyle(self:GetParent():GetJustifyH() == "RIGHT") -- make cards golden if it is a golden booster
				
				SkillCardsUI:SetWaitingForToOpenPacks(count)
				C_SkillCardCollection.PurchaseSealedCard(cardType, count)
			end
		end

		local item = Item:CreateFromID(self.actionID)
		local link = item and item:GetLink() or ""

		StaticPopup_Show("BATTLENET_UNAVAILABLE")
		StaticPopup_Show("CONFIRM_SKILL_CARD_MASS_PURCHASE", count.." "..link, nil, func)
		StaticPopup_Hide("BATTLENET_UNAVAILABLE")
	else
		dprint("C_SkillCardCollection.PurchaseSealedCard("..cardType..", 1)")
		C_SkillCardCollection.PurchaseSealedCard(cardType, 1)
	end
end

--[[function SkillCardBoosterActionButtonMixin:OnEnter()
	ExtraActionButtonMixin.OnEnter(self)
	GameTooltip:AddLine(HOLD_SHIFT_TO_OPEN_MULTIPLE_BOOSTERS, 0, 0.8, 1, true)
	GameTooltip:Show()
end]]--

function SkillCardBoosterActionButtonMixin:OnEnable()
	ExtraActionButtonMixin.OnEnable(self)
	self.DisabledOverlay:Hide()
end

function SkillCardBoosterActionButtonMixin:OnDisable()
	ExtraActionButtonMixin.OnDisable(self)
	self.DisabledOverlay:Show()
end

function SkillCardBoosterActionButtonMixin:SetHasPendingCards(value)
	self.parentHasPendingCards = value

	if (value) then
		self:SetAttribute("disable-tooltipTitle", CANT_USE_ITEM)
		self:SetAttribute("disable-tooltipText", PURCHASE_SEALED_CARD_UNCLAIMED_CARDS)
	else
		self:SetAttribute("disable-tooltipTitle", nil)
		self:SetAttribute("disable-tooltipText", nil)
	end
end

function SkillCardBoosterActionButtonMixin:GetHasPendingCards()
	return self.parentHasPendingCards
end

function SkillCardBoosterActionButtonMixin:Maximize()
	self:SetScale(1)
end

function SkillCardBoosterActionButtonMixin:Layout()
	self.Icon:ClearAllPoints()
	self.Icon:SetSize(50, 50)
	self.Icon:SetPoint("CENTER", 0, 0)

	self.DisabledOverlay = self:CreateTexture(nil, "BORDER")
	self.DisabledOverlay:SetSize(50, 50)
	self.DisabledOverlay:SetPoint("CENTER")
	self.DisabledOverlay:SetTexture(0, 0, 0, 0.7)
	self.DisabledOverlay:Hide()

    self.Art:Hide()
end

-------------------------------------------------------------------------------
--                             Action Button Plus                            --
-------------------------------------------------------------------------------
SkillCardBoosterPurchaseButtonMixin = {}

function SkillCardBoosterPurchaseButtonMixin:OnLoad()
	self:Layout()
end

function SkillCardBoosterPurchaseButtonMixin:OnEnable()
	SkillCardBoosterActionButtonMixin.OnEnable(self)
end

function SkillCardBoosterPurchaseButtonMixin:OnDisable()
	SkillCardBoosterActionButtonMixin.OnDisable(self)
end

function SkillCardBoosterPurchaseButtonMixin:Maximize()
	SkillCardBoosterActionButtonMixin.Maximize(self)
end

function SkillCardBoosterPurchaseButtonMixin:Init(optionID)
	local cardType, icon, tooltipTitle, tooltipText, dialogueTextArg2 = self:GetParent():GetPurchaseOptionData(optionID)

	if not(icon) then
		return
	end

	self:SetAttribute("cardType", cardType)
	self:SetAttribute("tooltipTitle", tooltipTitle)
	self:SetAttribute("tooltipText", tooltipText)
	self:SetAttribute("dialogueTextArg2", dialogueTextArg2)

	self.Icon:SetTexture(icon)
end

function SkillCardBoosterPurchaseButtonMixin:AddTooltipCost()
	local cardType = self:GetAttribute("cardType")

	if not(cardType) then
		return
	end

	local itemID, count = C_SkillCardCollection.GetSealedCardCost(cardType, 1)

	if not(itemID) then
		return
	end

	local item = Item:CreateFromID(itemID)

	if (item) then
		local color = GREEN_FONT_COLOR

		if count > GetItemCount(item:GetItemID()) then
			color = RED_FONT_COLOR
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(COSTS_LABEL.." "..color:WrapText(count).." "..item:GetLink().." "..CreateSimpleTextureMarkup(item:GetIcon(), 16, 16, 0, 0))
		GameTooltip:AddLine(SKILL_CARD_PURCHASE_COST_INCREASE, nil, nil, nil, true)
	end
end

function SkillCardBoosterPurchaseButtonMixin:OnEnter()
	local title = self:GetAttribute("tooltipTitle")
	local text = self:GetAttribute("tooltipText")

	if self:GetParent():GetJustifyH() == "LEFT" then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end

	if title then
		GameTooltip:AddLine(title, 1, 1, 1)
	end

	if text then
		GameTooltip:AddLine(text, nil, nil, nil, true)
	end

	self:AddTooltipCost()

	if self:IsEnabled() == 0 then
		local title = self:GetAttribute("disable-tooltipTitle")
		local text = self:GetAttribute("disable-tooltipText")

		if title then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(title, 1, 0, 0)
		end

		if text then
			GameTooltip:AddLine(text, nil, nil, nil, true)
		end
	end

	GameTooltip:Show()
end

function SkillCardBoosterPurchaseButtonMixin:OnLeave()
	GameTooltip:Hide()
end

function SkillCardBoosterPurchaseButtonMixin:HandlePurchaseSkillCardError(reason)
	if (reason[1] == "PURCHASE_SEALED_CARD_NO_TOKEN") then
		reason = ERR_VENDOR_MISSING_TURNINS
	else
		reason = _G[reason[1]] or reason[1]
	end

	SendSystemMessage("|cffFF0000"..reason.."|r")
	UIErrorsFrame:AddMessage(reason, 1, 0, 0)
end

function SkillCardBoosterPurchaseButtonMixin:OnClick()
	local cardType = self:GetAttribute("cardType") or ""

	local canPurchase, reason = C_SkillCardCollection.CanPurchaseSealedCard(cardType, 1)

	if canPurchase then
		local itemID, count = C_SkillCardCollection.GetSealedCardCost(cardType, 1)
		local item = Item:CreateFromID(itemID)
		local link = item and item:GetLink() or ""
		StaticPopup_Show("BATTLENET_UNAVAILABLE")
		StaticPopup_Show("CONFIRM_SKILL_CARD_PURCHASE", count.." "..link, self:GetAttribute("dialogueTextArg2"), cardType)
		StaticPopup_Hide("BATTLENET_UNAVAILABLE")
	else
		self:HandlePurchaseSkillCardError(reason)
	end
end

function SkillCardBoosterPurchaseButtonMixin:Layout()
	SkillCardBoosterActionButtonMixin.Layout(self)
	--self.Icon:SetAtlas("itemupgrade_greenplusicon", Const.TextureKit.IgnoreAtlasSize)
end
-------------------------------------------------------------------------------
--                          Skill Card Booster Frame                         --
-------------------------------------------------------------------------------
SkillCardBoosterActionBarMixin = CreateFromMixins(CallbackRegistryMixin)
SkillCardBoosterActionBarMixin.boostersPerRowDefault = 5
SkillCardBoosterActionBarMixin.boostersPerRowMinimized = 8
SkillCardBoosterActionBarMixin.boostersPerRow = 5

function SkillCardBoosterActionBarMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:SetScript("OnEvent", OnEventToMethod)
	self:RegisterEvent("PURCHASE_SEALED_CARD_RESULT")

	self:GenerateCallbackEvents({
		"OnResultsDisplayed",
	})

	self.boosterHalfWidth = nil
	self.boosterSpacing = 4
	self.boostersCollection = CreateFramePoolCollection()
	self.boosterIDToButton = {}

	self.purchaseButtonCollection = CreateFramePoolCollection()
	self.purchaseOptions = {}

	self.boosterItemsRO = {}
	self.boosterItemsSorted = {}

	self:Layout()
end

function SkillCardBoosterActionBarMixin:OnShow()
	self:RegisterEvent("BONUS_SEALED_CARD_PACK_REWARDED")
	self:ScanBags()
end

function SkillCardBoosterActionBarMixin:OnHide()
	self:UnregisterEvent("BONUS_SEALED_CARD_PACK_REWARDED")
end

function SkillCardBoosterActionBarMixin:HasActive()
	return self.boostersCollection:GetNumActive() and (self.boostersCollection:GetNumActive() > 0)
end

function SkillCardBoosterActionBarMixin:Acquire(frameType, collection, template)
	local pool, isNewPool = collection:GetOrCreatePool(frameType, self, template, nil)

	local checkButton, isNew = pool:Acquire()

	checkButton:Show()

	if not(self.boosterHalfWidth) then
		self.boosterHalfWidth = checkButton:GetWidth()/2+(self.boosterSpacing/2)
	end

	return checkButton
end

function SkillCardBoosterActionBarMixin:AcquirePurchaseButton()
	return self:Acquire("Button", self.purchaseButtonCollection, "SkillCardBoosterPurchaseButton")
end

function SkillCardBoosterActionBarMixin:AcquireBooster()
	return self:Acquire("CheckButton", self.boostersCollection, "SkillCardBoosterActionButton")
end

function SkillCardBoosterActionBarMixin:ReleasePurchaseButtons()
	self.purchaseButtonCollection:ReleaseAll()
end

function SkillCardBoosterActionBarMixin:ReleaseBoosters()
	wipe(self.boosterIDToButton)
	self.boostersCollection:ReleaseAll()
end

function SkillCardBoosterActionBarMixin:SetHasPendingCards(value)
	for booster in self.boostersCollection:EnumerateActive() do
		booster:SetHasPendingCards(value)
	end

	for purchaseOption in self.purchaseButtonCollection:EnumerateActive() do
		if value then
			purchaseOption:SetAttribute("disable-tooltipTitle", CANT_USE_ITEM)
			purchaseOption:SetAttribute("disable-tooltipText", PURCHASE_SEALED_CARD_UNCLAIMED_CARDS)
			purchaseOption:Disable()
		else
			purchaseOption:SetAttribute("disable-tooltipTitle", nil)
			purchaseOption:SetAttribute("disable-tooltipText", nil)
			purchaseOption:Enable()
		end
	end
end

function SkillCardBoosterActionBarMixin:OnResultsDisplayed(hasResults, total_boosters)
	if hasResults and not(total_boosters > (self.boostersPerRowDefault*2)) then
		self.Title:Show()
		self.TitleShadow:Show()
		self.Art:Show()
	else
		self.Title:Hide()
		self.TitleShadow:Hide()
		self.Art:Hide()
	end

	self:TriggerEvent("OnResultsDisplayed", hasResults)
end

function SkillCardBoosterActionBarMixin:AllocateBoosters(inventoryList)
	self:ReleasePurchaseButtons()
	self:ReleaseBoosters()

	local itemID = nil
	local total_boosters = self:GetTotalBoosters() + self:GetNumPurchaseOptions()

	if total_boosters > (self.boostersPerRowDefault * 2) then
		self.boostersPerRow = self.boostersPerRowMinimized
	else
		self.boostersPerRow = self.boostersPerRowDefault
	end

	if total_boosters > 0 then
		-- First pass: acquire, initialize, and maximize all buttons
		for i = 1, total_boosters do
			local checkButton

			if (i <= self:GetTotalBoosters()) then -- set up regular booster action button
				itemID = inventoryList[i]

				checkButton = self:AcquireBooster()
				checkButton:Init(i, itemID)
			else
				checkButton = self:AcquirePurchaseButton()
				checkButton:Init(i - self:GetTotalBoosters())
			end

			checkButton:Maximize()
			self.boosterIDToButton[i] = checkButton
		end

		-- Now perform layout positioning using mathematical grid calculations
		local firstButton = self.boosterIDToButton[1]
		local buttonWidth = firstButton:GetWidth()
		local buttonHeight = firstButton:GetHeight()
		local spacing = self.boosterSpacing

		local numRows = math.ceil(total_boosters / self.boostersPerRow)
		local gridHeight = (numRows * buttonHeight) + ((numRows - 1) * spacing)
		local startY = (gridHeight / 2) - (buttonHeight / 2)

		local lastRow = -1
		local itemsInThisRow, rowWidth, startX

		for i = 1, total_boosters do
			local checkButton = self.boosterIDToButton[i]
			local row = math.floor((i - 1) / self.boostersPerRow)
			local col = (i - 1) % self.boostersPerRow -- FIX: Added local scope

			-- Optimize: Compute row-specific constants only when entering a new row
			if row ~= lastRow then
				lastRow = row
				itemsInThisRow = math.min(self.boostersPerRow, total_boosters - (row * self.boostersPerRow))
				rowWidth = (itemsInThisRow * buttonWidth) + ((itemsInThisRow - 1) * spacing)

				if self:GetJustifyH() == "LEFT" then
					if self.boostersPerRow == self.boostersPerRowMinimized then
						startX = spacing * 8
					else
						startX = spacing
					end
				elseif self:GetJustifyH() == "RIGHT" then
					if self.boostersPerRow == self.boostersPerRowMinimized then
						startX = -spacing * 8
					else
						startX = -spacing
					end
				else -- "CENTER" or fallback
					startX = -(rowWidth / 2) + (buttonWidth / 2)
				end
			end

			local xOffset
			if self:GetJustifyH() == "RIGHT" then
				xOffset = startX - (col * (buttonWidth + spacing))
			else
				xOffset = startX + (col * (buttonWidth + spacing))
			end

			local yOffset = startY - (row * (buttonHeight + spacing))

			if self:GetJustifyH() == "LEFT" then
				if self.boostersPerRow == self.boostersPerRowMinimized then
					checkButton:ClearAndSetPoint("LEFT", self, "LEFT", xOffset, yOffset)
				else
					checkButton:ClearAndSetPoint("LEFT", self.Title, "RIGHT", xOffset, yOffset)
				end
			elseif self:GetJustifyH() == "RIGHT" then
				if self.boostersPerRow == self.boostersPerRowMinimized then
					checkButton:ClearAndSetPoint("RIGHT", self, "RIGHT", xOffset, yOffset)
				else
					checkButton:ClearAndSetPoint("RIGHT", self.Title, "LEFT", xOffset, yOffset)
				end
			else -- "CENTER"
				checkButton:ClearAndSetPoint("CENTER", self, "CENTER", xOffset, yOffset)
			end
		end

		self:OnResultsDisplayed(true, total_boosters)
	else
		self:OnResultsDisplayed(false, total_boosters)
	end
end

function SkillCardBoosterActionBarMixin:GetVisibleButtonCount()
	return self:GetTotalBoosters()
end

function SkillCardBoosterActionBarMixin:ScanBags()
	local inventoryListRO = {}
	local inventoryListSorted = {unpack(self.boosterItemsSorted)}

	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)
			if itemLink then

				local item = Item:CreateFromLink(itemLink)
				local itemID = item and item:GetItemID()

				if item and self:GetBoosters()[itemID] then
					if not(inventoryListRO[itemID]) then
						inventoryListRO[itemID] = true
					end
				end
			end
		end
	end

	for i = #inventoryListSorted, 1, -1 do
		local itemID = inventoryListSorted[i]

		if (itemID) then
			if not(inventoryListRO[itemID]) then
				table.remove(inventoryListSorted, i)
			end
		end
	end

	self:SetTotalBoosters(#inventoryListSorted)
	self:AllocateBoosters(inventoryListSorted)
end

function SkillCardBoosterActionBarMixin:SetTotalBoosters(value)
	self.totalBoosters = value
end

function SkillCardBoosterActionBarMixin:GetTotalBoosters()
	return self.totalBoosters
end

function SkillCardBoosterActionBarMixin:SetBoosters(value)
	self.boosterItemsRO = value

	for itemID, pos in pairs(self.boosterItemsRO) do
		self.boosterItemsSorted[pos] = itemID
	end

	self:ScanBags()
end

function SkillCardBoosterActionBarMixin:AddPurchaseOption(data)
	table.insert(self.purchaseOptions, {data.cardType, data.icon, data.tooltipTitle, data.tooltipText, data.dialogueTextArg2})
end

function SkillCardBoosterActionBarMixin:GetPurchaseOptionData(index)
	if not(self.purchaseOptions[index]) then
		return
	end

	return unpack(self.purchaseOptions[index])
end

function SkillCardBoosterActionBarMixin:GetNumPurchaseOptions()
	return #self.purchaseOptions
end

function SkillCardBoosterActionBarMixin:GetBoosters()
	return self.boosterItemsRO or {}
end

function SkillCardBoosterActionBarMixin:UseItemID(itemID)
	for booster in self.boostersCollection:EnumerateActive() do
		if booster.actionID and (booster.actionID == itemID)  then
			booster:OnClick()
			return true
		end
	end
end

function SkillCardBoosterActionBarMixin:BONUS_SEALED_CARD_PACK_REWARDED()
	--dprint("SkillCardBoosterActionBarMixin:BONUS_SEALED_CARD_PACK_REWARDED")

	if self:GetParent():GetMassRevealStatistics():IsVisible() then
		return
	end

	Timer.After(1, GenerateClosure(self.ScanBags, self)) -- to cover delay between a bunch of BAG_UPDATE and our event
end

function SkillCardBoosterActionBarMixin:PURCHASE_SEALED_CARD_RESULT(result)
	dprint("SkillCardBoosterActionBarMixin:PURCHASE_SEALED_CARD_RESULT", result)
	if result ~= "PURCHASE_SEALED_CARD_OK" then
		SkillCardUtil.HandleError(result)
	end
end

function SkillCardBoosterActionBarMixin:SetJustifyH(value)
	self.justifyH = value
	self.Title:ClearAndSetPoint(value, ((value == "RIGHT") and -1 or 1)*24, 0)
	self.Title:SetJustifyH(value)
end

function SkillCardBoosterActionBarMixin:GetJustifyH()
	return self.justifyH
end

function SkillCardBoosterActionBarMixin:Layout()
	self:SetSize(512, 64)
	--self:SetBackdrop(GameTooltip:GetBackdrop())

	self.Title = self:CreateFontString(nil, "OVERLAY")
	self.Title:SetSize(128, 64)
	self.Title:SetFontObject(GameFontHighlightMedium)
	self.Title:SetPoint("LEFT")
	self.Title:SetVertexColor(1, 0.82, 0)

	self.TitleShadow = self:CreateTexture(nil, "ARTWORK")
	self.TitleShadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.TitleShadow:SetPoint("CENTER", self.Title, 0, 0)
	self.TitleShadow:SetHeight(64)
	self.TitleShadow:SetWidth(192)
	self.TitleShadow:SetAlpha(1)

	self.Art = self:CreateTexture(nil, "BACKGROUND")
end