-------------------------------------------------------------------------------
--                         Starting Choice Panel                            --
-------------------------------------------------------------------------------
WildCardStartingChoiceEntryMixin = {}

local STARTING_CHOICE_ENTRY_COUNT = 4
local STARTING_CHOICE_ENTRY_SPACING = 48

local function IsStartingChoiceRerollOK(result)
	return result == "OK" or result == "REROLL_UNLOCKED_STARTING_ABILITIES_OK"
end

local function GetStartingChoiceInternalID(entry)
	return entry and (entry.EntryID or entry.InternalID or entry.internalID or entry.ID)
end

local function GetStartingChoiceRank(entry)
	local rank = entry and (entry.Rank or entry.rank)
	rank = tonumber(rank)
	if not rank or rank == 0 then
		return 1
	end

	return rank
end

local StartingChoiceQualityNameToIndex = {
	Poor = 0,
	Common = 1,
	Normal = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
}

local function NormalizeStartingChoiceQuality(quality)
	if type(quality) == "number" then
		return quality
	end

	if type(quality) == "string" then
		return tonumber(quality) or StartingChoiceQualityNameToIndex[quality]
	end
end

local function GetStartingChoiceSpellID(entry, internalID, rank)
	if entry and (entry.SpellID or entry.spellID) then
		return entry.SpellID or entry.spellID
	end

	if internalID and CharacterAdvancementUtil then
		return CharacterAdvancementUtil.GetTalentRankSpellByID(internalID, rank) or CharacterAdvancementUtil.GetSpellByID(internalID)
	end
end

local function GetStartingChoiceQuality(entry, spellID, rank)
	if entry and (entry.Quality or entry.quality) then
		return NormalizeStartingChoiceQuality(entry.Quality or entry.quality)
	end

	if spellID and C_CharacterAdvancement and C_CharacterAdvancement.GetQualityInfo then
		return NormalizeStartingChoiceQuality(C_CharacterAdvancement.GetQualityInfo(spellID))
	end

	if rank and rank > 1 then
		return rank
	end
end

local function IsStartingChoiceLocked(entry, internalID)
	if entry and entry.IsLocked ~= nil then
		return entry.IsLocked
	end

	if internalID and C_CharacterAdvancement and C_CharacterAdvancement.IsLockedID then
		return C_CharacterAdvancement.IsLockedID(internalID)
	end

	return false
end

function WildCardStartingChoiceEntryMixin:SetOwnerPanel(panel)
	self.ownerPanel = panel
end

function WildCardStartingChoiceEntryMixin:SetControlsEnabled(enabled)
	if enabled then
		self:Enable()
		self.LockButton:Enable()
	else
		self:Disable()
		self.LockButton:Disable()
	end
end

function WildCardStartingChoiceEntryMixin:SetQuality(quality)
	quality = quality or 1
	local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1]

	if quality >= 2 then
		self.IconOverlay:Hide()

		self.SlotAdd:Show()
		self.SlotAdd:SetVertexColor(color:GetRGB())
		self.SlotAdd2:Show()
		self.SlotAdd2:SetVertexColor(color:GetRGB())
	else
		self.IconOverlay:Show()
		self.SlotAdd:Hide()
		self.SlotAdd2:Hide()
	end

	self.QualityGlow:SetVertexColor(color:GetRGB())
end

function WildCardStartingChoiceEntryMixin:SetEntry(entry)
	self.entry = entry
	self.internalID = GetStartingChoiceInternalID(entry)
	self.rank = GetStartingChoiceRank(entry)
	self.spellID = GetStartingChoiceSpellID(entry, self.internalID, self.rank)
	self.quality = GetStartingChoiceQuality(entry, self.spellID, self.rank)
	self.locked = IsStartingChoiceLocked(entry, self.internalID)

	if self.spellID then
		local name, _, icon = GetSpellInfo(self.spellID)
		self.Icon:SetTexture(icon)
		self.Name:SetText(name or UNKNOWN)
	else
		self.Icon:SetTexture(nil)
		self.Name:SetText(UNKNOWN)
	end

	self:SetQuality(self.quality)
	self.QualityGlow.AG:Stop()
	self.QualityGlow:SetAlpha(0)
	if not self.locked then
		self.QualityGlow.AG:Play()
	end

	if self.rank and self.rank > 1 then
		self.Rank:SetText(self.rank)
		self.Rank:Show()
	else
		self.Rank:Hide()
	end

	self.LockButton:SetChecked(self.locked)
	if self.locked then
		self.LockButton:SetLocked()
	else
		self.LockButton:SetUnlocked()
	end

	self:SetShown(entry ~= nil)
end

function WildCardStartingChoiceEntryMixin:OnEnter()
	if not self.spellID then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self.spellID))
	GameTooltip:Show()
end

function WildCardStartingChoiceEntryMixin:OnLeave()
	GameTooltip:Hide()
end

function WildCardStartingChoiceEntryMixin:OnLocked()
	if self.ownerPanel then
		self.ownerPanel:LockEntry(self)
	end
end

function WildCardStartingChoiceEntryMixin:OnUnlocked()
	if self.ownerPanel then
		self.ownerPanel:UnlockEntry(self)
	end
end

WildCardStartingChoiceMixin = {}
WildCardStartingChoiceMixin.OnEvent = OnEventToMethod

function WildCardStartingChoiceMixin:OnLoad()
	self.entries = {}
	self:SetFrameLevel(self:GetParent():GetFrameLevel() + 8)
	self:SetSize(320, 128)
	self:SetPoint("CENTER", self:GetParent(), "CENTER", 0, 0)
	self:EnableMouse(true)
	self:SetAlpha(0)
	self:Layout()
	self:SetScript("OnEvent", self.OnEvent)
end

function WildCardStartingChoiceMixin:Layout()
	for index = 1, STARTING_CHOICE_ENTRY_COUNT do
		local button = CreateFrame("Button", "$parentEntry"..index, self)
		button:SetSize(48, 48)
		button:SetPoint("CENTER", ((index - 2.5) * STARTING_CHOICE_ENTRY_SPACING), 0)
		Mixin(button, WildCardStartingChoiceEntryMixin)
		button:SetOwnerPanel(self)
		button:SetScript("OnEnter", button.OnEnter)
		button:SetScript("OnLeave", button.OnLeave)

		button.Slot = button:CreateTexture(nil, "BACKGROUND")
		button.Slot:SetPoint("CENTER")
		button.Slot:SetTexture("Interface\\Buttons\\UI-EmptySlot")
		button.Slot:SetSize(64, 64)

		button.Icon = button:CreateTexture(nil, "ARTWORK")
		button.Icon:SetSize(36, 36)
		button.Icon:SetPoint("CENTER")

		button.IconOverlay = button:CreateTexture(nil, "ARTWORK")
		button.IconOverlay:SetPoint("CENTER")
		button.IconOverlay:SetSize(60, 60)
		button.IconOverlay:SetTexture("Interface\\Buttons\\UI-Quickslot2")

		button.Highlight = button:CreateTexture(nil, "OVERLAY")
		button.Highlight:SetPoint("CENTER")
		button.Highlight:SetSize(42, 42)
		button.Highlight:SetTexture("Interface\\Buttons\\ButtonHilight-SquareQuickslot")
		button.Highlight:Hide()
		button:SetHighlightTexture(button.Highlight)

		button.QualityGlow = button:CreateTexture(nil, "OVERLAY")
		button.QualityGlow:SetAtlas("spell-activation-icon-glow-white", Const.TextureKit.IgnoreAtlasSize)
		button.QualityGlow:SetSize(56, 56)
		button.QualityGlow:SetPoint("CENTER", 0, 0)
		button.QualityGlow:SetBlendMode("ADD")
		button.QualityGlow:SetAlpha(0)

		button.QualityGlow.AG = button.QualityGlow:CreateAnimationGroup()
		button.QualityGlow.AG.FadeIn = button.QualityGlow.AG:CreateAnimation("ALPHA")
		button.QualityGlow.AG.FadeIn:SetChange(1)
		button.QualityGlow.AG.FadeIn:SetDuration(0.1)
		button.QualityGlow.AG.FadeIn:SetOrder(1)
		button.QualityGlow.AG.FadeOut = button.QualityGlow.AG:CreateAnimation("ALPHA")
		button.QualityGlow.AG.FadeOut:SetChange(-1)
		button.QualityGlow.AG.FadeOut:SetDuration(1)
		button.QualityGlow.AG.FadeOut:SetOrder(2)

		button.Pushed = button:CreateTexture(nil, "OVERLAY")
		button.Pushed:SetPoint("CENTER")
		button.Pushed:SetSize(36, 36)
		button.Pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		button:SetPushedTexture(button.Pushed)

		button.SlotAdd = button:CreateTexture(nil, "ARTWORK")
		button.SlotAdd:SetSize(37, 37)
		button.SlotAdd:SetPoint("CENTER", button, 0, 0)
		button.SlotAdd:SetTexture("Interface\\Addons\\AwAddons\\Textures\\SpellKit\\ArtifactPower-QuestBorder")
		button.SlotAdd:Hide()

		button.SlotAdd2 = button:CreateTexture(nil, "OVERLAY")
		button.SlotAdd2:SetSize(37, 37)
		button.SlotAdd2:SetPoint("CENTER", button, 0, 0)
		button.SlotAdd2:SetTexture("Interface\\Addons\\AwAddons\\Textures\\SpellKit\\ArtifactPower-QuestBorder")
		button.SlotAdd2:SetBlendMode("ADD")
		button.SlotAdd2:Hide()

		button.Rank = button:CreateFontString(nil, "OVERLAY")
		button.Rank:SetFontObject(NumberFontNormalSmallGray)
		button.Rank:SetPoint("BOTTOMRIGHT", button.Icon, "BOTTOMRIGHT", 4, -1)

		button.Name = button:CreateFontString(nil, "OVERLAY")
		button.Name:SetFontObject(GameFontNormalSmall)
		button.Name:SetWidth(96)
		button.Name:SetHeight(28)
		button.Name:SetJustifyH("CENTER")
		button.Name:SetPoint("TOP", button.Icon, "BOTTOM", 0, -8)
		button.Name:Hide()

		button.LockButton = CreateFrame("CheckButton", "$parentLockButton", button, "SmallLockButtonTemplate")
		button.LockButton:SetPoint("BOTTOM", button, "TOP", 0, 4)
		button.LockButton:RegisterCallback("OnLocked", button.OnLocked, button)
		button.LockButton:RegisterCallback("OnUnlocked", button.OnUnlocked, button)

		self.entries[index] = button
	end

	self.ActionsBG = self:CreateTexture(nil, "BACKGROUND")
	self.ActionsBG:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.ActionsBG:SetSize(300, 64)
	self.ActionsBG:SetPoint("CENTER", 0, -54)

	self.RollButton = CreateFrame("Button", "$parentRollButton", self, "StaticPopupButtonTemplate")
	self.RollButton:SetSize(131, 22)
	self.RollButton:SetPoint("RIGHT", self, "CENTER", -4, -54)
	self.RollButton:SetText(WILDCARD_ROLL_ABILITIES or "WILDCARD_ROLL_ABILITIES")
	self.RollButton:SetMotionScriptsWhileDisabled(true)
	self.RollButton:SetScript("OnClick", GenerateClosure(self.Roll, self))

	self.KeepButton = CreateFrame("Button", "$parentKeepButton", self, "StaticPopupButtonTemplate")
	self.KeepButton:SetSize(131, 22)
	self.KeepButton:SetPoint("LEFT", self, "CENTER", 4, -54)
	self.KeepButton:SetText(WILDCARD_KEEP_ABILITIES or "WILDCARD_KEEP_ABILITIES")
	self.KeepButton:SetScript("OnClick", GenerateClosure(self.Keep, self))
end

function WildCardStartingChoiceMixin:OnShow()
	self:RegisterEvent("WILDCARD_ENTRY_LEARNED")
	self:RegisterEvent("WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT")
	self:RegisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
	self:RegisterEvent("CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT")
	self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
	self:Refresh()
end

function WildCardStartingChoiceMixin:OnHide()
	self:UnregisterEvent("WILDCARD_ENTRY_LEARNED")
	self:UnregisterEvent("WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT")
	self:UnregisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
	self:UnregisterEvent("CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT")
	self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
	self.rerolling = false
	self.revealing = false
	self.pendingRefresh = nil
	self:SetControlsEnabled(true)
	self:SetActionsShown(true)
	GameTooltip:Hide()
end

function WildCardStartingChoiceMixin:CanShow()
	return C_Wildcard and C_Wildcard.CanShowStartingChoice and C_Wildcard.CanShowStartingChoice()
end

function WildCardStartingChoiceMixin:HasEntries()
	local entries = C_Wildcard.GetStartingChoiceEntries and C_Wildcard.GetStartingChoiceEntries()
	return entries and entries[1]
end

function WildCardStartingChoiceMixin:SetControlsEnabled(enabled)
	for _, entryButton in ipairs(self.entries) do
		entryButton:SetControlsEnabled(enabled)
	end

	if enabled then
		self.KeepButton:Enable()
		self.RollButton:Enable()
	else
		self.KeepButton:Disable()
		self.RollButton:Disable()
	end
end

function WildCardStartingChoiceMixin:SetActionsShown(shown)
	self.ActionsBG:SetShown(shown)
	self.RollButton:SetShown(shown)
	self.KeepButton:SetShown(shown)
end

function WildCardStartingChoiceMixin:UpdateRollButtonEnabledState()
	local hasUnlocked = false

	for _, entryButton in ipairs(self.entries) do
		local locked = entryButton.locked
		if entryButton.internalID and C_CharacterAdvancement and C_CharacterAdvancement.IsLockedID then
			locked = C_CharacterAdvancement.IsLockedID(entryButton.internalID)
			entryButton.locked = locked
		end

		if entryButton:IsShown() and not locked then
			hasUnlocked = true
			break
		end
	end

	if hasUnlocked then
		self.RollButton:Enable()
	else
		self.RollButton:Disable()
	end
end

function WildCardStartingChoiceMixin:Refresh()
	if not self:CanShow() then
		local parent = self:GetParent()
		if self.rerolling or (parent and (parent.startingChoiceRerolling or parent.startingChoiceRestorePending or parent.startingChoiceReveal)) then
			return false
		end

		self:Hide()
		return false
	end

	local entries = C_Wildcard.GetStartingChoiceEntries and C_Wildcard.GetStartingChoiceEntries()
	if not entries or not entries[1] then
		self:Hide()
		return false
	end

	for index = 1, STARTING_CHOICE_ENTRY_COUNT do
		local entryButton = self.entries[index]
		entryButton:SetEntry(entries[index])
		entryButton:SetAlpha(self.revealing and 0 or 1)
	end

	self:UpdateRollButtonEnabledState()
	return true
end

function WildCardStartingChoiceMixin:PrepareReveal(reason)
	if not self:CanShow() then
		return false
	end

	local parent = self:GetParent()
	local startingChoiceKept
	if parent.IsStartingChoiceKeptForActiveSpec then
		startingChoiceKept = parent:IsStartingChoiceKeptForActiveSpec()
	else
		startingChoiceKept = parent.startingChoiceKept
	end

	if startingChoiceKept and reason ~= "popup-cancel" then
		return false
	end

	if not self:HasEntries() then
		return false
	end

	if not self:Refresh() then
		return false
	end

	if parent.ClearStartingChoiceKept then
		parent:ClearStartingChoiceKept()
	else
		parent.startingChoiceKept = false
	end
	self.revealing = true
	self:SetControlsEnabled(false)
	self:SetActionsShown(false)
	self:Show()
	self:SetAlpha(1)
	return true
end

function WildCardStartingChoiceMixin:FinishReveal()
	self.revealing = false
	self:Refresh()

	for _, entryButton in ipairs(self.entries) do
		if entryButton:IsShown() then
			entryButton.time = 0.2
			BaseFrameFadeIn(entryButton)
		end
	end

	self:SetActionsShown(true)
	self:SetControlsEnabled(not self.rerolling)
	self:UpdateRollButtonEnabledState()
	BaseFrameFadeIn(self)
end

function WildCardStartingChoiceMixin:ShowChoice(reason)
	if not self:PrepareReveal(reason) then
		return false
	end

	self.revealing = false
	for _, entryButton in ipairs(self.entries) do
		entryButton:SetAlpha(1)
	end
	self:SetActionsShown(true)
	self:SetControlsEnabled(not self.rerolling)
	self:UpdateRollButtonEnabledState()
	return true
end

function WildCardStartingChoiceMixin:HideChoice()
	self:Hide()
end

function WildCardStartingChoiceMixin:Keep()
	-- A click captured before the actions were pulled down can still dispatch
	-- mid-reroll; keeping then clears the in-flight reroll state and leaves the
	-- incoming result with nowhere to land. Roll/LockEntry/UnlockEntry guard alike.
	if self.rerolling then
		return
	end

	local parent = self:GetParent()
	if parent and parent.KeepStartingChoice then
		parent:KeepStartingChoice()
	end
end

function WildCardStartingChoiceMixin:Roll()
	if self.rerolling then
		return
	end

	self.rerolling = true
	local parent = self:GetParent()
	if parent.ClearStartingChoiceKept then
		parent:ClearStartingChoiceKept()
	else
		parent.startingChoiceKept = false
	end
	self:SetControlsEnabled(false)
	self:SetActionsShown(false)

	for _, entryButton in ipairs(self.entries) do
		BaseFrameFadeOut(entryButton)
	end

	if parent.StartStartingChoiceReroll then
		parent:StartStartingChoiceReroll()
	end

	if not C_Wildcard.RerollUnlockedStartingAbilities() then
		self.rerolling = false
		if parent.CancelStartingChoiceReroll then
			parent:CancelStartingChoiceReroll()
		end
		self:SetControlsEnabled(true)
		self:SetActionsShown(true)
	end
end

function WildCardStartingChoiceMixin:LockEntry(entryButton)
	if self.rerolling or not entryButton.internalID then
		return
	end

	C_CharacterAdvancement.LockID(entryButton.internalID)
end

function WildCardStartingChoiceMixin:UnlockEntry(entryButton)
	if self.rerolling or not entryButton.internalID then
		return
	end

	local spellLink = entryButton.spellID and LinkUtil:GetSpellLink(entryButton.spellID) or UNKNOWN
	StaticPopup_Show("UNLOCK_SPELL_CONFIRM", spellLink, nil, entryButton.internalID)
	self:Refresh()
end

function WildCardStartingChoiceMixin:HandleEntryLearned()
	if self.rerolling then
		self.pendingRefresh = true
		return true
	end

	if self:IsShown() then
		self:Refresh()
		return true
	end

	return false
end

function WildCardStartingChoiceMixin:WILDCARD_ENTRY_LEARNED()
	self:HandleEntryLearned()
end

function WildCardStartingChoiceMixin:WILDCARD_REROLL_UNLOCKED_STARTING_ABILITIES_RESULT(result)
	self.rerolling = false
	self.pendingRefresh = nil

	if self:GetParent().FinishStartingChoiceReroll then
		self:GetParent():FinishStartingChoiceReroll(result)
	else
		self:SetControlsEnabled(true)
		self:SetActionsShown(true)
		self:Refresh()
	end

	if result and not IsStartingChoiceRerollOK(result) then
		local errorMsg = _G[result] or result
		UIErrorsFrame:AddMessage(errorMsg, 1, 0, 0)
		SendSystemMessage("|cffFF0000"..errorMsg.."|r")
	end
end

function WildCardStartingChoiceMixin:CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT()
	self:Refresh()
end

function WildCardStartingChoiceMixin:CHARACTER_ADVANCEMENT_UNLOCK_ENTRY_RESULT()
	self:Refresh()
end

function WildCardStartingChoiceMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
	self:UpdateRollButtonEnabledState()
end
