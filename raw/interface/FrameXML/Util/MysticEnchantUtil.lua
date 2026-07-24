MysticEnchantUtil = {}

function MysticEnchantUtil.IsSpellMysticEnchant(spellID)
	return C_MysticEnchant.GetEnchantInfoBySpell(spellID) ~= nil
end

function MysticEnchantUtil.GetEnchantLink(spellID)
	local enchant =  C_MysticEnchant.GetEnchantInfoBySpell(spellID)
	if not enchant then return end

	local color = ITEM_QUALITY_COLORS[enchant.Quality]
	if color then
		return color:WrapText(format("|Hspell:%s|h[%s]|h", spellID, enchant.SpellName))
	else
		return GRAY_FONT_COLOR:WrapText(format("|Hspell:%s|h[%s]|h", spellID, enchant.SpellName))
	end
end

function MysticEnchantUtil.GetLegendaryEnchantID(unit)
	for i = 1, NUM_MYSTIC_ENCHANT_SLOTS do
		local spellID = C_MysticEnchant.GetAppliedEnchant(unit, i)
		if spellID then
			local enchant = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
			if enchant then
				local quality = Enum.EnchantQualityEnum[enchant.Quality]
				if quality == Enum.ItemQuality.Legendary then
					return spellID
				end
			end
		end
	end
end

function MysticEnchantUtil.GetAppliedEnchantCountByQuality(unit)
	local enchants = {}
	for i = 1, NUM_MYSTIC_ENCHANT_SLOTS do
		local spellID = C_MysticEnchant.GetAppliedEnchant(unit, i)
		if spellID then
			local enchant = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
			if enchant then
				local quality = Enum.EnchantQualityEnum[enchant.Quality]
				if not enchants[quality] then
					enchants[quality] = {}
				end
				
				if not enchants[quality][spellID] then
					enchants[quality][spellID] = 0
				end

				enchants[quality][spellID] = enchants[quality][spellID] + 1
			end
		end
	end
	
	return enchants
end

function MysticEnchantUtil.GetAppliedEnchants(unit)
	local enchants = {}
	for i = 1, NUM_MYSTIC_ENCHANT_SLOTS do
		local spellID = C_MysticEnchant.GetAppliedEnchant(unit, i)
		if spellID and spellID ~= 0 then
			if not enchants[spellID] then
				enchants[spellID] = 1
			else
				enchants[spellID] = enchants[spellID] + 1
			end
		end
	end
	return enchants
end

function MysticEnchantUtil.IsEnchantApplied(unit, spellID)
	for i = 1, NUM_MYSTIC_ENCHANT_SLOTS do
		if spellID == C_MysticEnchant.GetAppliedEnchant(unit, i) then
			return true
		end
	end
end 

function MysticEnchantUtil.HasUnlockedEnchantTab()
	return true
end 

function MysticEnchantUtil.NeedsToPurchaseExtract()
	return GetItemCount(ItemData.MYSTIC_EXTRACT) <= 0
end 