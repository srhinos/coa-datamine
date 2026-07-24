AddonCompatibility = {
	Registered = {}
}

ClassTalentUtil = ClassTalentUtil or {}
ClassTalentUtil.GetThumbnailAtlas = ClassTalentUtil.GetThumbnailAtlas or function(className, spec)
	if CharacterAdvancementUtil and CharacterAdvancementUtil.GetThumbnailAtlas then
		return CharacterAdvancementUtil.GetThumbnailAtlas(className, spec)
	end

	return "spec-thumbnail-hero-hero"
end

if not VANITY_ITEMS then
	VANITY_ITEMS = setmetatable({}, {
		__index = function(_, itemID)
			if not itemID or not C_VanityCollection or not C_VanityCollection.GetItem then
				return nil
			end

			if not VanityCollectionUtil or not VanityCollectionUtil.GetItem then
				return C_VanityCollection.GetItem(itemID)
			end

			return VanityCollectionUtil.GetItem(itemID)
		end,
	})
end

AddonCompatibility.EventFrame = CreateFrame("Frame")
AddonCompatibility.EventFrame:RegisterEvent("ADDON_LOADED")
AddonCompatibility.EventFrame:SetScript("OnEvent", function(_, event, ...)
	local handler = AddonCompatibility[event]
	if handler then
		handler(AddonCompatibility, ...)
	end
end)

function AddonCompatibility:ADDON_LOADED(addon)
	if self.Registered[addon] then
		for _, func in ipairs(self.Registered[addon]) do
			func()
		end
	end
end

function AddonCompatibility:Register(addon, callback)
	if type(addon) ~= "string" then return end
	if type(callback) ~= "function" then return end
	
	self.Registered[addon] = self.Registered[addon] or {}
	tinsert(self.Registered[addon], callback)
end
