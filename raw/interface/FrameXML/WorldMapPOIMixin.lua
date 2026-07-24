WorldMapPOIMixin = {}

WorldMapPOIMixin.TooltipType = EnumUtil.MakeEnum("None", "Map", "Tooltip")

function WorldMapPOIMixin:OnLoad()
	self:SetTooltipType(WorldMapPOIMixin.TooltipType.Map)
	self.tooltipText = {}
	self.maxWidth, self.maxHeight = 22, 22
end

function WorldMapPOIMixin:SetAtlas(atlasName)
	self:SetNormalAtlas(atlasName, true)
	self:SetHighlightAtlas(atlasName, true)
	local width, height = AtlasUtil:GetSize(atlasName)
	self:RecalculateSize(width, height)
end

function WorldMapPOIMixin:RecalculateSize(width, height)
	if not width or not height then
		width, height = self:GetSize()
	end
	local ratio = width / height
	if width > self.maxWidth then
		width = self.maxWidth
		height = width / ratio
	end
	if height > self.maxHeight then
		height = self.maxHeight
		width = height * ratio
	end
	self:SetSize(width, height)
end

function WorldMapPOIMixin:SetMaxSize(width, height)
	self.maxWidth, self.maxHeight = width, height
	self:RecalculateSize()
end

function WorldMapPOIMixin:SetTexture(texture)
	self:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
	self:SetNormalTexture(texture)
	self:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
	self:SetHighlightTexture(texture)
end

function WorldMapPOIMixin:SetTooltipTitle(tooltipTitle)
	self.tooltipTitle = tooltipTitle
	if self:IsMouseOver() then
		self:OnEnter()
	end
end

function WorldMapPOIMixin:AddTooltipLine(...)
	if ... ~= nil then
		table.insert(self.tooltipText, { ... })
	end
end

function WorldMapPOIMixin:ClearTooltip()
	wipe(self.tooltipText)
	if self.tooltipTitle then
		self.tooltipTitle = nil
	end
end

function WorldMapPOIMixin:SetTooltipType(tooltipType)
	local mouseover = self:IsMouseOver()
	if mouseover then
		self:OnLeave()
	end
	self.tooltipType = tooltipType
	if mouseover then
		self:OnEnter()
	end
end

function WorldMapPOIMixin:OnEnter()
	if self.tooltipType == WorldMapPOIMixin.TooltipType.None then return end

	if self.tooltipType == WorldMapPOIMixin.TooltipType.Tooltip then
		if self.OnShowTooltip then
			self:OnShowTooltip()
		else
			if not self.tooltipTitle then return end
			WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
			WorldMapTooltip:AddLine(self.tooltipTitle, 1, 1, 1, false)
			for _, line in ipairs(self.tooltipText) do
				local text, r, g, b = unpack(line)
				WorldMapTooltip:AddLine(text, r, g, b, true)
			end
			WorldMapTooltip:Show()
		end
		WorldMapPOIFrame.allowBlobTooltip = false

	elseif self.tooltipType == WorldMapPOIMixin.TooltipType.Map then
		if not self.tooltipTitle then return end
		WorldMapFrame.poiHighlight = 1
		WorldMapFrameAreaLabel:SetText(self.tooltipTitle)
		if #self.tooltipText > 0 then
			local descriptionText
			for _, line in ipairs(self.tooltipText) do
				local text, r, g, b = unpack(line)
				if r and g and b then
					text = ColorUtil.MakeColorCode(r, g, b, 1) .. text .. FONT_COLOR_CODE_CLOSE
				end
				descriptionText = descriptionText and descriptionText .. "\n" .. line or line
			end
			if descriptionText then
				WorldMapFrameAreaDescription:SetText(descriptionText)
			end
		end
	end
end

function WorldMapPOIMixin:OnLeave()
	if WorldMapTooltip:IsOwned(self) then
		WorldMapPOIFrame.allowBlobTooltip = true
		WorldMapTooltip:Hide()
	else
		WorldMapFrame.poiHighlight = nil
		WorldMapFrameAreaLabel:SetText(WorldMapFrame.areaName)
		WorldMapFrameAreaDescription:SetText(WorldMapFrame.honorableCombatText)
	end
end

function WorldMapPOIMixin:Clear()
	self:ClearTooltip()
	self:SetTooltipType(WorldMapPOIMixin.TooltipType.Map)
	if self:IsMouseOver() then
		self:OnLeave()
	end
end

WorldMapChallengeFailPOIMixin = CreateFromMixins(WorldMapPOIMixin)

function WorldMapChallengeFailPOIMixin:OnLoad()
	WorldMapPOIMixin.OnLoad(self)
	self:SetTooltipType(WorldMapPOIMixin.TooltipType.Tooltip)
end

function WorldMapChallengeFailPOIMixin:SetFailure(death, x, y)
	self.death = death
	self:SetAtlas("warfronts-basemapicons-empty-barracks-minimap", Const.TextureKit.IgnoreAtlasSize)
	self:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x, y)
end

--GetChallengeFailures(int zone, int amount)
-- Challenge=188,
-- FailReason="CHALLENGE_FAIL_REASON_COMPLETE_WITHOUT_DEATH",
-- AreaId=132,
-- DeathCount=1,
-- KillerSpell=0,
-- Ruleset=0,
-- Level=1,
-- KillerLevel=0,
-- KillerDamage=0,
-- Y=0.73571300506592,
-- ZoneId=1,
-- KillerName="",
-- EndTime=1685660575,
-- KillerType="TYPEID_OBJECT",
-- PlayerGender="GENDER_MALE",
-- PlayerLevel=1,
-- Difficulty=0,
-- X=0.29823571443558,
-- Name="Dwarfy",
-- PlayerRace="RACE_DWARF",
-- PlayerClass="CLASS_HERO",
-- MapId=0,
-- KillerEntry=0,
-- StartTime=1685660572
function WorldMapChallengeFailPOIMixin:OnShowTooltip()
	local death = self.death
	if not death then return end

	WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")

	local class = death.PlayerClass:sub(7)
	local className = LOCALIZED_CLASS_NAMES_MALE[class] or LOCALIZED_CLASS_NAMES_MALE["HERO"]
	local color = RAID_CLASS_COLORS[class] or RAID_CLASS_COLORS["HERO"]
	local duration = SecondsToTime(death.EndTime - death.StartTime, false, true)

	-- name level class
	local playerName = color:WrapText(death.Name)
	local levelAndClass = UNIT_TYPE_LEVEL_TEMPLATE:format(death.PlayerLevel, color:WrapText(className))
	WorldMapTooltip:SetText(playerName .. " " .. levelAndClass)

	-- challenge (level)
	local challenge = C_Challenge.GetChallengeInfo(death.Challenge)
	if challenge then
		WorldMapTooltip:AddLine(format("%s (%s)", challenge.Name, death.Level), NORMAL_FONT_COLOR:GetRGB())
	end

	-- failure reason
	WorldMapTooltip:AddLine(CHALLENGE_FAIL_REASON_S:format(_G[death.FailReason] or death.FailReason),
	                        RED_FONT_COLOR:GetRGB())

	if death.FailReason == "CHALLENGE_FAIL_REASON_COMPLETE_WITHOUT_DEATH" then
		self:AddDeathTooltip()
	end

	-- duration
	WorldMapTooltip:AddLine(CHALLENGE_DURATION:format(duration), NORMAL_FONT_COLOR:GetRGB())

	-- high risk chad
	if death.Ruleset == 1 then
		WorldMapTooltip:AddLine(CHALLENGE_FAILED_HIGH_RISK, RED_FONT_COLOR:GetRGB())
	end

	GameTooltip_AddSpacer(WorldMapTooltip)

	-- Timestamp Info
	local endTime = date(CHALLENGE_FAILED_AT_TIME, death.EndTime)
	local timeSinceFailed = SecondsToTime(time() - death.EndTime, false, true)
	WorldMapTooltip:AddLine(endTime, NORMAL_FONT_COLOR:GetRGB())
	WorldMapTooltip:AddLine(CHALLENGE_FAILED_TIME_AGO:format(timeSinceFailed), HIGHLIGHT_FONT_COLOR:GetRGB())
	WorldMapTooltip:Show()
end

function WorldMapChallengeFailPOIMixin:AddDeathTooltip()
	local death = self.death
	if not death then return end

	-- setup killer
	local killer
	local typeID = Enum.TypeID[death.KillerType]

	-- Creatures
	if typeID == Enum.TypeID.TYPEID_UNIT then
		killer = CHALLENGE_FAIL_KILLED_BY:format(death.KillerName .. " (" .. UNIT_LEVEL_TEMPLATE:format(death.KillerLevel) .. ")")

	-- players
	elseif typeID == Enum.TypeID.TYPEID_PLAYER then
		killer = CHALLENGE_FAIL_KILLED_BY:format(death.KillerName .. " (" .. UNIT_LEVEL_TEMPLATE:format(death.KillerLevel) .. " Player)")
		
	-- Environment	
	elseif typeID == Enum.TypeID.TYPEID_OBJECT then
		if death.KillerName:len() > 0 then
			killer = CHALLENGE_FAIL_KILLED_BY:format(death.KillerName .. " (" .. ENVIRONMENTAL_DAMAGE .. ")")
		else
			killer = CHALLENGE_FAIL_KILLED_BY:format(UNKNOWNOBJECT)
		end
	end

	if killer then
		WorldMapTooltip:AddLine(killer, RED_FONT_COLOR:GetRGB())
		-- damage taken
		if death.KillerDamage and death.KillerDamage > 0 then
			local damage = ShortenNumber(death.KillerDamage)

			-- spell info
			if death.KillerSpell and death.KillerSpell > 0 then
				local spellName = GetSpellInfo(death.KillerSpell)
				if spellName then
					WorldMapTooltip:AddLine(CHALLENGE_FAIL_DAMAGE_TAKEN_FROM:format(damage, spellName), RED_FONT_COLOR:GetRGB())
				else
					WorldMapTooltip:AddLine(CHALLENGE_FAIL_DAMAGE_TAKEN_FROM:format(damage, UNKNOWN), RED_FONT_COLOR:GetRGB())
				end
			-- no spell, either melee damage if unit / player or just show damage taken
			elseif typeID == Enum.TypeID.TYPEID_PLAYER or typeID == Enum.TypeID.TYPEID_UNIT then
				WorldMapTooltip:AddLine(CHALLENGE_FAIL_DAMAGE_TAKEN_FROM:format(damage, MELEE_ATTACK), RED_FONT_COLOR:GetRGB())
			else
				WorldMapTooltip:AddLine(CHALLENGE_FAIL_DAMAGE_TAKEN:format(damage), RED_FONT_COLOR:GetRGB())
			end
		end
	end
end

function WorldMapChallengeFailPOIMixin:Clear()
	self:ClearTooltip()
	if self:IsMouseOver() then
		self:OnLeave()
	end
	self.deathInfo = nil
end