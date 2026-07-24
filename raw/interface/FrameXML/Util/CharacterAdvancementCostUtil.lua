ABILITY_PURGE_MARK_OF_ASCENSION_COST = 10000
TALENT_PURGE_MARK_OF_ASCENSION_COST = 7500
UNLEARN_ABILITY_MARK_OF_ASCENSION_COST = 250
ABILITY_PURGE_MARK_OF_ASCENSION_COA_COST_PER_LEVEL = 167
TALENT_PURGE_MARK_OF_ASCENSION_COA_COST_PER_LEVEL = 125
UNLEARN_ABILITY_MARK_OF_ASCENSION_COA_COST_PER_LEVEL = 4
FREE_RESET_LEVEL = 10

CACostUtil = {}

local function CalculateResetCostGold(level, value)
	if (IsCustomClass()) then
		return ((value * 416.666666667) + (1.16220833333 * math.pow(level, 2)) + (18.7038333333 * level) - 359.025) * level * 0.25
	else
		return ((value * 50000) + (139.465 * math.pow(level, 2)) + (2244.46 * level) - 43083)
	end
end

local function CalculateResetCostTalentsMarks(level)
	if (IsCustomClass()) then
		return TALENT_PURGE_MARK_OF_ASCENSION_COA_COST_PER_LEVEL * level
	else
		return TALENT_PURGE_MARK_OF_ASCENSION_COST
	end
end

local function CalculateResetCostAbilityMarks(level)
	if (IsCustomClass()) then
		return ABILITY_PURGE_MARK_OF_ASCENSION_COA_COST_PER_LEVEL  * level
	else
		return ABILITY_PURGE_MARK_OF_ASCENSION_COST
	end
end

function CACostUtil:GetUnlearnMarksCost(level)
	if IsCustomClass() then
		return UNLEARN_ABILITY_MARK_OF_ASCENSION_COA_COST_PER_LEVEL * level
	else
		return UNLEARN_ABILITY_MARK_OF_ASCENSION_COST
	end
end

function CACostUtil:GetUnlearnCostPerLevel(level)
    local costPerLevel = 0

  	if (level <= 19) then
        costPerLevel = 32
    elseif (level >= 20) and (level <= 29) then
        costPerLevel = 71
    elseif (level >= 30) and (level <= 49) then
        costPerLevel = 521
    elseif (level >= 50) and (level <= 59) then
        costPerLevel = 1107
    elseif (level >= 60) then
        costPerLevel = 2221
    end

    return costPerLevel
end

function CACostUtil:GetUnlearnMoneyCost(level, abilityUnlearns, talentUnlearns, talentRank)
    if level <= FREE_RESET_LEVEL then
        return 0
    end

    local costPerLevel = IsCustomClass() and CACostUtil:GetUnlearnCostPerLevel(level)*0.25 or CACostUtil:GetUnlearnCostPerLevel(level)
    local bonusCost = 0

    if (IsCustomClass()) then
    	abilityUnlearns = abilityUnlearns or CA_GetCreditAmount(Enum.ResetCreditType.AbilityUnlearn)
    	talentUnlearns = talentUnlearns or CA_GetCreditAmount(Enum.ResetCreditType.TalentUnlearn)
    	bonusCost = (abilityUnlearns + talentUnlearns) * 4.16666666667 * level * 0.25

    	return (level * costPerLevel) + bonusCost
    end

    talentRank = 0 -- before it used to be level + talentrank, now it seem to care just about level (old logic from ServerEBB.lua)

    return (level+talentRank)*costPerLevel -- from CA
end

-- TODO: Probably get rid of next reset cost?
function CACostUtil:GetResetCost(resetCreditType, purgeIndexTable)
	local level = UnitLevel("player")
	local isFree = (level < FREE_RESET_LEVEL)
	local cost = {
		[Enum.UnlearnCost.Gold] = 0,
		[Enum.UnlearnCost.MarksOfAscension] = 0,
	}

	for _, costIndex in pairs(purgeIndexTable) do -- here we make reset cost talent purge, ability purge etc
		cost[costIndex] = isFree and 0 or 1
	end

	if isFree then
		return cost
	end

	cost[Enum.UnlearnCost.Gold] = CalculateResetCostGold(level, CA_GetCreditAmount(resetCreditType))
	cost[Enum.UnlearnCost.MarksOfAscension] = (resetCreditType == Enum.ResetCreditType.AbilityReset) and CalculateResetCostAbilityMarks(level) or CalculateResetCostTalentsMarks(level)

	return cost
end

function CACostUtil:GetSingleAbilityResetCost()
	return self:GetResetCost(Enum.ResetCreditType.AbilityReset, {Enum.UnlearnCost.AbilityPurge, Enum.UnlearnCost.ClassPurge})
end

function CACostUtil:GetSingleTalentResetCost()
	return self:GetResetCost(Enum.ResetCreditType.TalentReset, {Enum.UnlearnCost.TalentPurge, Enum.UnlearnCost.SpecializationPurge})
end

function CACostUtil:GetSingleUnlearnCost(internalID, abilityUnlearns, talentUnlearns)
	local level = UnitLevel("player")
	local isWildcard = C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)

	local cost = { 
		[Enum.UnlearnCost.ScrollOfUnlearning] = 0,
		[Enum.UnlearnCost.ScrollOfFortune] = 0,
		[Enum.UnlearnCost.ScrollOfFortuneAbilities] = 0,
		[Enum.UnlearnCost.ScrollOfFortuneTalents] = 0,
		[Enum.UnlearnCost.MarksOfAscension] = 0,
		[Enum.UnlearnCost.Gold] = 0 
	}

	if (isWildcard) then
		if (C_Wildcard.WillRollStartingAbilities() or (C_CharacterAdvancement.GetLearnedAE() <= 8)) then
			return cost
		end
		cost[Enum.UnlearnCost.ScrollOfFortuneAbilities] = 1
		cost[Enum.UnlearnCost.ScrollOfFortuneTalents] = 1
		cost[Enum.UnlearnCost.ScrollOfFortune] = 1
	else
		if (level < FREE_RESET_LEVEL) then
			return cost
		end

		local currentRank = C_CharacterAdvancement.IsTalentID(internalID) and C_CharacterAdvancement.GetTalentRankByID(internalID)

		cost[Enum.UnlearnCost.ScrollOfUnlearning] = 1
		cost[Enum.UnlearnCost.Gold] = self:GetUnlearnMoneyCost(level, abilityUnlearns, talentUnlearns, currentRank)
		cost[Enum.UnlearnCost.MarksOfAscension] = self:GetUnlearnMarksCost(level)
	end

	return cost
end

function CACostUtil:GetWildcardIndexTableForInternalID(internalID)
	if C_CharacterAdvancement.IsAbilityID(internalID) or C_CharacterAdvancement.IsTalentAbilityID(internalID) then
		return {Enum.UnlearnCost.ScrollOfFortuneAbilities, Enum.UnlearnCost.ScrollOfFortune}
	else
		return {Enum.UnlearnCost.ScrollOfFortuneTalents, Enum.UnlearnCost.ScrollOfFortune}
	end
end

function CACostUtil:GetSpellsResetCostWildCard(unlearnList) -- does not support CoA
	local items = {
		[Enum.UnlearnCost.ScrollOfFortuneAbilities] = GetTokenCount(TokenUtil.GetScrollOfFortuneAbilitiesForSpec()),
		[Enum.UnlearnCost.ScrollOfFortuneTalents] = GetTokenCount(TokenUtil.GetScrollOfFortuneTalentsForSpec()),
		[Enum.UnlearnCost.ScrollOfFortune] = GetTokenCount(TokenUtil.GetScrollOfFortuneForSpec()),
	}
	local indexTable = {}
	local finalCost = {}

	if (type(unlearnList) == "number") then
		local internalID = unlearnList

		indexTable = self:GetWildcardIndexTableForInternalID(internalID)

		if not CharacterAdvancementUtil.IsUnlearnFreeForID(internalID) then
			CostUtil:FinalazeCost(items, self:GetSingleUnlearnCost(internalID), finalCost, indexTable)
		end

		return finalCost
	end

	for i = 1, #unlearnList do
		local internalID = unlearnList[i]

		indexTable = self:GetWildcardIndexTableForInternalID(internalID)

    	if not CharacterAdvancementUtil.IsUnlearnFreeForID(internalID) then
			CostUtil:FinalazeCost(items, self:GetSingleUnlearnCost(internalID), finalCost, indexTable)
		end
	end

	return finalCost

end

function CACostUtil:GetSpellsResetCost(unlearnList)
	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		return self:GetSpellsResetCostWildCard(unlearnList)
	end

	local items = {
		[Enum.UnlearnCost.ScrollOfUnlearning] = GetItemCount(ItemData.SCROLL_OF_UNLEARNING),
		[Enum.UnlearnCost.MarksOfAscension] = GetItemCount(ItemData.MARK_OF_ASCENSION),
	}

	local indexTable = {Enum.UnlearnCost.ScrollOfUnlearning, Enum.UnlearnCost.MarksOfAscension, Enum.UnlearnCost.Gold}
	local finalCost = {}

	local abilityUnlearns = CA_GetCreditAmount(Enum.ResetCreditType.AbilityUnlearn)
	local talentUnlearns = CA_GetCreditAmount(Enum.ResetCreditType.TalentUnlearn)

	if (type(unlearnList) == "number") then
		local internalID = unlearnList

		if not CharacterAdvancementUtil.IsUnlearnFreeForID(internalID) then
			CostUtil:FinalazeCost(items, self:GetSingleUnlearnCost(internalID, abilityUnlearns, talentUnlearns), finalCost, indexTable)
		end

		return finalCost
	end

	for i = 1, #unlearnList do
		local internalID = unlearnList[i]

    	if not CharacterAdvancementUtil.IsUnlearnFreeForID(internalID) then
			CostUtil:FinalazeCost(items, self:GetSingleUnlearnCost(internalID, abilityUnlearns, talentUnlearns), finalCost, indexTable)

			if C_CharacterAdvancement.IsTalentID(internalID) then
				talentUnlearns = talentUnlearns + 1
			else
				abilityUnlearns = abilityUnlearns + 1
			end
		end
	end

	return finalCost
end

-------------------------------------------------------------------------------
--                                Full Resets                                --
-------------------------------------------------------------------------------

function CACostUtil:GetAbilityResetCost(items, indexTable)
	items = items or {
		[Enum.UnlearnCost.AbilityPurge] = GetItemCount(ItemData.ABILITY_PURGE),
		[Enum.UnlearnCost.ClassPurge] = GetItemCount(ItemData.CLASS_PURGE),
		[Enum.UnlearnCost.MarksOfAscension] = GetItemCount(ItemData.MARK_OF_ASCENSION),
	}

	indexTable = indexTable or {Enum.UnlearnCost.AbilityPurge, Enum.UnlearnCost.ClassPurge, Enum.UnlearnCost.MarksOfAscension, Enum.UnlearnCost.Gold}

	return CostUtil:FinalazeCost(items, self:GetSingleAbilityResetCost(), {}, indexTable)
end

function CACostUtil:GetTalentResetCost(items, indexTable)
	items = items or {
		[Enum.UnlearnCost.TalentPurge] = GetItemCount(ItemData.TALENT_PURGE),
		[Enum.UnlearnCost.SpecializationPurge] = GetItemCount(ItemData.SPECIALIZATION_PURGE),
		[Enum.UnlearnCost.MarksOfAscension] = GetItemCount(ItemData.MARK_OF_ASCENSION),
	}

	indexTable = indexTable or {Enum.UnlearnCost.TalentPurge, Enum.UnlearnCost.SpecializationPurge, Enum.UnlearnCost.MarksOfAscension, Enum.UnlearnCost.Gold}

	return CostUtil:FinalazeCost(items, self:GetSingleTalentResetCost(), {}, indexTable)
end

-- this method combines actual cost of talent/ability reset
function CACostUtil:GetAbilityAndTalentResetCost()
	local cost = {}
	local costTalentReset = self:GetTalentResetCost()

	local items = {
		[Enum.UnlearnCost.AbilityPurge] = GetItemCount(ItemData.ABILITY_PURGE),
		[Enum.UnlearnCost.ClassPurge] = GetItemCount(ItemData.CLASS_PURGE),
		[Enum.UnlearnCost.MarksOfAscension] = GetItemCount(ItemData.MARK_OF_ASCENSION),
	}
	local indexTable = {Enum.UnlearnCost.AbilityPurge, Enum.UnlearnCost.ClassPurge, Enum.UnlearnCost.MarksOfAscension, Enum.UnlearnCost.Gold}

	if (costTalentReset[Enum.UnlearnCost.MarksOfAscension]) then
		items[Enum.UnlearnCost.MarksOfAscension] = items[Enum.UnlearnCost.MarksOfAscension] - costTalentReset[Enum.UnlearnCost.MarksOfAscension]
		if (items[Enum.UnlearnCost.MarksOfAscension] <= 0) then
			items[Enum.UnlearnCost.MarksOfAscension] = nil
			table.remove(indexTable, 3)
		end
	end

	local cost = self:GetAbilityResetCost(items, indexTable)

	CostUtil:MergeCosts(cost, costTalentReset)

	return cost
end

function CACostUtil:ResetCheck()
    if C_Player:InCombat() then
        UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0, 0)
        return false
    end

    if C_Player:IsImmune() then
        UIErrorsFrame:AddMessage("Cannot do while affected by an immunity.", 1, 0, 0)
        return false
    end

    return true
end