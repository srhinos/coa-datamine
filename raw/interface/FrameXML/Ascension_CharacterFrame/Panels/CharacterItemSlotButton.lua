ItemSlotButtonMixin = {}

function ItemSlotButtonMixin:OnLoad()
	local slotName = self:GetAttribute("invslot")
	self.slotName = slotName
	local id, textureName = GetInventorySlotInfo(slotName)
	self:SetID(id)
	local texture = _G[self:GetName().."IconTexture"]
	texture:SetTexture(textureName)

	SetParentTableKey(self, "ItemSlots", id)

	self.backgroundTextureName = textureName
	self.UpdateTooltip = self.OnEnter

	local position = self:GetAttribute("position")
	if position == "left" then
		self.Frame:SetAtlas("Char-LeftSlot", Const.TextureKit.UseAtlasSize)
	elseif position == "right" then
		self.Frame:SetAtlas("Char-RightSlot", Const.TextureKit.UseAtlasSize)
	elseif position == "bottom" then
		self.Frame:SetAtlas("Char-BottomSlot", Const.TextureKit.UseAtlasSize)
	end
end

function ItemSlotButtonMixin:OnShow()
	self.checkRelic = UnitHasRelicSlot(self.unit)
	if self.checkRelic and self.slotName == "RangedSlot" then
		self.backgroundTextureName = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic"
	end
	self:MarkDirty()
end

function ItemSlotButtonMixin:Update()
	local itemLink = GetInventoryItemLink(self.unit, self:GetID())
	local itemID = itemLink and GetItemInfoFromHyperlink(itemLink)
	local textureName
	if itemID and  self:GetID() ~= INVSLOT_AMMO then -- ammo slot caches weird with GetInventoryItemLink
		textureName = GetItemIcon(itemID) or "Interface\\Icons\\"..GetItemIconInstant(itemID)
	else
		textureName = GetInventoryItemTexture(self.unit, self:GetID())
	end
	local cooldown = self.Cooldown
	if textureName then
		SetItemButtonTexture(self, textureName)
		SetItemButtonCount(self, GetInventoryItemCount(self.unit, self:GetID()))
		if GetInventoryItemBroken(self.unit, self:GetID()) then
			SetItemButtonTextureVertexColor(self, CANNOT_USE_ITEM_COLOR:GetRGB())
			SetItemButtonNormalTextureVertexColor(self, CANNOT_USE_ITEM_COLOR:GetRGB())
		else
			SetItemButtonTextureVertexColor(self, WHITE_FONT_COLOR:GetRGB())
			SetItemButtonNormalTextureVertexColor(self, WHITE_FONT_COLOR:GetRGB())
		end
		if cooldown then
			local start, duration, enable = GetInventoryItemCooldown(self.unit, self:GetID())
			CooldownFrame_SetTimer(cooldown, start, duration, enable)
		end
		self.hasItem = 1
	else
		textureName = self.backgroundTextureName
		SetItemButtonTexture(self, textureName)
		SetItemButtonCount(self, 0)
		SetItemButtonTextureVertexColor(self, WHITE_FONT_COLOR:GetRGB())
		SetItemButtonNormalTextureVertexColor(self, WHITE_FONT_COLOR:GetRGB())
		if cooldown then
			cooldown:Hide()
		end
		self.hasItem = nil
	end

	SetItemButtonQuality(self, GetInventoryItemQuality(self.unit, self:GetID()))
end

function ItemSlotButtonMixin:MarkDirty()
	self:SetScript("OnUpdate", function()
		self:Update()
		self:SetScript("OnUpdate", nil)
	end)
end

function ItemSlotButtonMixin:OnClick(button)
	if IsModifiedClick() then
		return self:OnModifiedClick(button)
	end
end

function ItemSlotButtonMixin:OnModifiedClick()
	if HandleModifiedItemClick(GetInventoryItemLink(self.unit, self:GetID())) then
		return true
	end
end

function ItemSlotButtonMixin:SetUnit(unit)
	self.unit = unit
	self:MarkDirty()
end

CharacterItemSlotButtonMixin = CreateFromMixins(ItemSlotButtonMixin)

local VERTICAL_FLYOUTS = { [16] = true, [17] = true, [18] = true }

function CharacterItemSlotButtonMixin:OnLoad()
	ItemSlotButtonMixin.OnLoad(self)
	self:SetUnit("player")
	self:RegisterForDrag("LeftButton")
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	self.verticalFlyout = VERTICAL_FLYOUTS[self:GetID()]

	local popoutButton = self.PopoutButton
	if not popoutButton then return end
	popoutButton.id = self:GetID()

	if self.verticalFlyout then
		popoutButton:SetHeight(16)
		popoutButton:SetWidth(38)

		popoutButton:GetNormalTexture():SetTexCoord(0.15625, 0.84375, 0.5, 0)
		popoutButton:GetHighlightTexture():SetTexCoord(0.15625, 0.84375, 1, 0.5)
		popoutButton:ClearAllPoints()
		popoutButton:SetPoint("TOP", self, "BOTTOM", 0, 2)
	else
		popoutButton:SetHeight(38)
		popoutButton:SetWidth(16)

		popoutButton:GetNormalTexture():SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 0, 0.84375, 0)
		popoutButton:GetHighlightTexture():SetTexCoord(0.15625, 1, 0.84375, 1, 0.15625, 0.5, 0.84375, 0.5)
		popoutButton:ClearAllPoints()
		popoutButton:SetPoint("LEFT", self, "RIGHT", -2, 0)
	end
end

function CharacterItemSlotButtonMixin:OnShow()
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("ITEM_LOCK_CHANGED")
	self:RegisterEvent("CURSOR_UPDATE")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:RegisterEvent("SHOW_COMPARE_TOOLTIP")
	self:RegisterEvent("UPDATE_INVENTORY_ALERTS")
	self:RegisterEvent("MODIFIER_STATE_CHANGED")

	if self:GetID() == INVSLOT_AMMO then
		self:RegisterEvent("MERCHANT_UPDATE")
		self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
		self:RegisterEvent("BAG_UPDATE")
	end
	
	ItemSlotButtonMixin.OnShow(self)
end

function CharacterItemSlotButtonMixin:OnHide()
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:UnregisterEvent("ITEM_LOCK_CHANGED")
	self:UnregisterEvent("CURSOR_UPDATE")
	self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
	self:UnregisterEvent("SHOW_COMPARE_TOOLTIP")
	self:UnregisterEvent("UPDATE_INVENTORY_ALERTS")
	self:UnregisterEvent("MODIFIER_STATE_CHANGED")

	if self:GetID() == INVSLOT_AMMO then
		self:UnregisterEvent("MERCHANT_UPDATE")
		self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
		self:UnregisterEvent("BAG_UPDATE")
	end

	if EquipmentFlyoutFrame:IsOwnedBy(self.PopoutButton) then
		EquipmentFlyoutFrame:Hide()
	end
end

function CharacterItemSlotButtonMixin:OnEvent(event, arg1, arg2)
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if self:GetID() == arg1 then
			self:MarkDirty()
		end
	elseif event == "UNIT_INVENTORY_CHANGED" then
		if arg1 == self.unit then
			self:MarkDirty()
		end
	elseif event == "ITEM_LOCK_CHANGED" then
		if not arg2 and arg1 == self:GetID() then
			self:UpdateLock()
		end
	elseif event == "BAG_UPDATE_COOLDOWN" or event == "BAG_UPDATE" then
		self:MarkDirty()
	elseif event == "CURSOR_UPDATE" then
		if CursorCanGoInSlot(self:GetID()) then
			self:LockHighlight()
		else
			self:UnlockHighlight()
		end
	elseif event == "SHOW_COMPARE_TOOLTIP" then
		if (arg1 ~= self:GetID()) or (arg2 > NUM_SHOPPING_TOOLTIPS) then
			return
		end

		local tooltip = _G["ShoppingTooltip"..arg2]
		local anchor = "ANCHOR_RIGHT"
		if arg2 > 1 then
			anchor = "ANCHOR_BOTTOMRIGHT"
		end
		tooltip:SetOwner(self, anchor)
		local hasItem = tooltip:SetInventoryItem(self.unit, self:GetID())
		if not hasItem then
			tooltip:Hide()
		end
	elseif event == "UPDATE_INVENTORY_ALERTS" then
		self:MarkDirty()
	elseif event == "MODIFIER_STATE_CHANGED" then
		local mouseover = self:IsMouseOver()
		if IsModifiedClick("SHOWITEMFLYOUT") and mouseover then
			self:OnEnter()
		elseif not self.PopoutButton:IsShown() then
			if mouseover then
				self:OnEnter()
			elseif EquipmentFlyoutFrame:IsOwnedBy(self.PopoutButton) then
				EquipmentFlyoutFrame:Hide()
			end
		end
	elseif event == "MERCHANT_UPDATE" or event == "PLAYERBANKSLOTS_CHANGED" then
		self:MarkDirty()
	end
end

function CharacterItemSlotButtonMixin:UpdateLock()
	if IsInventoryItemLocked(self:GetID()) then
		SetItemButtonDesaturated(self, true)
	else
		SetItemButtonDesaturated(self, false)
	end
end

function CharacterItemSlotButtonMixin:OnEnter()
	if IsModifiedClick("SHOWITEMFLYOUT") then
		EquipmentFlyoutFrame:Open(self.PopoutButton, self.verticalFlyout)
	elseif not self.PopoutButton:IsShown() then
		if EquipmentFlyoutFrame:IsOwnedBy(self.PopoutButton) then
			EquipmentFlyoutFrame:Hide()
		end
	end

	if EquipmentFlyoutFrame:IsOwnedBy(self.PopoutButton) and not self.verticalLayout then
		GameTooltip:SetOwner(EquipmentFlyoutFrameButtons, "ANCHOR_RIGHT", 6, -EquipmentFlyoutFrameButtons:GetHeight() - 6)
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 6, -self:GetHeight() - 6)
	end

	local hasItem, _, repairCost = GameTooltip:SetInventoryItem(self.unit, self:GetID())
	if not hasItem then
		local text = _G[strupper(self.slotName)] or self.slotName
		GameTooltip:SetText(text)
	else
		-- check for appearance applied in this slot and append Transmogrified To: <item>
		local categoryID = AppearanceUtil.GetSlotCategoryID(self:GetID())
		if categoryID then
			local appearanceID = C_Appearance.GetAppearanceForCategory(categoryID)
			if appearanceID then
				local _, displayID, _, displayName = C_Appearance.GetAppearanceDisplayInfo(appearanceID)
				if displayID then
					local item = GetItemInfoInstant(displayID)
					if item then
						local itemName = CreateSquareTextureMarkup(item.icon, 18) .. " " .. ITEM_QUALITY_COLORS[item.quality]:WrapText(displayName)
						GameTooltip:AddLine(TRANSMOGRIFIED_HEADER:format(itemName), TRANSMOG_UNLOCK_COLOR:GetRGB())
					end
				end
			end
		end
	end

	if InRepairMode() and repairCost and (repairCost > 0) then
		GameTooltip:AddLine(REPAIR_COST, nil, nil, nil, true)
		SetTooltipMoney(GameTooltip, repairCost)
	else
		CursorUpdate(self)
	end
	
	GameTooltip:Show()
end

function CharacterItemSlotButtonMixin:OnLeave()
	GameTooltip:Hide()
	ResetCursor()
end

function CharacterItemSlotButtonMixin:Update()
	if self:GetID() == INVSLOT_AMMO and (UnitHasRelicSlot(self.unit) or not IsDefaultClass(self.unit)) then
		self:Hide()
		return
	elseif not self:IsShown() then
		self:Show()
	end
	ItemSlotButtonMixin.Update(self)
	if not AscensionCharacterEquipmentManagerPanel:IsShown() then
		self.ignored = nil
	else
		local currentSet = AscensionCharacterEquipmentManagerPanel:GetSelectedButton()
		if currentSet then
			self.ignored = currentSet:IsSlotLockedForSet(self:GetID())
		else
			self.ignored = nil
		end
	end

	if self.ignored then
		self:ShowIgnoredSlot()
	else
		self:HideIgnoredSlot()
	end

	self:UpdateLock(self)

	-- Update repair all button status
	MerchantFrame_UpdateGuildBankRepair()
	MerchantFrame_UpdateCanRepairAll()
end

function CharacterItemSlotButtonMixin:OnClick(button)
	if IsModifiedClick() then
		return self:OnModifiedClick(button)
	end

	MerchantFrame_ResetRefundItem()
    if AscensionCharacterEquipmentManagerPanel:IsShown() and AscensionCharacterEquipmentManagerPanel:GetSelectedButton() then
        local currentSet = AscensionCharacterEquipmentManagerPanel:GetSelectedButton()
        currentSet:SetSlotLocked(self:GetID(), not currentSet:IsSlotLockedForSet(self:GetID()))
        self:MarkDirty()
        return
    end
	if button == "LeftButton" then
		local type = GetCursorInfo()
		if type == "merchant" and MerchantFrame.extendedCost then
			MerchantFrame_ConfirmExtendedItemCost(MerchantFrame.extendedCost)
		else
			PickupInventoryItem(self:GetID())
			if CursorHasItem() then
				MerchantFrame_SetRefundItem(self, 1)
			end
		end
	else
		UseInventoryItem(self:GetID())
	end
end 

function CharacterItemSlotButtonMixin:OnModifiedClick()
	if ItemSlotButtonMixin.OnModifiedClick(self) then
		return
	end

	if IsModifiedClick("SOCKETITEM") then
		SocketInventoryItem(self:GetID())
	end
end

function CharacterItemSlotButtonMixin:ShowPopoutButton()
	if self.PopoutButton then
		self.PopoutButton:Show()
	end
end 

function CharacterItemSlotButtonMixin:HidePopoutButton()
	if self.PopoutButton then
		self.PopoutButton:Hide()
	end
end

function CharacterItemSlotButtonMixin:ShowIgnoredSlot()
	if self.ignoreTexture then
		self.ignoreTexture:Show()
	end
end

function CharacterItemSlotButtonMixin:HideIgnoredSlot()
	if self.ignoreTexture then
		self.ignoreTexture:Hide()
	end
end

function CharacterItemSlotButtonMixin:SetIgnored(ignored)
	if self.ignored ~= ignored then
		self.ignored = ignored
		self:MarkDirty()
	end
end