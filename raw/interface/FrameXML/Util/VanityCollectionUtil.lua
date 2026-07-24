VanityCollectionUtil = {}

local itemCache = {}
local spellReferenceCache = {}
local contentReferenceCache = {}
local seasonalShowcaseItems

function VanityCollectionUtil.GetItem(itemID)
	itemID = itemID and tonumber(itemID)
	if not itemID then
		return nil
	end

	local cached = itemCache[itemID]
	if cached ~= nil then
		return cached
	end

	local item = C_VanityCollection.GetItem(itemID)
	if item then
		itemCache[itemID] = item
	end
	return item
end

function VanityCollectionUtil.GetItemByLearnedSpell(spellID)
	spellID = spellID and tonumber(spellID)
	if not spellID then
		return nil
	end

	local cached = spellReferenceCache[spellID]
	if cached ~= nil then
		return cached and VanityCollectionUtil.GetItem(cached) or nil
	end

	local item = C_VanityCollection.GetItemByLearnedSpell(spellID)
	spellReferenceCache[spellID] = item and item.itemid or false
	return item
end

function VanityCollectionUtil.GetOwnerByContentItem(itemID)
	itemID = itemID and tonumber(itemID)
	if not itemID then
		return nil
	end

	local cached = contentReferenceCache[itemID]
	if cached ~= nil then
		return cached and VanityCollectionUtil.GetItem(cached) or nil
	end

	local item = C_VanityCollection.GetOwnerByContentItem(itemID)
	contentReferenceCache[itemID] = item and item.itemid or false
	return item
end

function VanityCollectionUtil.GetSeasonalShowcaseItems()
	if seasonalShowcaseItems then
		return seasonalShowcaseItems
	end

	seasonalShowcaseItems = C_VanityCollection.GetSeasonalShowcaseItems and C_VanityCollection.GetSeasonalShowcaseItems() or {}
	return seasonalShowcaseItems
end

function VanityCollectionUtil.InvalidateItem(itemID)
	itemID = itemID and tonumber(itemID)
	if itemID then
		itemCache[itemID] = nil
	else
		wipe(itemCache)
	end

	wipe(spellReferenceCache)
	wipe(contentReferenceCache)
	seasonalShowcaseItems = nil
end
