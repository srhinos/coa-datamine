WeeklyKeystoneMixin = {
	Width = 878,
	Height = 586,
}

function WeeklyKeystoneMixin:OnLoad()
	self.expansion = GetExpansionLevel()

	self.DungeonScroll:SetGetNumResultsFunction(function() return
		#C_Keystones.GetTimedDungeonsForExpansion(self.expansion)
	end)
	self.DungeonScroll:SetCanSelect(false)

	UIDropDownMenu_SetText(self.ExpansionDropdown, _G["MYTHIC_PLUS_DUNGEONS_EXPANSION"..self.expansion])
	UIDropDownMenu_Initialize(self.ExpansionDropdown, function(...)
		self:SetupExpansionDropdown(...)
	end)
end

function WeeklyKeystoneMixin:SetupExpansionDropdown(dropdown, level)
	for i = Enum.Expansion.Vanilla, Enum.Expansion.WoTLK do
		local info = UIDropDownMenu_CreateInfo()

		info.text = CreateAtlasMarkup("small-logo-expansion-"..i, 1) .. " " .. _G["MYTHIC_PLUS_DUNGEONS_EXPANSION"..i]
		info.checked = i == self.expansion
		info.func = function()
			self.expansion = i
			UIDropDownMenu_SetText(dropdown, _G["MYTHIC_PLUS_DUNGEONS_EXPANSION"..i])
			self.DungeonScroll:RefreshScrollFrame()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end

function WeeklyKeystoneMixin:OnShow()
	local parent = self:GetParent():GetParent()
	parent:SetSize(self.Width,self.Height)
	parent.PortraitFrame.portrait:SetPortraitTexture("Interface\\Icons\\inv_relics_hourglass")
	parent.TitleText:SetText(MYTHIC_PLUS_DUNGEONS)
	RunNextFrame(function()
		-- SetSize wont actually update until the next frame
		--causing the buttons to be all messed up on the scroll.
		if not self.DungeonScroll:IsInitialized() then
			self.DungeonScroll:SetTemplate("BestDungeonListItemTemplate", self)
		end
		self.DungeonScroll:RefreshScrollFrame()
	end)
	
	self:SetupCurrentAffixes()
	self:SetupBestKeystone()
end

function WeeklyKeystoneMixin:SetupCurrentAffixes()
	local affixes = C_MythicPlus.GetCurrentAffixes()
	local affixCount = #affixes
	for index, button in ipairs(self.AffixButtons) do
		button:SetAffix(affixes[index])
	end

	self.Background:SetAtlas("mythic-keystone-backdrop-"..affixCount)
	self.DialGlow:SetAtlas("mythic-keystone-dial-glow-"..affixCount, Const.TextureKit.UseAtlasSize)
	self.DialGlow:Hide()
	self.Dial.Animation:Play()
end

function WeeklyKeystoneMixin:SetupBestKeystone()
	local info = self.BestKeystone.Information
	local bestKey = C_Keystones.GetCurrentSetBest()

	if not bestKey then
		info.LevelText:SetTextColor(DISABLED_FONT_COLOR:GetRGB())

		info.TitleText:SetText(MYTHIC_PLUS_NO_BEST_AFFIX_SET_RUN)
		info.DungeonText:SetText(MYTHIC_PLUS_COMPLETE_A_KEYSTONE)
		info.LevelText:SetFormattedText("+%d", 0)
	else
		info.LevelText:SetTextColor(NORMAL_FONT_COLOR:GetRGB())

		info.TitleText:SetText(MYTHIC_PLUS_BEST_AFFIX_SET_RUN)
		local dungeonText = GetLFGDungeonInfo(bestKey.DungeonID)
		local runTimeString = SecondsToClock(bestKey.Time)
		if bestKey.Overtime then
			runTimeString = runTimeString .. "  " .. RED_FONT_COLOR.hex.."Overtime|r"
		end

		dungeonText = dungeonText .. "\n" .. runTimeString
		info.DungeonText:SetText(dungeonText)
		info.LevelText:SetFormattedText("+%d", bestKey.Level)
	end
end

BestDungeonListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function BestDungeonListItemMixin:Init(args)
	ScrollListItemBaseMixin.Init(self, args)
	self.parent = args[1]
	self:SetNormalAtlas("mythic-keystone-dungeon-button")
	self:GetNormalTexture():SetDrawLayer("BORDER")
	self:SetHighlightAtlas("mythic-keystone-dungeon-button-highlight")
	self.LevelRing:SetAtlas("ChallengeMode-KeystoneSlotBG", Const.TextureKit.IgnoreAtlasSize)
	self.LevelRingGlow:SetAtlas("ChallengeMode-KeystoneSlotFrameGlow", Const.TextureKit.IgnoreAtlasSize)
end

function BestDungeonListItemMixin:Update()
	local dungeonID = C_Keystones.GetTimedDungeonsForExpansion(self.parent.expansion)[self.index]
	local dungeonName, fileName, bestRun = C_Keystones.GetKeystoneDungeonInfo(dungeonID)
	fileName = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-"..fileName
	
	self.dungeonID = dungeonID
	self.dungeon = dungeonName
	self.keystone = bestRun
	local hasBest = bestRun ~= nil
	self:SetText(dungeonName:gsub(" %- ", "|n"):gsub(": ", "|n"))
	self.Background:SetTexture(fileName)
	self.BackgroundAdd:SetTexture(fileName)

	self.Background:SetDesaturated(not hasBest)
	self.BackgroundAdd:SetDesaturated(not hasBest)

	self.LevelRing:SetDesaturated(not hasBest)
	self.LevelRingGlow:SetShown(hasBest)

	if hasBest then
		self.LevelText:SetText(bestRun.Level)
	else
		self.LevelText:SetText("")
	end
end

function BestDungeonListItemMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("RIGHT", self, "LEFT")
	
	if self.keystone then
		-- has best key
		-- Dungeon Name __ 12/26/2022
		GameTooltip:AddDoubleLine(self.dungeon, date("%m/%d/%y", self.keystone.Date), 1, 0.82, 0, 1, 1, 1)
		-- best timed run
		local color = self.keystone.Overtime and RED_FONT_COLOR or GREEN_FONT_COLOR
		local runTimeString = format(SecondsToTime(self.keystone.Time, false, true))
		
		if self.keystone.Overtime then
			-- If overtime, show double line
			-- [red] 31 Mintues 2 Seconds __ Overtime
			GameTooltip:AddDoubleLine(runTimeString, "Overtime", color.r, color.g, color.b, color.r, color.g, color.b)
		else
			-- In Time is green
			-- [green] 26 Mintues
			GameTooltip:AddLine(runTimeString, color.r, color.g, color.b, false)
		end
		
		GameTooltip_AddSpacer(GameTooltip)
		-- Affixes
		-- [icon] AffixName
		-- ...
		GameTooltip:AddLine("Affixes:", 1, 0.82, 0, false)
		for _, affixID in ipairs(self.keystone.Affixes) do
			local name, _, icon = GetSpellInfo(affixID)

			if not name then
				name = "Affix ID: "..affixID
				icon = "Interface\\Icons\\inv_misc_questionmark"
			end
			
			icon = CreateSquareTextureMarkup(icon, 18)
			GameTooltip:AddLine(format("%s %s", icon, name), 1, 1, 1, false)
		end

		GameTooltip_AddSpacer(GameTooltip)
		-- Group
		-- [classcolor]Player __ class name
		GameTooltip:AddLine("Group:", 1, 0.82, 0, false)
		for _, player in ipairs(self.keystone.Players) do
			local name, class = unpack(player)
			local r, g, b = RAID_CLASS_COLORS[class]:GetRGB()
			GameTooltip:AddDoubleLine(name, LOCALIZED_CLASS_NAMES_MALE[class], r, g, b, r, g, b)
		end
	else
		-- no best key
		GameTooltip:SetText(self.dungeon, 1, 0.82, 0, 1, false)
		GameTooltip:AddLine(MYTHIC_PLUS_NOT_COMPLETED_DUNGEON, 1, 1, 1, true)
	end
	GameTooltip:Show()
end

function BestDungeonListItemMixin:OnLeave()
	GameTooltip:Hide()
end
