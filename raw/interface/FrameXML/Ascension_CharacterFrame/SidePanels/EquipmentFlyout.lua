EquipmentFlyoutMixin = {}

function EquipmentFlyoutMixin:OnLoad()
	self.ButtonPool = CreateFramePool("BUTTON", self.Buttons, "EquipmentFlyoutButtonTemplate")
	
end

function EquipmentFlyoutMixin:OnShow()
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

function EquipmentFlyoutMixin:OnHide()
	self.ButtonPool:ReleaseAll()
	if self.button then
		self.button:SetClosedArtwork()
	end
	self.button = nil
	self:UnregisterEvent("BAG_UPDATE")
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

function EquipmentFlyoutMixin:OnEvent(event, ...)
	if event == "BAG_UPDATE" then
		self:RefreshItems()
	elseif event == "UNIT_INVENTORY_CHANGED" then
		local arg1 = ...
		if arg1 == "player" then
			self:RefreshItems()
		end
	end
end

function EquipmentFlyoutMixin:IsOwnedBy(button)
	return self.button == button
end

function EquipmentFlyoutMixin:Open(button, verticalLayout)
	if self.button then
		self.button:SetClosedArtwork()
	end
	
	self.button = button
	self.verticalLayout = verticalLayout
	self.slotTexture = button:GetParent().backgroundTextureName
	self.slotID = button:GetParent():GetID()
	button:SetOpenArtwork()
	if self.verticalLayout then
		self.Buttons:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 6, -6)
	else
		self.Buttons:SetPoint("TOPLEFT", button, "TOPRIGHT", 6, -6)
	end
	self:Show()
	self:ClearAndSetPoint("CENTER", button:GetParent(), "CENTER", 0, 0)
	self:RefreshItems()
end

local itemsToShow = {}
local allItems = {}
local seenItems = {}

local function SortItems(a, b)
	-- sort unique items to the top first. 
	-- this ensures a ton of duplicates of an item will come after each unique version of an item
	-- think having many unused mystic scrolls in your inventory, but you want to swap trinkets
	local aItemID = itemsToShow[a]
	local bItemID = itemsToShow[b]
	if aItemID and not seenItems[aItemID] then
		seenItems[aItemID] = true
		return true
	end
	
	if bItemID and not seenItems[bItemID] then
		seenItems[bItemID] = true
		return false
	end
	-- Sort by location. This ends up as: inventory, backpack, bags, bank, and bank bags.
	return a < b
end

function EquipmentFlyoutMixin:RefreshItems()
	if not self.button then return end
	
	wipe(itemsToShow)
	wipe(allItems)
	wipe(seenItems)
	
	local id = self.button.id
	GetInventoryItemsForSlot(id, allItems)

	for location, itemID in pairs(allItems) do
		if location - id ~= ITEM_INVENTORY_LOCATION_PLAYER then -- Ignore the currently equipped item
			tinsert(itemsToShow, location)
		end
	end

	table.sort(itemsToShow, SortItems)

	local numItems = min(#itemsToShow, EQUIPMENT_FLYOUT_MAX_ITEMS)

	if GetInventoryItemID("player", id) then
		tinsert(itemsToShow, 1, EQUIPMENT_MANAGER_PLACEINBAGS_LOCATION)
		tinsert(itemsToShow, 2, EQUIPMENT_MANAGER_PLACEINBANK_LOCATION)
		numItems = numItems + 2
	end

	if numItems == 0 then
		self:Hide()
		return
	end

	self.ButtonPool:ReleaseAll()
	
	local width, height
	for i = 1, numItems do
		local location = itemsToShow[i]
		local button = self.ButtonPool:Acquire()
		button.location = location
		button:SetDisplay()
		button:Show()
		
		if not width then
			width, height = button:GetSize()
		end
		
		-- position in rows 
		local row = math.ceil(i / EQUIPMENT_MANAGER_COLUMNS)
		local column = i % EQUIPMENT_MANAGER_COLUMNS
		if column == 0 then
			column = EQUIPMENT_MANAGER_COLUMNS
		end

		row = row - 1
		column = column - 1

		button:SetPoint("TOPLEFT", self.Buttons, "TOPLEFT", column * width, row * -height)
	end

	local numColumns = math.min(numItems, EQUIPMENT_MANAGER_COLUMNS)
	local fullWidth = numColumns * width
	local fullHeight = math.ceil(numItems / EQUIPMENT_MANAGER_COLUMNS) * height
	self.Buttons:SetSize(fullWidth, fullHeight)
end


function EquipmentFlyoutMixin:OnButtonClicked(button)
	-- place in bags
	if button.location == EQUIPMENT_MANAGER_PLACEINBAGS_LOCATION then
		if UnitAffectingCombat("player") and not INVSLOTS_EQUIPABLE_IN_COMBAT[self.slotID] then
			UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1, 0.1, 0.1, 1)
			return
		end
		local action = EquipmentManager_UnequipItemInSlot(self.slotID)
		EquipmentManager_RunAction(action)
	-- place in bank
	elseif button.location == PDFITEMFLYOUT_PLACEINBANK_LOCATION then
		if UnitAffectingCombat("player") and not INVSLOTS_EQUIPABLE_IN_COMBAT[self.slotID] then
			UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1, 0.1, 0.1, 1)
			return
		end
		local action = EquipmentManager_UnequipItemInSlot(self.slotID, true)
		EquipmentManager_RunAction(action)
	-- Equip item in location
	elseif button.location then
		if UnitAffectingCombat("player") and not INVSLOTS_EQUIPABLE_IN_COMBAT[self.slotID] then
			UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1, 0.1, 0.1, 1)
			return
		end
		local action = EquipmentManager_EquipItemByLocation(button.location, self.slotID)
		EquipmentManager_RunAction(action)
	end

	if EquipmentFlyoutFrame:IsOwnedBy(self) then
		EquipmentFlyoutFrame:Hide()
	end
end


--
-- Equipment Flyout Popup Button
--
EquipmentFlyoutPopoutButtonMixin = {}

function EquipmentFlyoutPopoutButtonMixin:OnClick()
	PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
	if EquipmentFlyoutFrame:IsOwnedBy(self) then
		EquipmentFlyoutFrame:Hide()
	else
		EquipmentFlyoutFrame:Open(self, self:GetParent().verticalFlyout)
	end
end

function EquipmentFlyoutPopoutButtonMixin:SetOpenArtwork()
	if self:GetParent().verticalFlyout then
		self:GetNormalTexture():SetTexCoord(0.15625, 0.84375, 0, 0.5)
		self:GetHighlightTexture():SetTexCoord(0.15625, 0.84375, 0.5, 1)
	else
		self:GetNormalTexture():SetTexCoord(0.15625, 0, 0.84375, 0, 0.15625, 0.5, 0.84375, 0.5)
		self:GetHighlightTexture():SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 1, 0.84375, 1)
	end
end

function EquipmentFlyoutPopoutButtonMixin:SetClosedArtwork()
	if self:GetParent().verticalFlyout then
		self:GetNormalTexture():SetTexCoord(0.15625, 0.84375, 0.5, 0)
		self:GetHighlightTexture():SetTexCoord(0.15625, 0.84375, 1, 0.5)
	else
		self:GetNormalTexture():SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 0, 0.84375, 0)
		self:GetHighlightTexture():SetTexCoord(0.15625, 1, 0.84375, 1, 0.15625, 0.5, 0.84375, 0.5)
	end
end

--
-- Equipment Flyout Button
--
EquipmentFlyoutButtonMixin = {}

function EquipmentFlyoutButtonMixin:OnLoad()
	
end

function EquipmentFlyoutButtonMixin:OnEnter()
	if self.UpdateTooltip then
		self:UpdateTooltip()
	end
end

function EquipmentFlyoutButtonMixin:OnClick()
	self:GetParent():GetParent():OnButtonClicked(self)
end 

function EquipmentFlyoutButtonMixin:OnLeave()
	GameTooltip:Hide()
	ResetCursor()
end 

function EquipmentFlyoutButtonMixin:SetSpecialDisplay()
	local location = self.location
	SetItemButtonCount(self, nil)
	SetItemButtonTextureVertexColor(self, 1.0, 1.0, 1.0)
	SetItemButtonNormalTextureVertexColor(self, 1.0, 1.0, 1.0)
	
	-- Place in Bags
	if location == EQUIPMENT_MANAGER_PLACEINBAGS_LOCATION then
		SetItemButtonTexture(self, "Interface\\PaperDollInfoFrame\\UI-GearManager-ItemIntoBag")
		self.UpdateTooltip = function(self)
			GameTooltip:SetOwner(self:GetParent(), "ANCHOR_RIGHT", 6, -self:GetParent():GetHeight() - 6)
			GameTooltip:SetText(EQUIPMENT_MANAGER_PLACE_IN_BAGS, 1, 1, 1)
			if SHOW_NEWBIE_TIPS == "1" then
				GameTooltip:AddLine(NEWBIE_TOOLTIP_EQUIPMENT_MANAGER_PLACE_IN_BAGS, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
			end
			GameTooltip:Show()
		end
	-- Place in Bank
	elseif location == EQUIPMENT_MANAGER_PLACEINBANK_LOCATION then
		SetItemButtonTexture(self, "Interface\\PaperDollInfoFrame\\UI-GearManager-ItemIntoBank")
		self.UpdateTooltip = function(self)
			GameTooltip:SetOwner(self:GetParent(), "ANCHOR_RIGHT", 6, -self:GetParent():GetHeight() - 6)
			GameTooltip:SetText(EQUIPMENT_MANAGER_PLACE_IN_BANK, 1, 1, 1)
			if SHOW_NEWBIE_TIPS == "1" then
				GameTooltip:AddLine(NEWBIE_TOOLTIP_EQUIPMENT_MANAGER_PLACE_IN_BANK, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
			end
			GameTooltip:Show()
		end
	end
	if self:IsMouseOver() and self.UpdateTooltip then
		self:UpdateTooltip()
	end
end

function EquipmentFlyoutButtonMixin:SetDisplay()
	if self.location >= EQUIPMENT_MANAGER_FIRST_SPECIAL_LOCATION then
		return self:SetSpecialDisplay()
	end
	local id, _, textureName, count, durability, maxDurability, _, locked, start, duration, enable, setTooltip = EquipmentManager_GetItemInfoByLocation(self.location)
	local broken = maxDurability and durability == 0
	if textureName then
		SetItemButtonTexture(self, textureName)
		SetItemButtonCount(self, count)
		SetItemButtonQuality(self, GetItemQuality(id))
		if broken then
			SetItemButtonTextureVertexColor(self, CANNOT_USE_ITEM_COLOR:GetRGB())
			SetItemButtonNormalTextureVertexColor(self, CANNOT_USE_ITEM_COLOR:GetRGB())
		elseif locked then
			SetItemButtonTextureVertexColor(self, GRAY_FONT_COLOR:GetRGB())
			SetItemButtonNormalTextureVertexColor(self, GRAY_FONT_COLOR:GetRGB())
		else
			SetItemButtonTextureVertexColor(self, WHITE_FONT_COLOR:GetRGB())
			SetItemButtonNormalTextureVertexColor(self, WHITE_FONT_COLOR:GetRGB())
		end

		CooldownFrame_SetTimer(self.Cooldown, start, duration, enable)

		self.UpdateTooltip = function(self) GameTooltip:SetOwner(self:GetParent(), "ANCHOR_RIGHT", 6, -self:GetParent():GetHeight() - 6) setTooltip() end
		if self:IsMouseOver() then
			self:UpdateTooltip()
		end
	else
		textureName = self:GetParent().slotTexture
		SetItemButtonTexture(self, textureName)
		SetItemButtonCount(self, 0)
		SetItemButtonTextureVertexColor(self, 1.0, 1.0, 1.0)
		SetItemButtonNormalTextureVertexColor(self, 1.0, 1.0, 1.0)
		self.Cooldown:Hide()
		self.UpdateTooltip = nil
		SetItemButtonQuality(self, nil)
	end
end 