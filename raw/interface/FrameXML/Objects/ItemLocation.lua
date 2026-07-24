ItemLocation = {}
ItemLocationMixin = {}

function ItemLocation:CreateEmpty()
	return CreateFromMixins(ItemLocationMixin)
end

function ItemLocation:CreateFromBagAndSlot(bag, slot)
	local location = CreateFromMixins(ItemLocationMixin)
	location:SetBagAndSlot(bag, slot)
	return location
end

function ItemLocation:CreateFromEquipmentSlot(slot)
	local location = CreateFromMixins(ItemLocationMixin)
	location:SetEquipmentSlot(slot)
	return location
end

function ItemLocationMixin:Clear()
	self.bag = nil
	self.slot = nil
	self.equipmentSlot = nil
end

function ItemLocationMixin:SetBagAndSlot(bag, slot)
	self:Clear()
	
	self.bag = bag
	self.slot = slot
end

function ItemLocationMixin:GetBagAndSlot()
	return self.bag, self.slot
end

function ItemLocationMixin:SetEquipmentSlot(slot)
	self:Clear()
	self.equipmentSlot = slot
end

function ItemLocationMixin:GetEquipmentSlot()
	return self.equipmentSlot
end

function ItemLocationMixin:IsEquipmentSlot()
	return self.equipmentSlot ~= nil
end

function ItemLocationMixin:IsBagAndSlot()
	return self.bag ~= nil and self.slot ~= nil
end

function ItemLocationMixin:HasAnyLocation()
	return self:IsEquipmentSlot() or self:IsBagAndSlot()
end

function ItemLocationMixin:IsValid()
	if self:IsEquipmentSlot() then
		return GetInventoryItemID("player", self:GetEquipmentSlot()) ~= nil
	elseif self:IsBagAndSlot() then
		return GetContainerItemID(self:GetBagAndSlot())
	end
end

function ItemLocationMixin:IsEqualToBagAndSlot(otherBag, otherSlot)
	local bag, slot = self:GetBagAndSlot()

	if bag and slot then
		return bag == otherBag and slot == otherSlot
	end
	
	return false
end

function ItemLocationMixin:IsEqualToEquipmentSlot(otherSlot)
	local slot = self:GetEquipmentSlot()

	if slot then
		return slot == otherSlot
	end
	
	return false
end 

function ItemLocationMixin:IsEqualToLocation(otherLocation)
	if not otherLocation then return end
	
	local bag, slot = self:GetBagAndSlot()
	if bag and slot then
		local otherBag, otherSlot = otherLocation:GetBagAndSlot()
		return bag == otherBag, slot == otherSlot
	end
	
	local equipmentSlot = self:GetEquipmentSlot()
	if equipmentSlot then
		local otherSlot = otherLocation:GetEquipmentSlot()
		return equipmentSlot == otherSlot
	end
	
	return not otherLocation:HasAnyLocation()
end