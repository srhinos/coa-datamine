CurrencyPanelMixin = {}

function CurrencyPanelMixin:OnLoad()
	self.ScrollList:SetTemplate("CurrencyPanelItemTemplate")
	self.ScrollList:SetGetNumResultsFunction(GetCurrencyListSize)
	self.ScrollList:GetSelectedHighlight():SetTexture()
end

function CurrencyPanelMixin:OnShow()
	self:RegisterEvent("BAG_UPDATE")
end

function CurrencyPanelMixin:OnHide()
	self:UnregisterEvent("BAG_UPDATE")
	self:CloseDetails()
end

function CurrencyPanelMixin:OnEvent(event, ...)
	self:MarkDirty()
end

function CurrencyPanelMixin:MarkDirty()
	if not self:GetScript("OnUpdate") then
		self:SetScript("OnUpdate", function(self)
			self:SetScript("OnUpdate", nil)
			self.ScrollList:RefreshScrollFrame()
		end)
	end
end

function CurrencyPanelMixin:SetCurrencyUnused(currencyID, unused)
	SetCurrencyUnused(currencyID, unused and 1 or 0)
	self.ScrollList:RefreshScrollFrame()
	self:CloseDetails()
	BackpackTokenFrame_Update()
	ManageBackpackTokenFrame()
end

function CurrencyPanelMixin:SetCurrencyWatched(currencyID, watch)
	if GetNumWatchedCurrencies() >= MAX_WATCHED_TOKENS and watch then
		UIErrorsFrame:AddMessage(format(TOO_MANY_WATCHED_TOKENS, MAX_WATCHED_TOKENS), 1.0, 0.1, 0.1, 1.0)
		return
	end

	SetCurrencyBackpack(currencyID, watch and 1 or 0)
	self.ScrollList:RefreshScrollFrame()
	BackpackTokenFrame_Update()
	ManageBackpackTokenFrame()
end

function CurrencyPanelMixin:OpenDetails(currencyID)
	self.DetailsFrame.currencyID = currencyID
	local name, _, _, isUnused, isWatched = GetCurrencyListInfo(currencyID)
	self.DetailsFrame.Name:SetText(name)
	self.DetailsFrame.InactiveToggle:SetChecked(isUnused)
	self.DetailsFrame.BackpackToggle:SetChecked(isWatched)
	self.DetailsFrame:Show()
end

function CurrencyPanelMixin:CloseDetails()
	self.DetailsFrame:Hide()
	self.ScrollList:RefreshScrollFrame()
end

--
-- Currency Panel Item
--
CurrencyPanelItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function CurrencyPanelItemMixin:Init(args)
	ScrollListItemBaseMixin.Init(self, args)
	self.CategoryBackground:SetAtlas("Char-Stat-Top", Const.TextureKit.IgnoreAtlasSize)
end

function CurrencyPanelItemMixin:Update()
	local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(self.index)
	self.Check:Hide()

	if not name or name == "" then
		name = "UNKNOWN"
	end

	self:GetNormalTexture():SetShown(not isHeader and self.index % 2 == 0)

	if isHeader then
		self.CategoryBackground:Show()
		self.ExpandIcon:Show()
		self.Count:SetText("")
		self.Icon:SetTexture(nil)
		if isExpanded then
			self.ExpandIcon:SetAtlas("Char-Stat-Minus", Const.TextureKit.IgnoreAtlasSize)
		else
			self.ExpandIcon:SetAtlas("Char-Stat-Plus", Const.TextureKit.IgnoreAtlasSize)
		end
		self:SetHighlightTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
		self:GetHighlightTexture():SetPoint("TOPLEFT", 3, -2)
		self:GetHighlightTexture():SetPoint("BOTTOMRIGHT", -3, 2)
		self:SetText(name)
		self.Name:SetText("")
		self.itemID = nil
		self.LinkButton:Hide()
	else
		self.CategoryBackground:Hide()
		self.ExpandIcon:Hide()
		self.Count:SetText(count)
		self.extraCurrencyType = extraCurrencyType
		
		if extraCurrencyType == 1 then	--Arena points
			self.Icon:SetTexture("Interface\\PVPFrame\\PVP-ArenaPoints-Icon")
			self.Icon:SetTexCoord(0, 1, 0, 1)
		elseif extraCurrencyType == 2 then --Honor points
			local factionGroup = UnitFactionGroup("player")
			if factionGroup then
				self.Icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)
				self.Icon:SetTexCoord( 0.03125, 0.59375, 0.03125, 0.59375)
			else
				self.Icon:Hide() --We don't know their faction yet!
				self.Icon:SetTexCoord(0, 1, 0, 1)
			end
		else
			self.Icon:SetTexture(icon)
			self.Icon:SetTexCoord(0, 1, 0, 1)
		end

		if isWatched then
			self.Check:Show()
		end

		self:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		self:GetHighlightTexture():SetPoint("TOPLEFT", 0, 0)
		self:GetHighlightTexture():SetPoint("BOTTOMRIGHT", 0, 0)
		--Gray out the text if the count is 0
		if count == 0 then
			self.Count:SetFontObject("GameFontDisable")
			self.Name:SetFontObject("GameFontDisable")
		else
			self.Count:SetFontObject("GameFontHighlight")
			self.Name:SetFontObject("GameFontHighlight")
		end
		self:SetText("")
		self.Name:SetText(name)
		self.itemID = itemID
		self.LinkButton:Show()
	end

	--Manage highlight
	if self:IsSelected() and not isHeader then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end

	self.isHeader = isHeader
	self.isExpanded = isExpanded
	self.isUnused = isUnused
	self.isWatched = isWatched
end

function CurrencyPanelItemMixin:OnSelected()
	if self.isHeader then
		PlaySound(SOUNDKIT.MINI_MAP_ZOOM_70)
		if self.isExpanded then
			ExpandCurrencyList(self.index, 0)
		else
			ExpandCurrencyList(self.index, 1)
		end
		self:GetScrollList():GetParent():CloseDetails()
		return
	end

	if IsModifiedClick("TOKENWATCHTOGGLE") then
		if self.isWatched then
			SetCurrencyBackpack(self.index, 0)
			self.isWatched = false
		else
			-- Set an error message if trying to show too many quests
			if GetNumWatchedCurrencies() >= MAX_WATCHED_TOKENS then
				UIErrorsFrame:AddMessage(format(TOO_MANY_WATCHED_TOKENS, MAX_WATCHED_TOKENS), 1.0, 0.1, 0.1, 1.0)
				return
			end

			SetCurrencyBackpack(self.index, 1)
			self.isWatched = true
		end

		BackpackTokenFrame_Update()
		ManageBackpackTokenFrame()
	else
		PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON_50)
		self:GetScrollList():GetParent():OpenDetails(self.index)
	end
end 

function CurrencyPanelItemMixin:OnLinkButtonClick()
	if self.itemID then
		HandleModifiedItemClick(GetItemLink(self.itemID))
	end
end 