RecoveryItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

local RecoveryCategoryUpdateFunction = {}
local CachedQuests = {}
local CachedItems = {}

function RecoveryItemMixin:Init(...)
	ScrollListItemBaseMixin.Init(self, ...)
	self.Icon:SetBorderSize(52, 52)
	self:SetNormalAtlas("auctionhouse-background-buy-noncommodities-header")
	self:SetHighlightAtlas("search-highlight")
end

function RecoveryItemMixin:Update()
	self:ClearTooltip()
	self.category = self:GetScrollList():GetParent():GetCurrentCategory()
	self.categoryID = self:GetScrollList():GetParent():GetCategoryID(self.category)
	self.item = C_RecoveryService.GetCategoryItemAtIndex(self.category, self.index)
	if not self.item then
		return C_Logger.Error("No Recovery Item for %s (%s)", self.index, self.category or "nil")
	end
    
	local updateFunction = RecoveryCategoryUpdateFunction[self.categoryID]
	if updateFunction then
		updateFunction(self)
	end
	
	local timeSinceLost = SecondsToTime(time() - self.item.Date, false, true)
	self.Date:SetFormattedText("%s (%s ago)", date("%c", self.item.Date), timeSinceLost)
	self:UpdateCost()
	self.RecoverItemButton:SetShown(self:IsExpanded())
	self.Date:SetShown(self:IsExpanded())

	if self:IsSelected() then
		self:GetHighlightTexture():SetAlpha(0)
	else
		self:GetHighlightTexture():SetAlpha(1)
	end
end

function RecoveryItemMixin:OnSelected()
	self:ToggleExpanded(104)
	self.RecoverItemButton:SetShown(self:IsExpanded())
	self.Date:SetShown(self:IsExpanded())
	self:GetHighlightTexture():SetAlpha(0)
end

function RecoveryItemMixin:OnEnter()
	if self.tooltipHyperlink then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(self.tooltipHyperlink)
		GameTooltip:Show()
	else
		GameTooltip_GenericTooltip(self, "ANCHOR_RIGHT")
	end
end

function RecoveryItemMixin:OnLeave()
	GameTooltip:Hide()
end

function RecoveryItemMixin:ClearTooltip()
	self.tooltipTitle = nil
	self.tooltipText = nil
	self.tooltipHyperlink = nil
end

function RecoveryItemMixin:UpdateCost()
	local cost, multiLine = self:GetCostString()
	self.Money:SetText(cost)
	if multiLine then
		self.Money:SetFontSize(12)
	else
		self.Money:SetFontSize(16)
	end
end

function RecoveryItemMixin:GetItemRecoveryString(itemID, count)
	local item = CachedItems[itemID]
	if not item then
		item = Item:CreateFromID(itemID)
		CachedItems[itemID] = item
	end
	local link = item:GetIconLink(14 * GetUIScalar())
	if link then
		return link .. " x" .. count
	else
		return RED_FONTCOLOR:WrapText("["..RETRIEVING_ITEM_INFO.."]") .. " x" .. count
	end
end

function RecoveryItemMixin:GetTokenRecoveryString(tokenType, count)
	local link = TokenUtil.GetTokenLink(tokenType)
	local token = TokenUtil.CreateFromTokenType(tokenType)
	local icon = token:GetIcon()
	local iconMarkup = CreateSquareTextureMarkup(icon, 14 * GetUIScalar())
	return format("%s %s x%s", iconMarkup, link, count)
end

function RecoveryItemMixin:GetCostString()
	local costString
	if self.item.RecoveryCost then
		costString = GetCoinTextureString(self.item.RecoveryCost, 14 * GetUIScalar())
	end

	local multiLine = false

	if self.item.RecoveryCosts then
		for item, count in pairs(self.item.RecoveryCosts) do
			if costString then
				costString = costString .. "\n"
			else
				costString = ""
			end

			-- if this gets unwieldy just overwrite a function in the update function like .Recover is overwritten
			-- new function: `GetRecoveryEntryString` or something
			if type(item) == "string" then
				costString = costString .. self:GetTokenRecoveryString(item, count)
			else
				costString = costString .. self:GetItemRecoveryString(item, count)
			end
			multiLine = true
		end
	end
	return (costString or ""), multiLine
end

function RecoveryItemMixin:RecoverItem()
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
	local item = CachedItems[self.item.ItemEntry]
	if not item then
		return C_Logger.Error("No item found for ItemEntry: %s", (self.item.ItemEntry or "nil"))
	end
	local recoverFunc = GenerateClosure(C_RecoveryService.RecoverCategoryItemAtIndex, self.category, self.index, self.item.Id)
	C_Logger.Info("Recovering Item: %s x%s %s", self.item.ItemEntry, self.item.ItemCount or 1, self.item.Id)
	StaticPopup_Show("RECOVER_ITEM_CONFIRM", item:GetLink(), self:GetCostString(), recoverFunc)
end

function RecoveryItemMixin:RecoverWorldforgedItem()
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    local item = CachedItems[self.item.RequiredItemId]
    if not item then
        return C_Logger.Error("No item found for RequiredItemId: %s", (self.item.RequiredItemId or "nil"))
    end

    local item2 = CachedItems[self.item.RefundedItemId]
    if not item2 then
        return C_Logger.Error("No item found for RefundedItemId: %s", (self.item.RefundedItemId or "nil"))
    end
    local recoverFunc = GenerateClosure(C_RecoveryService.RecoverCategoryItemAtIndex, self.category, self.index, self.item.Id)
    C_Logger.Info("Recovering Item: %s x%s %s", self.item.RefundedItemId, self.item.ItemCount or 1, self.item.Id)
    local refund = item2:GetLink()
    if self.item.AdditionalRefund then
        for id, amount in pairs(self.item.AdditionalRefund) do
            if type(id) == "string" then
                local additionalLink = TokenUtil.GetTokenLink(id)
                refund =  refund .. "\n" .. additionalLink .. " x" .. amount
            else
                local additionalItem = CachedItems[id]
                if not additionalItem then
                    additionalItem = Item:CreateFromID(id)
                    CachedItems[id] = additionalItem
                end

                local additionalLink = additionalItem:GetLink()
                refund =  refund .. "\n" .. additionalLink .. " x" .. amount
            end
        end
    end
    StaticPopup_Show("RECOVER_WORLDFORGED_ITEM_CONFIRM", item:GetLink(), refund, recoverFunc)
end

function RecoveryItemMixin:RecoverQuest()
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
	local quest = CachedQuests[self.item.QuestId]
	if not quest then
		return C_Logger.Error("No quest found for QuestId: %s", (self.item.QuestId or "nil"))
	end
	local recoverFunc = GenerateClosure(C_RecoveryService.RecoverCategoryItemAtIndex, self.category, self.index, self.item.Id)
	C_Logger.Info("Recovering Quest: %s %s", self.item.QuestId, self.item.Id)
	StaticPopup_Show("RECOVER_ITEM_CONFIRM", quest:GetLink(), self:GetCostString(), recoverFunc)
end

function RecoveryItemMixin:RecoverCharacter()
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
	if not self.item.Name then
		return C_Logger.Error("Tried to RecoverCharacter but no name was found. Wrong type?")
	end
	local class = CLASS_ENUM_TO_CLASS_FILE[self.item.Class]
	local classColor = RAID_CLASS_COLORS[class] or HIGHLIGHT_FONT_COLOR
	local className = LOCALIZED_CLASS_NAMES_MALE[class] or UNKNOWN
	local name = classColor:WrapText(self.item.Name)

	local level = self.item.Level
	if not level or level <= 0 then
		level = "(" .. string.format(UNIT_TYPE_LETHAL_LEVEL_TEMPLATE, classColor:WrapText(className)) .. ")"
	else
		level = "(" .. string.format(UNIT_TYPE_LEVEL_TEMPLATE, self.item.Level, classColor:WrapText(className)) .. ")"
	end
	local recoverFunc = GenerateClosure(C_RecoveryService.RecoverCategoryItemAtIndex, self.category, self.index, self.item.Id)
	C_Logger.Info("Recovering Character: %s %s", name, self.item.Id)
	StaticPopup_Show("RECOVER_ITEM_CONFIRM", name .. " " .. level, self:GetCostString(), recoverFunc)
end

function RecoveryItemMixin:RecoverWildCardRoll()
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
	local recoverFunc = GenerateClosure(C_RecoveryService.RecoverCategoryItemAtIndex, self.category, self.index, self.item.Id)
	local spellLink = LinkUtil:GetSpellLinkInternalID(self.item.CAEntry)
	C_Logger.Info("Recovering WildCard Roll: Entry: [%s] Spell: [%s] Index: [%s]", self.item.CAEntry, spellLink, self.item.Id)
	StaticPopup_Show("RECOVER_WILDCARD_ROLL_CONFIRM", spellLink, self:GetCostString(), recoverFunc)
end

function RecoveryItemMixin:UpdateItemDisplay()
	local item = CachedItems[self.item.ItemEntry]

	if not item then
		item = Item:CreateFromID(self.item.ItemEntry)
		CachedItems[self.item.ItemEntry] = item
	end

	self.Icon:SetRounded(true)
	self.Icon:SetIcon(item:GetIcon())
	self.Icon:SetBorderAtlas(ITEM_QUALITY_ROUND_BORDER_ATLAS[item:GetQuality()])
	local link = item:GetLink()
	if link then
		self:SetText(link)
		self.tooltipHyperlink = link
	else
		self:SetText(RED_FONT_COLOR:WrapText("["..RETRIEVING_ITEM_INFO.."]"))
		self.tooltipHyperlink = "item:"..self.item.ItemEntry
	end
	if self.item.ItemCount then
		self.SubText:SetText("x"..self.item.ItemCount)
	else
		self.SubText:SetText("")
	end
	
	self.Recover = self.RecoverItem
	self.RecoverItemButton:SetText(RECOVER_ITEM)
end

function RecoveryItemMixin:UpdateDeletedCharacter()
	local class = CLASS_ENUM_TO_CLASS_FILE[self.item.Class]
	local classColor = RAID_CLASS_COLORS[class] or HIGHLIGHT_FONT_COLOR
	local className = LOCALIZED_CLASS_NAMES_MALE[class] or UNKNOWN
	local gender = self.item.Sex:sub(8)
	local race = self.item.Race:sub(6)
	if race == "UNDEAD_PLAYER" then
		race = "SCOURGE"
	end
	local coords = RACE_ICON_TCOORDS[race.."_"..gender]
	if coords then
		self.Icon:SetRounded(false)
		self.Icon:SetIcon("Interface\\Glues\\CharacterCreate\\UI-CHARACTERCREATE-RACES_Round")
		self.Icon.Icon:SetTexCoord(unpack(coords))
	else
		self.Icon:SetRounded(true)
		self.Icon:SetIcon("Interface\\Icons\\inv_misc_questionmark")
	end

	local name = classColor:WrapText(self.item.Name)
	self:SetText(name)
	self.Icon:SetBorderAtlas("item-border-round-gold")

	local level = self.item.Level
	if not level or level <= 0 then
		self.SubText:SetFormattedText(UNIT_TYPE_LETHAL_LEVEL_TEMPLATE, classColor:WrapText(className))
	else
		self.SubText:SetFormattedText(UNIT_TYPE_LEVEL_TEMPLATE, self.item.Level, classColor:WrapText(className))
	end
	
	self.Recover = self.RecoverCharacter
	self.RecoverItemButton:SetText(RECOVER_CHARACTER)
end

function RecoveryItemMixin:UpdateWildCardRoll()
	local entry = C_CharacterAdvancement.GetEntryByInternalID(self.item.CAEntry)
	self.Icon:SetRounded(true)

	if not entry then
		self.Icon:SetIcon("Intreface\\Icons\\inv_misc_questionmark")
		self:SetText(UNKNOWNOBJECT)
		self.Icon:SetBorderAtlas("item-border-round-grey")
	else
		local rank = self.item.CARank or 1
		local spellID = entry.Spells[rank] or entry.Spells[1]
		local spellName, _, icon = GetSpellInfo(spellID)

		self.Icon:SetIcon(icon)

		if entry.Type == Enum.CharacterAdvancementType.Talent then
			spellName = ITEM_QUALITY_COLORS[rank]:WrapText(spellName) .. HIGHLIGHT_FONT_COLOR:WrapText(format(" (" .. TOOLTIP_TALENT_RANK.. ")", rank, #entry.Spells))
			self.Icon:SetBorderAtlas(ITEM_QUALITY_ROUND_BORDER_ATLAS[rank])
		else
			spellName = SPELL_LINK_COLOR:WrapText(spellName)
			self.Icon:SetBorderAtlas(ITEM_QUALITY_ROUND_BORDER_ATLAS[8])
		end
		self:SetText(spellName)
		
		local specName = SpecializationUtil.GetSpecializationInfo(self.item.Specialization)
		if specName:startswith(SPECIALIZATION_LABEL) then
			self.SubText:SetText(specName) -- default name
		else
			self.SubText:SetText(SPECIALIZATION_LABEL .. " " .. specName)
		end
	end
	
	self.Recover = self.RecoverWildCardRoll
	self.RecoverItemButton:SetText(RECOVER_WILDCARD_ROLL)
end

function RecoveryItemMixin:UpdateWorldforgedDisplay()
    local item = CachedItems[self.item.RefundedItemId]

    if not item then
        item = Item:CreateFromID(self.item.RefundedItemId)
        CachedItems[self.item.RefundedItemId] = item
    end

    self.Icon:SetRounded(true)
    self.Icon:SetIcon(item:GetIcon())
    self.Icon:SetBorderAtlas(ITEM_QUALITY_ROUND_BORDER_ATLAS[item:GetQuality()])
    local link = item:GetLink()
    if link then
        self:SetText(link)
        self.tooltipHyperlink = link
    else
        self:SetText(RED_FONT_COLOR:WrapText("["..RETRIEVING_ITEM_INFO.."]"))
        self.tooltipHyperlink = "item:"..self.item.RefundedItemId
    end

    if self.item.AdditionalRefund then
        local subText
        for id, amount in pairs(self.item.AdditionalRefund) do
            if type(id) == "string" then
                local additionalLink = TokenUtil.GetTokenLink(id)
                subText = (subText and subText .. "\n" or "") .. additionalLink .. " x" .. amount
            else
                local additionalItem = CachedItems[id]
                if not additionalItem then
                    additionalItem = Item:CreateFromID(id)
                    CachedItems[id] = additionalItem
                end
                
                local additionalLink = additionalItem:GetLink()
                subText = (subText and subText .. "\n" or "") .. additionalLink .. " x" .. amount
            end
        end

        if subText then
            self.SubText:SetText(subText)
        end
    end

    self.Recover = self.RecoverWorldforgedItem
    self.RecoverItemButton:SetText(DOWNGRADE_ITEM)
end

RecoveryCategoryUpdateFunction[Enum.RecoveryCategory.DisenchantedItems] = RecoveryItemMixin.UpdateItemDisplay
RecoveryCategoryUpdateFunction[Enum.RecoveryCategory.DeletedCharacters] = RecoveryItemMixin.UpdateDeletedCharacter
RecoveryCategoryUpdateFunction[Enum.RecoveryCategory.VendoredItems] = RecoveryItemMixin.UpdateItemDisplay
RecoveryCategoryUpdateFunction[Enum.RecoveryCategory.DeletedItems] = RecoveryItemMixin.UpdateItemDisplay
RecoveryCategoryUpdateFunction[Enum.RecoveryCategory.RecylcedItems] = RecoveryItemMixin.UpdateItemDisplay
RecoveryCategoryUpdateFunction[Enum.RecoveryCategory.WildCardRoll] = RecoveryItemMixin.UpdateWildCardRoll
RecoveryCategoryUpdateFunction[Enum.RecoveryCategory.Worldforged] = RecoveryItemMixin.UpdateWorldforgedDisplay
