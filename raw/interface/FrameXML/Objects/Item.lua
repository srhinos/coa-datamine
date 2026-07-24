Item = {}
ItemMixin = {}

-- cache items and reuse
Item.Cache = {}
setmetatable(Item.Cache, {__mode = "kv"})

function Item:CreateFromID(itemID)
	if itemID and self.Cache[itemID] then
		return self.Cache[itemID]
	end

	local item = CreateFromMixins(ItemMixin)
	item:SetItemID(itemID)

	if issecure() and itemID then
		self.Cache[itemID] = item
	end
	return item
end

function Item:CreateFromLink(itemLink)
	local itemID = GetItemInfoFromHyperlink(itemLink)
	return self:CreateFromID(itemID)
end

function ItemMixin:Query()
	if not self:IsCached() then
		ItemQueryListener:Query(self.itemID)
	end
end

function ItemMixin:SetItemID(itemID)
	self.itemID = itemID and tonumber(itemID)
	self.instantInfo = nil
end

function ItemMixin:GetItemID()
	return self.itemID
end

function ItemMixin:Clear()
	self.itemID = nil
	self.instantInfo = nil
end

function ItemMixin:IsEmpty()
	return not self.itemID or type(self.itemID) ~= "number" or self.itemID <= 0
end

function ItemMixin:GetInfo()
	if self:IsEmpty() then return end
	
	return GetItemInfo(self.itemID)
end

function ItemMixin:GetInfoInstant()
	if self:IsEmpty() then return end
	if not self.instantInfo then
		self.instantInfo = GetItemInfoInstant(self.itemID)
	end
	
	return self.instantInfo or {}
end

function ItemMixin:GetFlavorText()
	if self:IsEmpty() then return end
	return GetItemFlavorText(self.itemID)
end

function ItemMixin:GetIconTextureMarkup(size, xOffset, yOffset)
	if self:IsEmpty() then return end
	return CreateSquareTextureMarkup(self:GetIcon(), size or 20, size or 20, xOffset, yOffset)
end

function ItemMixin:GetPvPPower()
	if self:IsEmpty() then return end
	return GetItemPvPPower(self.itemID)
end

function ItemMixin:GetPvEPower()
	if self:IsEmpty() then return end
	return GetItemPvEPower(self.itemID)
end

function ItemMixin:GetQuality()
	if self:IsEmpty() then return end
	local quality = select(3, GetItemInfo(self.itemID))
	return quality or GetItemQuality(self.itemID)
end

function ItemMixin:GetName()
	if self:IsEmpty() then return end
	local name = GetItemInfo(self.itemID)
	return name or GetItemName(self.itemID)
end

function ItemMixin:GetClassID()
	if self:IsEmpty() then return end
	return GetItemClassID(self.itemID)
end

function ItemMixin:GetSubClassID()
	if self:IsEmpty() then return end
	return GetItemSubClassID(self.itemID)
end

function ItemMixin:GetIcon()
	if self:IsEmpty() then return end
	return GetItemIcon(self.itemID) or "Interface\\Icons\\"..(GetItemIconInstant(self.itemID) or "inv_misc_questionmark")
end

function ItemMixin:GetLink()
	if self:IsEmpty() then return end
	local link = select(2, GetItemInfo(self.itemID))
	if not link then
		local quality = self:GetQuality()
		local name = self:GetName()
		local itemID = self:GetItemID()
		if not name then
			return C_Logger.Error("Could not find name for ItemID: %s", self:GetItemID() or "nil")
		end
		local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1]
		link = color:WrapText("|Hitem:"..itemID.."|h["..name.."]|h|r")
	end
	return link
end

function ItemMixin:GetIconLink(size, xOffset, yOffset)
	if self:IsEmpty() then return end
	local link = self:GetLink()
	if not link then return end
	
	local icon = self:GetIconTextureMarkup(size, xOffset, yOffset)
	return icon .. " " .. link
end

function ItemMixin:GetAbbreviation()
	local name = self:GetName()
	local abbr = name:sub(1,1)
	for text in name:gmatch("%s(%w)") do
		abbr = abbr .. text
	end
	
	return abbr
end

function ItemMixin:IsBloodforged()
	if self:IsEmpty() then return end
	local flavor = self:GetFlavorText()
	return flavor and flavor:find("Bloodforged", 1, true) ~= nil
end

function ItemMixin:IsAscended()
	if self:IsEmpty() then return end
	local flavor = self:GetFlavorText()
	return flavor and flavor:find("Ascended", 1, true) ~= nil
end

function ItemMixin:IsMythic()
	if self:IsEmpty() then return end
	local flavor = self:GetFlavorText()
	return flavor and flavor:find("Mythic", 1, true) ~= nil
end

function ItemMixin:GetMythicLevel()
	if self:IsEmpty() then return end
	local flavor = self:GetFlavorText()
	if flavor and flavor:find("Mythic", 1, true) ~= nil then
		local level = flavor:match("Mythic (.*)")
		level = level and tonumber(level)
		return level
	end
end

function ItemMixin:IsHeroic()
	if self:IsEmpty() then return end
	local flavor = self:GetFlavorText()
	return flavor and flavor:find("Heroic", 1, true) ~= nil
end

function ItemMixin:IsCached()
	if self:IsEmpty() then return false end
	return self:GetInfo() ~= nil
end

-- adds a callback to be executed when this item data is available, executes immediately if already loaded.
function ItemMixin:ContinueOnLoad(func)
	if type(func) ~= "function" or self:IsEmpty() then
		error("Usage: NonEmptyItem:ContinueOnLoad(function)", 2)
	end

	if self:IsCached() then
		func(self.itemID)
		return
	end

	ItemQueryListener:AddCallback(self.itemID, func)
end

-- returns a function that will cancel this callback when called
function ItemMixin:CancelableContinueOnLoad(func)
	if type(func) ~= "function" or self:IsEmpty() then
		error("Usage: NonEmptyItem:CancelableContinueOnLoad(function)", 2)
	end

	if self:IsCached() then
		func(self.itemID)
		return
	end

	return ItemQueryListener:AddCancelableCallback(self.itemID, func)
end 

