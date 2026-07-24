local AddonName, Addon = ...
-------------------------------------------------------------------------------
--                           EnchantCollectionMixin                          --
-------------------------------------------------------------------------------
EnchantCollectionMixin = {}

local EnchantCollectionEvents = {
	"MYSTIC_ENCHANT_REFORGE_RESULT",
	"MYSTIC_ENCHANT_SLOT_UPDATE",
	"MYSTIC_ENCHANT_LEARNED",
	"MYSTIC_ALTAR_CLOSED",
	"PLAYER_MONEY",
	"MYSTIC_ENCHANT_PRESET_SET_ACTIVE_RESULT",
	"ENCHANTCOLLECTION_DIALOGUE_SHOW",
	"ENCHANTCOLLECTION_DIALOGUE_HIDE",
	"MYSTIC_SCROLL_USED",
	"MYSTIC_ENCHANT_PROGRESS_UPDATE",
	"MYSTIC_ENCHANT_SLOT_MAP_REFRESH",
	"UNIT_SPELLCAST_START",
	"NEW_BAG_ITEM_ADDED",
	"BAG_ITEM_REPLACED",
	"ENCHANTCOLLECTION_PRESET_SWAP_STARTED",
	"MYSTIC_ENCHANT_DISENCHANT_RESULT",
}

local qualitySounds = {
	[0] = SOUNDKIT.COMMON_UI_MISSION_SELECT,
	[2] = SOUNDKIT.RARE_UI_ORDERHALL_TALENT_READY_TOAST,
	[3] = SOUNDKIT.RARE_UI_ORDERHALL_TALENT_READY_TOAST,
	[4] = SOUNDKIT.EPIC_UI_MISSION_200PERCENT,
	[5] = SOUNDKIT.LEGENDARY_UI_LEGENDARY_ITEM_TOAST,
	[6] = SOUNDKIT.LEGENDARY_UI_LEGENDARY_ITEM_TOAST,
	[7] = SOUNDKIT.LEGENDARY_UI_LEGENDARY_ITEM_TOAST,
	[8] = SOUNDKIT.LEGENDARY_UI_LEGENDARY_ITEM_TOAST,
}

-- TODO: Consider moving
local EnchantCollectionProgressSpells = {
	93235, -- SPELL_REFORGE_MYSTIC_ENCHANT
	93236, -- SPELL_COLLECTION_REFORGE_MYSTIC_ENCHANT
	93237, -- SPELL_DISENCHANT_MYSTIC_ENCHANT
	93238, -- SPELL_APPLY_MYSTIC_ENCHANT
	93239, -- SPELL_PURCHASE_MYSTIC_SCROLL
	84789, -- SPELL_ACTIVATE_MYSTIC_ENCHANT_PRESET
	84872, -- SPELL_UNLOCK_MYSTIC_ENCHANT_PRESET
	93241, -- SPELL_DESTROY_MYSTIC_ENCHANT
}

local EnchantCollectionProgressSpellsSilentProgress = {
	93235, -- SPELL_REFORGE_MYSTIC_ENCHANT
	93237, -- SPELL_DISENCHANT_MYSTIC_ENCHANT
}

HelpTips["EC_HELP_SAVE_CURRENCY"] = {
    text = ENCHANT_COLLECTION_NEED_MORE_EXTRACTS,
    parent  = "EnchantCollection.CurrencyExtract",
    targetPoint = HelpTip.Point.TopEdgeCenter,
}

HelpTips["EC_HELP_LEVEL"] = {
    text = ENCHANT_COLLECTION_NEED_MORE_LEVELS,
    parent  = "EnchantCollectionNineSlice.Level",
    targetPoint = HelpTip.Point.BottomEdgeCenter,
}
-------------------------------------------------------------------------------
--                           EnchantCollectionMixin                          --
-------------------------------------------------------------------------------
function EnchantCollectionMixin:OnLoad()
	self:Layout()

	for _, v in pairs(EnchantCollectionProgressSpells) do
		local name = GetSpellInfo(v)
		if (name) then
			EnchantCollectionProgressSpells[name] = v
		end
	end

	for _, v in pairs(PRESET_CHANGE_SPELLS) do
		local name = GetSpellInfo(v)
		if name then
			EnchantCollectionProgressSpells[name] = v
		end
	end

	for _, v in pairs(EnchantCollectionProgressSpellsSilentProgress) do
		local name = GetSpellInfo(v)
		if (name) then
			EnchantCollectionProgressSpellsSilentProgress[name] = v
		end
	end

	Timer.After(0.1, function() EnchantCollectionUtil:Init() end)
end

function EnchantCollectionMixin:OnShow()
	C_CVar.Set("allowMysticEnchantingUI", "1")
	for _, v in pairs(EnchantCollectionEvents) do
		self:HookEvent(v)
	end

	self:HookBucketEvent("BAG_UPDATE", 0.1)
	self:BAG_UPDATE()
	self:UpdateProgress()
	self:UpdateAltar()
	self:ClearCollectionScrollReforge()
	self:MYSTIC_ENCHANT_PRESET_SET_ACTIVE_RESULT(nil)

	C_Hook:RegisterBucket(self, {"UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_SUCCEEDED"}, 0.1, "StopSpellCast")
	C_Hook:RegisterBucket(self, {"MYSTIC_ENCHANT_COLLECTION_REFORGE_RESULT", 
									"MYSTIC_ENCHANT_APPLY_RESULT", 
									"MYSTIC_ENCHANT_PURCHASE_RESULT",
									"MYSTIC_ENCHANT_INSPECT_RESULT",
									"MYSTIC_ENCHANT_DESTROY_RESULT",
									"MYSTIC_ENCHANT_PRESET_UNLOCK_RESULT",
									"MYSTIC_ENCHANT_PRESET_SAVE_RESULT",
								}, 0.1, "HandleError")

	if (self.hasDelayedPreview) then
		self:ClearDelayedPreview()
	end
	
	if self:IsAnyEnchantKnown() and not self.openToScrollsTab then
		self:GetCollectionFrame():SetTab(Enum.ECCollectionTabs.CollectionTab)
	else
		self.openToScrollsTab = false
		self:GetCollectionFrame():SetTab(Enum.ECCollectionTabs.ScrollsTab)
	end
end

function EnchantCollectionMixin:OnHide()
	for _, v in pairs(EnchantCollectionUtil.dialogues) do

		StaticPopup_Hide(v)
	end

	self.InputBlock:Hide()

	self:UnhookAllEvents()
	self:GetSlotTab():HideActivationFrame()
	self:GetSlotTab():ClickUndo()
	self.EnchantUnlockPopup:Hide()
	self:GetCollectionFrame().CollectionTab.savedFilter = nil
end

function EnchantCollectionMixin:GetCollectionFrame()
	return self.Collection
end

function EnchantCollectionMixin:GetSlotsFrame()
	return self.Slots
end

function EnchantCollectionMixin:GetSlotTab()
	return self:GetSlotsFrame().SlotTab
end

function EnchantCollectionMixin:GetScrollsTab()
	return self:GetCollectionFrame().ScrollsTab
end

function EnchantCollectionMixin:GetArchitectTab()
	return self:GetSlotsFrame().ArchitectTab
end

function EnchantCollectionMixin:GetCollectionTab()
	return self:GetCollectionFrame().CollectionTab
end

function EnchantCollectionMixin:GetReforgeTab()
	return self:GetSlotsFrame().ReforgeTab
end

function EnchantCollectionMixin:UpdateProgressBar(statusBar, level, progress)
	statusBar.text = LEVEL.." "..level

	local oldValue = statusBar:GetValue()

	if (progress < oldValue) or not(oldValue) then
		oldValue = 0
	end

	if (statusBar:IsVisible()) then
		statusBar:PlayUpdateValueAnim(oldValue, progress)
	else
		statusBar:SetValue(progress)
	end

	-- safe thing. SetValue Should already trigger OnValueChanged but if value is 0 and it is inital setup text won't update properly
	statusBar:OnValueChanged(progress)
end

function EnchantCollectionMixin:UpdateProgress(progress, level) -- TODO: this code can be improved
	if not(progress) then
		progress, level = C_MysticEnchant.GetProgress()
	end

	if not(tonumber(progress)) or (progress > 100) then -- if progress is 0 it returns INF
		progress = 0
	else
		progress = math.ceil(progress)
	end

	level = (level > 0) and level or 1

	self:UpdateProgressBar(self:GetReforgeTab().ProgressBar, level, progress)
	
	self.Level.Text:SetText(level)
end

function EnchantCollectionMixin:GetScrollsTabItemData(itemID)
	return self:GetScrollsTab():GetItemDataByIDUnfiltered(itemID)
end

function EnchantCollectionMixin:SetScrollTabSelectedItem(itemID)
	self:GetScrollsTab():SetSelectedItem(itemID)
end

function EnchantCollectionMixin:GetEnchantStacks(spellID)
	return self:GetSlotTab():GetStackCount(spellID)
end

function EnchantCollectionMixin:TooltipAddStackData(spellID) -- consider moving to EnchantCollectionUtil
	local REData = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
	local stackCount = self:GetEnchantStacks(spellID)

	local textObject = (stackCount == 0) and GameFontDisable or GameFontHighlight

	GameTooltip:AddLine(string.format(AUCTION_NUM_STACKS.." %s/%s", stackCount, REData and REData.MaxStacks or 0), textObject:GetTextColor())
	GameTooltip:Show()
end

function EnchantCollectionMixin:ReforgeScroll(itemID)
	if not(self:GetReforgeTab():IsVisible()) then
		self:GetSlotsFrame():SetTab(Enum.ECSlotTabs.ReforgeTab)
	end

	self:GetReforgeTab():UpdateItem(itemID)
end

function EnchantCollectionMixin:ActivateScroll(itemID)
	if not(self:GetSlotTab():IsVisible()) then
		self:GetSlotsFrame():SetTab(Enum.ECSlotTabs.SlotTab)
	end

	self:GetSlotTab():SetItem(itemID)
end

function EnchantCollectionMixin:OnSelectCollectionEnchant(spellID)
	if not(EnchantCollectionUtil:GetAltar()) then
		UIErrorsFrame:AddMessage(_G["RE_COLLECTION_REFORGE_NO_MYSTIC_ALTAR"] or "RE_COLLECTION_REFORGE_NO_MYSTIC_ALTAR", 1, 0, 0)
		return
	end

	if (self:HasCollectionReforgeScrollDialogue()) then
		local itemID = self.CollectionScrollReforge.itemData.Entry
		local GUIDLow = self.CollectionScrollReforge.itemData.Guid

		if EnchantCollectionUtil:HandleCheck("CanCollectionReforgeItem", GUIDLow, spellID) then
			EnchantCollectionUtil:ShowCollectionReforgeItemDialogue(itemID, GUIDLow, spellID, GenerateClosure(self.CancelCollectionScrollReforge, self))
		end
	else
		local activeEnchant = self:GetSlotTab():HasEnchant()

		if activeEnchant and (self:GetSlotTab().spellID == spellID) then
			self:GetSlotTab():Clear()
		else
			self:GetSlotTab():SetEnchant(spellID)
		end
	end
end

function EnchantCollectionMixin:OnEnchantSelected(spellID)
	 self:GetCollectionTab():RefreshSelected(spellID)
end

function EnchantCollectionMixin:OnSelectEnchantScroll(itemID, isUntarnishedScroll)
	local selectedTabIndex = self:GetSlotsFrame():GetSelectedTab()

	self:SetScrollTabSelectedItem(itemID)

	if (selectedTabIndex == Enum.ECSlotTabs.ReforgeTab) then
		self:ReforgeScroll(itemID)
	elseif (selectedTabIndex == Enum.ECSlotTabs.SlotTab) then

		if (isUntarnishedScroll) then
			self:GetSlotTab():ClickUndo()
			self:ReforgeScroll(itemID)
			return
		end

		self:ActivateScroll(itemID)
		self:GetReforgeTab():UpdateItem(itemID)
	end
end

function EnchantCollectionMixin:OnCollectionTabSwitch(tabID)
	if BuildCreatorUtil.IsPickingEnchants() then
		self:GetSlotsFrame():SetTab(Enum.ECSlotTabs.ArchitectTab)
	elseif (self:GetSlotsFrame():GetSelectedTab() ~= tabID) then
		self:GetSlotsFrame():SetTab(tabID)
	end

	self:UpdateAltar()
	self:GetSlotTab():ClickUndo()
	self:ClearCollectionScrollReforge()
end

function EnchantCollectionMixin:IsAnyEnchantKnown()
	local _, totalKnownEnchants = C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN})

	if totalKnownEnchants and (totalKnownEnchants > 0) then
		return true, totalKnownEnchants
	end

	return false
end

function EnchantCollectionMixin:IsScrollTabActive()
	if (PanelTemplates_GetSelectedTab(self:GetCollectionFrame()) == Enum.ECCollectionTabs.ScrollsTab) then
		return true
	end

	return false
end

function EnchantCollectionMixin:HasCollectionReforgeScrollDialogue()
	return self.CollectionScrollReforge:IsVisible()
end

function EnchantCollectionMixin:CollectionReforgeScroll(itemData)
	self:SetKnownCollectionTabActive()
	
	local item = Item:CreateFromID(itemData.Entry)
	self.CollectionScrollReforge.Text:SetText("|cffffd100"..ENCHANT_COLLECTION_SCROLL_COLLECTION_REFORGE_TIP.."\n"..item:GetLink().."|r")

	self.CollectionScrollReforge.itemData = itemData

	BaseFrameFadeIn(self.CollectionScrollReforge)
end

function EnchantCollectionMixin:ClearCollectionScrollReforge()
	if (self.CollectionScrollReforge and self.CollectionScrollReforge:IsVisible()) then
		BaseFrameFadeOut(self.CollectionScrollReforge)
		self.CollectionScrollReforge.itemData = nil
	end
end

function EnchantCollectionMixin:CancelCollectionScrollReforge()
	self:ClearCollectionScrollReforge()
	self:GetCollectionFrame():SetTab(Enum.ECCollectionTabs.ScrollsTab)
end

function EnchantCollectionMixin:GetInUseStatus(GUIDlow)
	return self:GetSlotTab():IsItemGUIDUsed(GUIDlow)
end

-- TODO: Consider making a callback
function EnchantCollectionMixin:OnScrollUsed()
	self:GetScrollsTab():RefreshScrollData()
end

function EnchantCollectionMixin:UpdateAltar()
	self:GetReforgeTab():UpdateButtons()
	self:GetScrollsTab():RefreshScrollData()

	if not BuildCreatorUtil.IsPickingEnchants() and not(EnchantCollectionUtil:GetAltar()) then
		self.NoAltarFrame:Show()
		self:GetSlotTab():ClickUndo()
		self:ClearCollectionScrollReforge()
		--UIDropDownMenu_DisableDropDown(self:GetSlotTab().SpecDropDown)
	else
		self.NoAltarFrame:Hide()
		--UIDropDownMenu_EnableDropDown(self:GetSlotTab().SpecDropDown)
	end
end

function EnchantCollectionMixin:ShowSaveToCollectionTutorial()
	HelpTip:Show("EC_HELP_SAVE_CURRENCY")
end

function EnchantCollectionMixin:HideSaveToCollectionTutorial()
	HelpTip:Hide("EC_HELP_SAVE_CURRENCY")
end

function EnchantCollectionMixin:SetWaitingForReforge()
	self.waitingForReforge = true
end

function EnchantCollectionMixin:LevelButtonOnEnter(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:AddLine(string.format(MYSTIC_ENCHANTING_ALTAR.." "..LEVEL.." %s", button.Text:GetText()), 1, 1, 1, 1)
	GameTooltip:AddLine(MYSTIC_ENCHANT_EXP_BAR_DESC, 1, 0.82, 0, 1) -- TODO: Fix
	GameTooltip:Show()
end

function EnchantCollectionMixin:SetupEnchantUnlockPopup()
	self.EnchantUnlockPopup:Hide() 
	BaseFrameFadeIn(self.EnchantUnlockPopup)

	local hasKnown, total = self:IsAnyEnchantKnown()

	self.EnchantUnlockPopup:ClearAndSetPoint("CENTER", self:GetReforgeTab().AnimatedEnchant, "CENTER", 0, -32)

	if not(hasKnown) or not(self:GetReforgeTab():IsVisible()) then
		self.EnchantUnlockPopup:ClearAndSetPoint("CENTER", self.Collection, 0, 0)
	end
end

function EnchantCollectionMixin:PLAYER_MONEY()
	self:GetReforgeTab():UpdateButtons()
end

function EnchantCollectionMixin:BAG_UPDATE()
	self:GetScrollsTab():RefreshScrollData(self.waitingForReforge)

	self:GetReforgeTab():Init(self:GetScrollsTab():GetUntrainedScrolls(), self.waitingForReforge)

	--self.CurrencyExtract:SetItem(ItemData.MYSTIC_EXTRACT)
	--self.CurrencyOrb:SetItem(ItemData.MYSTIC_ORB)
end

function EnchantCollectionMixin:CheckForReforge(itemID)
	local REData = C_MysticEnchant.GetEnchantInfoByItem(itemID) or (itemID == ItemData.UNTARNISHED_MYSTIC_SCROLL)

	if (self.waitingForReforge and REData) then
		self.waitingForReforge = false
		if (self:GetReforgeTab():IsVisible()) then
			self:GetReforgeTab():UpdateItem(itemID, true)
		end
	end
end

function EnchantCollectionMixin:ClearDelayedPreview()
	self.hasDelayedPreview = false
	self:GetSlotTab():Clear()
end

function EnchantCollectionMixin:HandleError(...)
	local arg1, arg2 = ...

	if arg2 and (type(arg2) == "table") then -- work with bucket
		for _, data in ipairs(arg2) do
			for _, str in pairs(data) do
				EnchantCollectionUtil:HandleError("", {}, str)
			end
		end
	else
		EnchantCollectionUtil:HandleError("", {}, ...) -- work with just a string in 1st arg
	end
end

function EnchantCollectionMixin:SetKnownCollectionTabActive()
	self:GetCollectionFrame():SetTab(Enum.ECCollectionTabs.CollectionTab)
	self:GetCollectionFrame():ResetFiltersAndSearch()
end

function EnchantCollectionMixin:PlayEnchantQualitySound(quality)
	PlaySound(qualitySounds[quality or 2])
end

function EnchantCollectionMixin:PlayQualitySoundForItem(itemID)
	if (self.waitingForReforge) then
		local item = Item:CreateFromID(itemID)
		self:PlayEnchantQualitySound(item:GetQuality())
	end
end

function EnchantCollectionMixin:FilterForEnchantQuality(quality)
	self:SetKnownCollectionTabActive()
	self:GetCollectionFrame():ApplyQualityFilter(quality)
end

function EnchantCollectionMixin:NEW_BAG_ITEM_ADDED(Bag, Slot, ItemID, ItemCount)
	self:PlayQualitySoundForItem(ItemID)
	self:CheckForReforge(ItemID)
end

function EnchantCollectionMixin:BAG_ITEM_REPLACED(Bag, Slot, OldItemID, OldItemCount, NewItemID, NewItemCount)
	self:PlayQualitySoundForItem(NewItemID)
	self:CheckForReforge(NewItemID)
end

function EnchantCollectionMixin:MYSTIC_ENCHANT_REFORGE_RESULT(...) -- TODO: properly handle those results
	self:UpdateProgress()
	self:HandleError(...)
end

function EnchantCollectionMixin:MYSTIC_ENCHANT_DISENCHANT_RESULT(...)
	if (string.find(..., "_OK$")) then
		self.waitingForDisenchant = true
		self:SetupEnchantUnlockPopup()
	end

	self:HandleError(...)
end

function EnchantCollectionMixin:MYSTIC_ENCHANT_PROGRESS_UPDATE(...)
	self:UpdateProgress(...)
end

function EnchantCollectionMixin:MYSTIC_ENCHANT_SLOT_UPDATE(...)
	local slotID = EnchantCollectionUtil:GetFakeSlotID(...)
	
	self:GetSlotTab():MYSTIC_ENCHANT_SLOT_UPDATE(slotID)
end

function EnchantCollectionMixin:MYSTIC_ENCHANT_LEARNED(...) -- TODO: properly handle result
	local hasKnown, total = self:IsAnyEnchantKnown()

	if (hasKnown and (total == 1)) then
		self:SetKnownCollectionTabActive()
	end

	if PanelTemplates_GetSelectedTab(self:GetCollectionFrame()) == Enum.ECCollectionTabs.CollectionTab or not(self.waitingForDisenchant) then -- switch to collection and refresh it if we're not disenchanting
		self:SetKnownCollectionTabActive()
		self:SetupEnchantUnlockPopup()
	end
		
	self.waitingForDisenchant = false

	if (...) then
		local spellID = ...

		if spellID and (type(spellID) == "number") and (spellID ~= 0) then
			local REData = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
			if (REData) then
				self:PlayEnchantQualitySound(EnchantCollectionUtil:GetQualityFromQualityName(REData.Quality))
			end
		end
	end

	self.EnchantUnlockPopup:SetEnchant(...)
end

function EnchantCollectionMixin:MYSTIC_ALTAR_CLOSED()
	self:UpdateAltar()
end

function EnchantCollectionMixin:MYSTIC_ENCHANT_SLOT_MAP_REFRESH()
	self:GetSlotTab():ClearPreview()
end

function EnchantCollectionMixin:UpdateActivePresetButton()
	self:GetSlotTab().ActiveSpecButton.index = MysticEnchantManagerUtil.GetActivePreset()
	self:GetSlotTab().ActiveSpecButton:Update()
end

function EnchantCollectionMixin:MYSTIC_ENCHANT_PRESET_SET_ACTIVE_RESULT(result)
	self:UpdateActivePresetButton()
	-- update slots if preset updates
	if (self.hasDelayedPreview) then
		self:ClearDelayedPreview()
	end

	PlaySound(SOUNDKIT.UI_70_ARTIFACT_FORGE_RELIC_PLACE)

	EnchantCollectionUtil:Init()
	self:HandleError(result or "")
end

function EnchantCollectionMixin:ENCHANTCOLLECTION_DIALOGUE_SHOW()
	BaseFrameFadeIn(self.InputBlock)

	-- TODO: Move static popup logic to its own input block frame
	for i = 1, #StaticPopup_DisplayedFrames do
		local popup = StaticPopup_DisplayedFrames[i]
		popup:SetFrameLevel(self.EnchantUnlockPopup:GetFrameLevel()+30)
	end

end

function EnchantCollectionMixin:ENCHANTCOLLECTION_DIALOGUE_HIDE()
	BaseFrameFadeOut(self.InputBlock)
end

function EnchantCollectionMixin:MYSTIC_SCROLL_USED(itemID)
	self:GetScrollsTab():RefreshScrollData()
	if (self:GetScrollsTabItemData(itemID)) then
		if self:IsVisible() then
			self:GetCollectionFrame():SetTab(Enum.ECCollectionTabs.ScrollsTab)
		else
			self.openToScrollsTab = true
		end

		-- wait for tabs to switch
		Timer.After(0.1, function() 
			if self:GetSlotsFrame():GetSelectedTab() ~= Enum.ECSlotTabs.SlotTab then
				self:GetSlotsFrame():SetTab(Enum.ECSlotTabs.SlotTab)
			end

			self:OnSelectEnchantScroll(itemID, (itemID == ItemData.UNTARNISHED_MYSTIC_SCROLL))
		end)
	end
end

function EnchantCollectionMixin:MYSTIC_ENCHANT_UNLOCK_PRESET_USED()
	-- must be run next frame
	-- race condition between hybrid scroll setup and showing the frame
	-- not running after will likely cause scroll child to have 0 width.
	RunNextFrame(function()
		if not self:GetSlotTab():IsSpecManagerOpen() then
			self:GetSlotTab():ToggleSpecManager()
		end
	end)
end

-- TODO: consider making mixin for such things
function EnchantCollectionMixin:UNIT_SPELLCAST_START(...)
	local unit = ...

	if unit ~= "player" then
		return
	end

	local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)

	if not(EnchantCollectionProgressSpells[name]) then
		return
	end

    self.InputBlock.Progress.castID = castID

	self.InputBlock.Progress.value = (GetTime() - (startTime / 1000))
    self.InputBlock.Progress.maxValue = (endTime - startTime) / 1000

	self.InputBlock.Progress.BarTexture:SetVertexColor(0.42, 0.18, 1)
	self.InputBlock.Progress.fadeOut = false

    self.InputBlock.Progress.casting = true
    self.InputBlock.Progress:SetText(text)
    self.InputBlock.Progress:SetMinMaxValues(0, self.InputBlock.Progress.maxValue)
    self.InputBlock.Progress:SetValue(self.InputBlock.Progress.value)

    if not(EnchantCollectionProgressSpellsSilentProgress[name]) then
		BaseFrameFadeIn(self.InputBlock.Progress)
	    BaseFrameFadeIn(self.InputBlock)
	end
end

function EnchantCollectionMixin:ENCHANTCOLLECTION_PRESET_SWAP_STARTED()
	self.hasDelayedPreview = true
end

-- TODO: Work with bar color
function EnchantCollectionMixin:StopSpellCast(event, args)
	args = args[1]

	local unit = args[1]

	if unit ~= "player" then
		return
	end

	if not(self.InputBlock.Progress.casting) then
		return
	end

	if args[4] == self.InputBlock.Progress.castID then

		if (event ~= "UNIT_SPELLCAST_SUCCEEDED") then
			if (self.waitingForReforge) then
				self:GetReforgeTab():StopReforgeAnim()
				self:CheckForReforge(self:GetReforgeTab().itemData and self:GetReforgeTab().itemData.Entry)
			end

			if (self.waitingForDisenchant) then
				self.waitingForDisenchant = false
				BaseFrameFadeOut(self.EnchantUnlockPopup)
			end

			if (self.hasDelayedPreview) then
				self:ClearDelayedPreview()
			end

			self.InputBlock.Progress.BarTexture:SetVertexColor(1, 0, 0)
		else
			self.InputBlock.Progress.BarTexture:SetVertexColor(0, 1, 0)
		end
		
		self.InputBlock.Progress:SetValue(self.InputBlock.Progress.maxValue)
		self.InputBlock.Progress.casting = false
	end
end

function EnchantCollectionMixin:Layout()
	self:SetSize(1140, 606)

	PortraitFrame_SetIcon(self, "Interface\\Icons\\inv_MysticEnchantAltar")
	PortraitFrame_SetTitle(self, BUG_REPORT_CATEGORY_MYSTICENCHANTS)

	self.Slots = CreateFrame("FRAME", "$parent.Slots", self)
	self.Slots:SetPoint("BOTTOMLEFT", 4, 28)
	self.Slots:SetWidth(380)
	self.Slots:SetPoint("TOP", 0, -58)
	MixinAndLoadScripts(self.Slots, ECSlotFrameMixin)

	self.Collection = CreateFrame("FRAME", "$parent.Collection", self, "InsetFrameNoBGTemplate")
	self.Collection:SetPoint("BOTTOMLEFT", self.Slots, "BOTTOMRIGHT", 4, 0)
	self.Collection:SetPoint("TOPRIGHT", -4, -58)
	self.Collection.NineSlice:SetFrameLevel(self.Collection:GetFrameLevel()+1)
	MixinAndLoadScripts(self.Collection, ECCollectionFrameMixin)

	self.CollectionScrollReforge = CreateFrame("FRAME", "$parent.CollectionScrollReforge", self, nil)
	self.CollectionScrollReforge:SetPoint("TOPLEFT", self.Slots, 0, 0)
	self.CollectionScrollReforge:SetPoint("BOTTOMRIGHT", self.Slots.SlotTab, 0, 0)
	self.CollectionScrollReforge:SetBackdrop(GameTooltip:GetBackdrop())
	self.CollectionScrollReforge:SetBackdropBorderColor(0, 0, 0, 0)
	self.CollectionScrollReforge:SetBackdropColor(0.1, 0.03, 0.14, 1)
	self.CollectionScrollReforge:EnableMouse(true)
	self.CollectionScrollReforge:SetFrameLevel(self.Slots:GetFrameLevel()+6)
	self.CollectionScrollReforge:Hide()

	self.CollectionScrollReforge.Shadow = self.CollectionScrollReforge:CreateTexture(nil, "ARTWORK")
	self.CollectionScrollReforge.Shadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.CollectionScrollReforge.Shadow:SetPoint("CENTER", 0, 0)
	self.CollectionScrollReforge.Shadow:SetHeight(400)
	self.CollectionScrollReforge.Shadow:SetWidth(400)
	self.CollectionScrollReforge.Shadow:SetAlpha(1)

	self.CollectionScrollReforge.Text = self.CollectionScrollReforge:CreateFontString(nil, "OVERLAY")
	self.CollectionScrollReforge.Text:SetWidth(350)
	self.CollectionScrollReforge.Text:SetPoint("CENTER", 0, 16)
	self.CollectionScrollReforge.Text:SetFontObject(GameFontDisableLarge)
	self.CollectionScrollReforge.Text:SetText("|cffffd100"..ENCHANT_COLLECTION_SCROLL_COLLECTION_REFORGE_TIP.."|r")

	self.CollectionScrollReforge.Button = CreateFrame("BUTTON", "$parent.Button1", self.CollectionScrollReforge, "RedButtonTemplate")
	self.CollectionScrollReforge.Button:SetSize(172, 40)
	self.CollectionScrollReforge.Button:SetPoint("TOP", self.CollectionScrollReforge.Text, "BOTTOM", 0, -8)
	self.CollectionScrollReforge.Button:SetText(CANCEL)
	self.CollectionScrollReforge.Button:SetScript("OnClick", function() self:CancelCollectionScrollReforge() end)

	self.NoAltarFrame = CreateFrame("FRAME", "$parent.NoAltarFrame", self, nil)
	self.NoAltarFrame:SetPoint("TOPLEFT", self.Slots, "BOTTOMLEFT", 0, 80)
	self.NoAltarFrame:SetPoint("BOTTOMRIGHT", self.Slots, "BOTTOMRIGHT", 0, 44)
	self.NoAltarFrame:SetFrameLevel(self.Slots:GetFrameLevel()+4)

	MixinAndLoadScripts(self.NoAltarFrame, ECLargeDisabledTextFrameMixin)

	self.NoAltarFrame.Text:SetText("|cffff0000"..ENCHANT_COLLECTION_NO_ALTAR_FULL.."|r")

	self.CurrencyExtract = CreateFrame("BUTTON", "$parent.CurrencyExtract", self, nil)
	self.CurrencyExtract:SetPoint("TOPLEFT", self.Collection, "BOTTOMLEFT", 0, -2)
	self.CurrencyExtract:SetWidth(210)
	MixinAndLoadScripts(self.CurrencyExtract, ECCurrencyFrameMixin)
	self.CurrencyExtract:SetItem(ItemData.MYSTIC_EXTRACT)

	self.CurrencyMarks = CreateFrame("BUTTON", "$parent.CurrencyMarks", self, nil)
	self.CurrencyMarks:SetPoint("LEFT", self.CurrencyExtract, "RIGHT", 2, 0)
	self.CurrencyMarks:SetWidth(210)
	MixinAndLoadScripts(self.CurrencyMarks, ECCurrencyFrameMixin)
	self.CurrencyMarks:SetItem(ItemData.MARK_OF_ASCENSION)

	--[[self.CurrencyExtract:SetScript("OnEnter", function()
		HelpTip:Show("EC_HELP_LEVEL")
	end)

	self.CurrencyExtract:SetScript("OnLeave", function()
		HelpTip:Hide("EC_HELP_LEVEL")
	end)

	self.CurrencyOrb = CreateFrame("BUTTON", "$parent.CurrencyOrb", self, nil)
	self.CurrencyOrb:SetPoint("LEFT", self.CurrencyExtract, "RIGHT", 4, 0)
	self.CurrencyOrb:SetWidth(196)
	MixinAndLoadScripts(self.CurrencyOrb, ECCurrencyFrameMixin)
	self.CurrencyOrb:SetItem(ItemData.MYSTIC_ORB)]]--

	--self.InputBlock = CreateFrame("FRAME", "$parent.InputBlock", self, "InputBlockTemplate")
	self.InputBlock = CreateFrame("FRAME", "$parent.InputBlock", self, nil)
	self.InputBlock:EnableMouse(true)
	self.InputBlock:SetPoint("TOPLEFT")
	self.InputBlock:SetPoint("BOTTOMRIGHT")
	self.InputBlock:Hide()

	self.InputBlock:SetFrameLevel(self:GetFrameLevel()+30)

	self.InputBlock.texture = self.InputBlock:CreateTexture(nil, "OVERLAY")
	self.InputBlock.texture:SetTexture(0, 0, 0, 0.6)
	self.InputBlock.texture:SetAllPoints()

	self.InputBlock.Progress = CreateFrame("FRAME", "$parent.Progress", self.InputBlock, "BetterStatusBarTemplate")
	self.InputBlock.Progress:SetSize(332, 22)
	self.InputBlock.Progress:SetPoint("CENTER")
	self.InputBlock.Progress:SetStatusBarAtlas("ui-frame-bar-fill-white")
    self.InputBlock.Progress.BarTexture:SetVertexColor(0.42, 0.18, 1)
    self.InputBlock.Progress:Hide()

	self.InputBlock.Progress.BorderFrame = CreateFrame("FRAME", "$parent.BorderFrame", self.InputBlock.Progress, nil)
	self.InputBlock.Progress.BorderFrame:SetPoint("TOPLEFT", -5, 5)
	self.InputBlock.Progress.BorderFrame:SetPoint("BOTTOMRIGHT", 5, -5)
	self.InputBlock.Progress.BorderFrame:SetBackdrop(
		{
			edgeFile="Interface\\FriendsFrame\\UI-Toast-Border", 
			tile=true, 
			tileSize = 12, 
			edgeSize = 12,
		})
	
	self.InputBlock.Progress:SetMinMaxValues(0, 100)
	self.InputBlock.Progress:SetValue(50)

	-- TODO: Clean up
	self.InputBlock.Progress:SetScript("OnUpdate", function(self, elapsed)
		if ( self.casting ) then
			self.value = self.value + elapsed
			if ( self.value >= self.maxValue ) then
				self.fadeOut = true
				self:SetValue(self.maxValue)
				BaseFrameFadeOut(self)
				BaseFrameFadeOut(self:GetParent())
			end

			self:SetValue(self.value)
		elseif not(self.fadeOut) then
			self.fadeOut = true
			BaseFrameFadeOut(self)
			BaseFrameFadeOut(self:GetParent())
		end

		--[[
			if ( barSpark ) then
				local sparkPosition = (self.value / self.maxValue) * self:GetWidth();
				barSpark:SetPoint("CENTER", self, "LEFT", sparkPosition, 2);
			end
		]]--
	end)

	-- TODO: Add spark to self.InputBlock.Progress

	self.Level = CreateFrame("BUTTON", "$parent.Level", self.NineSlice)
	self.Level:SetFrameLevel(self.NineSlice:GetFrameLevel()+1)
	self.Level:SetSize(32, 32)
	self.Level:SetPoint("TOPLEFT", 32, -32)

	self.Level.Ring = self.Level:CreateTexture(nil, "BACKGROUND")
	self.Level.Ring:SetAtlas("services-ring-countcircle", Const.TextureKit.UseAtlasSize)
	self.Level.Ring:SetAllPoints()

	self.Level:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	self.Level.Text = self.Level:CreateFontString(nil, "OVERLAY")
	self.Level.Text:SetFontObject(GameFontNormal)
	self.Level.Text:SetPoint("CENTER", 0, 2)
	self.Level.Text:SetJustifyV("CENTER")
	self.Level.Text:SetJustifyH("CENTER")
	self.Level.Text:SetText(1)

	self.Level:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	self.Level:SetScript("OnEnter", function(button)
		self:LevelButtonOnEnter(button)
	end)

	self.EnchantUnlockPopup = CreateFrame("FRAME", "$self.EnchantUnlockPopup", self, nil)
	--self.EnchantUnlockPopup:SetPoint("TOP", 0, -128)
	self.EnchantUnlockPopup:SetPoint("CENTER", self.Collection, 0, 0)
	self.EnchantUnlockPopup:SetSize(256, 128)
	self.EnchantUnlockPopup:SetFrameLevel(self:GetFrameLevel() + 30)
	MixinAndLoadScripts(self.EnchantUnlockPopup, EnchantActivationPopupMixin)
	self.EnchantUnlockPopup:Hide()
end

EnchantCollection = CreateFrame("FRAME", "EnchantCollection", Collections, "PortraitFrameTemplate")
EnchantCollection:SetPoint("TOP", 0, 8)
EnchantCollection:Hide()
MixinAndLoadScripts(EnchantCollection, EnchantCollectionMixin)

_G["EnchantCollectionCloseButton"]:SetScript("OnClick", function()
    HideUIPanel(Collections)
end)

function EnchantCollection:ADDON_LOADED(addon)
	if addon ~= AddonName then return end
	if not Ascension_EnchantCollection_CDB then Ascension_EnchantCollection_CDB = {} end

	Addon.CDB = Ascension_EnchantCollection_CDB

	C_Hook:SendEvent("ENCHANTCOLLECTION_LOADED")
end

EnchantCollection:HookEvent("ADDON_LOADED")