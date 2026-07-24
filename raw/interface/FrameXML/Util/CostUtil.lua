CostUtil = {}

function CostUtil:GetScrollOfFortuneTalentsForSpec(specID)
	return ScrollsOfFortuneTalents[specID or SpecializationUtil.GetActiveSpecialization()] or ScrollsOfFortuneTalents[1]
end

function CostUtil:GetScrollOfFortuneAbilitiesForSpec(specID)
	return ScrollsOfFortuneAbilities[specID or SpecializationUtil.GetActiveSpecialization()] or ScrollsOfFortuneAbilities[1]
end

function CostUtil:GetScrollOfFortuneForSpec(specID)
	return ScrollsOfFortune[specID or SpecializationUtil.GetActiveSpecialization()] or ScrollsOfFortune[1]
end

function CostUtil:GetHandOfFateForSpec(specID)
	return HandsOfFate[specID or SpecializationUtil.GetActiveSpecialization()] or HandsOfFate[1]
end

-- unlearnCosts indexes should contain all indexTable indexes and vise versa
function CostUtil:FinalazeCost(items, unlearnCosts, finalCost, indexTable, index)
	index = index or 1
	-- indexTable contains list of currencies in appropriate order
	local costIndex = indexTable[index]

	local cost = unlearnCosts[costIndex]
	 -- newCount. Does not exist for gold since if you can't pay 
	 -- via items you should have cost displayed in gold
	local newCount = items[costIndex] and (items[costIndex] - cost)

	if not(newCount) or not(next(indexTable, index)) then -- is a final index
		finalCost[costIndex] = finalCost[costIndex] and (finalCost[costIndex] + unlearnCosts[costIndex]) or unlearnCosts[costIndex]
		return finalCost
	else
		if cost and (cost > 0) and (newCount >= 0) then
			finalCost[costIndex] = finalCost[costIndex] and (finalCost[costIndex] + cost) or cost
			items[costIndex] = newCount
			return finalCost
		end
	end

	return self:FinalazeCost(items, unlearnCosts, finalCost, indexTable, index+1)
end

function CostUtil:MergeCosts(costA, costB)
	for index, amount in pairs(costB) do
		costA[index] = costA[index] and (costA[index] + amount) or amount
	end
end

function CostUtil:CanPayThePrice(priceTable)
	local canPay = true
	local isFree = true

	if not(priceTable) or not(next(priceTable)) then
		return canPay, isFree
	end

	for index, amount in pairs(priceTable) do
		if amount ~= 0 then
			isFree = false
		end

		if (index == Enum.UnlearnCost.ScrollOfFortune) then
			if (amount > GetTokenCount(TokenUtil.GetScrollOfFortuneForSpec())) then
				canPay = false
				break
			end
		elseif (index == Enum.UnlearnCost.ScrollOfFortuneAbilities) then
			if (amount > GetTokenCount(TokenUtil.GetScrollOfFortuneAbilitiesForSpec())) then
				canPay = false
				break
			end
		elseif (index == Enum.UnlearnCost.ScrollOfFortuneTalents) then
			if (amount > GetTokenCount(TokenUtil.GetScrollOfFortuneTalentsForSpec())) then
				canPay = false
				break
			end
		elseif (index == Enum.UnlearnCost.Gold) then
			if (amount > GetMoney()) then
				canPay = false
				break
			end
		else 
			if (amount > GetItemCount(index)) then
				canPay = false
				break
			end
		end
	end

	return canPay, isFree
end

function CostUtil:FormatCost(index, amount, onlyIcon)
	if (index == Enum.UnlearnCost.Gold) then
        local gold, silver, copper = GetGoldForMoney(amount)
        return string.format(GOLD_AMOUNT_TEXTURE, gold, 11, 11).." "..string.format(SILVER_AMOUNT_TEXTURE, silver, 11, 11).." "..string.format(COPPER_AMOUNT_TEXTURE, copper, 11, 11)
    else
    	local item
    	
		if (index == Enum.UnlearnCost.ScrollOfFortune) then
			item = Item:CreateFromID(self:GetScrollOfFortuneForSpec())
		elseif (index == Enum.UnlearnCost.ScrollOfFortuneAbilities) then
			item = Item:CreateFromID(self:GetScrollOfFortuneAbilitiesForSpec())
		elseif (index == Enum.UnlearnCost.ScrollOfFortuneTalents) then
			item = Item:CreateFromID(self:GetScrollOfFortuneTalentsForSpec())
    	else
    		item = Item:CreateFromID(index)
    	end

    	if not(item) then
    		return ""
    	end

    	if not(item) or not(amount) or (amount == 0) then
    		return ""
    	end

    	if (onlyIcon) then
    		return "x"..amount.." "..(CreateSimpleTextureMarkup(item:GetIcon(), 16, 16, 0, 0))
    	else
        	return "x"..amount.." "..(item:GetLink())
        end
    end

    return ""
end