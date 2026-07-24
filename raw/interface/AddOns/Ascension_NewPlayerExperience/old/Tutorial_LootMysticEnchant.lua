-- Loot any enchant first time
do
	local T = {
		name = "LootMysticEnchant",
		cvar = "npeLootMysticEnchantTutorial",
		classless = true,
		priority = 200,
		events = {
			"NEW_BAG_ITEM_ADDED"
		},
		sequences = {
			["NEW_BAG_ITEM_ADDED"] = {
				"LOOT_MYSTIC_ENCHANT1",
				"LOOT_MYSTIC_ENCHANT2",
				"LOOT_MYSTIC_ENCHANT3",
				"LOOT_MYSTIC_ENCHANT4",
				"LOOT_MYSTIC_ENCHANT5",
			}
		}
	}

	NPE:RegisterTutorial(T)

	local _SUBSCRIBED_EVENT = T.SUBSCRIBED_EVENT

	function T:SUBSCRIBED_EVENT(event, bag, slot, id, count)
		if GetREInSlot(bag, slot) then
			_SUBSCRIBED_EVENT(self, event, bag, slot, id, count)
		end
	end

	NPEPopups["LOOT_MYSTIC_ENCHANT1"] = {
		cvar = T.cvar,
		cvarBit = T:NextBit(),
		offsetX = -200,
		offsetY = 0,
		point = "RIGHT",
		image1 = {
			atlas = "npe-mystic-enchant-item",
			width = 278,
			height = 175,
		},
	}

	NPEPopups["LOOT_MYSTIC_ENCHANT2"] = {
		cvar = T.cvar,
		cvarBit = T:NextBit(),
		offsetX = -150,
		offsetY = 50,
		point = "RIGHT",
		image1 = {
			atlas = "npe-mystic-enchant-auction",
			width = 405,
			height = 218,
		},
	}

	NPEPopups["LOOT_MYSTIC_ENCHANT3"] = {
		cvar = T.cvar,
		cvarBit = T:NextBit(),
		offsetX = -100,
		offsetY = -50,
		point = "RIGHT",
	}

	NPEPopups["LOOT_MYSTIC_ENCHANT4"] = {
		cvar = T.cvar,
		cvarBit = T:NextBit(),
		offsetX = -100,
		offsetY = 50,
		point = "RIGHT",
		image1 = {
			atlas = "npe-mystic-enchant-reforge",
			width = 263,
			height = 114,
		},
	}

	NPEPopups["LOOT_MYSTIC_ENCHANT5"] = {
		cvar = T.cvar,
		cvarBit = T:NextBit(),
		offsetX = -150,
		offsetY = 0,
		point = "RIGHT",
		image1 = {
			atlas = "npe-mystic-scroll",
		},
	}
end

-- First green enchant loot
do
	local T = {
		name = "LootGreenMysticEnchant",
		cvar = "npeLootGreenMysticEnchantTutorial",
		classless = true,
		priority = 100,
		events = {
			"NEW_BAG_ITEM_ADDED"
		},
		sequences = {
			["NEW_BAG_ITEM_ADDED"] = {
				"LOOT_GREEN_MYSTIC_ENCHANT1",
			}
		}
	}

	NPE:RegisterTutorial(T)

	local _SUBSCRIBED_EVENT = T.SUBSCRIBED_EVENT

	function T:SUBSCRIBED_EVENT(event, bag, slot, id, count)
		local RE = GetREInSlot(bag, slot) and GetREData(GetREInSlot(bag, slot))
		if RE and RE.quality == 2 then
			_SUBSCRIBED_EVENT(self, event, bag, slot, id, count)
		end
	end

	NPEPopups["LOOT_GREEN_MYSTIC_ENCHANT1"] = {
		cvar = T.cvar,
		cvarBit = T:NextBit(),
		offsetX = -300,
		offsetY = 0,
		point = "RIGHT",
		minWidth = 320,
	}
end

-- First blue enchant loot
do
	local T = {
		name = "LootBlueMysticEnchant",
		cvar = "npeLootBlueMysticEnchantTutorial",
		classless = true,
		priority = 101,
		events = {
			"NEW_BAG_ITEM_ADDED"
		},
		sequences = {
			["NEW_BAG_ITEM_ADDED"] = {
				"LOOT_BLUE_MYSTIC_ENCHANT1",
			}
		}
	}

	NPE:RegisterTutorial(T)

	local _SUBSCRIBED_EVENT = T.SUBSCRIBED_EVENT

	function T:SUBSCRIBED_EVENT(event, bag, slot, id, count)
		local RE = GetREInSlot(bag, slot) and GetREData(GetREInSlot(bag, slot))
		if RE and RE.quality == 3 then
			_SUBSCRIBED_EVENT(self, event, bag, slot, id, count)
		end
	end

	NPEPopups["LOOT_BLUE_MYSTIC_ENCHANT1"] = {
		cvar = T.cvar,
		cvarBit = T:NextBit(),
		offsetX = -300,
		offsetY = 0,
		point = "RIGHT",
		minWidth = 320,
	}
end

-- First purple enchant loot
do
	local T = {
		name = "LootPurpleMysticEnchant",
		cvar = "npeLootPurpleMysticEnchantTutorial",
		classless = true,
		priority = 102,
		events = {
			"NEW_BAG_ITEM_ADDED"
		},
		sequences = {
			["NEW_BAG_ITEM_ADDED"] = {
				"LOOT_PURPLE_MYSTIC_ENCHANT1",
			}
		}
	}

	NPE:RegisterTutorial(T)

	local _SUBSCRIBED_EVENT = T.SUBSCRIBED_EVENT

	function T:SUBSCRIBED_EVENT(event, bag, slot, id, count)
		local RE = GetREInSlot(bag, slot) and GetREData(GetREInSlot(bag, slot))
		if RE and RE.quality == 4 then
			_SUBSCRIBED_EVENT(self, event, bag, slot, id, count)
		end
	end

	NPEPopups["LOOT_PURPLE_MYSTIC_ENCHANT1"] = {
		cvar = T.cvar,
		cvarBit = T:NextBit(),
		offsetX = -300,
		offsetY = 0,
		point = "RIGHT",
		minWidth = 320,
	}
end

-- First orange enchant loot
do
	local T = {
		name = "LootOrangeMysticEnchant",
		cvar = "npelootOrangeMysticEnchantTutorial",
		classless = true,
		priority = 103,
		events = {
			"NEW_BAG_ITEM_ADDED"
		},
		sequences = {
			["NEW_BAG_ITEM_ADDED"] = {
				"LOOT_ORANGE_MYSTIC_ENCHANT1",
			}
		}
	}

	NPE:RegisterTutorial(T)

	local _SUBSCRIBED_EVENT = T.SUBSCRIBED_EVENT

	function T:SUBSCRIBED_EVENT(event, bag, slot, id, count)
		local RE = GetREInSlot(bag, slot) and GetREData(GetREInSlot(bag, slot))
		if RE and RE.quality == 5 then
			_SUBSCRIBED_EVENT(self, event, bag, slot, id, count)
		end
	end

	NPEPopups["LOOT_ORANGE_MYSTIC_ENCHANT1"] = {
		cvar = T.cvar,
		cvarBit = T:NextBit(),
		offsetX = -300,
		offsetY = 0,
		point = "RIGHT",
		minWidth = 320,
	}
end 