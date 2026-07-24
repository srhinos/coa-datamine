EquipmentSetItemMixin = CreateFromMixins("ScrollListItemBaseMixin")

function EquipmentSetItemMixin:Init()
	ScrollListItemBaseMixin.Init(self)
	self:RegisterForDrag("LeftButton")
	self.Icon:SetBorderTexture("Interface\\Buttons\\UI-Quickslot2")
	self.Icon:SetBorderSize(64, 64)

	self:SetNormalAtlas("Garr_ListButton")
	self:SetHighlightAtlas("Garr_ListButton-Highlight")
	
	self.lockedSlots = {}
end

function EquipmentSetItemMixin:Update()
	local info = self:GetScrollList():GetSetInfoByIndex(self.index)
	self.info = info
	self:CacheLockedSlots()
	self:SetText(info.name)
	self.Icon:SetIcon(info.icon)
	self.dirtyIconIndex = nil
	
	self.IsEquipped:SetShown(self:IsEquippedSet())
end

function EquipmentSetItemMixin:IsEquippedSet()
	local itemIDs = GetEquipmentSetItemIDs(self:GetText() or "")
	if not itemIDs then
		return false
	end

	local slotItemID
	for slot, itemID in pairs(itemIDs) do
		slotItemID = GetInventoryItemTrueID("player", slot) or 0
		if itemID ~= 1 and slotItemID ~= itemID then
			return false
		end
	end
	
	return true
end

function EquipmentSetItemMixin:OnClick(button)
	if button == "LeftButton" and self:IsSelected() then
		self:GetScrollList():SetSelectedIndex(nil, ScrollListMixin.UpdateType.Always)
	else
		ScrollListItemBaseMixin.OnClick(self, button)
	end
end

function EquipmentSetItemMixin:OnSelected()
	if self.info.id == 0 then
		local maxID = 1
		local numSets = GetNumEquipmentSets()
		for i = 1, numSets do
			local name = GetEquipmentSetInfo(i)
			local newSetID = tonumber(name:match(EQUIPMENT_MANAGER_NEW_SET .. " (%d+)"))
			if newSetID then
				maxID = math.max(maxID, newSetID + 1)
			end
		end

		self:GetScrollList():OpenIconSelector(self, EQUIPMENT_MANAGER_NEW_SET .. " " .. maxID, "interface\\icons\\inv_misc_questionmark", function(_, name, icon, iconIndex)
			if string.isNilOrEmpty(name) then
				return
			end
			SaveEquipmentSet(name, iconIndex or 1)
		end)
		self:GetScrollList():SetSelectedIndex(nil, ScrollListMixin.UpdateType.Always)
	end
end

function EquipmentSetItemMixin:OnMouseDown()
	self.Icon:SetPointOffset(1, -1)
	self.Icon:SetBorderTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	self.Icon:SetBorderSize(40, 40)
end

function EquipmentSetItemMixin:OnMouseUp()
	self.Icon:SetPointOffset(0, 0)
	self.Icon:SetBorderTexture("Interface\\Buttons\\UI-Quickslot2")
	self.Icon:SetBorderSize(64, 64)
end

function EquipmentSetItemMixin:OnDragStart()
	self:OnMouseUp()
	if self.info.id == 0 then return end
	PickupEquipmentSet(self.info.id)
end

function EquipmentSetItemMixin:OnEnter()
	if self.info.id == 0 then return end
	self.Controls:Show()
end

function EquipmentSetItemMixin:OnLeave()
	if not self:IsMouseOver() then
		self.Controls:Hide()
	end
end

function EquipmentSetItemMixin:OnHide()
	self:OnLeave()
	self.Icon:SetPointOffset(0, 0)
	self.Icon:SetBorderTexture("Interface\\Buttons\\UI-Quickslot2")
	self.Icon:SetBorderSize(64, 64)
end

function EquipmentSetItemMixin:OnDisable()
	self.Icon:SetIconDesaturated(true)
	self.Text:SetFontObject("GameFontDisable")
	self.Controls:Hide()
end

function EquipmentSetItemMixin:OnEnable()
	self.Icon:SetIconDesaturated(false)
	self.Text:SetFontObject("GameFontHighlight")
	if self:IsMouseOver() and self.info.id ~= 0 then
		self.Controls:Show()
	end
end

function EquipmentSetItemMixin:RequestDelete()
	local name = self.info.name
	local dialog = StaticPopup_Show("CONFIRM_DELETE_EQUIPMENT_SET", name)
	if dialog then
		dialog.data = name
	end
end

function EquipmentSetItemMixin:SetIcon(icon, iconIndex)
	self.Icon:SetIcon(icon)
	self.dirtyIconIndex = iconIndex
end

function EquipmentSetItemMixin:SetName(name)
	if not string.isNilOrEmpty(name) then
		self:SetText(name)
	end
end

function EquipmentSetItemMixin:OnRightClick()
	EquipmentManager_EquipSet(self:GetText())
end

function EquipmentSetItemMixin:ShowIconSelection()
	self:GetScrollList():OpenIconSelector(self)
end

function EquipmentSetItemMixin:SaveChanges()
	local name = self:GetText()
	if not string.isNilOrEmpty(name) then
		RefreshEquipmentSetIconInfo()
		local iconIndex
		-- we didnt change the icon, but we're going to be making a new set, so find the old icon index
		if not self.dirtyIconIndex then
			local iconTexture = self.Icon:GetIcon()
			for i = 1, GetEquipmentSetIconCount() do
				local texture, index = GetEquipmentSetIconInfo(i)
				if iconTexture == texture then
					iconIndex = index
					break
				end
			end
		else
			iconIndex = select(2, GetEquipmentSetIconInfo(self.dirtyIconIndex))
		end

		if not iconIndex then
			iconIndex = 1
		end

		if GetEquipmentSetInfoByName(name) and name ~= self.info.name then
			local dialog = StaticPopup_Show("CONFIRM_OVERWRITE_EQUIPMENT_SET", name)
			if dialog then
				self:CommitLockedSlots()
				dialog.data = name
				dialog.selectedIcon = iconIndex
				dialog.oldSet = self.info.name
			else
				UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0)
			end
			return
		elseif GetNumEquipmentSets() >= MAX_EQUIPMENT_SETS_PER_PLAYER and name ~= self.info.name then
			UIErrorsFrame:AddMessage(EQUIPMENT_SETS_TOO_MANY, 1.0, 0.1, 0.1, 1.0)
			return
		end

		local dialog = StaticPopup_Show("CONFIRM_SAVE_EQUIPMENT_SET", name)
		if dialog then
			self:CommitLockedSlots()
			dialog.data = name
			dialog.selectedIcon = iconIndex
			dialog.oldSet = name ~= self.info.name and self.info.name
		end
	end
end

local equipmentSlots = {}
function EquipmentSetItemMixin:CacheLockedSlots()
	wipe(self.lockedSlots)
	wipe(equipmentSlots)
	GetEquipmentSetLocations(self.info.name, equipmentSlots)
	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		if equipmentSlots[i] == 1 then
			self.lockedSlots[i] = true
		end
	end
end

function EquipmentSetItemMixin:CommitLockedSlots()
	EquipmentManagerClearIgnoredSlotsForSave()
	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		if self.lockedSlots[i] then
			EquipmentManagerIgnoreSlotForSave(i)
		end
	end
end

function EquipmentSetItemMixin:SetSlotLocked(slotID, locked)
	self.lockedSlots[slotID] = locked
end

function EquipmentSetItemMixin:IsSlotLockedForSet(slotID)
	return self.lockedSlots[slotID]
end