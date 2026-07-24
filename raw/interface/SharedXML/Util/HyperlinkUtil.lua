HyperlinkMixin = {}

function HyperlinkMixin:GetType()
	return self.type
end

function HyperlinkMixin:SetType(hType)
	self.type = hType
end

function HyperlinkMixin:Unpack()
	return unpack(self.args)
end

function HyperlinkMixin:GetArg(index)
	return self.args[index]
end

function HyperlinkMixin:SetArg(index, value)
	self.args[index] = value
end

function HyperlinkMixin:GetLabel()
	return self.label or self.type
end

function HyperlinkMixin:SetLabel(label)
	self.label = label
end

function HyperlinkMixin:GetColor()
	return self.color
end

function HyperlinkMixin:SetColor(color, ...)
	local colorType = type(color)
	if colorType == "string" then
		self.color = CreateColorFromCode(color)
		return
	end

	if colorType == "number" then
		self.color = CreateColor(color, ...)
		return
	end

	if colorType == "table" then
		self.color = color
		return
	end
end

function HyperlinkMixin:MakeLink()
	local str = ""
	for _, arg in ipairs(self.args) do
		str = str .. ":" .. tostring(arg)
	end
	str = self.type .. str
	
	str = format("|H%s|h%s|h", str, self:GetLabel())

	if self.color then
		str = self.color:WrapText(str)
	end
	
	return str
end

LinkUtil = {
	handlers = {}
}

function LinkUtil:CreateHyperlink(link, label)
	if not link then return end
	local color, linkType, args, name = link:match("(|cff%x%x%x%x%x%x)|H([^:|]+):(.+)|h([^|]*)|h")

	-- idk how else to match multiple groups and chain them
	if not linkType then
		linkType, args, name = link:match("|H([^:|]+):(.+)|h([^|]*)|h")
	end

	if not linkType then
		linkType, args, name = link:match("|H([^:|]+):(.+)|h")
	end

	if not linkType then
		linkType, args = link:match("([^:|]+):(.+)")
	end

	if not linkType then
		linkType = link:match("|H([^:|]+)|h")
		args = ""
	end

	if not linkType then return end
	local hLink = CreateFromMixins(HyperlinkMixin)
	if args:find(":") then
		args = args and args:SplitToTable(":", function(str)
			return tonumber(str) or str
		end) or { args }
	else
		args = { args }
	end

	if name and not label then
		label = name
	end

	hLink:SetType(linkType)
	hLink.args = args
	hLink:SetLabel(label)
	hLink:SetColor(color)
	return hLink
end

function LinkUtil:GetType(link)
	if not link then return end
	return link:match("(%a+):")
end 

function LinkUtil:HandleHyperlinkClick(frame, link, text, button)
	local hyperlink = self:CreateHyperlink(text)
	if not hyperlink then return end
	local hType = hyperlink:GetType()
	
	local func = self:GetHandler(hType, "onClick")
	if func then
		securecall(func, hyperlink, button)
		return
	end

	SetItemRef(link, text, button, frame);
end

local gameTooltipLinks = {
	["item"] = true,
	["spell"] = true,
	["unit"] = true,
	["quest"] = true,
	["enchant"] = true,
	["achievement"] = true,
	["instancelock"] = true,
	["talent"] = true,
	["glyph"] = true,
}
function LinkUtil:OnHyperlinkEnter(frame, link, text)
	local tooltip = GameTooltip or GlueTooltip
	local hyperlink = self:CreateHyperlink(text)
	if not hyperlink then return end

	local hType = hyperlink:GetType()
	self.mouseoverLinkType = hType
	if gameTooltipLinks[hType] then
		tooltip:SetOwner(frame, "ANCHOR_CURSOR", 0, 8)
		tooltip:SetHyperlink(link)
		tooltip:Show()
		return
	end

	local func = self:GetHandler(hType, "onEnter")
	if func then
		securecall(func, frame, hyperlink)
		return
	end
end

function LinkUtil:OnHyperlinkLeave(frame)
	local tooltip = GameTooltip or GlueTooltip
	local hType = self.mouseoverLinkType
	if not hType then
		return
	end

	if gameTooltipLinks[hType] then
		tooltip:Hide()
		return
	end

	local func = self:GetHandler(hType, "onLeave")
	if func then
		securecall(func, frame)
		return
	end
end

function LinkUtil:RemoveHandler(linkType)
	if not issecure() then return end
	self.handlers[linkType] = nil
end

function LinkUtil:GetHandler(linkType, func)
	return self.handlers[linkType] and self.handlers[linkType][func]
end

function LinkUtil:AddHandler(linkType, onClick, onEnter, onLeave)
	assert(type(onClick) == "function", "LinkUtil:AddHandler: Argument #2 (onClick) must be a function")
	if self.handlers[linkType] and not issecure() then
		if not C_Realm.IsDevelopment() then
			error("LinkUtil:AddHandler: " .. linkType .. "is already registered")
		else
			print("LinkUtil:AddHandler: insecure overwriting handler " .. linkType .. ". This will fail on live realms!")
		end
	end

	self.handlers[linkType] = { onClick = onClick, onEnter = onEnter, onLeave = onLeave }
end

function LinkUtil:GetSpellLink(spellID)
	local name = GetSpellInfo(spellID)
	if not name then return "" end
	return format("|cff71d5ff|Hspell:%d|h[%s]|h|r", spellID, name)
end

function LinkUtil:GetTalentLink(spellID)
	local entry = C_CharacterAdvancement.GetEntryBySpellID(spellID)
	if not entry then
		return LinkUtil:GetSpellLink(spellID)
	end

	local maxRank = #entry.Spells
	local thisRank = 1
	for i, spell in ipairs(entry.Spells) do
		if spell == spellID then
			thisRank = i
			break
		end
	end
	return format("|cff71d5ff|Hspell:%d|h[%s (%s)]|h|r", spellID, entry.Name, TOOLTIP_TALENT_RANK:format(thisRank, maxRank))
end

function LinkUtil:GetTalentLinkByID(internalID, rank)
	local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)
	if not entry or not rank then
		return
	end

	local maxRank = #entry.Spells
	local spellID = entry.Spells[rank]
	return format("|cff71d5ff|Hspell:%d|h[%s (%s)]|h|r", spellID, entry.Name, TOOLTIP_TALENT_RANK:format(rank, maxRank))
end

function LinkUtil:GetSpellLinkInternalID(internalID)
	local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)

	if not entry then
		return ""
	end

	return LinkUtil:GetSpellLink(entry.Spells[1])
end

function LinkUtil.ConvertDBUrlToHyperlink(link)
	local linkType, ID = link:lower():match("db%.ascension%.gg/%?([^=]+)=(%d+)")
	if not linkType or not ID then return end
	local linkFormat = "|Hascensiondb:%s:%s|h["..ASCENSIONDB_LINK.."]|h"
	if linkType == "weakaura" then
		return YELLOW_FONT_COLOR:WrapText(format(linkFormat, linkType, ID, "WeakAura " .. ID))
	elseif linkType == "item" then
		local name = GetItemName(ID)
		local quality = GetItemQuality(ID)
		if not name then return end
		return ITEM_QUALITY_COLORS[quality or 1]:WrapText(format(linkFormat, linkType, ID, name))
	elseif linkType == "spell" then
		local name = GetSpellInfo(ID)
		if not name then return end
		return SPELL_LINK_COLOR:WrapText(format(linkFormat, linkType, ID, name))
	else
		return YELLOW_FONT_COLOR:WrapText(format(linkFormat, linkType, ID, linkType .. " " .. ID))
	end
end

--
-- Register Default Handlers
--
LinkUtil:AddHandler("gmsound", function(link)
	if IsControlKeyDown() then
		SendChatMessage(format(".play %d", link:GetArg(1)))
	else
		PlaySound(link:GetArg(1))
		SendSystemMessage(format("Sound %d Played to self", link:GetArg(1)))
	end
end)

LinkUtil:AddHandler("discord", function(link)
	if DiscordFeaturesEnabled() then
		DiscordOpenGuildInvite(link:GetArg(1))
	else
		local url = "https://discord.gg/"..link:GetArg(1)
		StaticPopup_Show("OPEN_URL_DISCORD", url, nil, url)
	end
	return
end)

LinkUtil:AddHandler("ascensionweb", function(link)
	local url = ""
	for _, arg in ipairs(link.args) do
		url = url .. arg .. "/"
	end
	OpenAscensionURL(url)
end)

do
	local function DBOnClick(link)
		local linkType, ID = link:GetArg(1), link:GetArg(2)
		OpenAscensionDBURL("?"..linkType.."="..ID)
	end

	local function DBOnEnter(frame, link)
		local tooltip = GameTooltip or GlueTooltip
		local linkType, ID = link:GetArg(1), link:GetArg(2)
		tooltip:SetOwner(frame, "ANCHOR_CURSOR", 0, 8)
		if gameTooltipLinks[linkType] then
			tooltip:SetHyperlink(linkType .. ":" .. ID)
		else
			tooltip:SetText(VIEW_ASCENSION_DB)
		end
		tooltip:Show()
	end

	local function DBOnLeave(frame)
		(GameTooltip or GlueTooltip):Hide()
	end

	LinkUtil:AddHandler("ascensiondb", DBOnClick, DBOnEnter, DBOnLeave)
end

LinkUtil:AddHandler("buildcreatordelete", function(link)
	StaticPopup_Show("GM_DELETE_BUILD", link:GetArg(2), nil, link:GetArg(1))
end)

LinkUtil:AddHandler("appearance", function(link)
	local appearanceID = link:GetArg(1)

	if IsModifiedClick("CHATLINK") then
		return ChatEdit_InsertLink(link:MakeLink())
	end
	
	local displayType, displayID = C_Appearance.GetAppearanceDisplayInfo(appearanceID)
	if displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" then
		local item = Item:CreateFromID(displayID)
		DressUpItemLink(item:GetLink(), true)
	elseif displayType == "APPEARANCE_DISPLAY_TYPE_CREATURE" then
		DressUpCreature(displayID)
	end
end)

LinkUtil:AddHandler("item", function(link)
	if IsModifiedClick() then
		HandleModifiedItemClick(link:MakeLink())
	else
		ItemRefEnchantTooltip:Hide()

		ShowUIPanel(ItemRefTooltip)
		if not ItemRefTooltip:IsShown() then
			ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
		end
		ItemRefTooltip:SetHyperlink(link:MakeLink())

		if not ItemRefTooltip:IsShown() then return end
		local enchantID = link:GetArg(10)
		if enchantID then
			GameTooltip_AddSpacer(ItemRefTooltip)

			local line = format("@re:%d:0@", enchantID)
			local text = C_Format.Format(line, true, link:GetArg(1), enchantID)
			ItemRefTooltip:AddLine(text)
			ItemRefTooltip:Show()
		end
	end
end)

LinkUtil:AddHandler("mplusprofile", function(link)
	link:SetColor(KYRIAN_BLUE_COLOR)
	if IsModifiedClick() then
		ChatEdit_InsertLink(link:MakeLink())
	else
		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
		ItemRefTooltip:SetText(link:GetLabel(), link:GetColor():GetRGBA())

		GameTooltip_AddSpacer(ItemRefTooltip)
		ItemRefTooltip:AddLine("Best Runs by Dungeon", 1, 0.82, 0, false)
		
		local dungeons = C_Keystones.GetTimedDungeonsForExpansion(link:GetArg(1))
		for i = 2, #link.args do
			local level = link.args[i]
			level = level > 0 and "+" .. level or RED_FONT_COLOR:WrapText(INCOMPLETE)
			ItemRefTooltip:AddDoubleLine(GetLFGDungeonInfo(dungeons[i-1]), level, 1, 1, 1, GREEN_FONT_COLOR:GetRGB())
		end

		ItemRefTooltip:Show()
	end
end)

LinkUtil:AddHandler("mplusrun", function(link)
	link:SetColor(NIGHT_FAE_BLUE_COLOR)
	if IsModifiedClick() then
		ChatEdit_InsertLink(link:MakeLink())
	else
		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
		ItemRefTooltip:SetText(link:GetLabel(), link:GetColor():GetRGBA())
		
		local runTime, overtime = tonumber(link:GetArg(1)), tonumber(link:GetArg(2))

		if runTime > -1 then
			-- this is a completed run
			local timeString = format(SecondsToTime(runTime, false, true))
			if overtime == 1 then
				local r, g, b = RED_FONT_COLOR:GetRGB()
				ItemRefTooltip:AddDoubleLine(timeString, "Overtime", r, g, b, r, g, b)
			else
				local r, g, b = GREEN_FONT_COLOR:GetRGB()
				ItemRefTooltip:AddLine(timeString, r, g, b, false)
			end

			GameTooltip_AddSpacer(ItemRefTooltip)
			-- Affixes
			-- [icon] AffixName
			-- ...
			ItemRefTooltip:AddLine("Affixes:", 1, 0.82, 0, false)
			for i = 3, 7 do
				local affixID = tonumber(link:GetArg(i))
				if affixID == 0 then
					break
				end
				local name, _, icon = GetSpellInfo(affixID)

				if not name then
					name = "Affix ID: "..affixID
					icon = "Interface\\Icons\\inv_misc_questionmark"
				end

				icon = CreateSquareTextureMarkup(icon, 18)
				ItemRefTooltip:AddLine(format("%s %s", icon, name), 1, 1, 1, false)
			end

			GameTooltip_AddSpacer(ItemRefTooltip)
			-- Group
			-- [classcolor]Player __ class name
			ItemRefTooltip:AddLine("Group:", 1, 0.82, 0, false)
			for i = 8, 12 do
				local playerString = link:GetArg(i)
				if not playerString then
					break
				end
				local name, class = playerString:match("([^%d]*)(%d+)")
				class = tonumber(class) or Enum.Class.HERO
				local r, g, b = RAID_CLASS_COLORS[Enum.ClassFile[class]]:GetRGB()
				ItemRefTooltip:AddDoubleLine(name, LOCALIZED_CLASS_NAMES_MALE[Enum.ClassFile[class]], r, g, b, r, g, b)
			end
		else
			-- incomplete run
			ItemRefTooltip:AddLine(INCOMPLETE, RED_FONT_COLOR:GetRGB())
		end
		
		ItemRefTooltip:Show()
	end
end)

LinkUtil:AddHandler("gmexec", function(link)
	local command = link:GetArg(1)
	local undo = link:GetArg(2)

	if command:startswith("..") then
		if undo and undo:len() > 0 then
			print("Are you sure you want to execute:|cff00CCFF", command.."|r?", format("|cff44FF44|Hgmexec:%s:%s|h[Yes]|h|r", command:sub(2), undo))
		else
			print("Are you sure you want to execute:|cff00CCFF", command.."|r?", format("|cff44FF44|Hgmexec:%s|h[Yes]|h|r", command:sub(2)))
		end
		return
	end

	if undo and undo:len() > 0 then
		print("|cffFF8800[cmd]|r:|cff00CCFF", command, format("|cff44FF44|Hgmexec:%s:%s|h[repeat]|h|r", command, undo), format("|cffFF4444|Hgmexec:%s:%s|h[undo]|h|r", undo, command))
	else
		print("|cffFF8800[cmd]|r:|cff00CCFF", command, format("|cff44FF44|Hgmexec:%s|h[repeat]|h|r", command))
	end
	SendChatMessage(command)
end)

LinkUtil:AddHandler("tele", function(link)
	local tele = link:GetLabel()
	if tele then
		SendChatMessage(".tele "..tele)
	end
end)

LinkUtil:AddHandler("copy", function(link)
	local arg = link:GetArg(1)
	if arg then
		Internal_CopyToClipboard(arg)
		print("|cff00CCFF", arg, "|rCopied to Clipboard!")
	end
end)

LinkUtil:AddHandler("creature", function(link)
	local arg = tonumber(link:GetArg(1))
	if arg then
		DressUpCreature(arg)
	end
end)

LinkUtil:AddHandler("trial", function(link)
	local id = tonumber(link:GetArg(1))
	if id then
		local level = tonumber(link:GetArg(2)) or 1
		local challenge = C_Challenge.GetChallengeInfoByLevel(id, level)
		if challenge then
			if ItemRefTooltip:IsShown() then
				ItemRefTooltip:Hide()
			end
			ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
			ItemRefTooltip:AddDoubleLine(challenge.Name, TOOLTIP_UNIT_LEVEL:format(level), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
			ItemRefTooltip:AddLine(challenge.Description, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
			ItemRefTooltip:Show()
		end
	end
end)

LinkUtil:AddHandler("customtrial", function(link)
	local id = link:GetArg(1)
	if id and id:len() > 0 then
		TrialCreatorUtil.ContinueOnLoad(id, function(trial)
			if trial then
				if ItemRefTooltip:IsShown() then
					ItemRefTooltip:Hide()
				end
				ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
				ItemRefTooltip:SetText(trial.Title, NORMAL_FONT_COLOR:GetRGB())
				ItemRefTooltip:AddLine(trial.Description, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
				ItemRefTooltip:Show()
			end
		end)
	end
end)

LinkUtil:AddHandler("cabuild", function(link)
	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard, Enum.GameMode.Draft) then
		return
	end
	local buildID = link:GetArg(1)
	if buildID and buildID:len() > 0 then
		BuildCreator_LoadUI()
		Collections:GoToTab(Collections.Tabs.HeroArchitect)
		BuildCreatorFrame:ViewBuildID(buildID)
	end
end)

LinkUtil:AddHandler("token", function(link)
	ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
	ItemRefTooltip:SetToken(link:GetArg(1))
end)


do
	local keyword_onClick = function(link)
		if IsModifiedClick("CHATLINK") then
			return ChatEdit_InsertLink("|cff00ccff"..link:MakeLink().."|r")
		end
		-- create a new movable tooltip
		KeywordTooltip:Create(link:GetArg(1), KeywordTooltip.TooltipType.Movable)
		-- release all hover tooltips
		KeywordTooltip:ReleaseNested(KeywordTooltip.TooltipType.Hover)
	end
	
	local keyword_onEnter = function(frame, link)
		if frame.tooltipType and frame.tooltipType == KeywordTooltip.TooltipType.Hover then
			return
		end
		local level = frame:GetFrameLevel()
		-- release any same level tooltips
		KeywordTooltip:ReleaseNested(KeywordTooltip.TooltipType.Hover, level)
		KeywordTooltip:Create(link:GetArg(1), KeywordTooltip.TooltipType.Hover, level)
	end

	local keyword_onLeave = function(frame)
		local level = frame:GetFrameLevel()
		if not KeywordTooltip:IsMouseOverHoverTooltip(level) then
			KeywordTooltip:ReleaseNested(KeywordTooltip.TooltipType.Hover, level)
		end
	end
	LinkUtil:AddHandler("keyword", keyword_onClick, keyword_onEnter, keyword_onLeave)
end

LinkUtil:AddHandler("uierror", function(link)
	if ErrorHandler:IsShown() then
		ErrorHandler:ShowNewestError()
	else
		ErrorHandler:Show()
	end
end)

LinkUtil:AddHandler("url", function(link)
	local url = link:GetLabel()
	if url then
		StaticPopup_Show("OPEN_URL_CONFIRM", url, nil, url)
	end
end)