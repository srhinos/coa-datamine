MAX_SPELLS = 1024
MAX_SKILLLINE_TABS = 19
SPELLS_PER_PAGE = 12

local TabInfo = {
	[1] = {
		Background1 = "Interface\\Spellbook\\Spellbook-Page-1",
		Background2 = "Interface\\Spellbook\\Spellbook-Page-2",
		Portrait = "Interface\\Icons\\inv_misc_book_09",
		Title = SPELLBOOK,
		ShowSideBar = true,
		ShowPageButtons = true,
	},
	[2] = {
		Background1 = "Interface\\Spellbook\\Spellbook-Page-1-Red",
		Background2 = "Interface\\Spellbook\\Spellbook-Page-2",
		Portrait = "Interface\\Icons\\Ability_Hunter_BeastCall",
		Title = PET,
		ShowSideBar = false,
		ShowPageButtons = true,
	},
	[3] = {
		Background1 = "Interface\\Spellbook\\Professions-Book-Left",
		Background2 = "Interface\\Spellbook\\Professions-Book-Right",
		Portrait = "Interface\\Icons\\achievement_guildperk_bountifulbags",
		Title = TRADE_SKILLS,
		ShowSideBar = false,
		ShowPageButtons = false,
	},
}

--
-- Spellbook page mixin
--
SpellbookPageMixin = {}

function SpellbookPageMixin:OnLoad()
	SetParentArray(self, "Tabs", self:GetID())
	self.info = TabInfo[self:GetID()]
end

function SpellbookPageMixin:OnShow()
	AscensionSpellbookFrame.Background1:SetTexture(self.info.Background1)
	AscensionSpellbookFrame.Background2:SetTexture(self.info.Background2)

	AscensionSpellbookFrame.PortraitFrame.portrait:SetPortraitTexture(self.info.Portrait)
	AscensionSpellbookFrame.TitleText:SetText(self.info.Title)

	AscensionSpellbookFrame.SideBar:SetShown(self.info.ShowSideBar)

	AscensionSpellbookFrame.PreviousPageButton:SetShown(self.info.ShowPageButtons)
	AscensionSpellbookFrame.NextPageButton:SetShown(self.info.ShowPageButtons)
	
	AscensionSpellbookFrame:UpdateSideTabs()
	AscensionSpellbookFrame:UpdateSpells()
end

--
-- Ascension spell button mixin
--
SpellButtonMixin = {}

function SpellButtonMixin:OnLoad()
	SecureActionButton_OnLoad(self)
	self:SetAttribute("type", "spellbook")
	self:RegisterForDrag("LeftButton")
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	self.EmptySlot:SetAtlas("spellbook-emptyslot", Const.TextureKit.UseAtlasSize)
	self.TextBackground:SetAtlas("spellbook-text-background", Const.TextureKit.UseAtlasSize)
	self.TextBackground2:SetAtlas("spellbook-text-background", Const.TextureKit.UseAtlasSize)
	self.SlotFrame:SetAtlas("spellbook-slotframe", Const.TextureKit.UseAtlasSize)
	self.TrainFrame:SetAtlas("spellbook-trainslot", Const.TextureKit.UseAtlasSize)
	self.SpellHighlightTexture:SetAtlas("bags-newitem", Const.TextureKit.IgnoreAtlasSize)
	self.ClickBindingHighlight:SetAtlas("ClickCast-Highlight-Spellbook", Const.TextureKit.UseAtlasSize)
	self.TrainTextBackground:SetAtlas("spellbook-train-text-background", Const.TextureKit.UseAtlasSize)
	self.TrainTextBackground:SetAlpha(0.5)
end

function SpellButtonMixin:OnShow()
	self:RegisterEvent("CURSOR_UPDATE")
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:RegisterEvent("PET_BAR_UPDATE")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_CLOSE")
end

function SpellButtonMixin:OnHide()
	self:UnregisterEvent("CURSOR_UPDATE")
	self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:UnregisterEvent("PET_BAR_UPDATE")
	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:UnregisterEvent("CURRENT_SPELL_CAST_CHANGED")
	self:UnregisterEvent("TRADE_SKILL_SHOW")
	self:UnregisterEvent("TRADE_SKILL_CLOSE")
	self:Clear()
end

function SpellButtonMixin:OnDragStart()
	if self.isPassive then return end
	
	if not self.spell or not self.bookType then return end
	
	ClearCursor()
	PickupSpell(self.spell, self.bookType)
	
	self.pickedUp = true
	
	self.SpellHighlightTexture:Hide()
end

function SpellButtonMixin:OnReceiveDrag()
	self:OnDragStart()
end

function SpellButtonMixin:OnEnter()
	if self.spell and self.bookType then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		GameTooltip:SetSpell(self.spell, self.bookType)
		if self.TrainBook:IsShown() then
			GameTooltip:AddLine(SPELLBOOK_TRAINABLE_TOOLTIP, 0, 1, 0,  true)
		end
		if self.SpellHighlightTexture:IsShown() then
			GameTooltip:AddLine(SPELLBOOK_SPELL_NOT_ON_ACTION_BAR, 1, 0.1, 0.1, true)
		end
		GameTooltip:Show()
	end
end

function SpellButtonMixin:OnLeave()
	GameTooltip:Hide()
end

function SpellButtonMixin:Refresh()
	self:SetSpell(self.spell, self.bookType)
end

function SpellButtonMixin:OnEvent(event, ...)
	if not self.spell or not self.bookType then return end

	if event == "CURSOR_UPDATE" then
		if self.pickedUp then
			self:Refresh()
			self.pickedUp = false
		end
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		self:Refresh()
	elseif event == "PET_BAR_UPDATE" and self.bookType == BOOKTYPE_PET then
		self:Refresh()
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		self:UpdateCooldown()
	end
end

function SpellButtonMixin:OnModifiedClick(button)
	if IsModifiedClick("CHATLINK") then
		if MacroFrameText and MacroFrameText:HasFocus() then
			local name, rank

			name, rank = GetSpellInfo(self.spell, self.bookType)

			if name and not self.isPassive then
				if rank and strlen(rank) > 0 then
					ChatEdit_InsertLink(name.."("..rank..")")
				else
					ChatEdit_InsertLink(name)
				end
			end
		else
			local link = GetSpellLink(self.spell, self.bookType)
			ChatEdit_InsertLink(link)
		end

	elseif IsModifiedClick("PICKUPACTION") then
		self:OnDragStart()

	elseif IsModifiedClick("SELFCAST") then
		SecureActionButton_OnClick(self, button);
	end
end

function SpellButtonMixin:OnClick(button)
	if IsModifiedClick() then
		return self:OnModifiedClick(button)
	end
	SecureActionButton_OnClick(self, button);
end

function SpellButtonMixin:Clear()
	self.spell = nil
	self.bookType = nil
	self.IconTexture:Hide()
	self.SpellName:Hide()
	self.SubSpellName:Hide()
	self.Cooldown:Hide()
	self.canClickBind = false
	self.HighlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	self:SetChecked(false)
	self.IconTextureBg:Hide()
	self:Disable()
	self.isPassive = false
	self.pickedUp = false
	self.AbilityHighlight.Anim:Stop()
	self.AbilityHighlight:Hide()
	self.AutoCastable:Hide()
	self.SlotFrame:Hide()
	self.SeeTrainerString:Hide()
	self.RequiredLevelString:Hide()
	self.TrainFrame:Hide()
	self.TrainTextBackground:Hide()
	self.TrainBook:Hide()
	self.FlyoutArrow:Hide()
	self.ClickBindingIconCover:Hide()
	self.ClickBindingHighlight:Hide()
	self.SpellHighlightTexture:Hide()
	if self.shine then
		AscensionSpellbookFrame:ReleaseAutocastShine(self.shine)
	end
	self.shine = nil
	
	self:SetAttribute("bookType", nil)
	self:SetAttribute("spell", nil)
end

function SpellButtonMixin:UpdateCooldown()
	if not self.spell then return end
	local start, duration, enable = GetSpellCooldown(self.spell, self.bookType)

	if start and start > 0 and duration and duration > 0 and enable and enable > 0 then
		self.Cooldown:SetCooldown(start, duration)
		self.Cooldown:Show()
	else
		self.Cooldown:Hide()
	end
end

function SpellButtonMixin:SetSpell(spell, bookType)
	if not spell then
		self:Clear()
		return
	end
	
	if not bookType then bookType = "spell" end
	
	local name, rank, icon = GetSpellInfo(spell, bookType)
	local spellId = C_Spell:GetSpellID(spell, bookType)
	

	if not name or not spellId then
		self:Clear()
		return
	end
	
	local iconOnly = self:GetAttribute("icon-only")

	local onClassTab
	if bookType == BOOKTYPE_SPELL then
		onClassTab = AscensionSpellbookFrame.selectedSideTab.Class ~= nil
	else
		onClassTab = false
	end

	self.spell = spell
	self.bookType = bookType

	
	
	local autoCastAllowed, autoCastEnabled = GetSpellAutocast(spell, bookType)

	if autoCastEnabled and not self.shine then
		self.shine = AscensionSpellbookFrame:GetAutocastShine()
		self.shine:Show()
		self.shine:SetParent(self)
		self.shine:SetPoint("CENTER")
		AutoCastShine_AutoCastStart(self.shine)
	elseif autoCastEnabled then
		self.shine:Show()
		self.shine:SetParent(self)
		self.shine:SetPoint("CENTER")
		AutoCastShine_AutoCastStart(self.shine)
	elseif not autoCastEnabled and self.shine then
		AscensionSpellbookFrame:ReleaseAutocastShine(self.shine)
		self.shine = nil
	end

	self:UpdateCooldown()

	self.AutoCastable:SetShown(autoCastAllowed)
	self.isPassive = IsPassiveSpell(spell, bookType) == 1

	-- maybe show skill cards or upcoming active build spells here? idk taint disaster probably
	self.SlotFrame:Show()
	self.RequiredLevelString:Hide()

	local maxSpellID = C_Spell.GetMaxLearnableRank(spellId, C_Player:GetLevel())
	local canLearn = maxSpellID and not IsSpellKnown(maxSpellID) and not IsSpellIDKnown(maxSpellID)
	canLearn = canLearn and C_Spell.IsTrainerSpell(maxSpellID)
	if bookType == "spell" and canLearn then
		if self.iconOnly then
			self.SeeTrainerString:Hide()
			self.TrainTextBackground:Hide()
		else
			self.SeeTrainerString:Show()
			self.TrainTextBackground:Show()
		end
		self.TrainFrame:Show()
		self.TrainBook:Show()
		self.SpellName:SetPoint("LEFT", self, "RIGHT", 24, 8)
	else
		self.SeeTrainerString:Hide()
		self.TrainFrame:Hide()
		self.TrainTextBackground:Hide()
		self.TrainBook:Hide()
		self.SpellName:SetPoint("LEFT", self, "RIGHT", 8, 4)
	end

	self.IconTexture:SetTexture(icon)
	self.IconTexture:Show()

	if strlen(AscensionSpellbookFrame.searchText) > 0 then
		local desc = GetSpellDescription(spellId) or ""
		if name:lower():find(AscensionSpellbookFrame.searchText) or desc:lower():find(AscensionSpellbookFrame.searchText) then
			self.IconTexture:SetDesaturated(false)
			self.AbilityHighlight.Anim:Play()
			self.AbilityHighlight:Show()
			self.SpellName:SetFontObject(GameFontNormal)
			self.SubSpellName:SetFontObject(NewSubSpellFont)
			self.SlotFrame:SetDesaturated(false)
		else
			self.IconTexture:SetDesaturated(true)
			self.AbilityHighlight.Anim:Stop()
			self.AbilityHighlight:Hide()
			self.SpellName:SetFontObject(GameFontDisable)
			self.SubSpellName:SetFontObject(GameFontDisable)
			self.SlotFrame:SetDesaturated(true)
		end
	else
		self.IconTexture:SetDesaturated(false)
		self.AbilityHighlight.Anim:Stop()
		self.AbilityHighlight:Hide()
		self.SpellName:SetFontObject(GameFontNormal)
		self.SubSpellName:SetFontObject(NewSubSpellFont)
		self.SlotFrame:SetDesaturated(false)
	end

	if not iconOnly then
		self.SpellName:SetText(name)

		local subText = rank

		if strlen(rank) == 0 then
			if C_CharacterAdvancement.IsTalentSpellID(spellId) then
				if self.isPassive then
					subText = TALENT_PASSIVE
				else
					subText = TALENT
				end
			elseif self.isPassive then
				subText = SPELL_PASSIVE
			end
		end

		if strlen(subText) ~= 0 then
			self.SubSpellName:SetHeight(0)
			self.SubSpellName:SetText(subText)
		else
			self.SubSpellName:SetHeight(6)
			self.SubSpellName:SetText("")
		end

		self.SpellName:Show()
		self.SubSpellName:Show()
	else
		self.SpellName:Hide()
		self.SubSpellName:Hide()
	end

	if self.isPassive or not onClassTab then
		self.SpellHighlightTexture:Hide()
	else
		if bookType == BOOKTYPE_SPELL and not ActionBarUtil:FindSpellOnActionBar(name) then
			self.SpellHighlightTexture:Show()
		else
			self.SpellHighlightTexture:Hide()
		end
	end

	if self.isPassive then
		self.HighlightTexture:SetTexture("Interface\\Buttons\\UI-PassiveHighlight")
		self.SlotFrame:Hide()
	else
		self.HighlightTexture:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	end
	
	local _, cursorSpell, cursorBookType = GetCursorInfo()

	if self.bookType == BOOKTYPE_PROFESSION and cursorSpell and cursorBookType then
		local pickedUpName = GetSpellInfo(cursorSpell, cursorBookType)
		self.pickedUp = pickedUpName == name
	else
		self.pickedUp = cursorSpell == spell and cursorBookType == bookType
	end
	
	self:Enable()

	if GameTooltip:GetOwner() == self then
		self:OnEnter()
	end

	if self.isPassive then
		self:SetAttribute("spell", nil)
		self:SetAttribute("bookType", nil)
	else
		self:SetAttribute("spell", spell)
		self:SetAttribute("bookType", bookType)
	end
end

--
-- Tab Mixin
--
SpellbookTabMixin = {}

function SpellbookTabMixin:OnLoad()
	SetParentArray(self, "Tabs", self:GetID())
end

function SpellbookTabMixin:OnEnter()
	
end

function SpellbookTabMixin:OnClick()
	PlaySound(SOUNDKIT.UCHARACTERSHEETTAB)
	self:GetParent():OpenTab(self)
end

--
-- Side Tab Mixin
--
SpellbookSideTabMixin = {}

function SpellbookSideTabMixin:OnLoad()
	SetParentArray(self, "Tabs", self:GetID())
end

function SpellbookSideTabMixin:OnEnter()
	if self.tooltip and strlen(self.tooltip) > 0 then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltip)
		GameTooltip:Show()
	end
end

function SpellbookSideTabMixin:OnClick()
	if not self.HasInfo then return end
	PlaySound(SOUNDKIT.UCHARACTERSHEETTAB)
	
	self.Flash.Anim:Stop()
	self:GetParent():GetParent().TabsToFlash[self.tooltip] = nil
	self:GetParent():GetParent():SelectSideTab(self)
end

function SpellbookSideTabMixin:SetInfo(id, name, texture, offset, numSpells, highestRankOffset, highestRankNumSpells, hasNotMaxedSpells)
	if not id then
		self.Class = nil
		self.HasInfo = false
		self:Hide()
		return
	end

	self.HasInfo = true
	self:Show()
	self:SetID(id)

	if texture == "Interface\\Icons\\Ability_Kick" then
		texture = "Interface\\Icons\\inv_misc_book_09" -- swap general tab to better icon
	else
		self.Class = UNLOCALIZED_CLASS_NAMES[name]
	end

	self.NormalTexture:SetTexture(texture)
	self.tooltip = name
	
	local showAllRanks = GetCVarBool("ShowAllSpellRanks") and C_Spell.HasMultipleSpellRanks()

	self.offset = showAllRanks and offset or highestRankOffset
	self.numSpells = showAllRanks and numSpells or highestRankNumSpells

	if strlen(AscensionSpellbookFrame.searchText) > 0 then
		for i = self.offset + 1, self.numSpells + self.offset do
			local spellIndex = showAllRanks and i or GetKnownSlotFromHighestRankSlot(i)
			if spellIndex and spellIndex > 0 then
				local spellName = GetSpellInfo(spellIndex, "spell")
				local spellID = C_Spell:GetSpellID(spellIndex, "spell")
				local desc = spellID and GetSpellDescription(spellID) or ""
				if spellName and (spellName:lower():find(AscensionSpellbookFrame.searchText) or desc:lower():find(AscensionSpellbookFrame.searchText)) then
					self.NormalTexture:SetDesaturated(false)
					self.SearchHighlight:Show()
					return
				end
			end
		end
		self.NormalTexture:SetDesaturated(true)
		self.SearchHighlight:Hide()
	else
		self.NormalTexture:SetDesaturated(false)
		self.SearchHighlight:Hide()
	end

	if hasNotMaxedSpells then
		self.RankUp:Show()
	else
		self.RankUp:Hide()
	end
end

--
-- Main spellbook mixin
--
SpellbookMixin = {
	Spells = {},
	TabsToFlash = {},
	searchText = "",
}

local function ReleaseShine(pool, frame)
	frame:Hide()
	frame:ClearAllPoints()
	AutoCastShine_AutoCastStop(frame)
end

function SpellbookMixin:OnLoad()
	self.shines = CreateFramePool("Frame", self, "SpellBookShineTemplate", ReleaseShine)
	PanelTemplates_SetNumTabs(self, #self.Tabs)
	-- set side tab
	self.selectedSideTab = self.SideBar.Tab1
	self.selectedSideTabID = self.SideBar.Tab1:GetID()
	self.spellPage = 1

	self.currentContent = self.Content.Tabs[1]
	self.selectedSideTab:SetChecked(true)
	self:HookBucketEvent("SPELLS_CHANGED", 0.1)

	self:RegisterEvent("LEARNED_SPELL_IN_TAB")
	self:RegisterEvent("SKILL_LINES_CHANGED")
	
	self:EnableMouseWheel()
end

function SpellbookMixin:SPELLS_CHANGED()
	if not PLAYER_ENTERED_WORLD then return end

	if self:IsShown() then
		self:UpdateSideTabs()
		self:UpdateSpells()
	end
end

function SpellbookMixin:UpdatePet()
	if HasPetSpells() then
		self.Tabs[2]:Show()
		self.Tabs[3]:SetPoint("LEFT", self.Tabs[2], "RIGHT", -15, 0)
	else
		self.Tabs[2]:Hide()
		self.Tabs[3]:SetPoint("LEFT", self.Tabs[1], "RIGHT", -15, 0)
	end
end

function SpellbookMixin:UpdateSearch(text)
	self.searchText = text:lower():trim()
	self:UpdateSideTabs()
	self:UpdateSpells()
end

function SpellbookMixin:UpdateSideTabs()
	local numTabs = GetNumSpellTabs()

	if numTabs < 0 or self.selectedSideTabID > GetNumSpellTabs() then
		self:SelectSideTab(self.SideBar.Tabs[1])
	end

	local id = 1
	for i = 1, 19 do
		local tab = self.SideBar["Tab"..i]
		tab:SetFrameLevel(i)
		

		local _, icon= GetSpellTabInfo(id)

		-- skip internal tab
		if icon == "Interface\\Icons\\Mail_GMIcon" then
			id = id + 1
			icon = select(2, GetSpellTabInfo(id))
		end

		if i <= numTabs and id <= GetNumSpellTabs() then
			local name, texture, offset, numSpells, highestRankOffset, highestRankNumSpells = GetSpellTabInfo(id)
			tab:SetInfo(id, name, texture, offset, numSpells, highestRankOffset, highestRankNumSpells, C_Spell:TabHasNotMaxedRanks(id))
			if self.TabsToFlash[name] then
				tab.Flash.Anim:Play()
			else
				tab.Flash.Anim:Stop()
			end
		else
			tab:SetInfo()
		end
		
		id = id + 1
	end
end

function SpellbookMixin:UpdateSpells()
	if not self.bookType then return end

	if self.bookType == BOOKTYPE_SPELL then
		local tab = self.selectedSideTab
		local pageOffset = (self.spellPage - 1) * 12
		local offset = (tab.offset or 0) + pageOffset
		
		if pageOffset > tab.numSpells then
			offset = tab.offset
			self.spellPage = 1
			pageOffset = 0
		end

		local id = 1
		local showAllRanks = GetCVarBool("ShowAllSpellRanks") and C_Spell.HasMultipleSpellRanks()
		for i = 1, 12 do
			local spell = showAllRanks and offset + id or GetKnownSlotFromHighestRankSlot(offset + id)
			local button = self.Content.Spells["SpellButton"..i]
			if spell and spell > 0 and pageOffset + id <= tab.numSpells then
				button:SetSpell(spell, BOOKTYPE_SPELL)
			else
				button:SetSpell()
			end
			id = id + 1
		end

		self.PreviousPageButton:SetEnabled(self.spellPage > 1)
		self.NextPageButton:SetEnabled(pageOffset + 12 < tab.numSpells)

	elseif self.bookType == BOOKTYPE_PET then
		local offset = (self.spellPage - 1) * 12
		for i = 1, 12 do
			local button = self.Content.PetSpells["SpellButton"..i]
			button:SetSpell(i + offset, BOOKTYPE_PET)
		end

		self.PreviousPageButton:SetEnabled(self.spellPage > 1)
		self.NextPageButton:SetEnabled(HasPetSpells() and ((self.spellPage - 1) * 12) + 12 < HasPetSpells())
	elseif self.bookType == BOOKTYPE_PROFESSION then
		self.Content.Professions:UpdateProfessions()
	end
end

function SpellbookMixin:OnShow()
	PlaySound(SOUNDKIT.ABILITIES_OPENA)
	securecall(MultiActionBar_ShowAllGrids)
	securecall(UpdateMicroButtons)
	self:UpdatePet()
	self:RegisterEvent("UNIT_PET")
	self:UpdateSearch("")
end

function SpellbookMixin:OnHide()
	PlaySound(SOUNDKIT.ABILITIES_CLOSEA)
	self:UnregisterEvent("UNIT_PET")
	securecall(MultiActionBar_HideAllGrids)
	securecall(UpdateMicroButtons)
end

function SpellbookMixin:OnEvent(event, ...)
	if event == "UNIT_PET" and ... == "player" then
		self:UpdatePet()

	elseif event == "SKILL_LINES_CHANGED" then
		if self:IsShown() then
			self:UpdateSideTabs()
			self:UpdateSpells()
		end

	elseif event == "LEARNED_SPELL_IN_TAB" then
		if self:IsShown() then
			self:UpdateSideTabs()
			self:UpdateSpells()
		end
		local tabID = ...

		if self.selectedSideTabID == tabID or tabID == 1 then
			return
		end

		local name = GetSpellTabInfo(tabID)
		self.TabsToFlash[name] = true
	end
end

function SpellbookMixin:OpenTab(tab)
	if not tab then return end
	PanelTemplates_Tab_OnClick(tab, self)

	if self.currentContent then
		self.currentContent:Hide()
	end

	local id = tab:GetID()
	self.spellPage = 1

	if id == 1 then
		self.bookType = BOOKTYPE_SPELL
		self:UpdateSearch(self.Content.Spells.Search:GetText())
	elseif id == 2 then
		self.bookType = BOOKTYPE_PET
		self:UpdateSearch("")
	else
		self.bookType = BOOKTYPE_PROFESSION
		self:UpdateSearch("")
	end

	self.currentContent = self.Content.Tabs[id]
	self.currentContent:Show()
end

function SpellbookMixin:SelectSideTab(tab)
	if self.selectedSideTab then
		self.selectedSideTab:SetChecked(false)
	end

	tab:SetChecked(true)
	self.selectedSideTab = tab
	self.selectedSideTabID = tab:GetID()
	self.spellPage = 1
	self:UpdateSpells()
end

function SpellbookMixin:NextSpellPage()
	PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA_70)
	self.spellPage = self.spellPage + 1
	self:UpdateSpells()
end

function SpellbookMixin:PreviousSpellPage()
	PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA_70)
	self.spellPage = math.clamp(self.spellPage - 1, 1, self.spellPage)
	self:UpdateSpells()
end

function SpellbookMixin:GetAutocastShine()
	return self.shines:Acquire()
end

function SpellbookMixin:ReleaseAutocastShine(shine)
	self.shines:Release(shine)
end

function SpellbookMixin:GetSpellLocation(spellID)
	for _, tab in ipairs(self.SideBar.Tabs) do
		if tab.HasInfo then
			for i = tab.offset + 1, tab.offset + tab.numSpells do
				local name, rank = GetSpellInfo(i, BOOKTYPE_SPELL)
				if name and C_Spell:GetSpellID(name, rank) == spellID then
					return i, BOOKTYPE_SPELL
				end
			end
		end
	end

	for i = 1, 12 do
		local name, rank = GetSpellInfo(i, BOOKTYPE_PET)
		if name and C_Spell:GetSpellID(name, rank) == spellID then
			return i, BOOKTYPE_PET
		end
	end
end

function SpellbookMixin:OnAttributeChanged(name, value)
	if name =="toggle" then
		ToggleSpellBook(value)
	end
end

function ToggleSpellBook(bookType)
	if ( not HasPetSpells() and bookType == BOOKTYPE_PET ) then
		return
	end

	if not issecure() then
		print("Not Secure toggle")
		AscensionSpellbookFrame:SetAttribute("toggle", bookType)
		return
	end

	local shown = AscensionSpellbookFrame:IsShown()
	-- if visible and we toggled the current book type -> hide
	if shown and bookType == AscensionSpellbookFrame.bookType then
		HideUIPanel(AscensionSpellbookFrame)
		return
	elseif not shown then
		-- not shown, show ui
		ShowUIPanel(AscensionSpellbookFrame)
	end
	
	-- update tab if needed
	if bookType ~= AscensionSpellbookFrame.bookType then
		PlaySound(SOUNDKIT.ABILITIES_OPENA)
		if bookType == BOOKTYPE_SPELL then
			AscensionSpellbookFrame:OpenTab(AscensionSpellbookFrame.Tabs[1])
		elseif bookType == BOOKTYPE_PET then
			AscensionSpellbookFrame:OpenTab(AscensionSpellbookFrame.Tabs[2])
		end
	end
end