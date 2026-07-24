local GetInstanceDifficulty = GetInstanceDifficulty -- some non-launcher addons overwrite this zzzzz
-- The default tooltip border color
--TOOLTIP_DEFAULT_COLOR = { r = 0.5, g = 0.5, b = 0.5 };

function GameTooltip_UnitColor(unit)
	local r, g, b;
	if ( UnitPlayerControlled(unit) ) then
		if ( UnitCanAttack(unit, "player") ) then
			-- Hostile players are red
			if ( not UnitCanAttack("player", unit) ) then
				--[[
				r = 1.0;
				g = 0.5;
				b = 0.5;
				]]
				--[[
				r = 0.0;
				g = 0.0;
				b = 1.0;
				]]
				r = 1.0;
				g = 1.0;
				b = 1.0;
			else
				r = FACTION_BAR_COLORS[2].r;
				g = FACTION_BAR_COLORS[2].g;
				b = FACTION_BAR_COLORS[2].b;
			end
		elseif ( UnitCanAttack("player", unit) ) then
			-- Players we can attack but which are not hostile are yellow
			r = FACTION_BAR_COLORS[4].r;
			g = FACTION_BAR_COLORS[4].g;
			b = FACTION_BAR_COLORS[4].b;
		elseif ( UnitIsPVP(unit) ) then
			-- Players we can assist but are PvP flagged are green
			r = FACTION_BAR_COLORS[6].r;
			g = FACTION_BAR_COLORS[6].g;
			b = FACTION_BAR_COLORS[6].b;
		else
			-- All other players are blue (the usual state on the "blue" server)
			--[[
			r = 0.0;
			g = 0.0;
			b = 1.0;
			]]
			r = 1.0;
			g = 1.0;
			b = 1.0;
		end
	else
		local reaction = UnitReaction(unit, "player");
		if ( reaction ) then
			r = FACTION_BAR_COLORS[reaction].r;
			g = FACTION_BAR_COLORS[reaction].g;
			b = FACTION_BAR_COLORS[reaction].b;
		else
			--[[
			r = 0.0;
			g = 0.0;
			b = 1.0;
			]]
			r = 1.0;
			g = 1.0;
			b = 1.0;
		end
	end
	return r, g, b;
end

function GameTooltip_SetDefaultAnchor(tooltip, parent)		
	tooltip:SetOwner(parent, "ANCHOR_NONE");
	tooltip:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y);
	tooltip.default = 1;
end

function GameTooltip_OnLoad(self)
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
	self:HookEvent("EDIT_BOX_MODIFIER_CHANGED", function(key, state)
		GameTooltip_OnEvent(self, "MODIFIER_STATE_CHANGED", key, state)
	end)
	self.updateTooltip = TOOLTIP_UPDATE_TIME;
	self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
	self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
	self.statusBar2 = _G[self:GetName().."StatusBar2"];
	self.statusBar2Text = _G[self:GetName().."StatusBar2Text"];

	-- @HelloKitty: This inserts Mythic+ tooltip stuff and other item version stuff into existing tooltips, hooking their creation.
	-- TODO: Retail can hook globally, should we really be hooking here?
	if (self:HasScript('OnTooltipSetItem')) then
		self:HookScript('OnTooltipSetItem', GameTooltip_OnSetItem);
	end

	if self:HasScript("OnTooltipSetSpell") then
		self:HookScript("OnTooltipSetSpell", GameTooltip_OnSetSpell)
	end

	if self:HasScript("OnTooltipSetUnit") then
		self:HookScript("OnTooltipSetUnit", GameTooltip_OnSetUnit)
	end

	if self.SetHyperlink then
		hooksecurefunc(self, "SetHyperlink", GameTooltip_OnSetHyperlink)
	end

	if self.SetUnitBuff then
		hooksecurefunc(self, "SetUnitBuff", GenerateClosure(GameTooltip_OnSetUnitBuff, UnitBuff))
		hooksecurefunc(self, "SetUnitDebuff", GenerateClosure(GameTooltip_OnSetUnitBuff, UnitDebuff))
		hooksecurefunc(self, "SetUnitAura", GenerateClosure(GameTooltip_OnSetUnitBuff, UnitAura))
	end

	if self.SetMerchantCostItem then
		hooksecurefunc(self, "SetMerchantCostItem", GameTooltip_OnSetMerchantCostItem)
	end

	if self.enchantTooltip then
		self:HookScript("OnShow", function()
			RunNextFrame(function()
				self.enchantTooltip:SetBackdrop(self:GetBackdrop())
				self.enchantTooltip:SetBackdropColor(self:GetBackdropColor())
				self.enchantTooltip:SetBackdropBorderColor(self:GetBackdropBorderColor())
			end)
		end)
	end
end

function GameTooltip_OnEvent(self, event, ...)
	if not self:IsVisible() then return end
	if event == "MODIFIER_STATE_CHANGED" then
		local owner = self:GetOwner()
		if not owner then return end
		
		if owner.UpdateTooltip then return end

		if owner.OnEnter then
			return owner:OnEnter()
		end

		local onEnter = owner:GetScript("OnEnter")
		if onEnter then
			self:Hide()
			return onEnter(owner)
		end
	end
end

function GameTooltip_GetEnchantRequirements(enchant)
	if C_GameMode and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		return
	end

	local hasEnoughAE, hasEnoughTE
	local missingString
	local requiredTalents = {}
	local requiredAbilities = {}

	local textResult = nil

	if enchant and enchant.ClassRequirements then
		for i, classRequirement in ipairs(enchant.ClassRequirements) do
			local class = CharacterAdvancementUtil.GetClassFileByDBC(classRequirement.ClassType)
			wipe(requiredTalents)
			wipe(requiredAbilities)

			for _, tabType in ipairs(classRequirement.TabTypes) do
				local spec = CharacterAdvancementUtil.GetSpecFileByDBC(tabType.Tab)
				local investedAE = C_CharacterAdvancement.GetLearnedAE(classRequirement.ClassType, tabType.Tab)
				local investedTE = C_CharacterAdvancement.GetLearnedTE(classRequirement.ClassType, tabType.Tab)
				if tabType.RequiredAE > 0 then
					if investedAE < tabType.RequiredAE then
						tinsert(requiredAbilities, format("%d %s", tabType.RequiredAE, ClassInfoUtil.GetSpecName(class, spec)))
					else
						hasEnoughAE = true
						break
					end
				end
				
				if tabType.RequiredTE > 0 then
					if investedTE < tabType.RequiredTE then
						tinsert(requiredTalents, format("%d %s", tabType.RequiredTE, ClassInfoUtil.GetSpecName(class, spec)))
					else
						hasEnoughTE = true
						break
					end
				end
			end

			if hasEnoughTE or hasEnoughAE then
				break
			end

			if #requiredTalents > 0 then
				local specs = table.concat(requiredTalents, " "..OR.." ")
				specs = specs .. " " .. ClassInfoUtil.GetClassName(class)
				missingString = (missingString and missingString .. "|n" or "") .. RED_FONT_COLOR:WrapText(MYSTIC_ENCHANT_MISSING_TE_INVESTMENT:format(specs))
			end

			if #requiredAbilities > 0 then
				local specs = table.concat(requiredAbilities, " "..OR.." ")
				specs = specs .. " " .. ClassInfoUtil.GetClassName(class)
				missingString = (missingString and missingString .. "|n" or "") .. RED_FONT_COLOR:WrapText(MYSTIC_ENCHANT_MISSING_AE_INVESTMENT:format(specs))
			end
		end

		if missingString and not hasEnoughAE and not hasEnoughTE then
			if textResult then
				textResult = missingString .. "|n" .. textResult
			else
				textResult = missingString
			end
		end
	end


	return textResult
end

local function GameTooltip_GetSpellCastReqClassName(classType)
	if not classType or classType == 0 then
		return
	end

	local name = C_CharacterAdvancement.GetClassName(classType)
	if name == "None" then
		return
	end

	return name
end

local function GameTooltip_GetSpellCastReqTabName(tabType)
	if not tabType or tabType == 0 then
		return
	end

	local name = C_CharacterAdvancement.GetTabName(tabType)
	if name == "None" then
		return
	end

	return name
end

local function GameTooltip_GetSpellCastReqIcon(requirement)
	local classDBC = GameTooltip_GetSpellCastReqClassName(requirement.ClassType)
	if not classDBC then
		return
	end

	local classFile = CharacterAdvancementUtil.GetClassFileByDBC(classDBC)
	if not classFile then
		return
	end

	-- Try spec icon first (more specific)
	local specDBC = GameTooltip_GetSpellCastReqTabName(requirement.TabType)
	if specDBC then
		local specFile = CharacterAdvancementUtil.GetSpecFileByDBC(specDBC)
		if specFile then
			local specInfo = C_ClassInfo.GetSpecInfo(classFile, specFile)
			if specInfo and specInfo.SpecFilename then
				return CreateSquareTextureMarkup("Interface\\Icons\\" .. specInfo.SpecFilename, 16)
			end
		end
	end

	-- Fall back to class icon
	return CreateSquareTextureMarkup("Interface\\Icons\\classicon_" .. classFile:lower(), 16)
end

local function GameTooltip_GetSpellCastReqName(requirement)
	local className = GameTooltip_GetSpellCastReqClassName(requirement.ClassType)
	local tabName = GameTooltip_GetSpellCastReqTabName(requirement.TabType)
	local requirementName

	if tabName and className then
		requirementName = tabName .. " " .. className
	else
		requirementName = tabName or className
	end

	if not requirementName then
		return
	end

	if requirement.Points and requirement.Points > 0 then
		requirementName = format("%s (%d)", requirementName, requirement.Points)
	end

	local icon = GameTooltip_GetSpellCastReqIcon(requirement)
	if icon then
		requirementName = icon .. " " .. requirementName
	end

	return requirementName
end

-- Returns a colored requirement string (without header) for prepending to descriptions.
-- Used by both spell tooltips and draft cards.
function GameTooltip_GetSpellCastReqText(entry)
	if not entry or not entry.SpellCastReq or not next(entry.SpellCastReq) then
		return
	end

	-- HACK: Class requirements are meaningless in WildCard mode (classless dice rolls),
	-- so suppress the green/red class-name lines from spell tooltips.
	if C_GameMode and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		return
	end

	local reqText
	for _, requirement in ipairs(entry.SpellCastReq) do
		local requirementName = GameTooltip_GetSpellCastReqName(requirement)
		if requirementName then
			local color = requirement.IsMet and GREEN_FONT_COLOR or RED_FONT_COLOR
			local colored = color:WrapText(requirementName)
			reqText = reqText and (reqText .. "|n" .. colored) or colored
		end
	end

	return reqText
end

local function GameTooltip_GetSpellCastReqLines(entry)
	if not entry or not entry.SpellCastReq or not next(entry.SpellCastReq) then
		return
	end

	-- HACK: Suppress class-requirement lines in WildCard mode (see GameTooltip_GetSpellCastReqText).
	if C_GameMode and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		return
	end

	local lines = {
		{
			REQUIRES or "Requirements",
			NORMAL_FONT_COLOR.r,
			NORMAL_FONT_COLOR.g,
			NORMAL_FONT_COLOR.b,
		},
	}

	for _, requirement in ipairs(entry.SpellCastReq) do
		local requirementName = GameTooltip_GetSpellCastReqName(requirement)
		if requirementName then
			local color = requirement.IsMet and GREEN_FONT_COLOR or RED_FONT_COLOR
			tinsert(lines, { requirementName, color.r, color.g, color.b })
		end
	end

	return #lines > 1 and lines or nil
end

-- TODO: Really need a better solution to modifying game tooltips entirely
function GameTooltip_OnSetSpell(self)
	local spellName, _, spellID = self:GetSpell()
	if not spellID then return end

	-- tooltip modifiers
	for i = 1, self:NumLines() do
		local left = _G[self:GetName().."TextLeft"..i]
		local right = _G[self:GetName().."TextRight"..i]
		if left and left:GetText() and strlen(left:GetText()) > 0 then
			for _, func in pairs(ModTooltipSetSpell) do
				if type(func) == "function" then
					func(self, left, right, spellID)
				end
			end
		end
	end
	
	local characterAdvancementEntry = C_CharacterAdvancement.GetEntryBySpellID(spellID)
	if characterAdvancementEntry then
		local costLine, text, pointsLine, aeLine, levelLine

		-- Prepend spell cast requirements to the description line
		local reqText = GameTooltip_GetSpellCastReqText(characterAdvancementEntry)
		if reqText then
			-- Find the description line by its yellow text color (NORMAL_FONT_COLOR ~= 1.0, 0.82, 0.0)
			for i = 2, self:NumLines() do
				local left = _G[self:GetName().."TextLeft"..i]
				if left and left:GetText() and strlen(left:GetText()) > 0 then
					local r, g, b = left:GetTextColor()
					if r and r > 0.95 and g and g > 0.75 and g < 0.90 and b and b < 0.10 then
						local descText = left:GetText()
						left:SetText(reqText .. "|n" .. descText)
						break
					end
				end
			end
		end

		-- is skill card
		if C_SkillCard.IsCardedSpellID(spellID) then
			self:AddLine(SKILL_CARD_IS_ACTIVE, GREEN_FONT_COLOR:GetRGB())
		end

		if not C_Player:IsCustomClass() then
			local aeCost = C_CharacterAdvancement.GetAbilityEssenceCost(spellID)
			local teCost = C_CharacterAdvancement.GetTalentEssenceCost(spellID)

			-- ability essence + icon
			local _, masteryID = next(characterAdvancementEntry.Masteries)
			if aeCost == 0 and masteryID then
				if not C_CharacterAdvancement.CanRemoveByEntryID(masteryID) then
					aeCost = C_CharacterAdvancement.GetEntryByInternalID(masteryID).AECost
				end
			end

			if aeCost > 0 then
				text = aeCost .. " " .. AccessibilityUtil.GetAbilityEssenceMarkup()
				if GetItemCount(ItemData.ABILITY_ESSENCE) < aeCost then
					text = RED_FONT_COLOR:WrapText(text)
				else
					text = GREEN_FONT_COLOR:WrapText(text)
				end
				costLine = costLine and costLine .. "  " .. text or text
			end

			-- talent essence + icon
			if teCost > 0 then
				text = teCost .. " " .. AccessibilityUtil.GetTalentEssenceMarkup()
				if GetItemCount(ItemData.TALENT_ESSENCE) < teCost then
					text = RED_FONT_COLOR:WrapText(text)
				else
					text = GREEN_FONT_COLOR:WrapText(text)
				end
				costLine = costLine and costLine .. "  " .. text or text
			end

			-- qualtiy + gem
			if C_Config.GetBoolConfig("CONFIG_CHARACTER_ADVANCEMENT_QUALITIES_ENABLED") then
				local quality, qualityCount = C_CharacterAdvancement.GetQualityInfo(spellID)
				if quality and quality > Enum.SpellQuality.Common then
					if qualityCount and qualityCount > 0 then
						text = qualityCount .. " " .. AccessibilityUtil.GetRarityGemMarkup(quality)
						text = ITEM_QUALITY_COLORS[quality]:WrapText(text)
						costLine = costLine and costLine .. "  " .. text or text
					end
				end
			end
		end

		-- required level
		if characterAdvancementEntry.RequiredLevel and (characterAdvancementEntry.RequiredLevel > 0) then
			if C_Player:GetLevel() < characterAdvancementEntry.RequiredLevel then
				text = LEVEL..": "..RED_FONT_COLOR:WrapText(characterAdvancementEntry.RequiredLevel)
				levelLine = text
			else
				text = LEVEL..": "..GREEN_FONT_COLOR:WrapText(characterAdvancementEntry.RequiredLevel)
				levelLine = text
			end
		end

		if CA_USE_GATES_DEBUG then
			if characterAdvancementEntry.RequiredClassPoints and characterAdvancementEntry.RequiredClassPoints > 0 then
				local class = C_CharacterAdvancement.GetClassInfo(spellID)
				local invested = C_CharacterAdvancement.GetClassPointInvestment(characterAdvancementEntry.Class, 0)
				local hasEnough = invested >= characterAdvancementEntry.RequiredClassPoints
				text = hasEnough and GREEN_FONT_COLOR:WrapText(characterAdvancementEntry.RequiredClassPoints) or RED_FONT_COLOR:WrapText(characterAdvancementEntry.RequiredClassPoints)
				text = text.." "..AccessibilityUtil.GetClassPointsMarkup(class)

				pointsLine = format(CA_GATE_CLASS_POINTS_TEXT, text)
			end

			if characterAdvancementEntry.RequiredAEInvestment and characterAdvancementEntry.RequiredAEInvestment > 0 then
				local invested = C_CharacterAdvancement.GetGlobalAEInvestment()
				local hasEnough = invested >= characterAdvancementEntry.RequiredAEInvestment
				text = hasEnough and GREEN_FONT_COLOR:WrapText(characterAdvancementEntry.RequiredAEInvestment) or RED_FONT_COLOR:WrapText(C_CharacterAdvancement.GetGlobalAEInvestment().."/"..characterAdvancementEntry.RequiredAEInvestment)
				text = text.." "..AccessibilityUtil.GetAbilityEssenceMarkup()

				aeLine = format(CA_GATE_AE_INVESTMENT_TEXT, text)
			end
		end

		if costLine or levelLine or pointsLine or aeLine then
			GameTooltip_AddSpacer(self)

			if costLine then
				self:AddLine(format(SPELL_COST, costLine))
			end

			if levelLine then
				self:AddLine(levelLine)
			end

			if pointsLine then
				self:AddLine(pointsLine)
			end

			if aeLine then
				self:AddLine(aeLine)
			end
		end
	end

	if not (C_GameMode and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)) then
		local enchant = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
		if enchant then
			local quality = EnchantCollectionUtil:GetQualityFromQualityName(enchant.Quality)
			local colorStr = MYSTIC_ENCHANT_QUALITY_COLORS[quality].colorStr -- TODO: move EnchantCollectionUtil to FrameXML
			local knownStr = enchant.Known and "|cff1EFF00" .. MYSTIC_ENCHANT_COLLECTED or "|cff848484" .. MYSTIC_ENCHANT_NOT_COLLECTED
			local spellType = _G["MYSTIC_ENCHANT_QUALITY"..quality.."_DESC"] .. " " .. MYSTIC_ENCHANT
			local line1 = _G[self:GetName().."TextLeft1"]
			local line2 = _G[self:GetName().."TextLeft2"]
			local line2Text = line2 and line2:GetText() or ""

			if enchant.IsWorldforged then
				spellType = "|cff00CCFF" .. _G["MYSTIC_ENCHANT_QUALITY"..quality.."_DESC"] .. " " .. WORLDFORGED_ENCHANT .. "|r"
			end

			if not enchant.IsAvailableForCurrentClass then
				self:AddLine(CLASS_CANNOT_USE_MYSTIC_ENCHANT:format(UnitClass("player")), 1, 0, 0, true)
			end

			-- te/ae investment tooltip
			local requirementsText = GameTooltip_GetEnchantRequirements(enchant)
			if requirementsText then
				if not string.isNilOrEmpty(line2Text) then
					line2Text = requirementsText .. "|n" .. line2Text
				else
					line2Text = requirementsText
				end
				line2:SetText(line2Text)
			end

			line1:SetFormattedText("|c%s%s|r\n%s\n%s|r", colorStr, spellName, spellType, knownStr)
		end
	end

	local vanityItem = VanityCollectionUtil.GetItemByLearnedSpell(spellID)
	if vanityItem then
		local vanityItemID = vanityItem.itemid
		if not bit.contains(vanityItem.group, Enum.VanityCategory.Consumable) then
			if C_VanityCollection.IsCollectionItemOwned(vanityItemID) then
				self:AddLine(VANITY_ALREADY_OWNED, 0, 1, 0, false)
			else
				self:AddLine(VANITY_NOT_OWNED, 1, 0.2, 0.1, false)
			end
		end
	end

	if self:GetName() == "GameTooltip" then
		if C_Spell:IsActiveSpec(spellID) then
			self:AddLine(ACTIVE, 0, 1, 0)
		end
	end
	
	if C_CVar.GetBool("showTooltipID") then
		GameTooltip_AddIDLine(self, TOOLTIP_ID, spellID)
		if characterAdvancementEntry then
			GameTooltip_AddIDLine(self, TOOLTIP_CA_ID, characterAdvancementEntry.ID)
		end
	end
end

function GameTooltip_OnSetItem(self)
	local item, link = self:GetItem()
	if item == nil then return end

	-- tooltip modifiers
	for i = 1, self:NumLines() do
		local left = _G[self:GetName().."TextLeft"..i]
		local right = _G[self:GetName().."TextRight"..i]
		for _, func in pairs(ModTooltipSetItem) do
			if type(func) == "function" then
				if left and left:GetText() and strlen(left:GetText()) > 0 then
					func(self, left, right)
				end
			end
		end
	end

	if self:GetName() == "GameTooltip" then
		local itemEquipLoc = select(9, GetItemInfo(item))
		if itemEquipLoc and itemEquipLoc ~= "" then
			local equipSlot = INVTYPE_TO_INVSLOT[itemEquipLoc]

			if type(equipSlot) == "table" then
				equipSlot = equipSlot[1]
			end
			
			if equipSlot then
				local equippedItem = GetInventoryItemID("player", equipSlot)
				if equippedItem then
				    if IsShiftKeyDown() then
				        self:AddLine(TOOLTIP_HOLD_SHIFT_COMPARE_EXT, 0, 0.8, 1, true)
				    else
				        self:AddLine(TOOLTIP_HOLD_SHIFT_COMPARE, 0, 0.8, 1, true)
				    end
				end
			end
		end
	end

	if link then
		local itemID = GetItemInfoFromHyperlink(link)
		if itemID then
			local quality = GetItemQuality(itemID)
			if quality == Enum.ItemQuality.Heirloom then
				local needsMaxLevel = C_Config.GetBoolConfig("CONFIG_SCALING_HEIRLOOM_ITEMS_REQUIRE_MAX_LEVEL_REACHED_ON_ACCOUNT")
				if needsMaxLevel and not HasMaxLevelOnRealm() then
					self:AddLine(HEIRLOOM_REQUIRES_S_LEVEL:format(GetMaxLevel()), 1, 0.1, 0.1, true)
				end
			end
			if not (C_GameMode and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)) then
				local enchant = C_MysticEnchant.GetEnchantInfoByItem(itemID)
				if enchant then
					local requirementsText = GameTooltip_GetEnchantRequirements(enchant)
					if requirementsText then
						self:AddLine(requirementsText, 1, 1, 1, true)
					end

					local knownStr = enchant.Known and "|cff1EFF00" .. MYSTIC_ENCHANT_COLLECTED or "|cff848484" .. MYSTIC_ENCHANT_NOT_COLLECTED
					self:AddLine(knownStr, 1, 1, 1, false)
				end
			end

			local vanityItem = VanityCollectionUtil.GetOwnerByContentItem(itemID) or VanityCollectionUtil.GetItem(itemID)
			local vanityItemID = vanityItem and vanityItem.itemid or itemID
			if vanityItem and vanityItem.group and not bit.contains(vanityItem.group, Enum.VanityCategory.Consumable) then
				if C_VanityCollection.IsCollectionItemOwned(vanityItemID) then
					self:AddLine(VANITY_ALREADY_OWNED, 0, 1, 0, false)
				else
					self:AddLine(VANITY_NOT_OWNED, 1, 0.2, 0.1, false)
				end--[[ -- no way to check for skill card atm
			elseif C_VanityCollection.GetItem(itemID) then
				if C_VanityCollection.IsCollectionItemOwned(itemID) then
					self:AddLine(SKILL_CARD_ALREADY_OWNED, 0, 1, 0, false)
				else
					self:AddLine(SKILL_CARD_NOT_OWNED, 1, 0.2, 0.1, false)
				end]]
			end
			local appearanceID = C_Appearance.GetItemAppearanceID(itemID)
			if appearanceID then
				if C_AppearanceCollection.IsAppearanceCollected(appearanceID) then
					local r, g, b = TRANSMOG_UNLOCK_COLOR:GetRGB()
					self:AddLine(TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN, r, g, b, false)
				else
					local r, g, b = APPEARANCE_NOT_COLLECTED_COLOR:GetRGB()
					self:AddLine(TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN, r, g, b, false)
					if GetItemCount(itemID) > 0 then
						r, g, b = TRANSMOG_UNLOCK_COLOR:GetRGB()
						self:AddLine(TRANSMOGRIFY_TOOLTIP_COLLECT_APPEARANCE, r, g, b, true)
					end
				end
			end

			if C_MythicPlus.IsItemKeystone(itemID) then
				local keystoneInfo = C_MythicPlus.GetKeystoneInfo(itemID)
				_G[self:GetName().."TextLeft2"]:SetFormattedText("Mythic Level %d", keystoneInfo.keystoneLevel)
				_G[self:GetName().."TextLeft2"]:SetTextColor(NORMAL_FONT_COLOR:GetRGB())

				_G[self:GetName().."TextLeft"..self:NumLines()]:SetText("") -- remove @mythic tag@

				-- insert affixes
				local count = 1
				local insertLines = {
					[4] = { format(TOOLTIP_LOOT_MULTIPLIER_PCT_S, math.round(keystoneInfo.rewardMultiplier * 100)), 1, 1, 1, false },
					[5] = { MYTHIC_KEYSTONE_DUNGEON_MODIFIERS, 1, 1, 1, false }
				}
				local r, g, b = GREEN_FONT_COLOR:GetRGB()
				for i, affixID in ipairs(keystoneInfo.affixIDs) do
					insertLines[i + 5] = { format("  %s", GetSpellInfo(affixID)), r, g, b, false }
					count = count + 1
				end

				-- no modifiers
				if count == 1 then
					insertLines[6] = { format("  %s", NONE), r, g, b, false }
					count = 2
				end

				self:InsertLines(insertLines, count)
			end
		end
		
		if C_CVar.GetBool("showTooltipID") then
			GameTooltip_AddIDLine(self, TOOLTIP_ID, itemID)
		end
	end

	GameTooltip_ItemVersionReplacer(self)
end

function GameTooltip_ItemVersionReplacer(tooltip)
	local numLines = tooltip:NumLines()
	local name = tooltip:GetName()
	if not name then return end
	if numLines < 2 then return end
	
	local version, replaceLocation
	
	for i = numLines, 1, -1 do
		local text
		local line = _G[name.."TextLeft"..i]
		if line then
			text = line:GetText()
		end

		-- check font because there's some weird bug with ratingbuster here
		if text and strlen(text) > 0 and line:GetFont() then
			if text:startswith("\"@") then
				local desc
				version, desc = text:match("@(.+)@(.-)\"")
				desc = desc and strlen(desc) > 0 and "\""..desc.."\"" or ""

				line:SetText(desc)
			elseif text:startswith(ITEM_HEROIC) then
				replaceLocation = i
			end
		end
	end

	if version and replaceLocation then
		local line = _G[name.."TextLeft"..replaceLocation]
		if line and line:GetFont() then
			line:SetText(version)
		end
	end
end

function GameTooltip_AddUnitLootLockouts(self, unit)
	if not C_Instance.IsInRaid() or C_Player:InCombat() then return end
	if UnitIsPlayer(unit) then
		local mapID, difficultyID = GetActiveMapID(), GetInstanceDifficulty()
		local encounterData = GetEncounterDatasForMapAndDifficulty(unit, mapID, difficultyID)
		local red = RED_FONT_COLOR
		local green = GREEN_FONT_COLOR
		for _, encounter in pairs(encounterData) do
			if encounter.TimeRemaining > 0 then
				self:AddDoubleLine(encounter.EncounterName, ERR_NOT_ELIGIBLE_LOOT .. format(" (%s)", SecondsToTime(encounter.TimeRemaining)), red.r, red.g, red.b, red.r, red.g, red.b)
			elseif IsShiftKeyDown() then
				self:AddDoubleLine(encounter.EncounterName, ELIGIBLE_FOR_LOOT, green.r, green.g, green.b, green.r, green.g, green.b)
			end
		end
	else
		local encounterID = GetUnitEncounterID(unit)
		if encounterID then
			local r, g, b = RED_FONT_COLOR:GetRGB()
			
			local myTimeRemaining = GetUnitLootLockForEncounter("player", encounterID)
			if myTimeRemaining and myTimeRemaining > 0 then
				self:AddLine(ERR_PLAYER_NOT_ELIGIBLE_LOOT, r, g, b, false)
			end
			for groupUnit in GroupUtil.EnumerateGroupMembers() do
				if not UnitIsUnit(groupUnit, "player") then
					local lockoutRemaining = GetUnitLootLockForEncounter(groupUnit, encounterID)
					if lockoutRemaining and lockoutRemaining > 0 then
						local cr, cg, cb = RAID_CLASS_COLORS[select(2, UnitClass(groupUnit)) or "PRIEST"]
						self:AddDoubleLine(UnitName(groupUnit), ERR_NOT_ELIGIBLE_LOOT .. format(" (%s)", SecondsToTime(lockoutRemaining)), cr, cg, cb, r, g, b)
					end
				end
			end
		end
	end
end

function GameTooltip_OnSetUnit(self)
	local _, unit = self:GetUnit()
	if not UnitExists(unit) then return end
	GameTooltip_AddUnitLootLockouts(self, unit)
	
	if C_CVar.GetBool("showTooltipID") then
		if UnitIsPlayer(unit) then return end
		local id = GetCreatureIDFromUnit(unit)
		if id then
			GameTooltip_AddIDLine(self, TOOLTIP_ID, id)
		end
	end
end

function GameTooltip_OnSetUnitBuff(unitBuffFunc, self, ...)
	local caster, _, _, spellID = select(8, unitBuffFunc(...))
	if not spellID then return end
	-- tooltip modifiers
	for i = 1, self:NumLines() do
		local left = _G[self:GetName().."TextLeft"..i]
		local right = _G[self:GetName().."TextRight"..i]
		if left and left:GetText() and strlen(left:GetText()) > 0 then
			for _, func in pairs(ModTooltipSetSpell) do
				if type(func) == "function" then
					func(self, left, right, spellID)
				end
			end
		end
	end
	
	if C_CVar.GetBool("showTooltipID") then
		if caster then
			local name = UnitName(caster)
			local _, class = UnitClass(caster)
			local color = RAID_CLASS_COLORS[class] or HIGHLIGHT_FONT_COLOR
			GameTooltip_AddDoubleIDLine(self, TOOLTIP_ID, spellID, TOOLTIP_CAST_BY, color:WrapText(name))
		else
			GameTooltip_AddIDLine(self, TOOLTIP_ID, spellID)
		end
		self:Show()
	end
end

function GameTooltip_OnSetHyperlink(self, link)
	if C_CVar.GetBool("showTooltipID") then
		link = LinkUtil:CreateHyperlink(link)
		if not link then return end
		local linkType = link:GetType()
		if linkType == "item" or linkType == "spell" then return end -- handled by set spell / set item

		local id = link:GetArg(1)
		id = id and tonumber(id)
		if not id then return end

		GameTooltip_AddIDLine(self, TOOLTIP_ID, id)
		if linkType == "achievement" then
			-- category
			local categoryID = GetAchievementCategory(id)
			local categoryName, parentCategory = GetCategoryInfo(categoryID)
			local categoryText = ""
			while parentCategory and categoryID ~= -1 do
				categoryText = format("|cfff73600%s (|r%d|cfff73600)|r", categoryName, categoryID) .. categoryText

				categoryID = parentCategory
				categoryName, parentCategory = GetCategoryInfo(parentCategory)
				if categoryID and categoryID ~= -1 then
					categoryText = "|cffFFFFFF-|cff00FF00>|r" .. categoryText
				end
			end

			GameTooltip_AddIDLine(self, CATEGORY, categoryText)

			-- criteria
			local numCriteria = GetAchievementNumCriteria(id)
			if IsShiftKeyDown() then
				for i = 1, numCriteria do
					local name, _, _, _, _, _, _, _, _, criteriaID = GetAchievementCriteriaInfo(id, i)
					local shortName = name:sub(1, 16)
					if shortName ~= name then
						shortName = shortName .. "..."
					end
					GameTooltip_AddIDLine(self, shortName .. " " .. TOOLTIP_CRITERIA_ID, criteriaID)
				end
			end
		end
		self:Show()
	end
end

function GameTooltip_OnSetMerchantCostItem(self, itemIndex, costIndex)
	local item = self:GetItem()
	if not item then return end
	local count = GetItemCount(item)

	self:AddDoubleLine(" ", "Count |cffFFD100"..count.."|r", 1, 1, 1, ASCENSION_SECONDARY_COLOR:GetRGB())
	self:Show()
end

function GameTooltip_OnTooltipAddMoney(self, cost, maxcost)
	if( not maxcost ) then --We just have 1 price to display
		SetTooltipMoney(self, cost, nil, string.format("%s:", SELL_PRICE));
	else
		self:AddLine(string.format("%s:", SELL_PRICE), 1.0, 1.0, 1.0);
		local indent = string.rep(" ",4)
		SetTooltipMoney(self, cost, nil, string.format("%s%s:", indent, MINIMUM));
		SetTooltipMoney(self, maxcost, nil, string.format("%s%s:", indent, MAXIMUM));
	end
end

function SetTooltipMoney(frame, money, type, prefixText, suffixText)
	frame:AddLine(" ", 1.0, 1.0, 1.0);
	local numLines = frame:NumLines();
	if ( not frame.numMoneyFrames ) then
		frame.numMoneyFrames = 0;
	end
	if ( not frame.shownMoneyFrames ) then
		frame.shownMoneyFrames = 0;
	end
	local name = frame:GetName().."MoneyFrame"..frame.shownMoneyFrames+1;
	local moneyFrame = _G[name];
	if ( not moneyFrame ) then
		frame.numMoneyFrames = frame.numMoneyFrames+1;
		moneyFrame = CreateFrame("Frame", name, frame, "TooltipMoneyFrameTemplate");
		name = moneyFrame:GetName();
		MoneyFrame_SetType(moneyFrame, "STATIC");
	end
	_G[name.."PrefixText"]:SetText(prefixText);
	_G[name.."SuffixText"]:SetText(suffixText);
	if ( type ) then
		MoneyFrame_SetType(moneyFrame, type);
	end
	--We still have this variable offset because many AddOns use this function. The money by itself will be unaligned if we do not use this.
	local xOffset;
	if ( prefixText ) then
		xOffset = 4;
	else
		xOffset = 0;
	end
	moneyFrame:SetPoint("LEFT", frame:GetName().."TextLeft"..numLines, "LEFT", xOffset, 0);
	moneyFrame:Show();
	if ( not frame.shownMoneyFrames ) then
		frame.shownMoneyFrames = 1;
	else
		frame.shownMoneyFrames = frame.shownMoneyFrames+1;
	end
	MoneyFrame_Update(moneyFrame:GetName(), money);
	local moneyFrameWidth = moneyFrame:GetWidth();
	if ( frame:GetMinimumWidth() < moneyFrameWidth ) then
		frame:SetMinimumWidth(moneyFrameWidth);
	end
	frame.hasMoney = 1;
end

function GameTooltip_ClearMoney(self)
	if ( not self.shownMoneyFrames ) then
		return;
	end
	
	local moneyFrame;
	for i=1, self.shownMoneyFrames do
		moneyFrame = _G[self:GetName().."MoneyFrame"..i];
		if(moneyFrame) then
			moneyFrame:Hide();
			MoneyFrame_SetType(moneyFrame, "STATIC");
		end
	end
	self.shownMoneyFrames = nil;
end

function GameTooltip_ClearStatusBars(self)
	if ( not self.shownStatusBars ) then
		return;
	end
	local statusBar;
	for i=1, self.shownStatusBars do
		statusBar = _G[self:GetName().."StatusBar"..i];
		if ( statusBar ) then
			statusBar:Hide();
		end
	end
	self.shownStatusBars = 0;
end

function GameTooltip_OnHide(self)
	if self.SetMinimumWidth then
		self:SetMinimumWidth(120)
	end
	self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
	self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
	self.default = nil;
	GameTooltip_ClearMoney(self);
	GameTooltip_ClearStatusBars(self);
	if ( self.shoppingTooltips ) then
		for _, frame in pairs(self.shoppingTooltips) do
			frame:Hide();
		end
	end
	self.comparing = false;

	if self.enchantTooltip then
		self.enchantTooltip:Hide()
	end
	
	self.itemMysticEnchant = nil
end

function GameTooltip_OnUpdate(self, elapsed)
	-- Only update every TOOLTIP_UPDATE_TIME seconds
	self.updateTooltip = self.updateTooltip - elapsed;
	if ( self.updateTooltip > 0 ) then
		return;
	end
	self.updateTooltip = TOOLTIP_UPDATE_TIME;

	local owner = self:GetOwner();
	if ( owner and owner.UpdateTooltip ) then
		owner:UpdateTooltip();
	end
end

function GameTooltip_AddNewbieTip(frame, normalText, r, g, b, newbieText, noNormalText)
	if ( SHOW_NEWBIE_TIPS == "1" ) then
		GameTooltip_SetDefaultAnchor(GameTooltip, frame);
		if ( normalText ) then
			GameTooltip:SetText(normalText, r, g, b);
			GameTooltip:AddLine(newbieText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		else
			GameTooltip:SetText(newbieText, r, g, b, 1, 1);
		end
		GameTooltip:Show();
	else
		if ( not noNormalText ) then
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
			GameTooltip:SetText(normalText, r, g, b);
		end
	end
end

function GameTooltip_ShowCompareItem(self, shift)
	if ( not self ) then
		self = GameTooltip;
	end
	local item, link = self:GetItem();
	if ( not link ) then
		return;
	end
	
	local shoppingTooltip1, shoppingTooltip2, shoppingTooltip3 = unpack(self.shoppingTooltips);

	local item1 = nil;
	local item2 = nil;
	local item3 = nil;
	local side = "left";
	if ( shoppingTooltip1:SetHyperlinkCompareItem(link, 1, shift, self) ) then
		item1 = true;
	end
	if ( shoppingTooltip2:SetHyperlinkCompareItem(link, 2, shift, self) ) then
		item2 = true;
	end
	if ( shoppingTooltip3:SetHyperlinkCompareItem(link, 3, shift, self) ) then
		item3 = true;
	end

	-- find correct side
	local rightDist = 0;
	local leftPos = self:GetLeft();
	local rightPos = self:GetRight();
	if ( not rightPos ) then
		rightPos = 0;
	end
	if ( not leftPos ) then
		leftPos = 0;
	end

	rightDist = GetScreenWidth() - rightPos;

	if (leftPos and (rightDist < leftPos)) then
		side = "left";
	else
		side = "right";
	end

	-- see if we should slide the tooltip
	
	local anchorParent = self.enchantTooltip and self.enchantTooltip:IsShown() and self.enchantTooltip or self
	if ( self:GetAnchorType() and self:GetAnchorType() ~= "ANCHOR_PRESERVE" ) then
		local totalWidth = 0;
		if ( item1  ) then
			totalWidth = totalWidth + shoppingTooltip1:GetWidth();
		end
		if ( item2  ) then
			totalWidth = totalWidth + shoppingTooltip2:GetWidth();
		end
		if ( item3  ) then
			totalWidth = totalWidth + shoppingTooltip3:GetWidth();
		end

		if ( (side == "left") and (totalWidth > leftPos) ) then
			self:SetAnchorType(self:GetAnchorType(), (totalWidth - leftPos), 0);
		elseif ( (side == "right") and (rightPos + totalWidth) >  GetScreenWidth() ) then
			self:SetAnchorType(self:GetAnchorType(), -((rightPos + totalWidth) - GetScreenWidth()), 0);
		end
	end

	-- anchor the compare tooltips
	if ( item3 ) then
		shoppingTooltip3:SetOwner(anchorParent, "ANCHOR_NONE");
		shoppingTooltip3:ClearAllPoints();
		if ( side and side == "left" ) then
			shoppingTooltip3:SetPoint("TOPRIGHT", anchorParent, "TOPLEFT", 0, -10);
		else
			shoppingTooltip3:SetPoint("TOPLEFT", anchorParent, "TOPRIGHT", 0, -10);
		end
		shoppingTooltip3:SetHyperlinkCompareItem(link, 3, shift, self);
		shoppingTooltip3:Show();
	end
	
	if ( item1 ) then
		if( item3 ) then
			shoppingTooltip1:SetOwner(shoppingTooltip3, "ANCHOR_NONE");
		else
			shoppingTooltip1:SetOwner(anchorParent, "ANCHOR_NONE");
		end
		shoppingTooltip1:ClearAllPoints();
		if ( side and side == "left" ) then
			if( item3 ) then
				shoppingTooltip1:SetPoint("TOPRIGHT", shoppingTooltip3, "TOPLEFT", 0, 0);
			else
				shoppingTooltip1:SetPoint("TOPRIGHT", anchorParent, "TOPLEFT", 0, -10);
			end
		else
			if( item3 ) then
				shoppingTooltip1:SetPoint("TOPLEFT", shoppingTooltip3, "TOPRIGHT", 0, 0);
			else
				shoppingTooltip1:SetPoint("TOPLEFT", anchorParent, "TOPRIGHT", 0, -10);
			end
		end
		shoppingTooltip1:SetHyperlinkCompareItem(link, 1, shift, self);
		shoppingTooltip1:Show();

		if ( item2 ) then
			shoppingTooltip2:SetOwner(shoppingTooltip1, "ANCHOR_NONE");
			shoppingTooltip2:ClearAllPoints();
			if ( side and side == "left" ) then
				shoppingTooltip2:SetPoint("TOPRIGHT", shoppingTooltip1, "TOPLEFT", 0, 0);
			else
				shoppingTooltip2:SetPoint("TOPLEFT", shoppingTooltip1, "TOPRIGHT", 0, 0);
			end
			shoppingTooltip2:SetHyperlinkCompareItem(link, 2, shift, self);
			shoppingTooltip2:Show();
		end
	end
	
	self.comparing = true
end

function GameTooltip_ShowStatusBar(self, min, max, value, text)
	self:AddLine(" ", 1.0, 1.0, 1.0);
	local numLines = self:NumLines();
	if ( not self.numStatusBars ) then
		self.numStatusBars = 0;
	end
	if ( not self.shownStatusBars ) then
		self.shownStatusBars = 0;
	end
	local index = self.shownStatusBars+1;
	local name = self:GetName().."StatusBar"..index;
	local statusBar = _G[name];
	if ( not statusBar ) then
		self.numStatusBars = self.numStatusBars+1;
		statusBar = CreateFrame("StatusBar", name, self, "TooltipStatusBarTemplate");
	end
	if ( not text ) then
		text = "";
	end
	_G[name.."Text"]:SetText(text);
	statusBar:SetMinMaxValues(min, max);
	statusBar:SetValue(value);
	statusBar:Show();
	statusBar:SetPoint("LEFT", self:GetName().."TextLeft"..numLines, "LEFT", 0, -2);
	statusBar:SetPoint("RIGHT", self, "RIGHT", -9, 0);
	statusBar:Show();
	self.shownStatusBars = index;
	self:SetMinimumWidth(140);
end

function GameTooltip_AddSpacer(self)
	self:AddLine(" ")
end

function GameTooltip_Hide()
	-- Used for XML OnLeave handlers
	GameTooltip:Hide();
end

function GameTooltip_HideResetCursor()
	GameTooltip:Hide();
	ResetCursor();
end

function GameTooltip_AutoAnchor(self)
	local x, y = self:GetCenter()
	local midY = GetScreenHeight() / 2
	local midX = GetScreenWidth() / 2
	
	local xPos = x >= midX and "LEFT" or "RIGHT"
	local yPos = y >= midY and "BOTTOM" or ""
	
	return "ANCHOR_"..yPos..xPos
end

do
	local startColor = CreateColor(1, 1, 0)
	local targetColor = CreateColor(0, 0, 1)
	local color = CreateColor(0, 0, 0)
	
	local function ToFriendlyString(t)
		if type(t) == "table" then
			return t.GetName and t:GetName() or tostring(t)
		end
		
		return tostring(t)
	end
	
	local function AddTable(t, depth, tooltip)
		local key, limit
		if depth == 0 then
			limit = 14
			key = "self."
		else
			limit = 8
			key = string.rep(" ", depth * 4) .. "."
		end

		local i = 0

		for k, v in pairs(t) do
			if i >= limit then break end
			ColorUtil:Lerp(startColor, targetColor, i/50, color)
			local vType = type(v)

			local text
			
			if vType == "userdata" then
			elseif vType == "table" and v.GetObjectType then
				if IsKeyDown(Enum.Key.F1) then
					text = v:GetObjectType()
				end
			elseif vType == "function" then
				if IsShiftKeyDown() then
					if k:find("^Get") or k:find("^Is") then
						local success, getValue = pcall(v, t)
						if success then
							text = format("%s = |cffFFFFFF%s|r: |cff00DDFF%s|r", ToFriendlyString(v), type(getValue), ToFriendlyString(getValue))
						else
							text = ToFriendlyString(v)
						end
					else
						text =  ToFriendlyString(v)
					end
				end
			else
				text = ToFriendlyString(v)
			end

			if text then
				tooltip:AddDoubleLine(key..tostring(k), text, color.r, color.g, color.b, 0.5, 1, 0.5)

				if depth < 2 and vType == "table" and IsControlKeyDown() then
					AddTable(v, depth + 1, tooltip)
				end
			end
		end
	end

	function GameTooltip_DebugFrame(frame, depth, self)
		if not self then self = GameTooltip end
		if not depth then depth = 1 end
		if not self:IsOwned(frame) then
			self:SetOwner(frame, GameTooltip_AutoAnchor(frame))
		end

		if not frame.UpdateTooltip and frame:GetScript("OnEnter") then
			frame.UpdateTooltip = function(frame)
				self:Hide()
				frame:GetScript("OnEnter")(frame)
			end
		end
		
		self:AddDoubleLine("Dump:", (frame:GetName() or tostring(frame)), 0, 1, 0, 1, 1, 1)

		local target = frame
		if IsAltKeyDown() then
			target = getmetatable(frame).__index
		end

		AddTable(target, 0, self)
		
		GameTooltip_AddSpacer(self)
		self:AddLine("CTRL: expand table members", 0, 0.8, 1)
		self:AddLine("SHIFT: show functions", 0, 0.8, 1)
		self:AddLine("F1: Show Frame Tables", 0, 0.8, 1)
		self:AddLine("ALT: target metatable.__index", 0, 0.8, 1)
	end
end

function GameTooltip_GenericTooltip(frame, anchor)
	local title = frame.tooltipTitle or frame.tooltip
	if title then
		if not anchor then anchor = GameTooltip_AutoAnchor(frame) end
		GameTooltip:SetOwner(frame, anchor)
		GameTooltip:SetText(title, 1, 1, 1, 1)
		local tooltipText = frame.tooltipText or frame.tooltip2
		if tooltipText then
			if type(tooltipText) == "table" then
				for _, line in ipairs(tooltipText) do
					local text, r, g, b
					if type(line) == "table" then
						text, r, g, b = unpack(line)
					else
						text = line
						r, g, b = NORMAL_FONT_COLOR:GetRGB()
					end
					GameTooltip:AddLine(text, r, g, b, true)
				end
			else
				GameTooltip:AddLine(tooltipText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
			end
		end
		GameTooltip:Show()
	end
end

function GameTooltip_AddIDLine(self, label, id)
	self:AddLine(ASCENSION_PRIMARY_COLOR:WrapText(label) .." ".. ASCENSION_SECONDARY_COLOR:WrapText(id), 1, 1, 1, true)
end

function GameTooltip_AddDoubleIDLine(self, label, id, label2, id2)
	local line = ASCENSION_PRIMARY_COLOR:WrapText(label) .." ".. ASCENSION_SECONDARY_COLOR:WrapText(id)
	local line2 = ASCENSION_PRIMARY_COLOR:WrapText(label2) .." ".. ASCENSION_SECONDARY_COLOR:WrapText(id2)
	self:AddDoubleLine(line, line2, 1, 1, 1, 1, 1, 1)
end
