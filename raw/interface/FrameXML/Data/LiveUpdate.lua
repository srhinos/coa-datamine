local LiveUpdate = {}
local ReadCustomWTF = ReadCustomWTF
local WriteCustomWTF = WriteCustomWTF
local currentFormat = "..\\..\\Data\\Content\\%s"
local oldFormat = "..\\..\\Data\\Content\\%s-old"
local GetJsonCacheData = GetJsonCacheData
local ClearJsonCache = ClearJsonCache
local issecure = issecure
local format = format

local function Write(file, text)
	local old = ReadCustomWTF(format(currentFormat, file))
	if old and old ~= "" then
		WriteCustomWTF(format(oldFormat, file), old)
	end

	WriteCustomWTF(format(currentFormat, file), text)
	UpdateAlertToast:Show()
end

LiveUpdate.Events = {
	["OVERWRITE_CHARACTER_ADVANCEMENT_DATA_PAYLOAD"] = "CharacterAdvancementData",
	["OVERWRITE_ENCHANTMENT_TO_ENCHANTMENT_SUGGESTION_DATA_PAYLOAD"] = "EnchantmentToEnchantmentSuggestionData",
	["OVERWRITE_LFG_DATA_PAYLOAD"] = "LFGData",
	["OVERWRITE_MYSTIC_ENCHANTMENT_DATA_PAYLOAD"] = "MysticEnchantmentData",
	["OVERWRITE_SPELL_RANK_DATA_PAYLOAD"] = "SpellRankData",
	["OVERWRITE_SPELL_TO_ENCHANTMENT_SUGGESTION_DATA_PAYLOAD"] = "SpellToEnchantmentSuggestionData",
	["OVERWRITE_SPELL_TO_SPELL_SUGGESTION_DATA_PAYLOAD"] = "SpellToSpellSuggestionData",
	["OVERWRITE_VANITY_COLLECTION_DATA_PAYLOAD"] = "VanityCollectionData",
	["OVERWRITE_WORLD_MAP_AREA_DATA_PAYLOAD"] = "WorldMapAreaData",
	["OVERWRITE_TRADE_SKILL_RECIPE_DATA_PAYLOAD"] = "TradeSkillRecipeData",
	["OVERWRITE_SKILL_CARD_DATA_PAYLOAD"] = "SkillCardData",
	["OVERWRITE_SPELL_TO_ROLE_SUGGESTION_DATA_PAYLOAD"] = "SpellToRoleSuggestionData",
	["OVERWRITE_ENCHANTMENT_TO_ROLE_SUGGESTION_DATA_PAYLOAD"] = "EnchantmentToRoleSuggestionData",
	["OVERWRITE_SPELL_TO_STAT_SUGGESTION_DATA_PAYLOAD"] = "SpellToStatSuggestionData",
	["OVERWRITE_ENCHANTMENT_TO_STAT_SUGGESTION_DATA_PAYLOAD"] = "EnchantmentToStatSuggestionData",
	["OVERWRITE_COA_SPEC_DATA_PAYLOAD"] = "COASpecData",
	["OVERWRITE_TRANSMOGRIFICATION_ITEM_DATA_PAYLOAD"] = "TransmogrificationItemData",
	["OVERWRITE_TRANSMOGRIFICATION_ITEM_SET_DATA_PAYLOAD"] = "TransmogrificationItemSetData",
	["OVERWRITE_TRANSMOGRIFICATION_ITEM_DISPLAY_DATA_PAYLOAD"] = "TransmogrificationItemDisplayData",
	["OVERWRITE_HAND_OF_FATE_QUEST_DATA_PAYLOAD"] = "HandOfFateQuestData",
	["OVERWRITE_ITEM_VARIATION_DATA_PAYLOAD"] = "ItemVariationData"
}

local f = CreateFrame("Frame")

f:RegisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST")
f:RegisterEvent("HOT_PATCH_VANITY_COLLECTION")

f:SetScript("OnEvent", function(self, event, ...)
	if not issecure() then return end

	if event == "HOT_PATCH_VANITY_COLLECTION" then
		local itemID = ...
		itemID = itemID and tonumber(itemID)
		if itemID and VanityCollectionUtil then
			VanityCollectionUtil.InvalidateItem(itemID)
		end
		return
	end

	local subEvent = ...
	event = subEvent:match("ASCENSION_CUSTOM_JSON_(.*)_UPDATE")
	if not event then return end

	local id = select(2, ...)
	
	if not HasJsonCacheData(event, id) then
		return
	end

	if LiveUpdate.Events[event] then
		local json = GetJsonCacheData(event, 0)
		if json and strlen(json) > 0 then
			Write(LiveUpdate.Events[event], json)
		end
		
		ClearJsonCache(event)
	end
end)

if C_Realm.IsDevelopment() then
	function RegisterTempLiveUpdate(category, file)
		LiveUpdate.Events[category] = file
	end

	function UnRegisterTempLiveUpdate(category)
		LiveUpdate.Events[category] = nil
	end
end 
