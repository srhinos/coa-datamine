C_ContentLoader = {}
ContentFileMixin = {}

C_ContentLoader.Runner = CreateFrame("Frame")
C_ContentLoader.Runner:SetScript("OnUpdate", function(self)
	if not C_ContentLoader:ResumeRoutines() then
		self:Hide()
		collectgarbage("collect")
	end
end)

local ITERATIONS = 100

local jsonFileToCategory = {
	["CharacterAdvancementData"]               = "OVERWRITE_CHARACTER_ADVANCEMENT_DATA_PAYLOAD",
	["EnchantmentToEnchantmentSuggestionData"] = "OVERWRITE_ENCHANTMENT_TO_ENCHANTMENT_SUGGESTION_DATA_PAYLOAD",
	["LFGData"]                                = "OVERWRITE_LFG_DATA_PAYLOAD",
	["MysticEnchantmentData"]                  = "OVERWRITE_MYSTIC_ENCHANTMENT_DATA_PAYLOAD",
	["SpellRankData"]                          = "OVERWRITE_SPELL_RANK_DATA_PAYLOAD",
	["SpellToEnchantmentSuggestionData"]       = "OVERWRITE_SPELL_TO_ENCHANTMENT_SUGGESTION_DATA_PAYLOAD",
	["SpellToSpellSuggestionData"]             = "OVERWRITE_SPELL_TO_SPELL_SUGGESTION_DATA_PAYLOAD",
	["VanityCollectionData"]                   = "OVERWRITE_VANITY_COLLECTION_DATA_PAYLOAD",
	["WorldMapAreaData"]                       = "OVERWRITE_WORLD_MAP_AREA_DATA_PAYLOAD",
	["TradeSkillRecipeData"]                   = "OVERWRITE_TRADE_SKILL_RECIPE_DATA_PAYLOAD",
	["SkillCardData"]                          = "OVERWRITE_SKILL_CARD_DATA_PAYLOAD",
	["SpellToRoleSuggestionData"]              = "OVERWRITE_SPELL_TO_ROLE_SUGGESTION_DATA_PAYLOAD",
	["EnchantmentToRoleSuggestionData"]        = "OVERWRITE_ENCHANTMENT_TO_ROLE_SUGGESTION_DATA_PAYLOAD",
	["SpellToStatSuggestionData"]              = "OVERWRITE_SPELL_TO_STAT_SUGGESTION_DATA_PAYLOAD",
	["EnchantmentToStatSuggestionData"]        = "OVERWRITE_ENCHANTMENT_TO_STAT_SUGGESTION_DATA_PAYLOAD",
	["COASpecData"]                            = "OVERWRITE_COA_SPEC_DATA_PAYLOAD",
	["TransmogrificationItemData"]             = "OVERWRITE_TRANSMOGRIFICATION_ITEM_DATA_PAYLOAD",
	["TransmogrificationItemSetData"]          = "OVERWRITE_TRANSMOGRIFICATION_ITEM_SET_DATA_PAYLOAD",
	["TransmogrificationItemDisplayData"]      = "OVERWRITE_TRANSMOGRIFICATION_ITEM_DISPLAY_DATA_PAYLOAD",
	["HandOfFateQuestData"]                    = "OVERWRITE_HAND_OF_FATE_QUEST_DATA_PAYLOAD",
	["ItemVariationData"]                      = "OVERWRITE_ITEM_VARIATION_DATA_PAYLOAD"
}

local WriteCustomWTF = WriteCustomWTF
local issecure = issecure

local function SaveNewJSON(file, json)
	if issecure() then
		WriteCustomWTF(format("..\\..\\Data\\Content\\%s", file), json)
	end
end

function C_ContentLoader:Load(file)
	local jsonCategory = jsonFileToCategory[file]
	local jsonData

	if jsonCategory and HasJsonCacheData(jsonCategory, 0) then
		local json = GetJsonCacheData(jsonCategory, 0)
		JSON_BENCHMARKS:Time("decode", file)
		jsonData = DecodeJSON(json)
		JSON_BENCHMARKS:Time("decode", file)
		ClearJsonCache(jsonCategory)
		SaveNewJSON(file, json)
	else
		jsonData = DecodeJSONContent(file)

		if not jsonData then
			JSON_BENCHMARKS:Time("decode", file)
			local json = LoadAscensionContentJSON(file)
			if json and json ~= "" then
				jsonData = DecodeJSON(json)
				-- end inside if, so if content fails the decode wont show as finished
				JSON_BENCHMARKS:Time("decode", file)
			end
		end
	end

	assert(jsonData, format("C_ContentLoader: Failed to decode Data\\Content\\%s.json", file))

	local contentFile = CreateFromMixins(ContentFileMixin)
	contentFile.json = jsonData
	contentFile.file = file
	return contentFile
end

function C_ContentLoader:AddToParseQueue(contentFile)
	self.routines = self.routines or {}
	tinsert(self.routines, contentFile:MakeCoroutine())
	self.Runner:Show()
end

function C_ContentLoader:ResumeRoutines()
	if not self.routines then return false end

	local count = #self.routines
	if count == 0 then
		return false
	end

	local iterations = ITERATIONS
	if GetFramerate() < 30 then
		iterations = iterations / 4
	elseif GetFramerate() < 60 then
		iterations = iterations / 2
	end

	while iterations > 0 do
		for i = count, 1, -1 do
			local co = self.routines[i]
			local success, isDone = coroutine.resume(co)
			if success and isDone then
				table.remove(self.routines, i)
				count = count - 1
			end
		end

		if count <= 0 then
			break
		end

		iterations = iterations - 1
	end

	return true
end

function ContentFileMixin:SetParser(parserFunc)
	self.parserFunc = parserFunc
end

function ContentFileMixin:MakeCoroutine()
	return coroutine.create(function()
		JSON_BENCHMARKS:Time("parse-async", self.file)
		for i = 1, #self.json do
			self.parserFunc(i, self.json[i])
			coroutine.yield()
		end
		JSON_BENCHMARKS:Time("parse-async", self.file)

		if self.OnParseComplete then
			self:OnParseComplete()
		end

		coroutine.yield(true)
	end)
end

function ContentFileMixin:ParseAsync()
	if self.parsed then return end
	assert(self.parserFunc, "Content File<" .. self.file .. ">: Tried to parse with no parser function set!")
	self.parsed = true
	C_ContentLoader:AddToParseQueue(self)
end

function ContentFileMixin:Parse()
	if self.parsed then return end
	assert(self.parserFunc, "Content File<" .. self.file .. ">: Tried to parse with no parser function set!")
	JSON_BENCHMARKS:Time("parse", self.file)
	for i = 1, #self.json do
		self.parserFunc(i, self.json[i])
	end
	JSON_BENCHMARKS:Time("parse", self.file)

	self.parsed = true
	if self.OnParseComplete then
		self:OnParseComplete()
	end
end

function ContentFileMixin:GetJsonTable()
	return self.json
end