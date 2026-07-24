StaticPopup_DisplayedFrames = { };

STATICPOPUP_NUMDIALOGS = 4;
STATICPOPUP_TEXTURE_ALERT = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew";
STATICPOPUP_TEXTURE_ALERTGEAR = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertOther";
StaticPopupDialogs = { };

CONFIRM_LEAVING_PENDING = CONFIRM_LEAVING_PENDING or "You have pending changes. If you click accept, pending changes will be erased."
CONFIRM_SWAP_S = CONFIRM_SWAP_S or "You're swapping %s. Please choose second Ability or Talent\nClick Undo button if you want to stop the process."

function StaticPopup_GetNumVisible(includeFrame)
	local count = 0
	for _, frame in pairs(StaticPopup_DisplayedFrames) do
		if frame:IsShown() then
			count = count + 1
		end
	end

	if includeFrame and not includeFrame:IsShown() then
		count = count + 1
	end

	return count
end

local function StaticPopup_TriggerVisibilityEvent(event, activeCount, frame)
	if EventRegistry then
		EventRegistry:TriggerEvent(event, activeCount, frame)
	end
end

local function IsConquestOfAzerothPlayer()
	local _, _, classID = UnitClass("player")
	return classID and classID >= 12 and classID <= 32
end

local function SendConquestOfAzerothImportMessage(message, isError)
	if ( isError ) then
		message = RED_FONT_COLOR and RED_FONT_COLOR:WrapText(message) or ("|cffff2020"..message.."|r")
	end

	SendSystemMessage(message)
end

local function GetConquestOfAzerothImportErrorText(traversalError, entryID, entryRank)
	local errorText = "Unable to import CoA build."
	if ( traversalError ) then
		local localizedError = _G[traversalError] or traversalError
		local entryName = entryID

		if ( C_CharacterAdvancement.GetEntryByInternalID and entryID ) then
			local entry = C_CharacterAdvancement.GetEntryByInternalID(entryID)
			entryName = entry and entry.Name or entryID
		end

		local success, formattedError = pcall(string.format, localizedError, entryName or "", entryRank or "")
		errorText = errorText.." "..(success and formattedError or localizedError)
	end

	return errorText
end

--
-- Custom Popups
--
StaticPopupDialogs["CHARACTER_ADVANCEMENT_IMPORT_PENDING_BUILD"] = {
	text = CHARACTER_ADVANCEMENT_IMPORT_PENDING_BUILD,
	button1 = IMPORT_BUILD,
	button2 = CANCEL,
	hasEditBox = true,
	hasWideEditBox = 1,
	maxLetters = 2048,
	timeout = 0,
	hideOnEscape = true,
	OnButton1 = function(self)
		local buildString = CharacterAdvancementUtil.GetBuildFromURL(self.wideEditBox:GetText())
		if ( not IsConquestOfAzerothPlayer() ) then
			C_CharacterAdvancement.ImportPendingBuild(buildString)
			return
		end

		local success, traversalError, entryID, entryRank = C_CharacterAdvancement.ImportPendingBuild(buildString)
		if ( success ) then
			SendConquestOfAzerothImportMessage("CoA build imported. Review pending changes before saving.")
			return
		end

		SendConquestOfAzerothImportMessage(GetConquestOfAzerothImportErrorText(traversalError, entryID, entryRank), true)
		return true
	end,
	EditBoxOnEnterPressed = function(self)
		if ( self:GetParent().button1:IsEnabled() == 1 ) then
			self:GetParent().button1:Click()
		end
	end,
	OnUpdate = function(self)
		local text = self.wideEditBox:GetText():trim()
		self.button1:SetEnabled(text:len() > 0)
	end
}

StaticPopupDialogs["CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES"] = {
	text = CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES,
	button1 = APPLY,
	button2 = DISCARD,
	button3 = GO_BACK,
	OnButton1 = function(self)
		CharacterAdvancementUtil.ConfirmApplyPendingBuild()
	end,
	OnButton2 = function(self)
		CharacterAdvancementUtil.MarkForSwap(nil)
		BuildCreatorUtil.ClearPendingBuildID()
		C_CharacterAdvancement.CancelPendingBuild()
	end,
	OnButton3 = function(self)
		Collections:GoToTab(Collections.Tabs.CharacterAdvancement)
	end,
	OnShow = function(self)
		self.button1:SetEnabled(C_CharacterAdvancement.CanApplyPendingBuild())
	end
}

StaticPopupDialogs["GM_TICKET_SUGGESTED_RESPONSE_DENY"] = {
	text = GM_TICKET_SUGGESTED_RESPONSE_DENY,
	button1 = DECLINE,
	button2 = CANCEL,
	hasEditBox = true,
	OnAccept = function(self, ticketID)
		C_GMTicket.DeclineAutomatedMessage(ticketID, self.editBox:GetText())
	end,
	EditBoxOnEnterPressed = function(self)
		if ( self:GetParent().button1:IsEnabled() == 1 ) then
			self:GetParent().button1:Click()
		end
	end,
}
StaticPopupDialogs["GM_TICKET_SUGGESTED_RESPONSE_CONFIRM"] = {
	text = GM_TICKET_SUGGESTED_RESPONSE_CONFIRM,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, ticketID)
		C_GMTicket.ApproveAutomatedMessage(ticketID)
	end,
}
StaticPopupDialogs["PLAYER_TICKET_REOPEN_WITH_MESSAGE_CONFIRM"] = {
	text = PLAYER_TICKET_REOPEN_WITH_MESSAGE_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, sendFunc)
		sendFunc()
	end,
}
StaticPopupDialogs["GM_TICKET_ASSIGN_CONFIRM"] = {
	text = GM_TICKET_ASSIGN_CONFIRM, 
	button1 = ASSIGN,
	button2 = CANCEL,
	hasEditBox = true,
	OnAccept = function(self, ticketID)
		local name = self.editBox:GetText():trim()
		if name and name ~= "" then
			C_GMTicket.AssignGMTicket(ticketID, name)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		if ( self:GetParent().button1:IsEnabled() == 1 ) then
			self:GetParent().button1:Click()
		end
	end,
	EditBoxOnTextChanged = function (self)
		local parent = self:GetParent();
		local len = strlen(parent.editBox:GetText())
		if (len >= 2 and len <= 16) then
			parent.button1:Enable();
		else
			parent.button1:Disable();
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end
}
StaticPopupDialogs["PLAYER_TICKET_REOPEN_CONFIRM"] = {
	text = PLAYER_TICKET_REOPEN_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, button)
		button:Disable()
		C_PlayerTicket.ReopenTicket()
	end,
}
StaticPopupDialogs["PLAYER_TICKET_CLOSE_CONFIRM"] = {
	text = PLAYER_TICKET_CLOSE_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, button)
		button:Disable()
		C_PlayerTicket.CloseTicket()
	end,
}
StaticPopupDialogs["OPEN_URL_CONFIRM"] = {
	text = OPEN_URL_CONFIRM,
	button1 = COPY_TO_CLIPBOARD,
	button2 = CLOSE,
	OnAccept = function(self, url)
		UIErrorsFrame:AddMessage(S_COPIED_TO_CLIPBOARD:format(url), 1.0, 1.0, 0.0, 1.0)
		SendSystemMessage(S_COPIED_TO_CLIPBOARD:format(url))
		Internal_CopyToClipboard(url)
	end
}

StaticPopupDialogs["CONFIRM_REPURCHASE_USE_GOLD"] = {
	text = CONFIRM_REPURCHASE_USE_GOLD,
	button1 = OKAY,
	button2 = CANCEL,
	whileDead = true,
	timeout = 0,
	hideOnEscape = true,
	OnAccept = function(self, button)
		button:GetParent():Refresh(true)
	end,
	OnCancel = function(self, button)
		button:SetChecked(false)
		button:GetParent():Refresh()
	end,
}
StaticPopupDialogs["CONFIRM_PURCHASE_NO_REFUNDS"] = {
	text = CONFIRM_PURCHASE_NO_REFUNDS,
	button1 = OKAY,
	button2 = CANCEL,
	whileDead = true,
	timeout = 0,
	hideOnEscape = true,
	OnAccept = function(self, callback)
		callback()
	end,
}

StaticPopupDialogs["CONFIRM_WILDCARD_MASS_ROLL"] = {
	text = CONFIRM_WILDCARD_MASS_ROLL,
	button1 = START,
	button2 = CANCEL,
	button3 = START_DONT_ASK_AGAIN,
	OnAccept = function(self, func)
		func()
	end,
	OnButton3 = function(self, func)
		func(true)
	end,
	timeout = 0,
	hideOnEscape = true,
	whileDead = true,
}
StaticPopupDialogs["CONFIRM_APPLY_COSMETIC_PET"] = {
	text = CONFIRM_APPLY_COSMETIC_PET,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		C_Appearance.ApplyPendingAppearances(true)
	end,
	timeout = 0,
	hideOnEscape = true,
	whileDead = true,
}

StaticPopupDialogs["OPEN_ASCENSION_URL"] = {
	text = CONFIRM_OPEN_ASCENSION_URL,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, url)
		OpenAscensionURL(url)
	end,
	hideOnEscape = true,
}

StaticPopupDialogs["CONFIRM_COLLECT_APPEARANCE"] = {
	text = TRANSMOGRIFY_CONFIRM_COLLECT_APPEARANCE,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, guid)
		C_AppearanceCollection.CollectItemAppearance(guid)
	end,
	timeout = 0,
	hideOnEscape = true,
	whileDead = true,
}

StaticPopupDialogs["CONFIRM_CUSTOM_STORE_PURCHASE"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		C_CustomStore.PurchaseCustomStoreItem(data.itemIndex, data.quantity)
	end,
	OnShow = function(self, data)
		local itemLink = data.itemLink
		if data.quantity > 1 then
			itemLink = itemLink .. " x" .. data.quantity
		end
		local text = CONFIRM_HIGH_COST_ITEM:format(itemLink)
		text = text .. "|n" .. data.costString
		self.text:SetText(text)
	end,
	showAlert = true,
	timeout = 0,
	hideOnEscape = true,
	exclusive = true,
	whileDead = true,
}

StaticPopupDialogs["CONFIRM_PURCHASE_SKILL_CARD_BOOSTER"] = {
	text = BOOSTER_CONFIRM,
	button1 = OKAY,
	button2 = CANCEL,
	whileDead = true,
	timeout = 0,
	hideOnEscape = true,
	OnAccept = function(self, callback)
		callback()
	end,
}

StaticPopupDialogs["CONFIRM_OVERWRITE_APPEARANCE_OUTFIT"] = {
	text = CONFIRM_OVERWRITE_APPEARANCE_OUTFIT,
	button1 = OVERWRITE,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, outfitName)
		PlaySound(SOUNDKIT.UI_TRANSMOGRIFY_APPLY)
		C_AppearanceOutfit.SaveOutfit(outfitName)
	end,
}
StaticPopupDialogs["CONFIRM_DELETE_APPEARANCE_OUTFIT"] = {
	text = CONFIRM_DELETE_APPEARANCE_OUTFIT,
	button1 = DELETE,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, outfitName)
		PlaySound(SOUNDKIT.UI_VOIDSTORAGE_DEPOSIT)
		C_AppearanceOutfit.DeleteOutfit(outfitName)
	end,
}
StaticPopupDialogs["CONFIRM_SAVE_APPEARANCE_OUTFIT"] = {
	text = CONFIRM_SAVE_APPEARANCE_OUTFIT,
	button1 = SAVE,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox = true,
	OnAccept = function(self)
		local name = self.editBox:GetText():trim()
		if name and name ~= "" then
			PlaySound(SOUNDKIT.UI_TRANSMOGRIFY_APPLY)
			C_AppearanceOutfit.SaveOutfit(name)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		if ( self:GetParent().button1:IsEnabled() == 1 ) then
			self:GetParent().button1:Click()
		end
	end,
	EditBoxOnTextChanged = function (self)
		local parent = self:GetParent();
		if ( strlen(parent.editBox:GetText()) <= 64 and parent.editBox:GetText() ~= NEW_OUTFIT) then
			parent.button1:Enable();
		else
			parent.button1:Disable();
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end
}

StaticPopupDialogs["MANASTORM_FAILED"] = {
	text = MANASTORM_FAILED,
	button1 = OKAY,
	button2 = DEATH_RECAP,
	OnButton2 = function(self, recapID)
		AscensionUI.DeathRecap:OpenRecap(nil, recapID)
		return true
	end,
	whileDead = 1,
}
StaticPopupDialogs["NAMEPLATE_ADDON_CONFLICT"] = {
	text = NAMEPLATE_ADDON_CONFLICT,
	button1 = DISABLE_ADDON,
	button2 = DISABLE_ASCENSION_NAMEPLATES,
	OnAccept = function(self, data)
		DisableAddOn(data)
		ReloadUI()
	end,
	OnCancel = function()
		C_CVar.Set("useNewNameplates", false)
		ReloadUI()
	end,
	timeout = 0,
	showAlert = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["CONFIRM_RESET_TO_DEFAULT_KEYBINDINGS"] = {
	text = CONFIRM_RESET_TO_DEFAULT_KEYBINDINGS,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		LoadBindings(0)
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["CONFIRM_DELETE_STABLED_PET"] = {
	text = CONFIRM_DELETE_STABLED_PET,
	button1 = YES,
	button2 = NO,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1,
	hasEditBox = 1,
	OnAccept = function(self, slotID)
		local petID = GetStablePetID(slotID)
		if petID then
			DeleteStablePet(petID)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		if ( self:GetParent().button1:IsEnabled() == 1 ) then
			self:GetParent().button1:Click()
		end
	end,
	EditBoxOnTextChanged = function (self)
		local parent = self:GetParent();
		if ( strupper(parent.editBox:GetText()) == strupper(PET_ABANDON) ) then
			parent.button1:Enable();
		else
			parent.button1:Disable();
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end
}
StaticPopupDialogs["LEAVE_THE_MANASTORM_CHECKPOINT_CONFIRM"] = {
	text = LEAVE_THE_MANASTORM_CHECKPOINT_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function()
		C_Manastorm.Leave()
	end,
}

StaticPopupDialogs["LEAVE_THE_MANASTORM_CONFIRM"] = {
	text = LEAVE_THE_MANASTORM_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function()
		C_Manastorm.Leave()
	end,
}

StaticPopupDialogs["CONFIRM_ACTIVATE_BUILD"] = {
	text = CONFIRM_ACTIVATE_BUILD,
	button1 = YES,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function(self, args)
		if C_BuildCreator.ActivateBuild(unpack(args)) then
			if BuildCreatorFrame then
				BuildCreatorFrame:ShowLoading()
			end
		end
	end,
}

StaticPopupDialogs["CONFIRM_ACTIVATE_BUILD_DEACTIVATE_BUILD_DRAFT"] = {
	text = CONFIRM_ACTIVATE_BUILD_DEACTIVATE_BUILD_DRAFT,
	button1 = YES,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function(self, args)
		if C_BuildCreator.ActivateBuild(unpack(args)) then
			if BuildCreatorFrame then
				BuildCreatorFrame:ShowLoading()
			end
		end
	end,
}

StaticPopupDialogs["CONFIRM_ACTIVATE_BUILD_DRAFT_NO_REWARDS"] = {
	text = CONFIRM_ACTIVATE_BUILD_DEACTIVATE_BUILD_DRAFT,
	button1 = YES,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function(self, args)
		if C_BuildCreator.ActivateBuild(unpack(args)) then
			if BuildCreatorFrame then
				BuildCreatorFrame:ShowLoading()
			end
		end
	end,
}

StaticPopupDialogs["CONFIRM_DEACTIVATE_BUILD"] = {
	text = CONFIRM_DEACTIVATE_BUILD,
	button1 = DEACTIVATE,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function(self, buildID)
		if C_BuildCreator.DeactivateBuild(buildID) then
			if BuildCreatorFrame then
				BuildCreatorFrame:ShowLoading()
			end
		end
	end,
}

StaticPopupDialogs["CONFIRM_DEACTIVATE_BUILD_DRAFT"] = {
	text = CONFIRM_DEACTIVATE_BUILD_DRAFT,
	button1 = DEACTIVATE,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function(self, buildID)
		if C_BuildCreator.DeactivateBuild(buildID) then
			if BuildCreatorFrame then
				BuildCreatorFrame:ShowLoading()
			end
		end
	end,
}

StaticPopupDialogs["CONFIRM_RESET_BUILD_NO_COST"] = {
	text = CONFIRM_RESET_BUILD_NO_COST,
	button1 = UNLEARN,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function()
		C_CharacterAdvancement.ApplyPendingBuild()
	end,
	OnCancel = function()
		BuildCreatorUtil.ClearPendingBuildID()
		C_CharacterAdvancement.CancelPendingBuild()
	end
}

StaticPopupDialogs["CONFIRM_RESET_BUILD"] = {
	text = CONFIRM_RESET_BUILD,
	button1 = UNLEARN,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function()
		C_CharacterAdvancement.ApplyPendingBuild()
	end,
	OnCancel = function()
		BuildCreatorUtil.ClearPendingBuildID()
		C_CharacterAdvancement.CancelPendingBuild()
	end
}

StaticPopupDialogs["CONFIRM_APPLY_PENDING_BUILD_NO_COST"] = {
	text = CONFIRM_APPLY_PENDING_BUILD_NO_COST,
	button1 = APPLY,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function()
		C_CharacterAdvancement.ApplyPendingBuild()
		if BuildCreatorUtil.GetPendingBuildID() then
			C_BuildCreator.ActivateBuild(BuildCreatorUtil.GetPendingBuildID(), true, true)
			BuildCreatorUtil.ClearPendingBuildID()
		end
	end,
}

StaticPopupDialogs["CONFIRM_APPLY_PENDING_BUILD"] = {
	text = CONFIRM_APPLY_PENDING_BUILD,
	button1 = APPLY,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function()
		C_CharacterAdvancement.ApplyPendingBuild()
		if BuildCreatorUtil.GetPendingBuildID() then
			C_BuildCreator.ActivateBuild(BuildCreatorUtil.GetPendingBuildID(), true, true)
			BuildCreatorUtil.ClearPendingBuildID()
		end
	end,
}

StaticPopupDialogs["CONFIRM_UNLEARN_ALL_S"] = {
	text = CONFIRM_UNLEARN_ALL_S,
	button1 = UNLEARN,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function(self, unlearnFunc)
		unlearnFunc()
	end,
}

StaticPopupDialogs["CONFIRM_LEARN_S"] = {
	text = CONFIRM_LEARN_S,
	button1 = LEARN,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function(self, internalID)
		C_CharacterAdvancement.LearnID(internalID)
	end,
}

StaticPopupDialogs["CONFIRM_LEAVING_PENDING"] = {
	text = CONFIRM_LEAVING_PENDING,
	button1 = ACCEPT,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function(self, data)
		CharacterAdvancementUtil.MarkForSwap(data[1], data[2])
	end,
}

StaticPopupDialogs["CONFIRM_SWAP_S"] = {
	text = CONFIRM_SWAP_S,
	button1 = ACCEPT,
	hideOnEscape = true,
	OnAccept = function(self, internalID)
		--CharacterAdvancementUtil.MarkForSwap(nil)
	end,
}

StaticPopupDialogs["CONFIRM_UNLEARN_S"] = {
	text = CONFIRM_UNLEARN_S,
	button1 = UNLEARN,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function(self, internalID)
		if not C_CharacterAdvancement.UnlearnID(internalID) and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
			aprint("|cffFF0000[WILDCARD] Unlearn request dropped by client (reveal pending). Try again in a moment.|r")
		end
	end,
}

StaticPopupDialogs["CONFIRM_WILDCARD_LEVELING"] = {
	text = WILCARD_LEVEL_10_CONFIRMATION,
	button1 = WILDCARD_REVEAL_NEW_SPELL_DIALOGUE,
	button2 = CANCEL,
	hideOnEscape = true,
	OnShow = function(self)
		if (SpecializationUtil.GetActiveSpecialization() == 1) and not(C_Player:IsPrestiged()) then 
			self.text:SetText(WILCARD_LEVEL_10_CONFIRMATION_SHORT)
		else
			self.text:SetText(WILCARD_LEVEL_10_CONFIRMATION)
		end
	end,
	OnAccept = function(self)
		if not C_Wildcard.RollAbilities() then
			aprint("|cffFF0000[WILDCARD] Roll request dropped by client (reveal pending). Try again in a moment.|r")
		end
	end,
	OnCancel = function(self)
		if WildCardDice and WildCardDice.ShowStartingChoicePanel and WildCardDice:ShowStartingChoicePanel("popup-cancel") then
			return
		end

		if WildCardDice and WildCardDice:IsVisible() then
			WildCardDice:OnFinishedAppear()
		end
	end,
}

StaticPopupDialogs["UNLOCK_SPELL_CONFIRM"] = {
	text = UNLOCK_SPELL_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, internalID)
		C_CharacterAdvancement.UnlockID(internalID)
	end,
}

StaticPopupDialogs["UNLOCK_SPEC_CONFIRM"] = {
	text = UNLOCK_SPELL_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, specID)
		SpecializationUtil.ToggleSpecializationPrestigeLock(specID)
	end,
}

StaticPopupDialogs["BUILD_CREATOR_DELETE_SAVED_BUILD"] = {
	text = BUILD_CREATOR_DELETE_SAVED_BUILD,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, callback)
		callback()
	end,
}


StaticPopupDialogs["BUILD_CREATOR_IMPORT_BUILD"] = {
	text = BUILD_CREATOR_IMPORT_BUILD,
	button1 = BUILDCREATOR_CREATEBUTTON_IMPORT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox = true,
	OnAccept = function(self)
		C_BuildEditor.DiscardPendingBuild()
		local buildString = CharacterAdvancementUtil.GetBuildFromURL(self.editBox:GetText())
		C_BuildEditor.ImportBuild(buildString)
		if BuildCreatorFrame then
			BuildCreatorFrame:CreateBuild(Enum.BuildCreateCategory.Import, true)
		end
	end,
}

StaticPopupDialogs["BUILD_CREATOR_EDIT_BUILD"] = {
	text = BUILD_CREATOR_EDIT_BUILD,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, build)
		if BuildCreatorFrame then
			BuildCreatorFrame:EditBuild(build)
		end
	end,
}

StaticPopupDialogs["BUILD_CREATOR_DELETE_BUILD"] = {
	text = DELETE_BUILD_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	button1 = YES,
	button2 = NO,
	whileDead = 1,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1,
	hasEditBox = 1,
	maxLetters = 32,
	OnAccept = function(self, buildID)
		BuildCreatorFrame:DeleteBuild(buildID)
	end,
	OnShow = function(self)
		self.button1:Disable();
		self.button2:Enable();
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		if ( self:GetParent().button1:IsEnabled() == 1 ) then
			self:GetParent().button1:Click()
		end
	end,
	EditBoxOnTextChanged = function (self)
		local parent = self:GetParent();
		if ( strupper(parent.editBox:GetText()) ==  DELETE_BUILD_CONFIRM_STRING ) then
			parent.button1:Enable();
		else
			parent.button1:Disable();
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end
}

StaticPopupDialogs["BUILD_CREATOR_PUBLISH_BUILD"] = {
	text = BUILD_CREATOR_PUBLISH_BUILD,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self)
		if BuildCreatorFrame then
			BuildCreatorFrame:PublishBuild()
		end
	end,
}

StaticPopupDialogs["BUILD_CREATOR_RESET_BUILD"] = {
	text = BUILD_CREATOR_RESET_BUILD,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self)
		C_BuildEditor.DiscardPendingBuild()
		BuildCreatorUtil.ResetPendingBuild()
	end,
}

StaticPopupDialogs["BUILD_CREATOR_CHANGE_BUILD_CATEGORY"] = {
	text = BUILD_CREATOR_CHANGE_BUILD_CATEGORY,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, callback)
		callback()
	end,
}

StaticPopupDialogs["BUILD_CREATOR_SET_COMMENT"] = {
	text = BUILD_CREATOR_SET_COMMENT,
	button1 = DONE,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox = true,
	maxLetters = 128,
	OnAccept = function(self, spellID)
		spellID = Enum.WeaponSIDSubClass[spellID] or Enum.ArmorSIDSubClass[spellID] or spellID
		C_BuildEditor.SetComment(spellID, self.editBox:GetText())
		BuildCreatorUtil.UpdatePendingBuild()
	end,
	EditBoxOnEnterPressed = function(self)
		self:GetParent().button1:Click()
	end,
}

StaticPopupDialogs["BUILD_CREATOR_SET_ENCHANT_LEVEL"] = {
	text = "Set enchant level for %s",
	button1 = DONE,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox = true,
	maxLetters = 2,
	OnAccept = function(self, spellID)
		local number = tonumber(self.editBox:GetText())
		if number and number > 0 and number < 80 then
			C_BuildEditor.SetEnchantLevel(spellID, number)
			BuildCreatorUtil.UpdatePendingBuild()
		end
	end,
	EditBoxOnEnterPressed = function(self)
		self:GetParent().button1:Click()
	end,
}

StaticPopupDialogs["BUILD_CREATOR_FINISH_PICKING_SPELLS"] = {
	text = BUILD_CREATOR_FINISH_PICKING_SPELLS,
	button1 = DONE,
	whileDead = true,
	hideOnEscape = false,
	OnAccept = function(self)
		Collections:GoToTab(Collections.Tabs.HeroArchitect)
		BuildCreatorUtil.SetPickMode(nil)
		BuildCreatorUtil.UpdatePendingBuild()
	end,
}

StaticPopupDialogs["BUILD_CREATOR_FINISH_PICKING_ENCHANTS"] = {
	text = BUILD_CREATOR_FINISH_PICKING_ENCHANTS,
	button1 = DONE,
	whileDead = true,
	hideOnEscape = false,
	OnAccept = function(self)
		Collections:GoToTab(Collections.Tabs.HeroArchitect)
		BuildCreatorUtil.SetPickMode(nil)
		BuildCreatorUtil.UpdatePendingBuild()
	end,
}

StaticPopupDialogs["DRAFT_MISSING_SKILLCARD_CONFIRM"] = {
	text = DRAFT_MISSING_SKILLCARD_CONFIRM,
	button1 = LEARN,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, func)
		func()
	end
}

StaticPopupDialogs["RECOVER_WORLDFORGED_ITEM_CONFIRM"] = {
    text = RECOVER_WORLDFORGED_ITEM_CONFIRM,
    button1 = ACCEPT,
    button2 = CANCEL,
    whileDead = true,
    hideOnEscape = true,
    OnAccept = function(self, func)
        func()
    end
}

StaticPopupDialogs["RECOVER_ITEM_CONFIRM"] = {
	text = RECOVER_ITEM_CONFIRM,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, func)
		func()
	end
}

StaticPopupDialogs["RECOVER_WILDCARD_ROLL_CONFIRM"] = {
	text = RECOVER_WILDCARD_ROLL_CONFIRM,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, func)
		func()
	end
}

StaticPopupDialogs["IRON_SOUL_CONFIRM"] = {
	text = IRON_SOUL_CONFIRM,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, func)
		func()
	end
}

StaticPopupDialogs["BC_SET_ENCHANT_LEVEL"] = {
	text = BC_SET_ENCHANT_LEVEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = 1,
	hideOnEscape = 1,
	hasEditBox = 1,
	maxLetters = 3,
	timeout = 0,
	OnAccept = function(self, callback)
		local text = self.editBox:GetText()
		local level = tonumber(text)
		if not level or not callback then return end
		callback(level)
	end,
	EditBoxOnEnterPressed = function(self, callback)
		local text = self:GetText()
		local level = tonumber(text)
		if not level or not callback then return end
		self:GetParent().button1:Click()
	end,
	EditBoxOnEscapePressed = function (self)
		self:GetParent().button2:Click()
	end,
	OnHide = function (self)
		self.editBox:SetText("");
	end,
}

StaticPopupDialogs["CHANGE_SPEC_BUILD_DRAFT"] = {
	text = CHANGE_SPEC_BUILD_DRAFT,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, func)
		func()
	end
}

StaticPopupDialogs["CHANGE_SPEC_STABLE_PET"] = {
	text = CHANGE_SPEC_STABLE_PET,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, func)
		func()
	end
}

StaticPopupDialogs["BUILD_DRAFT_DEACTIVATE_CONFIRM"] = {
	text = BUILD_DRAFT_DEACTIVATE_CONFIRM,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, deactivateFunc)
		deactivateFunc()
	end
}

StaticPopupDialogs["BUILD_DRAFT_ACTIVATE_CONFIRM_NO_REWARDS"] = {
	text = BUILD_DRAFT_ACTIVATE_CONFIRM_NO_REWARDS,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, args)
		if C_BuildCreator.ActivateBuild(unpack(args)) then
			if BuildCreatorFrame then
				BuildCreatorFrame:ShowLoading()
			end
		end
	end
}


StaticPopupDialogs["BUILD_DRAFT_ACTIVATE_CONFIRM"] = {
	text = BUILD_DRAFT_ACTIVATE_CONFIRM,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, args)
		if type(args) == "function" then
			args()
			return
		end
		if C_BuildCreator.ActivateBuild(unpack(args)) then
			if BuildCreatorFrame then
				BuildCreatorFrame:ShowLoading()
			end
		end
	end
}

StaticPopupDialogs["BUILD_CREATOR_ACTIVATE_ALTERNATE_BUILD"] = {
	text = BUILD_CREATOR_ACTIVATE_ALTERNATE_BUILD,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, activateFunc)
		activateFunc()
	end,
	OnUpdate = function(self)
		self.button1:SetEnabled(not C_Player:IsImmune() and not C_Player:InCombat())
	end
}

StaticPopupDialogs["DRAFT_CANCEL_HOF_CONFIRM"] = {
	text = DRAFT_CANCEL_HOF_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = false,
	OnAccept = function(self)
		CancelHandOfFateSelection()
		Draft:InvalidateAllCards()
	end,
}

StaticPopupDialogs["DRAFT_CANCEL_SWAP_CONFIRM"] = {
	text = DRAFT_CANCEL_SWAP_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = false,
	OnAccept = function(self)
		CancelHandOfFateSelection()
		Draft:InvalidateAllCards()
	end,
}

StaticPopupDialogs["DRAFT_UNLEARN_CONFIRM"] = {
	text = DRAFT_UNLEARN_CONFIRM,
	button1 = DRAFT_UNLEARN,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = false,
	OnAccept = function(self, selectFunc)
		selectFunc()
		Draft:InvalidateAllCards()
	end,
	OnUpdate = function(self)
		self.button1:SetEnabled(not C_Player:IsImmune())
	end
}

StaticPopupDialogs["DRAFT_CHOICE_CONFIRM"] = {
	text = DRAFT_CHOICE_CONFIRM,
	button1 = DRAFT_LEARN,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = false,
	OnAccept = function(self, selectFunc)
		selectFunc()
		Draft:InvalidateAllCards()
	end,
	OnUpdate = function(self)
		self.button1:SetEnabled(not C_Player:IsImmune())
	end
}

StaticPopupDialogs["DRAFT_SWAP_CONFIRM"] = {
	text = DRAFT_SWAP_CONFIRM,
	button1 = DRAFT_SWAP,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = false,
	OnAccept = function(self, selectFunc)
		selectFunc()
		Draft:InvalidateAllCards()
	end,
	OnUpdate = function(self)
		self.button1:SetEnabled(not C_Player:IsImmune())
	end
}

StaticPopupDialogs["DRAFT_CANT_CHOOSE_IMMUNE"] = {
	text = "",
	button1 = OKAY,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["BUILD_DRAFT_MAX_LEVEL_UPGRADE"] = {
	text = BUILD_DRAFT_MAX_LEVEL_UPGRADE,
	button1 = PVE_BUILD,
	button2 = NO,
	button3 = PVP_BUILD,
	OnShow = function(self, data)
		self.button3:SetEnabled(data.pvp)
		self.button1:SetEnabled(data.pve)
	end,
	OnButton1 = function(self, data)
		C_BuildCreator.ActivateBuild(data.pve, true, true)
	end,
	OnButton3 = function(self, data)
		C_BuildCreator.ActivateBuild(data.pvp, true, true)
	end,
	OnUpdate = function(self)
		local enabled = not C_Player:IsImmune() and not C_Player:InCombat()
		self.button1:SetEnabled(enabled)
		self.button3:SetEnabled(enabled)
	end,
}

StaticPopupDialogs["DELETE_CUSTOM_TRIAL_CONFIRM"] = {
	text = DELETE_CUSTOM_TRIAL_CONFIRM,
	button1 = DELETE,
	button2 = CANCEL,
	OnAccept = function(self, data)
		data()
	end
}

StaticPopupDialogs["CHALLENGES_EDITOR_PUBLISH_CONFIRM"] = {
	text = CHALLENGES_EDITOR_PUBLISH_CONFIRM,
	button1 = PUBLISH_TRIAL,
	button2 = CANCEL,
	OnAccept = function(self, data)
		data()
	end
}

StaticPopupDialogs["BUILD_CREATOR_ACTIVATE_BUILD_DRAFT"] = {
	text = BUILD_CREATOR_ACTIVATE_BUILD_DRAFT,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		data()
	end,
}

StaticPopupDialogs["CHALLENGES_SYNC"] = {
    text = CHALLENGES_SYNC,
    button1 = YES,
    button2 = NO,
    OnShow = function(self, data)
        self.timeleft = data
	    self.activateIn = 3
    end,
    OnAccept = function(self)
        C_Challenge.SendChallengeSyncResponse(true)
    end,
    OnCancel = function(self)
        C_Challenge.SendChallengeSyncResponse(false)
    end,
    OnUpdate = function(self, elapsed)
	    if self.activateIn then
		    if self.activateIn <= 0 then
			    self.button1:Enable()
			    self.button1:SetText(YES)
		    else
			    self.activateIn = self.activateIn - elapsed
			    self.button1:Disable()
			    self.button1:SetText(YES .. " (" .. math.ceil(self.activateIn) .. ")")
		    end
	    else
		    self.button1:SetEnabled(false)
	    end
    end,
    timeout = 60,
    whileDead = 1,
}

StaticPopupDialogs["CHALLENGES_SYNC_REMOVE"] = {
	text = CHALLENGES_SYNC_REMOVE,
	button1 = YES,
	button2 = NO,
	OnShow = function(self, data)
		self.timeleft = data
		self.activateIn = 3
	end,
	OnAccept = function(self)
		C_Challenge.SendChallengeSyncResponse(true)
	end,
	OnCancel = function(self)
		C_Challenge.SendChallengeSyncResponse(false)
	end,
	OnUpdate = function(self, elapsed)
		if self.activateIn then
			if self.activateIn <= 0 then
				self.button1:Enable()
				self.button1:SetText(YES)
			else
				self.activateIn = self.activateIn - elapsed
				self.button1:Disable()
				self.button1:SetText(YES .. " (" .. math.ceil(self.activateIn) .. ")")
			end
		else
			self.button1:SetEnabled(false)
		end
	end,
	timeout = 60,
	whileDead = 1,
}

StaticPopupDialogs["VANITY_PURCHASE"] = {
	text = "Do you want to purchase:\n%s\nfor: %s",
	button1 = YES,
	button2 = CANCEL,
	OnShow = function(self, data)
		self.button1:SetEnabled(data.hasCurrency)
	end,
	OnAccept = function(self, data)
		data.purchase()
	end,
}

StaticPopupDialogs["VANITY_PURCHASE_MULTI"] = {
	text = "Do you want to purchase:\n%s\nusing:\n%s",
	button1 = "Bazaar Tokens",
	button3 = "Donation Points",
	button2 = CANCEL,
	OnShow = function(self, data)
		self.button1:SetEnabled(data.hasCurrency1)
		self.button3:SetEnabled(data.hasCurrency2)
	end,
	OnAccept = function(self, data)
		data.purchase1()
	end,
	OnAlt = function (self, data)
		data.purchase2()
	end,
}

StaticPopupDialogs["BUILD_DRAFT_SELECT_ROLES_CONFIRM"] = {
	text = BUILD_DRAFT_SELECT_ROLES_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	hideOnEscape = true,
	OnShow = function()
		BuildDraftSelectRoleFrame.SelectRoleText:Hide()
		BuildDraftSelectRoleFrame.WarningText:Hide()
	end,
	OnHide = function()
		BuildDraftSelectRoleFrame.SelectRoleText:Show()
		BuildDraftSelectRoleFrame.WarningText:Show()
	end,
	OnAccept = function (self, callback)
		callback()
	end
}

StaticPopupDialogs["BUILD_DRAFT_BUILD_CONFIRM"] = {
	text = BUILD_DRAFT_BUILD_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function (self, callback)
		callback()
	end
}

StaticPopupDialogs["BUILD_DRAFT_SWAPEQUIP_NOTIFY"] = {
	text = BUILD_DRAFT_EQUIP_NOTIFY,
	button1 = OKAY,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function (self, data)
		PickupInventoryItem(data:GetID());
		if ( CursorHasItem() ) then
			MerchantFrame_SetRefundItem(data, 1)
		end
	end,
	OnUpdate = function ()
		if not GetCursorInfo() then
			self:Hide()
		end
	end
}

StaticPopupDialogs["BUILD_DRAFT_AUTOEQUIP_NOTIFY"] = {
	text = BUILD_DRAFT_EQUIP_NOTIFY,
	button1 = OKAY,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function ()
		AutoEquipCursorItem()
	end,
	OnUpdate = function ()
		if not GetCursorInfo() then
			self:Hide()
		end
	end
}

StaticPopupDialogs["BUILD_DRAFT_EQUIP_NOTIFY"] = {
	text = BUILD_DRAFT_EQUIP_NOTIFY,
	button1 = OKAY,
	button2 = CANCEL,
	hideOnEscape = true,
	OnAccept = function (self, data)
		local bag, slot, itemID = unpack(data)
		if itemID ~= GetContainerItemID(bag, slot) then return end
		UseContainerItem(bag, slot)
	end
}

StaticPopupDialogs["NAME_ADDON_PRESET"] = {
	text = NAME_ADDON_PRESET,
	button1 = OKAY,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = 32,
	OnShow = function(self)
		self.button1:Disable()
	end,
	OnAccept = function (self)
		local id = self.editBox:GetText()
		local state = C_AddonPanel:MakeSaveState()
		C_AddonPanel:WriteSaveState(id, state, true)
	end,
	EditBoxOnEnterPressed = function(self)
		self:GetParent().button1:Click()
	end,
	EditBoxOnTextChanged = function(self)
		self:GetParent().button1:SetEnabled(strlen(self:GetText()) >= 4)
	end
}

StaticPopupDialogs["RENAME_ADDON_PRESET"] = {
	text = RENAME_ADDON_PRESET,
	button1 = OKAY,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = 32,
	OnShow = function(self)
		self.button1:Disable()
	end,
	EditBoxOnEnterPressed = function(self)
		self:GetParent().button1:Click()
	end,
	OnAccept = function(self, data)
		local id = self.editBox:GetText()
		C_AddonPanel:DeleteSaveState(data.oldID)
		C_AddonPanel:WriteSaveState(id, data.state, true)
	end,
	EditBoxOnTextChanged = function(self)
		self:GetParent().button1:SetEnabled(strlen(self:GetText()) >= 4)
	end
}

StaticPopupDialogs["DELETE_ADDON_PRESET"] = {
	text = DELETE_ADDON_PRESET,
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, data)
		C_AddonPanel:DeleteSaveState(data)
		CloseDropDownMenus()
	end,
}

StaticPopupDialogs["SAVE_ADDON_PRESET"] = {
	text = SAVE_ADDON_PRESET,
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, data)
		C_AddonPanel:WriteSaveState(data, C_AddonPanel:MakeSaveState(), true)
		CloseDropDownMenus()
	end,
}

StaticPopupDialogs["OPEN_URL_DISCORD"] = {
	text = OPEN_URL_DISCORD_S,
	button1 = COPY_TO_CLIPBOARD,
	button2 = CLOSE,
	OnAccept = function(self, url)
		UIErrorsFrame:AddMessage(S_COPIED_TO_CLIPBOARD:format(url), 1.0, 1.0, 0.0, 1.0)
		SendSystemMessage(S_COPIED_TO_CLIPBOARD:format(url))
		Internal_CopyToClipboard(url)
	end
}

StaticPopupDialogs["ASCENSIONHELP_OPEN_URL"] = {
	OnShow =
	function(self, data)
		self.text:SetFormattedText(data.title)
		self.editBox:SetText(data.url)
		self.editBox:SetAutoFocus(true)
		self.editBox:HighlightText()
	end,
	text         = "",
	wide         = true,
	closeButton  = true,
	button1      = "OK",
	timeout      = 60,
	hasEditBox   = true,
	hideOnEscape = true,
	EditBoxOnEnterPressed  = function(self) self:GetParent():Hide() end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end
}

StaticPopupDialogs["GM_DELETE_BUILD"] = {
	text = DELETE_BUILD_CONFIRM,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data)
		SendChatMessage(format(".buildcreator delete %s", data))
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1,
	hasEditBox = 1,
	maxLetters = 32,
	OnShow = function(self)
		self.button1:Disable();
		self.button2:Enable();
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		if ( self:GetParent().button1:IsEnabled() == 1 ) then
			self:GetParent().button1:Click()
		end
	end,
	EditBoxOnTextChanged = function (self)
		local parent = self:GetParent();
		if ( strupper(parent.editBox:GetText()) ==  DELETE_BUILD_CONFIRM_STRING ) then
			parent.button1:Enable();
		else
			parent.button1:Disable();
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end
};

StaticPopupDialogs["RENAME_TALENT_LOADOUT"] = {
	text = RENAME_TALENT_LOADOUT,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	whileDead = true,
	hideOnEscape = true,
	exclusive = 1,
	OnAccept = function(self, uuid)
		local name = self.editBox:GetText():trim()
		name = name:sub(1, 36)
		if name == "" then
			return
		end

		C_CharacterAdvancement.SetLoadoutName(uuid, name)
	end,
	EditBoxOnTextChanged = function(self)
		local text = self:GetText()
		if strlen(text) > 36 then
			self:SetText(text:sub(1, 36)) -- limit to 36 char
		end
	end,
	EditBoxOnEnterPressed = function(self)
		self:GetParent().button1:Click()
	end
}

StaticPopupDialogs["ACTIVATE_TALENT_LOADOUT_CONFIRM"] = {
	text = ACTIVATE_TALENT_LOADOUT_CONFIRM,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	exclusive = 1,
	OnAccept = function(self, uuid)
		C_CharacterAdvancement.ActivateLoadout(uuid)
	end,
}

local function CanResurrectInClosestCity()
	return UnitLevel("player") >= 10
end

StaticPopupDialogs["SAFE_RESURRECT_DIALOG"] = {
	text = SAFE_RESURRECT_DIALOG,
	button1 = RESURRECT_CLOSEST_TOWN,
	button2 = CANCEL,
	button3 = RESURRECT_CLOSEST_CITY,
	whileDead = true,
	showAlert = true,
	hideOnEscape = true,
	exclusive = 1,
	OnShow = function(self)
		self.button3:SetEnabled(CanResurrectInClosestCity())
		self.button3:SetAttribute("disableTooltipTitle", RESURRECT_CLOSEST_CITY)
		self.button3:SetAttribute("disableTooltipText", string.format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, 10))
	end,
	OnButton1 = function() -- Show confirmation dialog instead
		StaticPopup_Show("CONFIRM_RESURRECT_TOWN_DIALOG")
	end,
	OnButton3 = function() -- Show confirmation dialog instead
		if not CanResurrectInClosestCity() then
			return
		end

		StaticPopup_Show("CONFIRM_RESURRECT_CITY_DIALOG")
	end,
}

-- New confirmation dialog for resurrecting in the closest town
StaticPopupDialogs["CONFIRM_RESURRECT_TOWN_DIALOG"] = {
	text = CONFIRM_RESURRECT_TOWN_PENALTY, -- Use the new global string key
	button1 = YES, -- Or ACCEPT if defined and preferred
	button2 = NO, -- Or CANCEL if defined and preferred
	whileDead = true,
	showAlert = true,
	hideOnEscape = true,
	exclusive = 1,
	preferredIndex = 3, -- Standard UI layer
	OnAccept = function()
		CastSpellByID(84423) -- Closest Town
		GhostFrame:Hide()
		ClosestResFrame:Hide()
	end,
	-- OnCancel can be omitted if default behavior (closing the dialog) is sufficient
}

-- New confirmation dialog for resurrecting in the closest city
StaticPopupDialogs["CONFIRM_RESURRECT_CITY_DIALOG"] = {
	text = CONFIRM_RESURRECT_CITY_PENALTY, -- Use the new global string key
	button1 = YES, -- Or ACCEPT if defined and preferred
	button2 = NO, -- Or CANCEL if defined and preferred
	whileDead = true,
	showAlert = true,
	hideOnEscape = true,
	exclusive = 1,
	preferredIndex = 3, -- Standard UI layer
	OnAccept = function()
		if not CanResurrectInClosestCity() then
			return
		end

		CastSpellByID(84433) -- Closest City
		GhostFrame:Hide()
		ClosestResFrame:Hide()
	end,
	-- OnCancel can be omitted if default behavior (closing the dialog) is sufficient
}

StaticPopupDialogs["RETURN_GRAVEYARD_CONFIRM"] = {
	text = RETURN_GRAVEYARD_CONFIRM,
	button1 = YES,
	button2 = CANCEL,
	whileDead = true,
	hideOnEscape = true,
	exclusive = 1,
	OnButton1 = function()
		PortGraveyard()
	end,
}

StaticPopupDialogs["NPE_CLOSE_TUTORIAL_CONFIRM"] = {
	text = CLOSE_NPE_TUTORIAL_CONFIRM,
	button1 = END_TUTORIAL,
	button2 = CONTINUE_TUTORIAL,
	whileDead = true,
	hideOnEscape = true,
	exclusive = 1,
	OnAccept = function()
		NPE:CompleteTutorialSequence()
	end
}

StaticPopupDialogs["POPUP_SELECT_RULESET"] = {
	text = POPUP_SELECT_RULESET,
	button1 = YES,
	button2 = NO,
	whileDead = true,
	hideOnEscape = true,
	exclusive = 1,
	OnAccept = function(self, data)
		C_Player:SetRuleset(self.ruleset)
		data:UpdateSelection()
		if data.FromGossip then
			HideUIPanel(AscensionLFGFrame)
		end
	end
}

StaticPopupDialogs["LEAVE_DUNGEON_CONFIRM"] = {
	text = LEAVE_DUNGEON_CONFIRM,
	button1 = YES,
	button2 = NO,
	whileDead = true,
	hideOnEscape = false,
	exclusive = 1,
	OnAccept = function()
		LFGTeleport(true)
	end,
	OnCancel = function(self)
		LFDLeaveFrame:Show()
	end
}

StaticPopupDialogs["NPE_RESET_ALL"] = {
    text = INTERFACE_OPTIONS_NPE_RESET_CVARS,
    button1 = YES,
    button2 = NO,
    whileDead = true,
    hideOnEscape = true,
    exclusive = 1,
    OnAccept = function()
        NPEPopups:ResetAllCVars()
		NPE:ResetAllTutorials()
		ReloadUI()
    end
}

StaticPopupDialogs["HELPTIP_RESET_ALL"] = {
    text = INTERFACE_OPTIONS_HELPTIP_RESET_CVARS,
    button1 = YES,
    button2 = NO,
    whileDead = true,
    hideOnEscape = true,
    exclusive = 1,
    OnAccept = function()
        HelpTips:ResetAllCVars()
		HelpPlate:ResetAllCVars()
    end
}

StaticPopupDialogs["BATTLEGROUND_EXPAND_SEARCH"] = {
	text = BATTLEGROUND_EXPAND_SEARCH_TEXT,
	button1 = YES,
	button2 = NO,
	whileDead = true,
	hideOnEscape = true,
	OnShow = function(self, queueID)
		GetBattlefieldList(queueID, 0, 0)
	end,

	OnAccept = function(self, queueID)
		local queued = 0
		for i = 1, MAX_BATTLEFIELD_QUEUES do
			if GetBattlefieldStatus(i) ~= "none" then
				queued = queued + 1
			end
		end

		if queued == MAX_BATTLEFIELD_QUEUES then
			return 1
		end
		local bgIndex
		for i = 1, GetNumBattlegroundTypes() do
			local _, _, _, _, battleGroundID  = GetBattlegroundInfo(i)
			if battleGroundID == queueID then
				bgIndex = i
				break
			end
		end
		
		if not bgIndex then return end

		local partyMembers = GetNumPartyMembers()
		local raidMembers = GetNumRaidMembers()
		local joinAsParty 
		if (partyMembers > 0 and UnitIsPartyLeader("player")) or (raidMembers > 0 and IsRaidLeader()) then
			joinAsParty = 1
		end
		JoinBattlefield(bgIndex, joinAsParty) 
	end,

	OnUpdate = function(self)
		local queued = 0
		for i = 1, MAX_BATTLEFIELD_QUEUES do
			if GetBattlefieldStatus(i) ~= "none" then
				queued = queued + 1
			end
		end
		if queued == MAX_BATTLEFIELD_QUEUES then
			self.text:SetText(BATTLEGROUND_EXPAND_SEARCH_TEXT_ERR)
			self.button1:Disable()
			StaticPopup_Resize(self, "BATTLEGROUND_EXPAND_SEARCH")
		else
			self.text:SetText(BATTLEGROUND_EXPAND_SEARCH_TEXT)
			self.button1:Enable()
			self.maxHeightSoFar = 0
			StaticPopup_Resize(self, "BATTLEGROUND_EXPAND_SEARCH")
		end
	end
}

--
-- Blizzard Popups
--
StaticPopupDialogs["CONFIRM_SAVE_EQUIPMENT_SET"] = {
	text = CONFIRM_SAVE_EQUIPMENT_SET,
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		SaveEquipmentSet(self.data, self.selectedIcon);
		if self.oldSet and GetEquipmentSetInfoByName(self.oldSet) then
			DeleteEquipmentSet(self.oldSet);
		end
	end,
	OnHide = function (self) self.data = nil; self.selectedIcon = nil; self.oldSet = nil end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
}

StaticPopupDialogs["CONFIRM_OVERWRITE_EQUIPMENT_SET"] = {
	text = CONFIRM_OVERWRITE_EQUIPMENT_SET,
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		SaveEquipmentSet(self.data, self.selectedIcon);
		if self.oldSet then
			DeleteEquipmentSet(self.oldSet);
		end
		GearManagerDialogPopup:Hide();
	end,
	OnHide = function (self) self.data = nil; self.selectedIcon = nil; self.oldSet = nil end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
}

StaticPopupDialogs["CONFIRM_DELETE_EQUIPMENT_SET"] = {
	text = CONFIRM_DELETE_EQUIPMENT_SET,
	button1 = YES,
	button2 = NO,
	OnAccept = function (self) DeleteEquipmentSet(self.data); end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
}

StaticPopupDialogs["CONFIRM_REMOVE_GLYPH"] = {
	text = CONFIRM_REMOVE_GLYPH,
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		local talentGroup = PlayerTalentFrame and PlayerTalentFrame.talentGroup or 1;
		if ( talentGroup == GetActiveTalentGroup() ) then
			RemoveGlyphFromSocket(self.data);
		end
	end,
	OnCancel = function (self)
	end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

StaticPopupDialogs["CONFIRM_GLYPH_PLACEMENT"] = {
	text = CONFIRM_GLYPH_PLACEMENT,
	button1 = YES,
	button2 = NO,
	OnAccept = function (self) PlaceGlyphInSocket(self.data); end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
}

StaticPopupDialogs["CONFIRM_RESET_VIDEO_SETTINGS"] = { 
	text = CONFIRM_RESET_SETTINGS,
	button1 = RESET_TO_DEFAULT,
	button2 = CANCEL,
	OnAccept = function ()
		VideoOptionsFrame_SetCurrentToDefaults();
	end,
	OnCancel = function() end,
	showAlert = 1,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
	whileDead = 1,
}

StaticPopupDialogs["CONFIRM_RESET_AUDIO_SETTINGS"] = { 
	text = CONFIRM_RESET_SETTINGS,
	button1 = RESET_TO_DEFAULT,
	button2 = CANCEL,
	OnAccept = function ()
		AudioOptionsFrame_SetCurrentToDefaults();
	end,
	OnCancel = function() end,
	showAlert = 1,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
	whileDead = 1,
}

StaticPopupDialogs["CONFIRM_RESET_INTERFACE_SETTINGS"] = { 
	text = CONFIRM_RESET_INTERFACE_SETTINGS,
	button1 = RESET_TO_DEFAULT,
	button2 = CANCEL,
	OnAccept = function ()
		InterfaceOptionsFrame_SetCurrentToDefaults();
	end,
	OnCancel = function() end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1,
	whileDead = 1,
}

StaticPopupDialogs["CONFIRM_PURCHASE_TOKEN_ITEM"] = {
	text = CONFIRM_PURCHASE_TOKEN_ITEM,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count);
	end,
	OnCancel = function()
	
	end,
	OnShow = function()
	
	end,
	OnHide = function()
	
	end,
	timeout = 0,
	hideOnEscape = 1,
	hasItemFrame = 1,
}

StaticPopupDialogs["CONFIRM_REFUND_TOKEN_ITEM"] = {
	text = CONFIRM_REFUND_TOKEN_ITEM,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		local currentHonor, maxHonor = GetHonorCurrency();
		local currentArenaPoints, maxArenaPoints = GetArenaCurrency();
		local overflowHonor = MerchantFrame.honorPoints and ( MerchantFrame.honorPoints + currentHonor > maxHonor );
		local overflowArena = MerchantFrame.arenaPoints and ( MerchantFrame.arenaPoints + currentArenaPoints > maxArenaPoints );
		if ( overflowHonor and overflowArena ) then
			StaticPopup_Show("CONFIRM_REFUND_MAX_HONOR_AND_ARENA", (MerchantFrame.honorPoints + currentHonor - maxHonor), (MerchantFrame.arenaPoints + currentArenaPoints - maxArenaPoints) )
		elseif ( overflowHonor ) then
			StaticPopup_Show("CONFIRM_REFUND_MAX_HONOR", (MerchantFrame.honorPoints + currentHonor - maxHonor) )
		elseif ( overflowArena ) then
			StaticPopup_Show("CONFIRM_REFUND_MAX_ARENA_POINTS", (MerchantFrame.arenaPoints + currentArenaPoints - maxArenaPoints))
		else
			ContainerRefundItemPurchase(MerchantFrame.refundBag, MerchantFrame.refundSlot, MerchantFrame.refundItemEquipped);
		end
		StackSplitFrame:Hide();
	end,
	OnCancel = function()
		ClearCursor();
	end,
	OnShow = function(self)
		if(MerchantFrame.price ~= 0) then
			MoneyFrame_Update(self.moneyFrame, MerchantFrame.price);
		end
	end,
	OnHide = function()
		MerchantFrame_ResetRefundItem();	
	end,
	timeout = 0,
	hideOnEscape = 1,
	hasItemFrame = 1,
}

StaticPopupDialogs["CONFIRM_REFUND_MAX_HONOR"] = {
	text = CONFIRM_REFUND_MAX_HONOR,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		ContainerRefundItemPurchase(MerchantFrame.refundBag, MerchantFrame.refundSlot);
		StackSplitFrame:Hide();
	end,
	OnCancel = function()
		ClearCursor();
	end,
	OnShow = function()
	
	end,
	OnHide = function()
		MerchantFrame_ResetRefundItem();
	end,
	timeout = 0,
	hideOnEscape = 1,
}

StaticPopupDialogs["CONFIRM_REFUND_MAX_ARENA_POINTS"] = {
	text = CONFIRM_REFUND_MAX_ARENA_POINTS,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		ContainerRefundItemPurchase(MerchantFrame.refundBag, MerchantFrame.refundSlot);
		StackSplitFrame:Hide();
	end,
	OnCancel = function()
		ClearCursor();
	end,
	OnShow = function()
	
	end,
	OnHide = function()
		MerchantFrame_ResetRefundItem();
	end,
	timeout = 0,
	hideOnEscape = 1,
}

StaticPopupDialogs["CONFIRM_REFUND_MAX_HONOR_AND_ARENA"] = {
	text = CONFIRM_REFUND_MAX_HONOR_AND_ARENA,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		ContainerRefundItemPurchase(MerchantFrame.refundBag, MerchantFrame.refundSlot);
		StackSplitFrame:Hide();
	end,
	OnCancel = function()
		ClearCursor();
	end,
	OnShow = function()
	
	end,
	OnHide = function()
		MerchantFrame_ResetRefundItem();
	end,
	timeout = 0,
	hideOnEscape = 1,
}

StaticPopupDialogs["CONFIRM_HIGH_COST_ITEM"] = {
	text = CONFIRM_HIGH_COST_ITEM,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count);
	end,
	OnCancel = function()
	
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, MerchantFrame.price*MerchantFrame.count);
	end,
	OnHide = function()
	
	end,
	timeout = 0,
	hideOnEscape = 1,
	hasMoneyFrame = 1,
}

StaticPopupDialogs["CONFIRM_COMPLETE_EXPENSIVE_QUEST"] = {
	text = CONFIRM_COMPLETE_EXPENSIVE_QUEST,
	button1 = COMPLETE_QUEST,
	button2 = CANCEL,
	OnAccept = function()
		GetQuestReward(QuestInfoFrame.itemChoice);
		PlaySound("igQuestListComplete");
	end,
	OnCancel = function() 
		DeclineQuest();
		PlaySound("igQuestCancel");
	end,
	OnShow = function()
		QuestInfoFrame.acceptButton:Disable();
		QuestInfoFrame.cancelButton:Disable();
	end,
	OnHide = function()
		QuestInfoFrame.cancelButton:Enable();
	end,
	timeout = 0,
	hideOnEscape = 1,
	hasMoneyFrame = 1,
};
StaticPopupDialogs["CONFIRM_ACCEPT_PVP_QUEST"] = {
	text = CONFIRM_ACCEPT_PVP_QUEST,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		AcceptQuest();
	end,
	OnCancel = function() 
		DeclineQuest();
		PlaySound("igQuestCancel");
	end,
	OnShow = function()
		QuestFrameAcceptButton:Disable();
		QuestFrameDeclineButton:Disable();
	end,
	OnHide = function()
		QuestFrameDeclineButton:Enable();
	end,
	timeout = 0,
	hideOnEscape = 1,
};
StaticPopupDialogs["USE_GUILDBANK_REPAIR"] = {
	text = USE_GUILDBANK_REPAIR,
	button1 = USE_PERSONAL_FUNDS,
	button2 = OKAY,
	OnAccept = function()
		RepairAllItems();
		PlaySound("ITEM_REPAIR");
	end,
	OnCancel = function ()
		RepairAllItems(1);
		PlaySound("ITEM_REPAIR");
	end,
	timeout = 0,
	hideOnEscape = 1
};
StaticPopupDialogs["GUILDBANK_WITHDRAW"] = {
	text = GUILDBANK_WITHDRAW,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		WithdrawGuildBankMoney(MoneyInputFrame_GetCopper(self.moneyInputFrame));
	end,
	OnHide = function(self)
		MoneyInputFrame_ResetMoney(self.moneyInputFrame);
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent():GetParent();
		WithdrawGuildBankMoney(MoneyInputFrame_GetCopper(parent.moneyInputFrame));
		parent:Hide();
	end,
	hasMoneyInputFrame = 1,
	timeout = 0,
	hideOnEscape = 1
};
StaticPopupDialogs["GUILDBANK_DEPOSIT"] = {
	text = GUILDBANK_DEPOSIT,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		DepositGuildBankMoney(MoneyInputFrame_GetCopper(self.moneyInputFrame));
	end,
	OnHide = function(self)
		MoneyInputFrame_ResetMoney(self.moneyInputFrame);
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent():GetParent();
		DepositGuildBankMoney(MoneyInputFrame_GetCopper(parent.moneyInputFrame));
		parent:Hide();
	end,
	hasMoneyInputFrame = 1,
	timeout = 0,
	hideOnEscape = 1
};
StaticPopupDialogs["CONFIRM_BUY_GUILDBANK_TAB"] = {
	text = CONFIRM_BUY_GUILDBANK_TAB,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		BuyGuildBankTab();
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, GetGuildBankTabCost());
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1
};

StaticPopupDialogs["TOO_MANY_LUA_ERRORS"] = {
	text = TOO_MANY_LUA_ERRORS,
	button1 = DISABLE_ADDONS,
	button2 = IGNORE_ERRORS,
	OnAccept = function(self)
		DisableAllAddOns();
		ReloadUI();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_ACCEPT_SOCKETS"] = {
	text = CONFIRM_ACCEPT_SOCKETS,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		AcceptSockets();
		PlaySound("JewelcraftingFinalize");
	end,
	timeout = 0,
	showAlert = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["TAKE_GM_SURVEY"] = {
	text = TAKE_GM_SURVEY,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		GMSurveyFrame_LoadUI();
		ShowUIPanel(GMSurveyFrame);
		TicketStatusFrame:Hide();
	end,
	OnCancel = function(self)
		TicketStatusFrame.hasGMSurvey = false;
		TicketStatusFrame:Hide();
	end,
	timeout = 0,
	hideOnEscape = 1,
};

StaticPopupDialogs["CONFIRM_RESET_INSTANCES"] = {
	text = CONFIRM_RESET_INSTANCES,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		ResetInstances();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["CONFIRM_RESET_RAIDS"] = {
	text = CONFIRM_RESET_RAIDS,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		ResetRaids();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["CONFIRM_RESET_DUNGEONS"] = {
	text = CONFIRM_RESET_DUNGEONS,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		ResetDungeons();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["COMFIRM_RESET_SPECIFIC_INSTANCE"] = {
	text = CONFIRM_RESET_SPECIFIC_INSTANCES,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data)
		C_LootLockout.ResetInstanceDifficulty(unpack(data))
		C_LootLockout.QueryInstanceBinds()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["CONFIRM_GUILD_DISBAND"] = {
	text = CONFIRM_GUILD_DISBAND,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		GuildDisband();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
};

StaticPopupDialogs["CONFIRM_BUY_BANK_SLOT"] = {
	text = CONFIRM_BUY_BANK_SLOT,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		PurchaseSlot();
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, BankFrame.nextSlotCost);
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1,
};

StaticPopupDialogs["MACRO_ACTION_FORBIDDEN"] = {
	text = MACRO_ACTION_FORBIDDEN,
	button1 = OKAY,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["ADDON_ACTION_FORBIDDEN"] = {
	text = ADDON_ACTION_FORBIDDEN,
	button1 = DISABLE,
	button2 = IGNORE_DIALOG,
	OnAccept = function(self, data)
		DisableAddOn(data);
		ReloadUI();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"] = {
	text = CONFIRM_LOOT_DISTRIBUTION,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data)
		GiveMasterLoot(LootFrame.selectedSlot, data);
	end,
	timeout = 0,
	hideOnEscape = 1,
};

StaticPopupDialogs["CONFIRM_BATTLEFIELD_ENTRY"] = {
	text = CONFIRM_BATTLEFIELD_ENTRY,
	button1 = ENTER_BATTLE,
	button2 = LEAVE_QUEUE,
	OnShow = function(self, data)
		-- I don't know why this isn't playing sound but just re-play sound here.
		PlaySound(SOUNDKIT.PVP_THROUGH_QUEUE)
		--SendWindowsFlash()
		local status, mapName, instanceID, levelRangeMin, levelRangeMax, teamSize, registeredMatch = GetBattlefieldStatus(data);
		if ( teamSize == 0 ) then
			self.button2:Enable();
		else
			self.button2:Disable();
		end
	end,
	OnAccept = function(self, data)
		if ( not AcceptBattlefieldPort(data, 1) ) then
			return 1;
		end
		if( StaticPopup_Visible( "DEATH" ) ) then
			StaticPopup_Hide( "DEATH" );
		end
	end,
	OnCancel = function(self, data)
		if ( not AcceptBattlefieldPort(data, 0) ) then	--Actually declines the battlefield port.
			return 1;
		end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	noCancelOnEscape = 1,
	noCancelOnReuse = 1,
	multiple = 1,
	closeButton = 1,
	closeButtonIsHide = 1,
};

StaticPopupDialogs["BFMGR_CONFIRM_WORLD_PVP_QUEUED"] = {
	text = WORLD_PVP_QUEUED,
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["BFMGR_CONFIRM_WORLD_PVP_QUEUED_WARMUP"] = {
	text = WORLD_PVP_QUEUED_WARMUP,
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["BFMGR_DENY_WORLD_PVP_QUEUED"] = {
	text = WORLD_PVP_FAIL,
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["BFMGR_INVITED_TO_QUEUE"] = {
	text = WORLD_PVP_INVITED,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		BattlefieldMgrQueueInviteResponse(1,1);
	end,
	OnCancel = function(self, data)
		BattlefieldMgrQueueInviteResponse(1,0);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1
};

StaticPopupDialogs["BFMGR_INVITED_TO_QUEUE_WARMUP"] = {
	text = WORLD_PVP_INVITED_WARMUP;
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		BattlefieldMgrQueueInviteResponse(1,1);
	end,
	OnCancel = function(self, data)
		BattlefieldMgrQueueInviteResponse(1,0);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1
};

StaticPopupDialogs["BFMGR_INVITED_TO_ENTER"] = {
	text = WORLD_PVP_ENTER,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnShow = function(self)
		self.timeleft = select(4, GetWorldPVPQueueStatus(1));
	end,	
	OnAccept = function(self, data)
		BattlefieldMgrEntryInviteResponse(1,1);
	end,
	OnCancel = function(self, data)
		BattlefieldMgrEntryInviteResponse(1,0);
	end,
	timeout = 0,
	timeoutInformationalOnly = 1;
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1
};

StaticPopupDialogs["BFMGR_EJECT_PENDING"] = {
	text = WORLD_PVP_PENDING,
	button1 = OKAY,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["BFMGR_EJECT_PENDING_REMOTE"] = {
	text = WORLD_PVP_PENDING_REMOTE,
	button1 = OKAY,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["BFMGR_PLAYER_EXITED_BATTLE"] = {
	text = WORLD_PVP_EXITED_BATTLE,
	button1 = OKAY,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["BFMGR_PLAYER_LOW_LEVEL"] = {
	text = WORLD_PVP_LOW_LEVEL,
	button1 = OKAY,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["CONFIRM_GUILD_LEAVE"] = {
	text = CONFIRM_GUILD_LEAVE,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		GuildLeave();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_GUILD_PROMOTE"] = {
	text = CONFIRM_GUILD_PROMOTE,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, name)
		GuildSetLeader(name);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["RENAME_GUILD"] = {
	text = RENAME_GUILD_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 24,
	OnAccept = function(self)
		local text = self.editBox:GetText();
		RenamePetition(text);
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetParent().editBox:GetText();
		RenamePetition(text);
		self:GetParent():Hide();
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["RENAME_ARENA_TEAM"] = {
	text = RENAME_ARENA_TEAM_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 24,
	OnAccept = function(self)
		local text = self.editBox:GetText();
		RenamePetition(text);
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetText();
		RenamePetition(text);
		self:GetParent():Hide();
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_TEAM_LEAVE"] = {
	text = CONFIRM_TEAM_LEAVE,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, team)
		ArenaTeamLeave(team);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_TEAM_PROMOTE"] = {
	text = CONFIRM_TEAM_PROMOTE,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, team, name)
		ArenaTeamSetLeaderByName(team, name);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_TEAM_KICK"] = {
	text = CONFIRM_TEAM_KICK,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, team, name)
		ArenaTeamUninviteByName(team, name);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["HELP_TICKET_QUEUE_DISABLED"] = {
	text = HELP_TICKET_QUEUE_DISABLED,
	button1 = OKAY,
	showAlert = 1,
	timeout = 0,
}

StaticPopupDialogs["CLIENT_RESTART_ALERT"] = {
	text = CLIENT_RESTART_ALERT,
	button1 = OKAY,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["CLIENT_LOGOUT_ALERT"] = {
	text = CLIENT_LOGOUT_ALERT,
	button1 = OKAY,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["RELOAD_UI_NEEDED"] = {
	text = RELOAD_UI_ALERT,
	button1 = OKAY,
	button2 = CANCEL,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
	OnAccept = function()
		ReloadUI()
	end
};

StaticPopupDialogs["RESTART_GX_SUGGEST_RELOAD"] = {
	text = RESTART_GX_SUGGEST_RELOAD,
	button1 = OKAY,
	button2 = CANCEL,
	showAlert = 1,
	timeout = 0,
	whileDead = 1,
	OnAccept = function()
		ReloadUI()
	end
};
StaticPopupDialogs["COD_ALERT"] = {
	text = COD_INSUFFICIENT_MONEY,
	button1 = CLOSE,
	timeout = 0,
	hideOnEscape = 1
};

StaticPopupDialogs["COD_CONFIRMATION"] = {
	text = COD_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		TakeInboxItem(InboxFrame.openMailID, OpenMailFrame.lastTakeAttachment);
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, OpenMailFrame.cod);
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1
};

StaticPopupDialogs["COD_CONFIRMATION_AUTO_LOOT"] = {
	text = COD_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, index)
		AutoLootMailItem(index);
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, OpenMailFrame.cod);
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1
};

StaticPopupDialogs["DELETE_MAIL"] = {
	text = DELETE_MAIL_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		DeleteInboxItem(InboxFrame.openMailID);
		InboxFrame.openMailID = nil;
		HideUIPanel(OpenMailFrame);
	end,
	showAlert = 1,
	timeout = 0,
	hideOnEscape = 1
};

StaticPopupDialogs["DELETE_MONEY"] = {
	text = DELETE_MONEY_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		DeleteInboxItem(InboxFrame.openMailID);
		InboxFrame.openMailID = nil;
		HideUIPanel(OpenMailFrame);
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, OpenMailFrame.money);
	end,
	hasMoneyFrame = 1,
	showAlert = 1,
	timeout = 0,
	hideOnEscape = 1
};

StaticPopupDialogs["SEND_MONEY"] = {
	text = SEND_MONEY_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		if ( SetSendMailMoney(MoneyInputFrame_GetCopper(SendMailMoney)) ) then
			SendMailFrame_SendMail();
		end
	end,
	OnCancel = function(self)
		SendMailMailButton:Enable();
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, MoneyInputFrame_GetCopper(SendMailMoney));
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_REPORT_SPAM_CHAT"] = {
	text = REPORT_SPAM_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, lineID)
		ComplainChat(lineID);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_REPORT_SPAM_MAIL"] = {
	text = REPORT_SPAM_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, index)
		ComplainInboxItem(index);
	end,
	OnCancel = function(self, index)
		OpenMailReportSpamButton:Enable();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["JOIN_CHANNEL"] = {
	text = ADD_CHANNEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 31,
	whileDead = 1,
	OnAccept = function(self)
		local channel = self.editBox:GetText();
		JoinPermanentChannel(channel, nil, FCF_GetCurrentChatFrameID(), 1);
		ChatFrame_AddChannel(FCF_GetCurrentChatFrame(), channel);
		self.editBox:SetText("");
	end,
	timeout = 0,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		local editBox = parent.editBox;
		local channel = editBox:GetText();
		JoinPermanentChannel(channel, nil, FCF_GetCurrentChatFrameID(), 1);
		ChatFrame_AddChannel(FCF_GetCurrentChatFrame(), channel);
		editBox:SetText("");
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	hideOnEscape = 1
};

StaticPopupDialogs["CHANNEL_INVITE"] = {
	text = CHANNEL_INVITE,
	button1 = ACCEPT_ALT,
	button2 = CANCEL,
	hasEditBox = 1,
	autoCompleteParams = AUTOCOMPLETE_LIST.CHANINVITE,
	maxLetters = 31,
	whileDead = 1,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	OnAccept = function(self, data)
		local name = self.editBox:GetText();
		ChannelInvite(data, name);
		self.editBox:SetText("");
	end,
	timeout = 0,
	EditBoxOnEnterPressed = function(self, data)
		local parent = self:GetParent();
		local editBox = parent.editBox;
		ChannelInvite(data, editBox:GetText());
		editBox:SetText("");
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	hideOnEscape = 1
};

StaticPopupDialogs["CHANNEL_PASSWORD"] = {
	text = CHANNEL_PASSWORD,
	button1 = ACCEPT_ALT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 31,
	whileDead = 1,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	OnAccept = function(self, data)
		local password = self.editBox:GetText();
		SetChannelPassword(data, password);
		self.editBox:SetText("");
	end,
	timeout = 0,
	EditBoxOnEnterPressed = function(self, data)
		local parent = self:GetParent();
		local editBox = parent.editBox
		local password = editBox:GetText();
		SetChannelPassword(data, password);
		editBox:SetText("");
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	hideOnEscape = 1
};

StaticPopupDialogs["NAME_CHAT"] = {
	text = NAME_CHAT_WINDOW,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 31,
	whileDead = 1,
	OnAccept = function(self, renameID)
		local name = self.editBox:GetText();
		if ( renameID ) then
			FCF_SetWindowName(_G["ChatFrame"..renameID], name);
		else
			local frame = FCF_OpenNewWindow(name);
			FCF_CopyChatSettings(frame, DEFAULT_CHAT_FRAME);
		end
		self.editBox:SetText("");
		FCF_DockUpdate();
	end,
	timeout = 0,
	EditBoxOnEnterPressed = function(self, renameID)
		local parent = self:GetParent();
		local editBox = parent.editBox
		local name = editBox:GetText();
		if ( renameID ) then
			FCF_SetWindowName(_G["ChatFrame"..renameID], name);
		else
			local frame = FCF_OpenNewWindow(name);
			FCF_CopyChatSettings(frame, DEFAULT_CHAT_FRAME);
		end
		editBox:SetText("");
		FCF_DockUpdate();
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function (self)
		self:GetParent():Hide();
	end,
	hideOnEscape = 1
};

StaticPopupDialogs["RESET_CHAT"] = {
	text = RESET_CHAT_WINDOW,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = 1,
	OnAccept = function(self)
		FCF_ResetChatWindows();
		if ( ChatConfigFrame:IsShown() ) then
			ChatConfig_UpdateChatSettings();
		end
	end,
	timeout = 0,
	EditBoxOnEscapePressed = function (self)
		self:GetParent():Hide();
	end,
	hideOnEscape = 1
};
StaticPopupDialogs["PETRENAMECONFIRM"] = {
	text = PET_RENAME_CONFIRMATION,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self, data)
		PetRename(data);
	end,
	OnUpdate = function(self, elapsed)
		if ( not UnitExists("pet") ) then
			self:Hide();
		end
	end,
	timeout = 0,
	hideOnEscape = 1,
};

StaticPopupDialogs["DEATH"] = {
	text = DEATH_RELEASE_TIMER,
	button1 = DEATH_RELEASE,
	button2 = USE_SOULSTONE,
	button3 = "Last Checkpoint",
	button4 = DEATH_RECAP,
	OnShow = function(self)
		self.timeleft = GetReleaseTimeRemaining();
		local text = HasSoulstone();
		if ( text ) then
			self.button2:SetText(text);
		end

		if ( IsActiveBattlefieldArena() ) then
			self.text:SetText(DEATH_RELEASE_SPECTATOR);
		elseif ( self.timeleft == -1 ) then
			self.text:SetText(DEATH_RELEASE_NOTIMER);
		end
	end,
	OnAccept = function(self)
		if ( IsActiveBattlefieldArena() ) then
			local info = ChatTypeInfo["SYSTEM"];
			DEFAULT_CHAT_FRAME:AddMessage(ARENA_SPECTATOR, info.r, info.g, info.b, info.id);
		end
		RepopMe();
		if ( CannotBeResurrected() ) then
			return 1
		end
	end,
	OnCancel = function(self, data, reason)
		if ( reason == "override" ) then
			return;
		end
		if ( reason == "timeout" ) then
			return;
		end
		if ( reason == "clicked" ) then
			if ( HasSoulstone() ) then
				UseSoulstone();
			else
				RepopMe();
			end
			if ( CannotBeResurrected() ) then
				return 1
			end
		end
	end,
	OnAlt = function(self)
		if C_Instance:HasCheckpoint() and C_Instance:CanUseCheckpoint() then
			RequestRespawnAtCheckpoint()
		end
		return 1 -- dont close
	end,
	OnButton4 = function()
		AscensionUI.DeathRecap:OpenRecap()
		return true
	end,
	OnUpdate = function(self, elapsed)
		local canRes = not C_Manastorm.IsInManastorm() and (not C_Instance.IsInRaid() or GetWorldState(6000) ~= 1)
		if ( IsFalling() and (not IsOutOfBounds()) ) then
			self.button1:Disable();
			self.button2:Disable();
		elseif ( HasSoulstone() ) then	--Bug ID 153643
			self.button1:SetEnabled(canRes);
			self.button2:Enable();
		else
			self.button1:SetEnabled(canRes);
			self.button2:Disable();
		end

		self.button3:SetEnabled(C_Instance:HasCheckpoint() and C_Instance:CanUseCheckpoint() and canRes)

		if #AscensionUI.DeathRecap.Events > 0 then
			self.button4:Enable()
		else
			self.button4:Disable()
		end

	end,
	DisplayButton2 = function(self)
		return HasSoulstone()
	end,
	DisplayButton3 = function(self)
		return C_Instance:HasCheckpoint()
	end,
	timeout = 0,
	whileDead = 1,
	interruptCinematic = 1,
	notClosableByLogout = 1,
	cancels = "RECOVER_CORPSE"
};
StaticPopupDialogs["RESURRECT"] = {
	StartDelay = GetCorpseRecoveryDelay,
	delayText = RESURRECT_REQUEST_TIMER,
	text = RESURRECT_REQUEST,
	button1 = ACCEPT,
	button1DisableTooltipTitle = CANNOT_RESURRECT,
	button2 = DECLINE,
	OnShow = function(self)
		self.timeleft = GetCorpseRecoveryDelay() + 60;
	end,
	OnAccept = function(self)
		AcceptResurrect();
	end,
	OnCancel = function(self)
		DeclineResurrect();
		if ( UnitIsDead("player") and not UnitIsControlling("player") ) then
			StaticPopup_Show("DEATH");
		end
	end,
	OnUpdate = function(self)
		if GetCorpseRecoveryDelay() > 0 then
			self.button1:Disable();
		else
			self.button1:Enable();
		end
	end,
	timeout = 60,
	whileDead = 1,
	cancels = "DEATH",
	interruptCinematic = 1,
	notClosableByLogout = 1,
	hideOnEscape = 1,
	noCancelOnReuse = 1
};
StaticPopupDialogs["RESURRECT_NO_SICKNESS"] = {
	StartDelay = GetCorpseRecoveryDelay,
	delayText = RESURRECT_REQUEST_NO_SICKNESS_TIMER,
	text = RESURRECT_REQUEST_NO_SICKNESS,
	button1 = ACCEPT,
	button1DisableTooltipTitle = CANNOT_RESURRECT,
	button2 = DECLINE,
	OnShow = function(self)
		self.timeleft = GetCorpseRecoveryDelay() + 60;
	end,
	OnAccept = function(self)
		AcceptResurrect();
	end,
	OnCancel = function(self)
		DeclineResurrect();
		if ( UnitIsDead("player") and not UnitIsControlling("player") ) then
			StaticPopup_Show("DEATH");
		end
	end,
	OnUpdate = function(self)
		if GetCorpseRecoveryDelay() > 0 then
			self.button1:Disable();
		else
			self.button1:Enable();
		end
	end,
	timeout = 60,
	whileDead = 1,
	cancels = "DEATH",
	interruptCinematic = 1,
	notClosableByLogout = 1,
	hideOnEscape = 1,
	noCancelOnReuse = 1
};
StaticPopupDialogs["RESURRECT_NO_TIMER"] = {
	StartDelay = GetCorpseRecoveryDelay,
	delayText = RESURRECT_REQUEST_NO_SICKNESS_TIMER,
	text = RESURRECT_REQUEST_NO_SICKNESS,
	button1 = ACCEPT,
	button1DisableTooltipTitle = CANNOT_RESURRECT,
	button2 = DECLINE,
	OnShow = function(self)
		self.timeleft = GetCorpseRecoveryDelay() + 60;
	end,
	OnAccept = function(self)
		AcceptResurrect();
	end,
	OnCancel = function(self)
		DeclineResurrect();
		if ( UnitIsDead("player") and not UnitIsControlling("player") ) then
			StaticPopup_Show("DEATH");
		end
	end,
	OnUpdate = function(self)
		if GetCorpseRecoveryDelay() > 0 then
			self.button1:Disable();
		else
			self.button1:Enable();
		end
	end,
	timeout = 60,
	whileDead = 1,
	cancels = "DEATH",
	interruptCinematic = 1,
	notClosableByLogout = 1,
	hideOnEscape = 1,
	noCancelOnReuse = 1
};
StaticPopupDialogs["SKINNED"] = {
	text = DEATH_CORPSE_SKINNED,
	button1 = ACCEPT,
	timeout = 0,
	whileDead = 1,
	interruptCinematic = 1,
	notClosableByLogout = 1,	
};
StaticPopupDialogs["SKINNED_REPOP"] = {
	text = DEATH_CORPSE_SKINNED,
	button1 = DEATH_RELEASE,	
	button2 = DECLINE,
	OnAccept = function(self)
		StaticPopup_Hide("RESURRECT");
		StaticPopup_Hide("RESURRECT_NO_SICKNESS");
		StaticPopup_Hide("RESURRECT_NO_TIMER");
		RepopMe();
	end,
	timeout = 0,
	whileDead = 1,
	interruptCinematic = 1,
	notClosableByLogout = 1,
	hideOnEscape = 1	
};
StaticPopupDialogs["TRADE"] = {
	text = TRADE_WITH_QUESTION,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		BeginTrade();
	end,
	OnCancel = function(self)
		CancelTrade();
	end,
	timeout = 60,
	hideOnEscape = 1
};
StaticPopupDialogs["PARTY_INVITE"] = {
	text = INVITATION,
	button1 = ACCEPT,
	button2 = DECLINE,
	sound = "igPlayerInvite",
	OnShow = function(self)
		self.inviteAccepted = nil;
	end,
	OnAccept = function(self)
		AcceptGroup();
		self.inviteAccepted = 1;
	end,
	OnCancel = function(self)
		DeclineGroup();
	end,
	OnHide = function(self)
		if ( not self.inviteAccepted ) then
			DeclineGroup();
			self:Hide();
		end
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["REQUESTED_INVITE"] = {
	text = REQUESTED_INVITATION,
	button1 = ACCEPT,
	button2 = DECLINE,
	sound = "igPlayerInvite",
	OnAccept = function(self, unit)
		InviteUnit(unit);
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1,
};
StaticPopupDialogs["REQUESTED_GROUP_FINDER_INVITE"] = {
	text = REQUESTED_GROUP_FINDER_INVITATION,
	button1 = ACCEPT,
	button2 = DECLINE,
	sound = "igPlayerInvite",
	OnAccept = function(self, unit)
		InviteUnit(unit);
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1,
};
StaticPopupDialogs["SUGGESTED_INVITE"] = {
	text = SUGGESTED_INVITATION,
	button1 = ACCEPT,
	button2 = DECLINE,
	sound = "igPlayerInvite",
	OnAccept = function(self, unit)
		InviteUnit(unit);
		self.inviteAccepted = 1;
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1
};
StaticPopupDialogs["GUILD_INVITE"] = {
	text = GUILD_INVITATION,
	button1 = ACCEPT,
	button2 = DECLINE,
	OnAccept = function(self)
		AcceptGuild();
	end,
	OnCancel = function(self)
		DeclineGuild();
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["CHAT_CHANNEL_INVITE"] = {
	text = CHAT_INVITE_NOTICE_POPUP,
	button1 = ACCEPT,
	button2 = DECLINE,
	sound = "igPlayerInvite",
	OnShow = function(self)
		StaticPopupDialogs["CHAT_CHANNEL_INVITE"].inviteAccepted = nil;
	end,
	OnAccept = function(self, data)
		local name = data;
		local zoneChannel, channelName = JoinPermanentChannel(name, nil, DEFAULT_CHAT_FRAME:GetID(), 1);
		if ( channelName ) then
			name = channelName;
		end
		if ( not zoneChannel ) then
			return;
		end

		local i = 1;
		while ( DEFAULT_CHAT_FRAME.channelList[i] ) do
			i = i + 1;
		end
		DEFAULT_CHAT_FRAME.channelList[i] = name;
		DEFAULT_CHAT_FRAME.zoneChannelList[i] = zoneChannel;	
	end,
	EditBoxOnEnterPressed = function(self, data)
		local name = data;
		local zoneChannel, channelName = JoinPermanentChannel(name, nil, DEFAULT_CHAT_FRAME:GetID(), 1);
		if ( channelName ) then
			name = channelName;
		end
		if ( not zoneChannel ) then
			return;
		end

		local i = 1;
		while ( DEFAULT_CHAT_FRAME.channelList[i] ) do
			i = i + 1;
		end
		DEFAULT_CHAT_FRAME.channelList[i] = name;
		DEFAULT_CHAT_FRAME.zoneChannelList[i] = zoneChannel;	
		StaticPopupDialogs["CHAT_CHANNEL_INVITE"].inviteAccepted = 1;
		self:GetParent():Hide();
	end,
	EditBoxOnEscapePressed = function(self, data)
		self:GetParent():Hide();
	end,
	OnHide = function(self, data)
		local name = data;
		DeclineInvite(name);
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["LEVEL_GRANT_PROPOSED"] = {
	text = LEVEL_GRANT,
	button1 = ACCEPT,
	button2 = DECLINE,
	sound = "igPlayerInvite",
	OnAccept = function(self)
		AcceptLevelGrant();
	end,
	OnCancel = function(self)
		DeclineLevelGrant();
	end,
	OnHide = function()
		DeclineLevelGrant();
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1
};

function ChatChannelPasswordHandler(self, data)
	local password = _G[self:GetName().."EditBox"]:GetText();
	local name = data;
	local zoneChannel, channelName = JoinPermanentChannel(name, password, DEFAULT_CHAT_FRAME:GetID(), 1);
	if ( channelName ) then
		name = channelName;
	end
	if ( not zoneChannel ) then
		return;
	end

	local i = 1;
	while ( DEFAULT_CHAT_FRAME.channelList[i] ) do
		i = i + 1;
	end
	DEFAULT_CHAT_FRAME.channelList[i] = name;
	DEFAULT_CHAT_FRAME.zoneChannelList[i] = zoneChannel;	
	StaticPopupDialogs["CHAT_CHANNEL_INVITE"].inviteAccepted = 1;
end

StaticPopupDialogs["CHAT_CHANNEL_PASSWORD"] = {
	text = CHAT_PASSWORD_NOTICE_POPUP,
	hasEditBox = 1,
	maxLetters = 31,
	button1 = OKAY,
	button2 = CANCEL,
	sound = "igPlayerInvite",
	OnAccept = function(self, data)
		ChatChannelPasswordHandler(self, data);
	end,
	EditBoxOnEnterPressed = function(self, data)
		ChatChannelPasswordHandler(self:GetParent(), data);
		self:GetParent():Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["ARENA_TEAM_INVITE"] = {
	text = ARENA_TEAM_INVITATION,
	button1 = ACCEPT,
	button2 = DECLINE,
	OnAccept = function(self)
		AcceptArenaTeam();
	end,
	OnCancel = function(self)
		DeclineArenaTeam();
	end,
	timeout = 60,
	whileDead = 1,
	hideOnEscape = 1
};


StaticPopupDialogs["CAMP"] = {
	text = CAMP_TIMER,
	button1 = CANCEL,
	--button2 = CAMP_NOW,
	OnAccept = function(self)
		CancelLogout();
		--ForceLogout();
		-- uncomment the next line once forced logouts are completely implemented (they currently have a failure case)
		-- this.timeleft = 0;
	end,
	OnHide = function(self)
		if ( self.timeleft > 0 ) then
			CancelLogout();
			self:Hide();
		end
	end,
	timeout = 20,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["QUIT"] = {
	text = QUIT_TIMER,
	button1 = QUIT_NOW,
	button2 = CANCEL,
	OnAccept = function(self)
		ForceQuit();
		self.timeleft = 0;
	end,
	OnHide = function(self)
		if ( self.timeleft > 0 ) then
			CancelLogout();
			self:Hide();
		end
	end,
	timeout = 20,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["LOOT_BIND"] = {
	text = LOOT_NO_DROP,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self, slot)
		ConfirmLootSlot(slot);
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["EQUIP_BIND"] = {
	text = EQUIP_NO_DROP,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self, slot)
		EquipPendingItem(slot);
	end,
	OnCancel = function(self, slot)
		CancelPendingEquip(slot);
	end,
	OnHide = function(self, slot)
		CancelPendingEquip(slot);
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["AUTOEQUIP_BIND"] = {
	text = EQUIP_NO_DROP,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self, slot)
		EquipPendingItem(slot);
	end,
	OnCancel = function(self, slot)
		CancelPendingEquip(slot);
	end,
	OnHide = function(self, slot)
		CancelPendingEquip(slot);
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["USE_BIND"] = {
	text = USE_NO_DROP,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self)
		ConfirmBindOnUse();
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["DELETE_ITEM"] = {
	text = DELETE_ITEM,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		DeleteCursorItem();
	end,
	OnCancel = function (self)
		ClearCursor();
	end,
	OnUpdate = function (self)
		if ( not CursorHasItem() ) then
			self:Hide();
		end
	end,
	OnHide = function()
		MerchantFrame_ResetRefundItem();
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["DELETE_GOOD_ITEM"] = {
	text = DELETE_GOOD_ITEM,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		DeleteCursorItem();
	end,
	OnCancel = function (self)
		ClearCursor();
	end,
	OnUpdate = function (self)
		if ( not CursorHasItem() ) then
			self:Hide();
		end
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1,
	hasEditBox = 1,
	maxLetters = 32,
	OnShow = function(self)
		self.button1:Disable();
		self.button2:Enable();
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
		MerchantFrame_ResetRefundItem();
	end,
	EditBoxOnEnterPressed = function(self)
		if ( self:GetParent().button1:IsEnabled() == 1 ) then
			DeleteCursorItem();
			self:GetParent():Hide();
		end
	end,
	EditBoxOnTextChanged = function (self)
		local parent = self:GetParent();
		if ( strupper(parent.editBox:GetText()) ==  DELETE_ITEM_CONFIRM_STRING ) then
			parent.button1:Enable();
		else
			parent.button1:Disable();
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
		ClearCursor();
	end
};
StaticPopupDialogs["QUEST_ACCEPT"] = {
	text = QUEST_ACCEPT,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		ConfirmAcceptQuest();
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["QUEST_ACCEPT_LOG_FULL"] = {
	text = QUEST_ACCEPT_LOG_FULL,
	button1 = YES,
	button2 = NO,
	OnShow = function(self)
		self.button1:Disable();
	end,
	OnAccept = function(self)
		ConfirmAcceptQuest();
	end,
	timeout = 0,
	hideOnEscape = 1
};
StaticPopupDialogs["ABANDON_PET"] = {
	text = ABANDON_PET,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self)
		PetAbandon();
	end,
	OnUpdate = function(self, elapsed)
		if ( not UnitExists("pet") ) then
			self:Hide();
		end
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["ABANDON_QUEST"] = {
	text = ABANDON_QUEST_CONFIRM,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		AbandonQuest();
		if ( QuestLogDetailFrame:IsShown() ) then
			HideUIPanel(QuestLogDetailFrame);
		end
		PlaySound("igQuestLogAbandonQuest");		
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["ABANDON_QUEST_WITH_ITEMS"] = {
	text = ABANDON_QUEST_CONFIRM_WITH_ITEMS,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		AbandonQuest();
		if ( QuestLogDetailFrame:IsShown() ) then
			HideUIPanel(QuestLogDetailFrame);
		end
		PlaySound("igQuestLogAbandonQuest");		
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["ADD_FRIEND"] = {
	text = ADD_FRIEND_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	autoCompleteParams = AUTOCOMPLETE_LIST.ADDFRIEND,
	maxLetters = 12 + 1 + 64,
	OnAccept = function(self)
		AddFriend(self.editBox:GetText());
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		AddFriend(parent.editBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["SET_FRIENDNOTE"] = {
	text = SET_FRIENDNOTE_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 48,
	hasWideEditBox = 1,
	OnAccept = function(self)
		SetFriendNotes(FriendsFrame.NotesID, self.wideEditBox:GetText());
	end,
	OnShow = function(self)
		local name, level, class, area, connected, status, note = GetFriendInfo(FriendsFrame.NotesID);
		if ( note ) then
			self.wideEditBox:SetText(note);
		end
		self.wideEditBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.wideEditBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		SetFriendNotes(FriendsFrame.NotesID, parent.wideEditBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["SET_BNFRIENDNOTE"] = {
	text = SET_FRIENDNOTE_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 127,
	hasWideEditBox = 1,
	OnAccept = function(self)
		BNSetFriendNote(FriendsFrame.NotesID, self.wideEditBox:GetText());
	end,
	OnShow = function(self)
		local presenceID, givenName, surname, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText = BNGetFriendInfoByID(FriendsFrame.NotesID);
		if ( noteText ) then
			self.wideEditBox:SetText(noteText);
		end
		self.wideEditBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.wideEditBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		BNSetFriendNote(FriendsFrame.NotesID, parent.wideEditBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["ADD_IGNORE"] = {
	text = ADD_IGNORE_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 12 + 1 + 64, --name space realm (77 max)
	OnAccept = function(self)
		AddIgnore(self.editBox:GetText());
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		AddIgnore(parent.editBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["ADD_MUTE"] = {
	text = ADD_MUTE_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 12,
	OnAccept = function(self)
		AddMute(self.editBox:GetText());
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		AddMute(parent.editBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["ADD_TEAMMEMBER"] = {
	text = ADD_TEAMMEMBER_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	autoCompleteParams = AUTOCOMPLETE_LIST.TEAM_INVITE,
	maxLetters = 12,
	OnAccept = function(self)
		ArenaTeamInviteByName(PVPTeamDetails.team, self.editBox:GetText());
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		ArenaTeamInviteByName(PVPTeamDetails.team, parent.editBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["ADD_GUILDMEMBER"] = {
	text = ADD_GUILDMEMBER_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	autoCompleteParams = AUTOCOMPLETE_LIST.GUILD_INVITE,
	maxLetters = 12,
	OnAccept = function(self)
		GuildInvite(self.editBox:GetText());
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		GuildInvite(parent.editBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["ADD_RAIDMEMBER"] = {
	text = ADD_RAIDMEMBER_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	autoCompleteParams = AUTOCOMPLETE_LIST.INVITE,
	maxLetters = 12,
	OnAccept = function(self)
		InviteUnit(self.editBox:GetText());
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		InviteUnit(parent.editBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["REMOVE_GUILDMEMBER"] = {
	text = format(REMOVE_GUILDMEMBER_LABEL, "XXX"),
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		GuildUninvite(GuildFrame.selectedName);
		GuildMemberDetailFrame:Hide();
	end,
	OnShow = function(self)
		self.text:SetFormattedText(REMOVE_GUILDMEMBER_LABEL, GuildFrame.selectedName);
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["ADD_GUILDRANK"] = {
	text = ADD_GUILDRANK_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 15,
	OnAccept = function(self)
		GuildControlAddRank(self.editBox:GetText());
		UIDropDownMenu_Initialize(GuildControlPopupFrameDropDown, GuildControlPopupFrameDropDown_Initialize);
		GuildControlSetRank(UIDropDownMenu_GetSelectedID(GuildControlPopupFrameDropDown));
		UIDropDownMenu_SetSelectedID(GuildControlPopupFrameDropDown, UIDropDownMenu_GetSelectedID(GuildControlPopupFrameDropDown));
		GuildControlPopupFrameEditBox:SetText(GuildControlGetRankName(UIDropDownMenu_GetSelectedID(GuildControlPopupFrameDropDown)));
		GuildControlCheckboxUpdate(GuildControlGetRankFlags());
		CloseDropDownMenus();
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		GuildControlAddRank(parent.editBox:GetText());
		UIDropDownMenu_Initialize(GuildControlPopupFrameDropDown, GuildControlPopupFrameDropDown_Initialize);
		GuildControlSetRank(UIDropDownMenu_GetSelectedID(GuildControlPopupFrameDropDown));
		UIDropDownMenu_SetSelectedID(GuildControlPopupFrameDropDown, UIDropDownMenu_GetSelectedID(GuildControlPopupFrameDropDown));
		GuildControlPopupFrameEditBox:SetText(GuildControlGetRankName(UIDropDownMenu_GetSelectedID(GuildControlPopupFrameDropDown)));
		GuildControlCheckboxUpdate(GuildControlGetRankFlags());
		CloseDropDownMenus();
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["SET_GUILDMOTD"] = {
	text = SET_GUILDMOTD_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 128,
	hasWideEditBox = 1,
	OnAccept = function(self)
		GuildSetMOTD(self.wideEditBox:GetText());
	end,
	OnShow = function(self)
		self.wideEditBox:SetText(CURRENT_GUILD_MOTD);
		self.wideEditBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.wideEditBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		GuildSetMOTD(parent.wideEditBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["SET_GUILDPLAYERNOTE"] = {
	text = SET_GUILDPLAYERNOTE_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 31,
	hasWideEditBox = 1,
	OnAccept = function(self)
		GuildRosterSetPublicNote(GetGuildRosterSelection(), self.wideEditBox:GetText());
	end,
	OnShow = function(self)
		--Sets the text to the 7th return from GetGuildRosterInfo(GetGuildRosterSelection());
		self.wideEditBox:SetText(select(7, GetGuildRosterInfo(GetGuildRosterSelection())));
		self.wideEditBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.wideEditBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		GuildRosterSetPublicNote(GetGuildRosterSelection(), parent.wideEditBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["SET_GUILDOFFICERNOTE"] = {
	text = SET_GUILDOFFICERNOTE_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 31,
	hasWideEditBox = 1,
	OnAccept = function(self)
		GuildRosterSetOfficerNote(GetGuildRosterSelection(), self.wideEditBox:GetText());
	end,
	OnShow = function(self)
		local name, rank, rankIndex, level, class, zone, note, officernote, online;
		name, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(GetGuildRosterSelection());

		self.wideEditBox:SetText(select(8, GetGuildRosterInfo(GetGuildRosterSelection())));
		self.wideEditBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.wideEditBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		GuildRosterSetOfficerNote(GetGuildRosterSelection(), parent.wideEditBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["RENAME_PET"] = {
	text = PET_RENAME_LABEL,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 12,
	OnAccept = function(self)
		local text = self.editBox:GetText();
		local dialogFrame = StaticPopup_Show("PETRENAMECONFIRM", text);
		if ( dialogFrame ) then
			dialogFrame.data = text;
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		local text = parent.editBox:GetText();
		local dialogFrame = StaticPopup_Show("PETRENAMECONFIRM", text);
		if ( dialogFrame ) then
			dialogFrame.data = text;
		end
		parent:Hide();
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	OnUpdate = function(self, elapsed)
		if ( not UnitExists("pet") ) then
			self:Hide();
		end
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["DUEL_REQUESTED"] = {
	text = DUEL_REQUESTED,
	button1 = ACCEPT,
	button2 = DECLINE,
	sound = "igPlayerInvite",
	OnAccept = function(self)
		AcceptDuel();
	end,
	OnCancel = function(self)
		CancelDuel();
	end,
	timeout = 60,
	hideOnEscape = 1
};
StaticPopupDialogs["DUEL_OUTOFBOUNDS"] = {
	text = DUEL_OUTOFBOUNDS_TIMER,
	timeout = 10,
};
StaticPopupDialogs["UNLEARN_SKILL"] = {
	text = UNLEARN_SKILL,
	button1 = UNLEARN,
	button2 = CANCEL,
	OnAccept = function(self, index)
		AbandonSkill(index);
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["UNLEARN_SKILLID"] = {
	text = UNLEARN_SKILL,
	button1 = UNLEARN,
	button2 = CANCEL,
	OnAccept = function(self, skillID)
		AbandonSkillID(skillID);
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["XP_LOSS"] = {
	text = CONFIRM_XP_LOSS,
	button1 = ACCEPT,
	button1DisableTooltipTitle = CANNOT_RESURRECT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		if ( data ) then
			self.text:SetFormattedText(CONFIRM_XP_LOSS_AGAIN, data);
			self.data = nil;
			return 1;
		else
			AcceptXPLoss();
		end
	end,
	OnUpdate = function(self, elapsed)
		if ( not CheckSpiritHealerDist() ) then
			self:Hide();
			CloseGossip();
			return
		end
	end,
	OnCancel = function(self)
		CloseGossip();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["XP_LOSS_NO_DURABILITY"] = {
	text = CONFIRM_XP_LOSS_NO_DURABILITY,
	button1 = ACCEPT,
	button1DisableTooltipTitle = CANNOT_RESURRECT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		if ( data ) then
			self.text:SetFormattedText(CONFIRM_XP_LOSS_AGAIN_NO_DURABILITY, data);
			self.data = nil;
			return 1;
		else
			AcceptXPLoss();
		end
	end,
	OnUpdate = function(self, elapsed)
		if ( not CheckSpiritHealerDist() ) then
			self:Hide();
			CloseGossip();
			return
		end
	end,
	OnCancel = function(self)
		CloseGossip();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["XP_LOSS_NO_SICKNESS"] = {
	text = CONFIRM_XP_LOSS_NO_SICKNESS,
	button1 = ACCEPT,
	button1DisableTooltipTitle = CANNOT_RESURRECT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		if ( data ) then
			self.text:SetText(CONFIRM_XP_LOSS_AGAIN_NO_SICKNESS);
			self.data = nil;
			return 1;
		else
			AcceptXPLoss();
		end
	end,
	OnUpdate = function(self, dialog)
		if ( not CheckSpiritHealerDist() ) then
			self:Hide();
			CloseGossip();
			return
		end
	end,
	OnCancel = function(self)
		CloseGossip();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["XP_LOSS_NO_SICKNESS_NO_DURABILITY"] = {
	text = CONFIRM_XP_LOSS_NO_SICKNESS_NO_DURABILITY,
	button1 = ACCEPT,
	button1DisableTooltipTitle = CANNOT_RESURRECT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		AcceptXPLoss();
	end,
	OnUpdate = function(self, dialog)
		if ( not CheckSpiritHealerDist() ) then
			self:Hide();
			CloseGossip();
			return
		end
	end,
	OnCancel = function(self)
		CloseGossip();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["RECOVER_CORPSE"] = {
	StartDelay = GetCorpseRecoveryDelay,
	delayText = RECOVER_CORPSE_TIMER,
	text = RECOVER_CORPSE,
	button1 = ACCEPT,
	button1DisableTooltipTitle = CANNOT_RESURRECT,
	OnAccept = function(self)
		RetrieveCorpse();
		return 1;
	end,
	timeout = 0,
	whileDead = 1,
	interruptCinematic = 1,
	notClosableByLogout = 1
};
StaticPopupDialogs["RECOVER_CORPSE_INSTANCE"] = {
	text = RECOVER_CORPSE_INSTANCE,
	timeout = 0,
	whileDead = 1,
	interruptCinematic = 1,
	notClosableByLogout = 1
};

StaticPopupDialogs["AREA_SPIRIT_HEAL"] = {
	text = AREA_SPIRIT_HEAL,
	button1 = CANCEL,
	OnShow = function(self)
		self.timeleft = GetAreaSpiritHealerTime();
	end,
	OnAccept = function(self)
		CancelAreaSpiritHeal();
	end,
	timeout = 0,
	whileDead = 1,
	interruptCinematic = 1,
	notClosableByLogout = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["BIND_ENCHANT"] = {
	text = BIND_ENCHANT,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self)
		BindEnchant();
	end,
	timeout = 0,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["REPLACE_ENCHANT"] = {
	text = REPLACE_ENCHANT,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		ReplaceEnchant();
	end,
	timeout = 0,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["TRADE_REPLACE_ENCHANT"] = {
	text = REPLACE_ENCHANT,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		ReplaceTradeEnchant();
	end,
	timeout = 0,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["TRADE_POTENTIAL_BIND_ENCHANT"] = {
	text = TRADE_POTENTIAL_BIND_ENCHANT,
	button1 = OKAY,
	button2 = CANCEL,
	OnShow = function(self)
		TradeFrameTradeButton:Disable();
	end,
	OnHide = function(self)
		TradeFrameTradeButton_SetToEnabledState();
	end,
	OnCancel = function(self)
		ClickTradeButton(TRADE_ENCHANT_SLOT, true);
	end,
	timeout = 0,
	showAlert = 1,
	hideOnEscape = 1,
	noCancelOnReuse = 1
};
StaticPopupDialogs["END_REFUND"] = {
	text = END_REFUND,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self)
		EndRefund(self.data);
	end,
	timeout = 0,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1,
};
StaticPopupDialogs["END_BOUND_TRADEABLE"] = {
	text = END_BOUND_TRADEABLE,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self)
		EndBoundTradeable(self.data);
	end,
	timeout = 0,
	exclusive = 1,
	showAlert = 1,
	hideOnEscape = 1,
};
StaticPopupDialogs["INSTANCE_BOOT"] = {
	text = INSTANCE_BOOT_TIMER,
	OnShow = function(self)
		self.timeleft = GetInstanceBootTimeRemaining();
		if ( self.timeleft <= 0 ) then
			self:Hide();
		end
	end,
	timeout = 0,
	whileDead = 1,
	interruptCinematic = 1,
	notClosableByLogout = 1
};

StaticPopupDialogs["INSTANCE_LOCK"] = {
	-- we use a custom timer called lockTimeleft in here to avoid special casing the static popup code
	-- if you use timeout or timeleft then you will go through the StaticPopup system's standard OnUpdate
	-- code which we don't want for this dialog
	text = INSTANCE_LOCK_TIMER,
	button1 = ACCEPT,
	button2 = INSTANCE_LEAVE,
	OnShow = function(self)
		local lockTimeleft, isPreviousInstance = GetInstanceLockTimeRemaining();
		if ( lockTimeleft <= 0 ) then
			self:Hide();
			return;
		end
		self.lockTimeleft = lockTimeleft;
		self.isPreviousInstance = isPreviousInstance;

		local type, difficulty;
		self.name, type, difficulty, self.difficultyName = GetInstanceInfo();

		self.extraFrame:SetAllPoints(self.text)
		self.extraFrame:Show()
		self.extraFrame:SetScript("OnEnter", InstanceLock_OnEnter)
		self.extraFrame:SetScript("OnLeave", GameTooltip_Hide)
		
	end,
	OnHide = function(self)
		self.extraFrame:SetScript("OnEnter", nil)
		self.extraFrame:SetScript("OnLeave", nil)
	end,
	OnUpdate = function(self, elapsed)
		local lockTimeleft = self.lockTimeleft - elapsed;
		if ( lockTimeleft <= 0 ) then
			local OnCancel = StaticPopupDialogs["INSTANCE_LOCK"].OnCancel;
			if ( OnCancel ) then
				OnCancel(self, nil, "timeout");
			end
			self:Hide();
			return;
		end
		self.lockTimeleft = lockTimeleft;

		local name = GetDungeonNameWithDifficulty(self.name, self.difficultyName);

		-- Set dialog message using information that describes which bosses are still around
		local text = _G[self:GetName().."Text"];
		local lockstring = string.format((self.isPreviousInstance and INSTANCE_LOCK_TIMER_PREVIOUSLY_SAVED or INSTANCE_LOCK_TIMER), name, SecondsToTime(ceil(lockTimeleft), nil, 1));
		local time, extending;
		time, extending, self.extraFrame.encountersTotal, self.extraFrame.encountersComplete = GetInstanceLockTimeRemaining();
		local bosses = string.format(BOSSES_KILLED, self.extraFrame.encountersComplete, self.extraFrame.encountersTotal);
		text:SetFormattedText(INSTANCE_LOCK_SEPARATOR, lockstring, bosses);

		-- make sure the dialog fits the text
		StaticPopup_Resize(self, "INSTANCE_LOCK");
	end,
	OnAccept = function(self)
		RespondInstanceLock(true);
		self.name, self.difficultyName = nil, nil;
		self.lockTimeleft = nil;
	end,
	OnCancel = function(self, data, reason)
		if ( reason == "timeout" ) then
			self:Hide();
			return;
		end
		RespondInstanceLock(false);
		self.name, self.difficultyName = nil, nil;
		self.lockTimeleft = nil;
	end,
	timeout = 0,
	showAlert = 1,
	whileDead = 1,
	interruptCinematic = 1,
	notClosableByLogout = 1,
	noCancelOnReuse = 1,
};

StaticPopupDialogs["CONFIRM_TALENT_WIPE"] = {
	text = CONFIRM_TALENT_WIPE,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		ConfirmTalentWipe();
	end,
	OnUpdate = function(self, elapsed)
		if ( not CheckTalentMasterDist() ) then
			self:Hide();
		end
	end,
	OnCancel = function(self)
		if ( PlayerTalentFrame ) then
			HideUIPanel(PlayerTalentFrame);
		end
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	hideOnEscape = 1
};
StaticPopupDialogs["CONFIRM_BINDER"] = {
	text = CONFIRM_BINDER,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		ConfirmBinder();
	end,
	OnUpdate = function(self, elapsed)
		if ( not CheckBinderDist() ) then
			self:Hide();
		end
	end,
	timeout = 0,
	hideOnEscape = 1
};
StaticPopupDialogs["CONFIRM_SUMMON"] = {
	text = CONFIRM_SUMMON;
	button1 = ACCEPT,
	button2 = CANCEL,
	OnShow = function(self)
		self.timeleft = GetSummonConfirmTimeLeft();
	end,
	OnAccept = function(self)
		ConfirmSummon();
	end,
	OnCancel = function()
		CancelSummon();
	end,
	OnUpdate = function(self, elapsed)
		if ( UnitAffectingCombat("player") or (not PlayerCanTeleport()) ) then
			self.button1:Disable();
		else
			self.button1:Enable();
		end
	end,
	timeout = 0,
	interruptCinematic = 1,
	notClosableByLogout = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["BILLING_NAG"] = {
	text = BILLING_NAG_DIALOG;
	button1 = OKAY,
	timeout = 0,
	showAlert = 1
};
StaticPopupDialogs["IGR_BILLING_NAG"] = {
	text = IGR_BILLING_NAG_DIALOG;
	button1 = OKAY,
	timeout = 0,
	showAlert = 1
};
StaticPopupDialogs["CONFIRM_LOOT_ROLL"] = {
	text = LOOT_NO_DROP,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self, id, rollType)
		ConfirmLootRoll(id, rollType);
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["GOSSIP_CONFIRM"] = {
	text = "%s",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		SelectGossipOption(data, "", true);
	end,
	hasMoneyFrame = 1,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["GOSSIP_ENTER_CODE"] = {
	text = ENTER_CODE,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = function(self, data)
		SelectGossipOption(data, self.editBox:GetText(), true);
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self, data)
		local parent = self:GetParent();
		SelectGossipOption(data, parent.editBox:GetText(), true);
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CREATE_COMBAT_FILTER"] = {
	text = ENTER_FILTER_NAME,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = 1,
	hasEditBox = 1,
	maxLetters = 32,
	OnAccept = function(self)
		CombatConfig_CreateCombatFilter(self.editBox:GetText());
	end,
	timeout = 0,
	EditBoxOnEnterPressed = function(self, data)
		local parent = self:GetParent();
		CombatConfig_CreateCombatFilter(parent.editBox:GetText());
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function (self)
		self:GetParent():Hide();
	end,
	OnHide = function (self)
		self.editBox:SetText("");
	end,
	hideOnEscape = 1
};
StaticPopupDialogs["COPY_COMBAT_FILTER"] = {
	text = ENTER_FILTER_NAME,
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = 1,
	hasEditBox = 1,
	maxLetters = 32,
	OnAccept = function(self)
		CombatConfig_CreateCombatFilter(self.editBox:GetText(), self.data);
	end,
	timeout = 0,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		CombatConfig_CreateCombatFilter(parent.editBox:GetText(), parent.data);
		parent:Hide();
	end,
	EditBoxOnEscapePressed = function (self)
		self:GetParent():Hide();
	end,
	OnHide = function (self)
		self.editBox:SetText("");
	end,
	hideOnEscape = 1
};
StaticPopupDialogs["CONFIRM_COMBAT_FILTER_DELETE"] = {
	text = CONFIRM_COMBAT_FILTER_DELETE,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self)
		CombatConfig_DeleteCurrentCombatFilter();
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	hideOnEscape = 1
};
StaticPopupDialogs["CONFIRM_COMBAT_FILTER_DEFAULTS"] = {
	text = CONFIRM_COMBAT_FILTER_DEFAULTS,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self)
		CombatConfig_SetCombatFiltersToDefault();
	end,
	timeout = 0,
	whileDead = 1,
	exclusive = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["WOW_MOUSE_NOT_FOUND"] = {
	text = WOW_MOUSE_NOT_FOUND,
	button1 = OKAY,
	OnHide = function(self)
		SetCVar("enableWoWMouse", "0");	
		if ( InterfaceOptionsFrame:IsShown() ) then
			InterfaceOptionsMousePanelWoWMouse:Click();
		end
	end,
	timeout = 0,
	whileDead = 1,
	showAlert = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_TEAM_DISBAND"] = {
	text = CONFIRM_TEAM_DISBAND,
	button1 = YES,
	button2 = NO,
	OnAccept = function (self)
		ArenaTeamDisband(self.data);
	end,
	OnCancel = function (self)
	end,
	hideOnEscape = 1,
	timeout = 0,
	whileDead = 1,
};

StaticPopupDialogs["CONFIRM_BUY_STABLE_SLOT"] = {
	text = CONFIRM_BUY_STABLE_SLOT,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		BuyStableSlot();
	end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, GetNextStableSlotCost());
	end,
	timeout = 0,
	hideOnEscape = 1,
	hasMoneyFrame = 1,
};

StaticPopupDialogs["TALENTS_INVOLUNTARILY_RESET"] = {
	text = TALENTS_INVOLUNTARILY_RESET,
	button1 = OKAY,
	timeout = 0,
};

StaticPopupDialogs["TALENTS_INVOLUNTARILY_RESET_PET"] = {
	text = TALENTS_INVOLUNTARILY_RESET_PET,
	button1 = OKAY,
	timeout = 0,
};

StaticPopupDialogs["VOTE_BOOT_PLAYER"] = {
	text = VOTE_BOOT_PLAYER,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		SetLFGBootVote(true);
	end,
	OnCancel = function(self)
		SetLFGBootVote(false);
	end,
	showAlert = true,
	noCancelOnReuse = 1,
	whileDead = 1,
	interruptCinematic = 1,
	timeout = 0,
};

StaticPopupDialogs["VOTE_BOOT_REASON_REQUIRED"] = {
	text = VOTE_BOOT_REASON_REQUIRED,
	button1 = OKAY,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 64,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		UninviteUnit(parent.data, self:GetText());
		parent:Hide();
	end,
	EditBoxOnTextChanged = function(self)
		if ( strtrim(self:GetText()) == "" ) then
			self:GetParent().button1:Disable();
		else
			self:GetParent().button1:Enable();
		end
	end,
	OnShow = function(self)
		self.button1:Disable();
	end,
	OnAccept = function(self)
		UninviteUnit(self.data, self.editBox:GetText());
	end,
	timeout = 0,
	whileDead = 1,
	interruptCinematic = 1,
};

StaticPopupDialogs["LAG_SUCCESS"] = {
	text = HELPFRAME_REPORTLAG_TEXT1,
	button1 = OKAY,
	timeout = 0,
}

StaticPopupDialogs["LFG_OFFER_CONTINUE"] = {
	text = LFG_OFFER_CONTINUE,
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		PartyLFGStartBackfill();
	end,
	noCancelOnReuse = 1,
	timeout = 0,
}

StaticPopupDialogs["CONFIRM_MAIL_ITEM_UNREFUNDABLE"] = {
	text = END_REFUND,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self)
		RespondMailLockSendItem(self.data.slot, true);
	end,
	OnCancel = function(self)
		RespondMailLockSendItem(self.data.slot, false);
	end,
	timeout = 0,
	hasItemFrame = 1,
}

StaticPopupDialogs["AUCTION_HOUSE_DISABLED"] = {
	text = ERR_AUCTION_HOUSE_DISABLED,
	button1 = OKAY,
	timeout = 0,
	showAlertGear = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_BLOCK_INVITES"] = {
	text = BLOCK_INVITES_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, inviteID)
		BNSetBlocked(inviteID, true);
		BNDeclineFriendInvite(inviteID);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["BATTLENET_UNAVAILABLE"] = {
	text = BATTLENET_UNAVAILABLE_ALERT,
	button1 = OKAY,
	timeout = 0,
	showAlertGear = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["CONFIRM_BNET_REPORT"] = {
	text = "%s",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function (self)
		BNet_SendReport();
	end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
};

StaticPopupDialogs["CONFIRM_REMOVE_FRIEND"] = {
	text = REMOVE_FRIEND_CONFIRMATION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, presenceID)
		BNRemoveFriend(presenceID);
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["SKILL_CARD_REMOVAL"] = {
	text = SKILL_CARD_REMOVAL_POPUP,
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, data)
		SkillCardUtil.RemoveCardAtIndex(unpack(data))
	end,
}

StaticPopupDialogs["CONFIRM_SKILL_CARD_PURCHASE"] = {
	text = PURCHASE_SKILL_CARD_DIALOGUE,
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, data)
		dprint("C_SkillCardCollection.PurchaseSealedCard("..data..", 1)")
		C_SkillCardCollection.PurchaseSealedCard(data, 1)
	end,
}

StaticPopupDialogs["CONFIRM_SKILL_CARD_MASS_PURCHASE"] = {
	text = PURCHASE_MASS_SKILL_CARD_DIALOGUE,
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(self, func)
		func()
	end,
}

function StaticPopup_FindVisible(which, data)
	local info = StaticPopupDialogs[which];
	if ( not info ) then
		return nil;
	end
	for index = 1, STATICPOPUP_NUMDIALOGS, 1 do
		local frame = _G["StaticPopup"..index];
		if ( frame:IsShown() and (frame.which == which) and (not info.multiple or (frame.data == data)) ) then
			return frame;
		end
	end
	return nil;
end

function StaticPopup_UpdateText(which, text_arg1, text_arg2, data)
	local info = StaticPopupDialogs[which];
	if ( not info ) then
		return
	end
	local frame
	for index = 1, STATICPOPUP_NUMDIALOGS, 1 do
		local popupFrame = _G["StaticPopup"..index];
		if popupFrame:IsShown() and (popupFrame.which == which) and (not info.multiple or not data or frame.data == data) then
			frame = popupFrame
			break
		end
	end

	if not frame then
		return
	end

	local text = _G[frame:GetName().."Text"];
	if ( text_arg2 ) then
		text:SetFormattedText(info.text, text_arg1, text_arg2);
	elseif ( text_arg1 ) then
		text:SetText(info.text, text_arg1);
	else
		text:SetText(info.text);
	end

	StaticPopup_Resize(frame, which)
	return 1;
end

function StaticPopup_Resize(dialog, which)
	local info = StaticPopupDialogs[which];
	if ( not info ) then
		return nil;
	end

	local text = _G[dialog:GetName().."Text"];
	local editBox = _G[dialog:GetName().."EditBox"];
	local button1 = _G[dialog:GetName().."Button1"];
	local button2 = _G[dialog:GetName().."Button2"];
	
	local maxHeightSoFar, maxWidthSoFar = (dialog.maxHeightSoFar or 0), (dialog.maxWidthSoFar or 0);
	local width = 320;
	if info.wide or info.hasWideEditBox then
		width = math.max(width, 420)
	elseif info.editBoxWidth and info.editBoxWidth > 260 then
		width = math.max(width, info.editBoxWidth) - 260;
	elseif which == "HELP_TICKET" then
		width = math.max(width, 350);
	elseif which == "NAMEPLATE_ADDON_CONFLICT" then
		width = math.max(width, 320 + button1:GetWidth() + button2:GetWidth())
	end

	local button3 = _G[dialog:GetName().."Button3"];
	local button4 = _G[dialog:GetName().."Button4"];
	local buttons = {button1, button2, button3, button4};
	local outerMargin = 60;
	local buttonMinWidth = outerMargin;
	for index, button in ipairs(buttons) do
		if button:IsShown() then
			buttonMinWidth = buttonMinWidth + button:GetWidth();
		end
	end

	width = max(width, buttonMinWidth);

	if info.showAlert or info.showAlertGear or info.closeButton then
		width = width + 110
	end

	if ( width > maxWidthSoFar )  then
		dialog:SetWidth(width);
		dialog.maxWidthSoFar = width;
	end
	
	local height = 32 + text:GetHeight() + 8 + button1:GetHeight();
	if ( info.hasEditBox ) then
		if ( info.hasWideEditBox  ) then
			dialog.text:SetWidth(360);
		else
			dialog.text:SetWidth(290);
		end
		height = height + 8 + editBox:GetHeight();
	elseif ( info.hasMoneyFrame ) then
		height = height + 16;
	elseif ( info.hasMoneyInputFrame ) then
		height = height + 22;
	end
	if ( info.hasItemFrame ) then
		height = height + 64;
	end

	if ( height > maxHeightSoFar ) then
		dialog:SetHeight(height);
		dialog.maxHeightSoFar = height;
	end
end

function StaticPopup_Show(which, text_arg1, text_arg2, data)
	local info = StaticPopupDialogs[which];
	if ( not info ) then
		return nil;
	end

	if ( UnitIsDeadOrGhost("player") and not info.whileDead ) then
		if ( info.OnCancel ) then
			info.OnCancel();
		end
		return nil;
	end

	if ( InCinematic() and not info.interruptCinematic ) then
		if ( info.OnCancel ) then
			info.OnCancel();
		end
		return nil;
	end

	if ( info.exclusive ) then
		StaticPopup_HideExclusive();
	end

	if ( info.cancels ) then
		for index = 1, STATICPOPUP_NUMDIALOGS, 1 do
			local frame = _G["StaticPopup"..index];
			if ( frame:IsShown() and (frame.which == info.cancels) ) then
				frame:Hide();
				local OnCancel = StaticPopupDialogs[frame.which].OnCancel;
				if ( OnCancel ) then
					OnCancel(frame, frame.data, "override");
				end
			end
		end
	end

	if ( (which == "CAMP") or (which == "QUIT") ) then
		for index = 1, STATICPOPUP_NUMDIALOGS, 1 do
			local frame = _G["StaticPopup"..index];
			if ( frame:IsShown() and not StaticPopupDialogs[frame.which].notClosableByLogout ) then
				frame:Hide();
				local OnCancel = StaticPopupDialogs[frame.which].OnCancel;
				if ( OnCancel ) then
					OnCancel(frame, frame.data, "override");
				end
			end
		end
	end

	if ( which == "DEATH" ) then
		for index = 1, STATICPOPUP_NUMDIALOGS, 1 do
			local frame = _G["StaticPopup"..index];
			if ( frame:IsShown() and not StaticPopupDialogs[frame.which].whileDead ) then
				frame:Hide();
				local OnCancel = StaticPopupDialogs[frame.which].OnCancel;
				if ( OnCancel ) then
					OnCancel(frame, frame.data, "override");
				end
			end
		end
	end

	-- Pick a free dialog to use
	local dialog = nil;
	-- Find an open dialog of the requested type
	dialog = StaticPopup_FindVisible(which, data);
	if ( dialog ) then
		if ( not info.noCancelOnReuse ) then
			local OnCancel = info.OnCancel;
			if ( OnCancel ) then
				OnCancel(dialog, dialog.data, "override");
			end
		end
		dialog:Hide();
	end
	if ( not dialog ) then
		-- Find a free dialog
		local index = 1;
		if ( info.preferredIndex ) then
			index = info.preferredIndex;
		end
		for i = index, STATICPOPUP_NUMDIALOGS do
			local frame = _G["StaticPopup"..i];
			if ( not frame:IsShown() ) then
				dialog = frame;
				break;
			end
		end

		--If dialog not found and there's a preferredIndex then try to find an available frame before the preferredIndex
		if ( not dialog and info.preferredIndex ) then
			for i = 1, info.preferredIndex do
				local frame = _G["StaticPopup"..i];
				if ( not frame:IsShown() ) then
					dialog = frame;
					break;
				end
			end
		end
	end
	if ( not dialog ) then
		if ( info.OnCancel ) then
			info.OnCancel();
		end
		return nil;
	end

	dialog.maxHeightSoFar, dialog.maxWidthSoFar = 0, 0;
	-- Set the text of the dialog
	local text = _G[dialog:GetName().."Text"];
	if ( (which == "DEATH") or
			(which == "CAMP") or
			(which == "QUIT") or
			(which == "DUEL_OUTOFBOUNDS") or
			(which == "RECOVER_CORPSE") or
			(which == "RESURRECT") or
			(which == "RESURRECT_NO_SICKNESS") or
			(which == "INSTANCE_BOOT") or
			(which == "INSTANCE_LOCK") or
			(which == "CONFIRM_SUMMON") or
			(which == "BFMGR_INVITED_TO_ENTER") or
			(which == "AREA_SPIRIT_HEAL") ) then
		text:SetText(" ");	-- The text will be filled in later.
		text.text_arg1 = text_arg1;
		text.text_arg2 = text_arg2;
	elseif ( which == "BILLING_NAG" ) then
		text:SetFormattedText(info.text, text_arg1, MINUTES);
	elseif text_arg1 and text_arg2 then
		text:SetFormattedText(info.text, text_arg1, text_arg2);
	elseif text_arg1 then
		text:SetFormattedText(info.text, text_arg1)
	else
		text:SetText(info.text)
	end

	-- Show or hide the alert icon
	local alertIcon = _G[dialog:GetName().."AlertIcon"];
	if ( info.showAlert ) then
		alertIcon:SetTexture(STATICPOPUP_TEXTURE_ALERT);
	elseif ( info.showAlertGear ) then
		alertIcon:SetTexture(STATICPOPUP_TEXTURE_ALERTGEAR);
	else		
		alertIcon:SetTexture();
	end

	-- Show or hide the close button
	if ( info.closeButton ) then
		local closeButton = _G[dialog:GetName().."CloseButton"];
		closeButton:SetAttribute("disableTooltipTitle", info.closeButtonDisableTooltipTitle)
		closeButton:SetAttribute("disableTooltipText", info.closeButtonDisableTooltipText)
		closeButton:SetAttribute("TooltipTitle", info.closeButtonTooltipTitle)
		closeButton:SetAttribute("TooltipText", info.closeButtonTooltipText)
		if ( info.closeButtonIsHide ) then
			closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-HideButton-Up");
			closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-HideButton-Down");
		else
			closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
			closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
		end
		closeButton:Show();
	else
		_G[dialog:GetName().."CloseButton"]:Hide();
	end

	-- Set the editbox of the dialog
	local wideEditBox = _G[dialog:GetName().."WideEditBox"];
	local editBox = _G[dialog:GetName().."EditBox"];
	if ( info.hasEditBox ) then
		if ( info.hasWideEditBox ) then
			wideEditBox:Show();
			editBox:Hide();

			if ( info.maxLetters ) then
				wideEditBox:SetMaxLetters(info.maxLetters);
			end
			if ( info.maxBytes ) then
				wideEditBox:SetMaxBytes(info.maxBytes);
			end
			wideEditBox:SetText("");
		else
			wideEditBox:Hide();
			editBox:Show();

			if ( info.maxLetters ) then
				editBox:SetMaxLetters(info.maxLetters);
			end
			if ( info.maxBytes ) then
				editBox:SetMaxBytes(info.maxBytes);
			end
			editBox:SetText("");
		end
	else
		wideEditBox:Hide();
		editBox:Hide();
	end

	-- Show or hide money frame
	if ( info.hasMoneyFrame ) then
		_G[dialog:GetName().."MoneyFrame"]:Show();
		_G[dialog:GetName().."MoneyInputFrame"]:Hide();
	elseif ( info.hasMoneyInputFrame ) then
		_G[dialog:GetName().."MoneyInputFrame"]:Show();
		_G[dialog:GetName().."MoneyFrame"]:Hide();
		-- Set OnEnterPress for money input frames
		if ( info.EditBoxOnEnterPressed ) then
			_G[dialog:GetName().."MoneyInputFrameGold"]:SetScript("OnEnterPressed", StaticPopup_EditBoxOnEnterPressed);
			_G[dialog:GetName().."MoneyInputFrameSilver"]:SetScript("OnEnterPressed", StaticPopup_EditBoxOnEnterPressed);
			_G[dialog:GetName().."MoneyInputFrameCopper"]:SetScript("OnEnterPressed", StaticPopup_EditBoxOnEnterPressed);
		else
			_G[dialog:GetName().."MoneyInputFrameGold"]:SetScript("OnEnterPressed", nil);
			_G[dialog:GetName().."MoneyInputFrameSilver"]:SetScript("OnEnterPressed", nil);
			_G[dialog:GetName().."MoneyInputFrameCopper"]:SetScript("OnEnterPressed", nil);
		end
	else
		_G[dialog:GetName().."MoneyFrame"]:Hide();
		_G[dialog:GetName().."MoneyInputFrame"]:Hide();
	end

	-- Show or hide item button
	if ( info.hasItemFrame ) then
		_G[dialog:GetName().."ItemFrame"]:Show();
		if ( data and type(data) == "table" ) then
			_G[dialog:GetName().."ItemFrame"].link = data.link
			_G[dialog:GetName().."ItemFrameIconTexture"]:SetTexture(data.texture);
			local nameText = _G[dialog:GetName().."ItemFrameText"];
			nameText:SetTextColor(unpack(data.color or {1, 1, 1, 1}));
			nameText:SetText(data.name);
			if ( data.count and data.count > 1 ) then
				_G[dialog:GetName().."ItemFrameCount"]:SetText(data.count);
				_G[dialog:GetName().."ItemFrameCount"]:Show();
			else
				_G[dialog:GetName().."ItemFrameCount"]:Hide();
			end
		end
	else
		_G[dialog:GetName().."ItemFrame"]:Hide();
	end

	-- Set the buttons of the dialog
	local button1 = _G[dialog:GetName().."Button1"];
	local button2 = _G[dialog:GetName().."Button2"];
	local button3 = _G[dialog:GetName().."Button3"];
	local button4 = _G[dialog:GetName().."Button4"];

	-- Rewritten for Ascension because the default implementation = bad
	local tempButtons = {}
	tinsert(tempButtons, button1)
	tinsert(tempButtons, button3) -- button 3 comes before button 2 in 3.3.5
	tinsert(tempButtons, button2)
	tinsert(tempButtons, button4)

	for i = #tempButtons, 1, -1 do
		local button = tempButtons[i]
		button:SetText(info["button"..button:GetID()])
		button:Hide()
		button:ClearAllPoints()
		-- remove if we don't use this button
		if ( not (info["button"..button:GetID()] and ( not info["DisplayButton"..button:GetID()] or info["DisplayButton"..button:GetID()](dialog))) ) then
			tremove(tempButtons, i);
		end
	end

	-- now our list is just buttons we want to use
	local numButtons = #tempButtons
	dialog.numButtons = numButtons
	
	local buttonTextMargin = 20
	local minButtonWidth = 120
	local maxButtonWidth = minButtonWidth

	for index, button in ipairs(tempButtons) do
		local buttonWidth = button:GetTextWidth() + buttonTextMargin
		maxButtonWidth = max(maxButtonWidth, buttonWidth)
	end
	
	StaticPopup_Resize(dialog, which)
	
	local buttonPadding = 10
	local totalButtonPadding = buttonPadding * (numButtons - 1)
	local totalButtonWidth = maxButtonWidth * maxButtonWidth
	local totalWidth = totalButtonWidth + totalButtonPadding

	local uncondensedTotalWidth = totalButtonWidth + totalButtonPadding;

	if uncondensedTotalWidth < dialog:GetWidth() then
		for index, button in ipairs(tempButtons) do
			button:SetWidth(maxButtonWidth);
			button:Show()
		end
		totalWidth = uncondensedTotalWidth;
	else
		totalWidth = totalButtonPadding;
		for index, button in ipairs(tempButtons) do
			local buttonWidth = math.max(minButtonWidth, button:GetTextWidth()) + buttonTextMargin;
			button:SetWidth(buttonWidth);
			totalWidth = totalWidth + buttonWidth;
			button:Enable()
			button:Show()
			button:SetAttribute("disableTooltipTitle", info["button"..index.."DisableTooltipTitle"])
			button:SetAttribute("disableTooltipText", info["button"..index.."DisableTooltipText"])
			button:SetAttribute("TooltipTitle", info["button"..index.."TooltipTitle"])
			button:SetAttribute("TooltipText", info["button"..index.."TooltipText"])
		end
	end

	local offset = totalWidth / 2;
	if numButtons > 0 then
		tempButtons[1]:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", -offset, 16);
		for index = 2, #tempButtons do
			tempButtons[index]:SetPoint("BOTTOMLEFT", tempButtons[index-1], "BOTTOMRIGHT", buttonPadding, 0);
		end
	end

	table.wipe(tempButtons)
	

	-- Set the miscellaneous variables for the dialog
	dialog.which = which;
	dialog.timeleft = info.timeout or 0;
	dialog.hideOnEscape = info.hideOnEscape;
	dialog.exclusive = info.exclusive;
	dialog.enterClicksFirstButton = info.enterClicksFirstButton;
	-- Clear out data
	dialog.data = data;

	if ( info.StartDelay ) then
		dialog.startDelay = info.StartDelay();
		button1:Disable();
	else
		dialog.startDelay = nil;
		button1:Enable();
	end

	editBox.autoCompleteParams = info.autoCompleteParams;
	wideEditBox.autoCompleteParams = info.autoCompleteParams;
	
	editBox.autoCompleteRegex = info.autoCompleteRegex;
	wideEditBox.autoCompleteRegex = info.autoCompleteRegex;
	
	editBox.autoCompleteFormatRegex = info.autoCompleteFormatRegex;
	wideEditBox.autoCompleteFormatRegex = info.autoCompleteFormatRegex;
	
	editBox.addHighlightedText = true;
	wideEditBox.autoCompleteFormatRegex = true;
	
	-- Finally size and show the dialog
	StaticPopup_TriggerVisibilityEvent("UI.StaticPopup.Show", StaticPopup_GetNumVisible(dialog), dialog);
	StaticPopup_SetUpPosition(dialog);
	dialog:Show();
	
	StaticPopup_Resize(dialog, which);

	if ( info.sound ) then
		PlaySound(info.sound);
	end

	return dialog;
end

function StaticPopup_Hide(which, data)
	for index = 1, STATICPOPUP_NUMDIALOGS, 1 do
		local dialog = _G["StaticPopup"..index];
		if ( (dialog.which == which) and (not data or (data == dialog.data)) ) then
			dialog:Hide();
		end
	end
end

function StaticPopup_OnUpdate(dialog, elapsed)
	if ( dialog.timeleft > 0 ) then
		local which = dialog.which;
		local timeleft = dialog.timeleft - elapsed;
		if ( timeleft <= 0 ) then
			if ( not StaticPopupDialogs[which].timeoutInformationalOnly ) then
				dialog.timeleft = 0;
				local OnCancel = StaticPopupDialogs[which].OnCancel;
				if ( OnCancel ) then
					OnCancel(dialog, dialog.data, "timeout");
				end
				dialog:Hide();
			end
			return;
		end
		dialog.timeleft = timeleft;

		if ( (which == "DEATH") or
		     (which == "CAMP")  or
			 (which == "QUIT") or
			 (which == "DUEL_OUTOFBOUNDS") or
			 (which == "INSTANCE_BOOT") or
			 (which == "CONFIRM_SUMMON") or
			 (which == "BFMGR_INVITED_TO_ENTER") or
			 (which == "AREA_SPIRIT_HEAL") or 
			 (which == "CHALLENGES_SYNC" or which == "CHALLENGES_SYNC_REMOVE")) then
			local text = _G[dialog:GetName().."Text"];
			local hasText = nil;
			local resize = false
			if ( text:GetText() ~= " " ) then
				hasText = 1;
			end
			timeleft = ceil(timeleft);
			if ( which == "INSTANCE_BOOT" ) then
				if ( timeleft < 60 ) then
					text:SetFormattedText(StaticPopupDialogs[which].text, timeleft, SECONDS);
				else
					text:SetFormattedText(StaticPopupDialogs[which].text, ceil(timeleft / 60), MINUTES);
				end
			elseif ( which == "CONFIRM_SUMMON" ) then
				if ( timeleft < 60 ) then
					text:SetFormattedText(StaticPopupDialogs[which].text, GetSummonConfirmSummoner(), GetSummonConfirmAreaName(), timeleft, SECONDS);
				else
					text:SetFormattedText(StaticPopupDialogs[which].text, GetSummonConfirmSummoner(), GetSummonConfirmAreaName(), ceil(timeleft / 60), MINUTES);
				end
            elseif ( which == "CHALLENGES_SYNC" ) then
                local challenges = C_Challenge.GetPendingChallenges()
                local challengeString
                for _, challenge in ipairs(challenges) do
                    local challengeInfo = C_Challenge.GetChallengeInfo(challenge.ChallengeId)
                    if challengeInfo then
                        challengeString = (challengeString and challengeString .. "\n" or "\n") .. "|cffffff00[" .. challengeInfo.Name .. " (" .. challenge.Level .. ")]|r"
                    end
                end
                text:SetFormattedText(StaticPopupDialogs[which].text, challengeString or "", SecondsToTime(timeleft, false, true, 1));
				resize = true
			elseif ( which == "CHALLENGES_SYNC_REMOVE" ) then
				text:SetFormattedText(StaticPopupDialogs[which].text, SecondsToTime(timeleft, false, true, 1));
				resize = true
			else
				if ( timeleft < 60 ) then
					text:SetFormattedText(StaticPopupDialogs[which].text, timeleft, SECONDS);
				else
					text:SetFormattedText(StaticPopupDialogs[which].text, ceil(timeleft / 60), MINUTES);
				end
			end
			if ( not hasText or resize ) then
				StaticPopup_Resize(dialog, which);
			end
		end
	end
	if ( dialog.startDelay ) then
		local which = dialog.which;
		local timeleft = dialog.startDelay - elapsed;
		if ( timeleft <= 0 ) then
			dialog.startDelay = nil;
			local text = _G[dialog:GetName().."Text"];
			text:SetFormattedText(StaticPopupDialogs[which].text, text.text_arg1, text.text_arg2);
			local button1 = _G[dialog:GetName().."Button1"];
			button1:Enable();
			StaticPopup_Resize(dialog, which);
			return;
		end
		dialog.startDelay = timeleft;

		if ( which == "RECOVER_CORPSE" or (which == "RESURRECT") or (which == "RESURRECT_NO_SICKNESS") or (which == "RESURRECT_NO_TIMER") ) then
			local text = _G[dialog:GetName().."Text"];
			local hasText = nil;
			if ( text:GetText() ~= " " ) then
				hasText = 1;
			end
			timeleft = ceil(timeleft);
			if ( (which == "RESURRECT") or (which == "RESURRECT_NO_SICKNESS") or (which == "RESURRECT_NO_TIMER") ) then
				if ( timeleft < 60 ) then
					text:SetFormattedText(StaticPopupDialogs[which].delayText, text.text_arg1, timeleft, SECONDS);
				else
					text:SetFormattedText(StaticPopupDialogs[which].delayText, text.text_arg1, ceil(timeleft / 60), MINUTES);
				end
			else
				if ( timeleft < 60 ) then
					text:SetFormattedText(StaticPopupDialogs[which].delayText, timeleft, SECONDS);
				else
					text:SetFormattedText(StaticPopupDialogs[which].delayText, ceil(timeleft / 60), MINUTES);
				end
			end
			if ( not hasText ) then
				StaticPopup_Resize(dialog, which);
			end
		end
	end

	local onUpdate = StaticPopupDialogs[dialog.which].OnUpdate;
	if ( onUpdate ) then
		onUpdate(dialog, elapsed);
	end
end

function StaticPopup_EditBoxOnEnterPressed(self)
	local EditBoxOnEnterPressed, which, dialog;
	local parent = self:GetParent();
	if ( parent.which ) then
		which = parent.which;
		dialog = parent;
	elseif ( parent:GetParent().which ) then
		-- This is needed if this is a money input frame since it's nested deeper than a normal edit box
		which = parent:GetParent().which;
		dialog = parent:GetParent();
	end
	if ( not self.autoCompleteParams or not AutoCompleteEditBox_OnEnterPressed(self) ) then
		EditBoxOnEnterPressed = StaticPopupDialogs[which].EditBoxOnEnterPressed;
		if ( EditBoxOnEnterPressed ) then
			EditBoxOnEnterPressed(self, dialog.data);
		end
	end
end

function StaticPopup_EditBoxOnEscapePressed(self)
	local EditBoxOnEscapePressed = StaticPopupDialogs[self:GetParent().which].EditBoxOnEscapePressed;
	if ( EditBoxOnEscapePressed ) then
		EditBoxOnEscapePressed(self, self:GetParent().data);
	end
end

function StaticPopup_EditBoxOnTextChanged(self, userInput)
	if ( not self.autoCompleteParams or not AutoCompleteEditBox_OnTextChanged(self, userInput) ) then
		local EditBoxOnTextChanged = StaticPopupDialogs[self:GetParent().which].EditBoxOnTextChanged;
		if ( EditBoxOnTextChanged ) then
			EditBoxOnTextChanged(self, self:GetParent().data);
		end
	end
end

function StaticPopup_OnShow(self)
	PlaySound("igMainMenuOpen");

	local dialog = StaticPopupDialogs[self.which];
	local OnShow = dialog.OnShow;

	if ( OnShow ) then
		OnShow(self, self.data);
	end
	if ( dialog.hasMoneyInputFrame ) then
		_G[self:GetName().."MoneyInputFrameGold"]:SetFocus();
	end
	if ( dialog.enterClicksFirstButton ) then
		self:SetScript("OnKeyDown", StaticPopup_OnKeyDown);
	end
end

function StaticPopup_OnHide(self)
	PlaySound("igMainMenuClose");

	StaticPopup_CollapseTable();
	StaticPopup_TriggerVisibilityEvent("UI.StaticPopup.Hide", StaticPopup_GetNumVisible(), self);
	
	local dialog = StaticPopupDialogs[self.which];
	local OnHide = dialog.OnHide;
	if ( OnHide ) then
		OnHide(self, self.data);
	end
	self.extraFrame:Hide();
	if ( dialog.enterClicksFirstButton ) then
		self:SetScript("OnKeyDown", nil);
	end
end

function StaticPopup_OnClick(dialog, index)
	if ( not dialog:IsShown() ) then
		return;
	end
	local which = dialog.which;
	local info = StaticPopupDialogs[which];
	if ( not info ) then
		return nil;
	end
	local hide = true;
	if ( index == 1 ) then
		local OnAccept = info.OnAccept or info.OnButton1;
		if ( OnAccept ) then
			hide = not OnAccept(dialog, dialog.data, dialog.data2);
		end
	elseif ( index == 3 ) then
		local OnAlt = info.OnAlt or info.OnButton3;
		if ( OnAlt ) then
			hide = not OnAlt(dialog, dialog.data, "clicked");
		end
	elseif index == 4 then
		local OnButton4 = info.OnButton4
		if OnButton4 then
			hide = not OnButton4(dialog, dialog.data, "clicked")
		end
	else
		local OnCancel = info.OnCancel or info.OnButton2;
		if ( OnCancel ) then
			hide = not OnCancel(dialog, dialog.data, "clicked");
		end
	end

	if ( hide and (which == dialog.which) ) then
		-- can dialog.which change inside one of the On* functions???
		dialog:Hide();
	end
end

function StaticPopup_OnKeyDown(self, key)
	-- previously, StaticPopup_EscapePressed() captured the escape key for dialogs, but now we need
	-- to catch it here
	if ( GetBindingFromClick(key) == "TOGGLEGAMEMENU" ) then
		return StaticPopup_EscapePressed();
	elseif ( GetBindingFromClick(key) == "SCREENSHOT" ) then
		RunBinding("SCREENSHOT");
		return;
	end

	local dialog = StaticPopupDialogs[self.which];
	if ( dialog ) then
		if ( key == "ENTER" and dialog.enterClicksFirstButton ) then
			local frameName = self:GetName();
			local button;
			local i = 1;
			while ( true ) do
				button = _G[frameName.."Button"..i];
				if ( button ) then
					if ( button:IsShown() ) then
						StaticPopup_OnClick(self, i);
						return;
					end
					i = i + 1;
				else
					break;
				end
			end
		end
	end
end

function StaticPopup_Visible(which)
	for index = 1, STATICPOPUP_NUMDIALOGS, 1 do
		local frame = _G["StaticPopup"..index];
		if( frame:IsShown() and (frame.which == which) ) then 
			return frame:GetName();
		end
	end
	return nil;
end

function StaticPopup_EscapePressed()
	local closed = nil;
	for _, frame in pairs(StaticPopup_DisplayedFrames) do
		if( frame:IsShown() and frame.hideOnEscape ) then
			local standardDialog = StaticPopupDialogs[frame.which];
			if ( standardDialog ) then
				local OnCancel = standardDialog.OnCancel;
				local noCancelOnEscape = standardDialog.noCancelOnEscape;
				if ( OnCancel and not noCancelOnEscape) then
					OnCancel(frame, frame.data, "clicked");
				end
				frame:Hide();
			else
				StaticPopupSpecial_Hide(frame);
			end
			closed = 1;
		end
	end
	return closed;
end

function StaticPopup_GetLastVisible()
	local lastFrame = StaticPopup_DisplayedFrames[#StaticPopup_DisplayedFrames]

	-- wildcard and primary stat frame take same space as 1st popup window
	if not(lastFrame) then
		lastFrame = not WildCardUtil.IsRapidRolling() and WildCardUtil.GetVisibleDice()
	end

	if not(lastFrame) then
		if ForcedPrimaryStatFrame and ForcedPrimaryStatFrame:IsVisible() then
			lastFrame = ForcedPrimaryStatFrame
		end
	end

	return lastFrame
end

function StaticPopup_SetUpPosition(dialog)
	if ( not tContains(StaticPopup_DisplayedFrames, dialog) ) then
		local lastFrame = StaticPopup_GetLastVisible();
		if ( lastFrame ) then
			dialog:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0);
		else
			dialog:SetPoint("TOP", UIParent, "TOP", 0, -135);
		end
		tinsert(StaticPopup_DisplayedFrames, dialog);
	end
end

function StaticPopup_CollapseTable()
	local displayedFrames = StaticPopup_DisplayedFrames;
	local index = #displayedFrames;
	while ( ( index >= 1 ) and ( not displayedFrames[index]:IsShown() ) ) do
		tremove(displayedFrames, index);
		index = index - 1;
	end
end

function StaticPopupSpecial_Show(frame)
	if ( frame.exclusive ) then
		StaticPopup_HideExclusive();
	end
	StaticPopup_TriggerVisibilityEvent("UI.StaticPopup.Show", StaticPopup_GetNumVisible(frame), frame);
	StaticPopup_SetUpPosition(frame);
	frame:Show();
end

function StaticPopupSpecial_Hide(frame)
	frame:Hide();
	StaticPopup_CollapseTable();
	StaticPopup_TriggerVisibilityEvent("UI.StaticPopup.Hide", StaticPopup_GetNumVisible(), frame);
end

--Used to figure out if we can resize a frame
function StaticPopup_IsLastDisplayedFrame(frame)
	for i=#StaticPopup_DisplayedFrames, 1, -1 do
		local popup = StaticPopup_DisplayedFrames[i];
		if ( popup:IsShown() ) then
			return frame == popup
		end
	end
	return false;
end

function StaticPopup_OnEvent(self)
	self.maxHeightSoFar = 0;
	StaticPopup_Resize(self, self.which);
end

function StaticPopup_HideExclusive()
	for _, frame in pairs(StaticPopup_DisplayedFrames) do
		if ( frame:IsShown() and frame.exclusive ) then	
			local standardDialog = StaticPopupDialogs[frame.which];
			if ( standardDialog ) then
				frame:Hide();
				local OnCancel = standardDialog.OnCancel;
				if ( OnCancel ) then
					OnCancel(frame, frame.data, "override");
				end
			else
				StaticPopupSpecial_Hide(frame);
			end
			break;
		end
	end
end


StaticPopupDialogs["GENERIC_ERROR"] = {
	text = "",
	button1 = OKAY,
	OnAccept = function(self, callback)
		if callback and type(callback) == "function" then
			callback()
		end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

StaticPopupDialogs["GENERIC_CONFIRM"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self, data)
		if data and type(data.onAccept) == "function" then
			data.onAccept()
		end
	end,
	OnCancel = function(self, data)
		if data and type(data.onCancel) == "function" then
			data.onCancel()
		end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};


function StaticPopup_GenericError(text, arg1, arg2, callback)
	StaticPopupDialogs["GENERIC_ERROR"].text = text;
	StaticPopup_Show("GENERIC_ERROR", arg1, arg2, callback);
end

function StaticPopup_GenericConfirm(text, arg1, arg2, confirmText, cancelText, onAccept, onCancel)
	StaticPopupDialogs["GENERIC_CONFIRM"].text = text;
	StaticPopupDialogs["GENERIC_CONFIRM"].button1 = confirmText or ACCEPT;
	StaticPopupDialogs["GENERIC_CONFIRM"].button2 = cancelText or CANCEL;
	StaticPopup_Show("GENERIC_CONFIRM", arg1, arg2, { onAccept = onAccept, onCancel = onCancel });
end
