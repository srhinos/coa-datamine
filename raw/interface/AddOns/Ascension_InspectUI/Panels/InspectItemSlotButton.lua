InspectItemSlotButtonMixin = CreateFromMixins(ItemSlotButtonMixin)

function InspectItemSlotButtonMixin:OnLoad()
	ItemSlotButtonMixin.OnLoad(self)
	self:SetUnit("target")
end

function InspectItemSlotButtonMixin:OnShow()
	ItemSlotButtonMixin.OnShow(self)
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end 

function InspectItemSlotButtonMixin:OnHide()
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end 

function InspectItemSlotButtonMixin:OnEvent(event, ...)
	if event == "UNIT_INVENTORY_CHANGED" then 
		local unit = ...
		if unit == self.unit then 
			self:Update()
		end 
	end
end


function InspectItemSlotButtonMixin:OnEnter()
	SetInspectedSlot(self:GetID())
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 6, -self:GetHeight() - 6)
	local hasItem = GameTooltip:SetInventoryItem(self.unit, self:GetID())
	if not hasItem then
		local text = _G[strupper(self.slotName)] or self.slotName
		GameTooltip:SetText(text)
	else
		-- check for transomg
		local itemLink = GetInventoryItemLink(self.unit, self:GetID())
		local itemID = itemLink and GetItemInfoFromHyperlink(itemLink)
		local appearanceID = GetInventoryItemID(self.unit, self:GetID())
		if itemID and itemID ~= appearanceID then
			local item = GetItemInfoInstant(appearanceID)
			if item then
				local itemName = CreateSquareTextureMarkup(item.icon, 14) .. " " .. ITEM_QUALITY_COLORS[item.quality]:WrapText(item.name)
				GameTooltip:AddLine(TRANSMOGRIFIED_HEADER:format(itemName), TRANSMOG_UNLOCK_COLOR:GetRGB())
			end
		end
	end
	CursorUpdate(self)
	GameTooltip:Show()
end

function InspectItemSlotButtonMixin:OnLeave()
	GameTooltip:Hide()
	ResetCursor()
end