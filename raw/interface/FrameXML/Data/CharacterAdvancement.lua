CHARACTER_ADVANCEMENT_SPELLS = {}
CHARACTER_ADVANCEMENT_TALENTS = {}
CHARACTER_ADVANCEMENT_NODES = {}
CHARACTER_ADVANCEMENT_HIDDEN = {}
CHARACTER_ADVANCEMENT_REQUIRED = {}
CHARACTER_ADVANCEMENT_REQUIRED_FOR = {}

local ClassRemap

if IsHeroClass() then
	ClassRemap = {
		["Hunter"]      = "HUNTER",
		["Warlock"]     = "WARLOCK",
		["Priest"]      = "PRIEST",
		["Paladin"]     = "PALADIN",
		["Mage"]        = "MAGE",
		["Rogue"]       = "ROGUE",
		["Druid"]       = "DRUID",
		["Shaman"]      = "SHAMAN",
		["Warrior"]     = "WARRIOR",
		["DeathKnight"] = "DEATHKNIGHT",
		["General"] 	= "GENERAL",
	}
elseif IsDefaultClass() then
	ClassRemap = {
		["RebornHunter"]      = "HUNTER",
		["RebornWarlock"]     = "WARLOCK",
		["RebornPriest"]      = "PRIEST",
		["RebornPaladin"]     = "PALADIN",
		["RebornMage"]        = "MAGE",
		["RebornRogue"]       = "ROGUE",
		["RebornDruid"]       = "DRUID",
		["RebornShaman"]      = "SHAMAN",
		["RebornWarrior"]     = "WARRIOR",
		["RebornDeathKnight"] = "DEATHKNIGHT",
	}
elseif IsCustomClass() then
	ClassRemap = {
		["Necromancer"]       = "NECROMANCER",
		["Pyromancer"]        = "PYROMANCER",
		["Cultist"]           = "CULTIST",
		["Starcaller"]        = "STARCALLER",
		["SunCleric"]         = "SUNCLERIC",
		["Tinker"]            = "TINKER",
		["Runemaster"]        = "SPIRITMAGE",
		["Primalist"]         = "WILDWALKER",
		["Reaper"]            = "REAPER",
		["Venomancer"]        = "PROPHET",
		["Chronomancer"]      = "CHRONOMANCER",
		["SonOfArugal"]       = "SONOFARUGAL",
		["Guardian"]          = "GUARDIAN",
		["Stormbringer"]      = "STORMBRINGER",
		["DemonHunter"]       = "DEMONHUNTER",
		["Barbarian"]         = "BARBARIAN",
		["WitchDoctor"]       = "WITCHDOCTOR",
		["WitchHunter"]       = "WITCHHUNTER",
		["KnightOfXoroth"]    = "FLESHWARDEN",
		["Monk"]              = "MONK",
		["Ranger"]            = "RANGER",
		["ConquestOfAzeroth"] = "CONQUESTOFAZEROTH",
	}
end

if not ClassRemap then return end

for _, data in ipairs(C_CharacterAdvancement.GetAllEntries()) do
	data.Flags = data.Flags or 0
	if not bit.contains(data.Flags, Enum.CharacterAdvancementFlag.Disabled) and not bit.contains(data.Flags, Enum.CharacterAdvancementFlag.Deprecated) then
		-- Set Default Values
		data.Class = data.Class and ClassRemap[data.Class]
		if data.Class then
			data.Tab = strupper(data.Tab) or ""
			data.NodeType = data.NodeType and Enum.TraitNodeEntryType[data.NodeType] or Enum.TraitNodeEntryType.SpendSquare
			
			if data.Type == "TalentAbility" then
				data.Type = "Talent"
			end

			if type(data.DraftRequired_XOR) == "string" then
				data.DraftRequired_XOR = data.DraftRequired_XOR:SplitToTable(",", tonumber)
			end

			if type(data.Spells) == "string" then
				data.Spells = data.Spells:SplitToTable(",", tonumber)
			end

			if data.Masteries then
				for _, mastery in ipairs(data.Masteries) do
					CHARACTER_ADVANCEMENT_REQUIRED_FOR[mastery] = CHARACTER_ADVANCEMENT_REQUIRED_FOR[mastery] or {}
					tinsert(CHARACTER_ADVANCEMENT_REQUIRED_FOR[mastery], data.ID)
				end
			end

			if data.RequiredIDs then
				for _, id in ipairs(data.RequiredIDs) do
					if not CHARACTER_ADVANCEMENT_REQUIRED[data.ID] then
						CHARACTER_ADVANCEMENT_REQUIRED[data.ID] = {}
					end

					if not CHARACTER_ADVANCEMENT_REQUIRED_FOR[id] then
						CHARACTER_ADVANCEMENT_REQUIRED_FOR[id] = {}
					end

					tinsert(CHARACTER_ADVANCEMENT_REQUIRED_FOR[id], data.ID)
					tinsert(CHARACTER_ADVANCEMENT_REQUIRED[data.ID], id)
				end
			end

			if (data.ParentNode and data.ParentNode ~= 0) then
				data.Distance = data.Distance or 0
				data.Anchor = data.Anchor or "TOP"
				data.Color = data.Color or "TEAL"
				CHARACTER_ADVANCEMENT_NODES[data.ID] = data
			end

			if bit.contains(data.Flags, Enum.CharacterAdvancementFlag.HiddenClientside) then
				CHARACTER_ADVANCEMENT_HIDDEN[data.Class] = CHARACTER_ADVANCEMENT_HIDDEN[data.Class] or {}
				CHARACTER_ADVANCEMENT_HIDDEN[data.Class][data.Tab] = CHARACTER_ADVANCEMENT_HIDDEN[data.Class][data.Tab] or {}
				CHARACTER_ADVANCEMENT_HIDDEN[data.Class][data.Tab][data.ID] = data
			elseif data.Type == "Talent" then
				CHARACTER_ADVANCEMENT_TALENTS[data.Class] = CHARACTER_ADVANCEMENT_TALENTS[data.Class] or {}
				CHARACTER_ADVANCEMENT_TALENTS[data.Class][data.Tab] = CHARACTER_ADVANCEMENT_TALENTS[data.Class][data.Tab] or {}
				CHARACTER_ADVANCEMENT_TALENTS[data.Class][data.Tab][data.ID] = data
			elseif data.Type == "Ability" then
				data.Spells = data.Spells[1]
				CHARACTER_ADVANCEMENT_SPELLS[data.Class] = CHARACTER_ADVANCEMENT_SPELLS[data.Class] or {}
				CHARACTER_ADVANCEMENT_SPELLS[data.Class][data.Tab] = CHARACTER_ADVANCEMENT_SPELLS[data.Class][data.Tab] or {}
				CHARACTER_ADVANCEMENT_SPELLS[data.Class][data.Tab][data.ID] = data
			end
		end

		if bit.contains(data.Flags, Enum.CharacterAdvancementFlag.ConnectingNode) then
			-- for starting nodes
			data.ParentNode = data.ParentNode or 0
			data.Distance = data.Distance or 0
			data.Anchor = data.Anchor or "TOP"
			data.Color = data.Color or "TEAL"
			data.PositionX = data.PositionX or 0
			data.PositionY = data.PositionY or 0
			CHARACTER_ADVANCEMENT_NODES[data.ID] = data
		end
	end
end