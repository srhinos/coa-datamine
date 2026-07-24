ECScrollListItemMixin = {}

function ECScrollListItemMixin:OnLoad()
	self:Layout()

	self.Button:SetScript("OnClick", function() 
		self:GetScrollsTab():GetEnchantCollection():ActivateScroll(self.itemData.Entry) 
	end)
end

function ECScrollListItemMixin:Init()
end

function ECScrollListItemMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	if (self.item) then
		GameTooltip:SetHyperlink(self.item:GetLink())
	end

	if not(self.isAlreadyInUse) and self.fitsLevel and self.fitsClass then
		self.Name:SetTextColor(GameFontHighlight:GetTextColor())
	end

	GameTooltip:Show()
end

function ECScrollListItemMixin:OnLeave()
	GameTooltip:Hide()

	if not(self.isAlreadyInUse) and self.fitsLevel and self.fitsClass then
		if (self.isSelected) then
			self.Name:SetTextColor(GameFontHighlight:GetTextColor())
		else
			self.Name:SetTextColor(GameFontNormal:GetTextColor())
		end
	end
end

function ECScrollListItemMixin:SetEmptyScroll()
	local icon = GetItemIconInstant(ItemData.UNTARNISHED_MYSTIC_SCROLL) or "inv_misc_questionmark"
	self.Enchant:SetState(Enum.ECSlotStates.Known, true)
	self.Enchant:SetQuality(0)
	self.Enchant:SetIcon("Interface\\Icons\\"..icon)
	self.Button:Hide()
end

function ECScrollListItemMixin:SetSelected()
	self.Name:SetTextColor(GameFontHighlight:GetTextColor())
	self.Enchant:ShowSelected()
end

function ECScrollListItemMixin:Update()
	local itemData = self:GetScrollsTab():GetItemData(self.index)

	if not(next(itemData)) then
		return
	end

	local isLocked = false

	self.isSelected = (self:GetScrollsTab():GetSelectedIndex() == self.index)
	self.fitsLevel = true

	self.itemData = itemData
	self.isAlreadyInUse = self:GetScrollsTab():GetEnchantCollection():GetInUseStatus(self.itemData.Guid)
	self.Name:SetTextColor(GameFontNormal:GetTextColor())
	self.Enchant:HideSelected()
	self.SubTitle:SetText("")
	self.Name:SetPoint("LEFT", self.Enchant, "RIGHT", 12, 0)
	self.Enchant:SetLocked(ECEnchantMixin.LockState.Unlocked)
	self.SubTitle:SetAlpha(1)

	if not(itemData.Entry) or itemData.Entry == -1 then
		self.item = nil
		self:SetName(itemData.Name)
		self:SetEmptyScroll()
		
		if (self.isSelected) then
			self:SetSelected()
		end

		return
	end

	local item = Item:CreateFromID(itemData.Entry)
	self.item = item

	if (itemData.Entry == ItemData.UNTARNISHED_MYSTIC_SCROLL) then
		self:SetEmptyScroll()

		if (self.isSelected) then
			self:SetSelected()
		end


		local count = GetItemCount(ItemData.UNTARNISHED_MYSTIC_SCROLL)
		local itemName = (itemData.Name and itemData.Name ~= "") and itemData.Name or item:GetName()
		if count > 0 then
			self:SetName(itemName.. GREEN_FONT_COLOR:WrapText("|nx"..count))
		else
			self:SetName(itemName)
		end
		return
	else
		self:SetName((itemData.Name and itemData.Name ~= "") and itemData.Name or item:GetName())
	end

	local REData = C_MysticEnchant.GetEnchantInfoByItem(itemData.Entry)
	local level = UnitLevel("player")

	self.fitsClass = REData.IsAvailableForCurrentClass and EnchantCollectionUtil.IsClassAndSpecAppropriate(REData)

	self.Enchant:SetState(Enum.ECSlotStates.Known, true)
	self.Enchant:SetIcon(item:GetIcon())
	self.Enchant:SetQuality(itemData.Quality or item:GetQuality())

	if not(self.fitsClass) or not(self.fitsLevel) then
		isLocked = true
	end

	if REData then
		if REData.Spec then
			self.Name:SetPoint("LEFT", self.Enchant, "RIGHT", 12, 6)
			self.SubTitle:SetText(EnchantCollectionUtil:GetSpecString(REData))
		end

		if REData.RequiredLevel and (REData.RequiredLevel > level) then
			isLocked = true
			self.fitsLevel = false
			if self.fitsClass then
				self.Name:SetPoint("LEFT", self.Enchant, "RIGHT", 12, 6)
				self.SubTitle:SetText("|cffFF0000"..(string.format(ITEM_MIN_LEVEL, REData.RequiredLevel)))
			end
		end
	end

	if isLocked then
		self.Enchant:SetLocked(ECEnchantMixin.LockState.Locked)
		self.Name:SetTextColor(GameFontDisable:GetTextColor())
		self.SubTitle:SetAlpha(0.6)
	end


	if (self.isSelected) then
		self:SetSelected()
		self.Button:Show()
	else
		self.Button:Hide()
	end

	if self.isAlreadyInUse or isLocked then
		self.Name:SetTextColor(GameFontDisable:GetTextColor())
		self.Enchant:SetLocked(ECEnchantMixin.LockState.Locked)
		self.Button:Disable()
	else
		self.Button:Enable()
		--[[if (EnchantCollectionUtil:GetAltar()) then -- activation is available everywhere
			
		else
			self.Button:Disable()
		end]]--
		self.Enchant:SetLocked(ECEnchantMixin.LockState.Unlocked)
	end

end

function ECScrollListItemMixin:GetScrollsTab()
	return self:GetParent():GetParent():GetParent()
end

function ECScrollListItemMixin:OnSelected()
	PlaySound("igMainMenuOptionCheckBoxOn")
	
	if not(self.isAlreadyInUse) then
		self:GetScrollsTab():GetEnchantCollection():OnSelectEnchantScroll(self.itemData.Entry, self.itemData.Entry == ItemData.UNTARNISHED_MYSTIC_SCROLL)
	end
end

function ECScrollListItemMixin:SetName(...)
	self.Name:SetText(...)
end

function ECScrollListItemMixin:Layout()
	self.Enchant = CreateFrame("BUTTON", "$parent.Enchant", self, "EnchantCollectionEnchantItem")
	self.Enchant:SetPoint("LEFT", 20, 2)
	self.Enchant:SetScale(0.8)
	self.Enchant:SetState(Enum.ECSlotStates.Unknown)
	self.Enchant:EnableMouse(false)
	self.Enchant:Show()

	self.Name = self:CreateFontString(nil, "OVERLAY")
	self.Name:SetFontObject(GameFontHighlightMedium)
	self.Name:SetPoint("LEFT", self.Enchant, "RIGHT", 12, 0)
	self.Name:SetWidth(182)
	self.Name:SetJustifyH("LEFT")
	self.Name:SetJustifyV("CENTER")

	self.SubTitle = self:CreateFontString(nil, "OVERLAY")
	self.SubTitle:SetFontObject(GameFontNormal)
	self.SubTitle:SetPoint("TOPLEFT", self.Name, "BOTTOMLEFT", 0, -2)
	self.SubTitle:SetJustifyH("LEFT")
	self.SubTitle:SetJustifyV("CENTER")

	self:SetBackdrop(GameTooltip:GetBackdrop())
	self:SetBackdropColor(0, 0, 0, 0.5)

	self.Button = CreateFrame("BUTTON", "$parent.Button", self, "RedButtonTemplate")
	self.Button:SetSize(172, 36)
	self.Button:SetPoint("RIGHT", -20, 0)
	self.Button:SetText(ACTIVATE)
	
	self.Button:Hide()

end

