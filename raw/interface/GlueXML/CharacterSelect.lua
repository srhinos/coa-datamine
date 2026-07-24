CHARACTER_SELECT_ROTATION_START_X = nil;
CHARACTER_SELECT_INITIAL_FACING = nil;

CHARACTER_ROTATION_CONSTANT = 0.6;

MOVING_TEXT_OFFSET = 12;
DEFAULT_TEXT_OFFSET = 0;
AUTO_DRAG_TIME = 0.5;                -- in seconds

DEFAULT_MAX_CHARACTERS_PER_REALM = 10;
UI_MAX_CHARACTERS_DISPLAYED = 128;
UI_MAX_INACTIVE_CHARACTERS_DISPLAYED = 8;

GAME_MODE_DISABLE_FORMAT = {
	None             = "",
	Random           = ERR_GAME_MODE_UNAVAILABLE,
	Ironman          = ERR_GAME_MODE_UNAVAILABLE,
	Survivalist      = ERR_GAME_MODE_UNAVAILABLE,
	Draft            = ERR_GAME_MODE_DISABLED,
	Resolute         = ERR_GAME_MODE_UNAVAILABLE,
	WildCard         = ERR_GAME_MODE_DISABLED,
	Felforged        = ERR_GAME_MODE_UNAVAILABLE,
	Nightmare        = ERR_GAME_MODE_UNAVAILABLE,
	BuildDraft       = ERR_GAME_MODE_UNAVAILABLE,
	Crusader         = ERR_GAME_MODE_UNAVAILABLE,
	FreepickRarities = ERR_GAME_MODE_DISABLED,
}

local translationTable = {}

local function CharacterSelect_GetDisplayMax()
	local maxCount = 0;
	if CharacterSelect and CharacterSelect.characterListMax and CharacterSelect.characterListMax > 0 then
		maxCount = CharacterSelect.characterListMax;
	else
		maxCount = DEFAULT_MAX_CHARACTERS_PER_REALM;
	end

	if maxCount < 1 then
		maxCount = 1;
	end

	return math.min(maxCount, UI_MAX_CHARACTERS_DISPLAYED);
end

local function CharacterSelect_CanCreateCharacter()
	local _, maxCount, activeChars = CharacterSelect_GetTotalCharacterCount();
	if not activeChars or not maxCount then
		return false;
	end
	return activeChars < maxCount;
end

local function CharacterSelect_GetRowHeight()
	-- Row height includes the padding that used to be created by manual spacing between buttons.
	-- It must also be tall enough to fit the game mode line (the 4th row of text) so it stays
	-- within the selection highlight bounds.
	return 86;
end

local function CharacterSelect_GetListCount()
	if CharacterSelect and CharacterSelect.viewingInactiveList then
		return #(CharacterSelect.inactiveCharacters or {});
	end
	return GetNumCharacters();
end

local function CharacterSelect_GetCharacterListEntry(charId, name)
	if not C_CharacterList or not C_CharacterList.GetEntries then
		return nil;
	end

	for _, entry in ipairs(C_CharacterList.GetEntries()) do
		if entry and entry.active ~= false then
			if (charId and (entry.id == charId or entry.characterId == charId or entry.guid == charId or entry.index == charId))
				or (name and entry.name == name) then
				return entry;
			end
		end
	end
end

local function CharacterSelect_IsTruthy(value)
	return value ~= nil and value ~= false and value ~= 0 and value ~= "0";
end

local function CharacterSelect_GetServiceFlag(entry, ...)
	if not entry then
		return nil;
	end

	local containers = { entry, entry.services, entry.paidServices };
	local lookupKeys = {};
	for i = 1, select("#", ...) do
		local key = select(i, ...);
		if key then
			lookupKeys[#lookupKeys + 1] = key;
		end
	end

	for _, container in ipairs(containers) do
		if container then
			for _, key in ipairs(lookupKeys) do
				if container[key] ~= nil then
					return container[key];
				end
			end
		end
	end

	for _, container in ipairs(containers) do
		if container then
			for key, value in pairs(container) do
				if type(key) == "string" then
					local lowerKey = key:lower();
					for _, target in ipairs(lookupKeys) do
						if lowerKey == tostring(target):lower() then
							return value;
						end
					end
				end
			end
		end
	end

	return nil;
end

CharacterSelectListItemMixin = CreateFromMixins(ScrollListItemBaseMixin);

function CharacterSelectListItemMixin:Init(...)
	ScrollListItemBaseMixin.Init(self, ...);
	self.baseHeight = CharacterSelect_GetRowHeight();
	self:SetHeight(self.baseHeight);

	-- Content is a VerticalLayoutFrame; layoutIndex determines the top-to-bottom order of the text
	-- rows. Set it directly as a field (the layout system reads region.layoutIndex) so it does not
	-- depend on region attribute parsing.
	local content = self.Content;
	content.Name.layoutIndex = 1;
	content.Info.layoutIndex = 2;
	content.Location.layoutIndex = 3;
	content.GameMode.layoutIndex = 4;
end

-- Show only the text rows that have content, then re-run the vertical layout. Because the Content
-- frame is anchored by LEFT (vertically centered) and only lays out shown rows, hiding the empty
-- ones keeps the remaining lines centered within the row.
function CharacterSelectListItemMixin:LayoutContent()
	local content = self.Content;
	content.Info:SetShown((content.Info:GetText() or "") ~= "");
	content.Location:SetShown((content.Location:GetText() or "") ~= "");
	content.GameMode:SetShown((content.GameMode:GetText() or "") ~= "");
	content:Layout();
end

function CharacterSelectListItemMixin:OnClick(button)
	ScrollListItemBaseMixin.OnClick(self, button);
end

function CharacterSelectListItemMixin:OnDoubleClick()
	if CharacterSelect.viewingInactiveList then
		CharacterSelect_SelectInactiveCharacter(self.index);
		CharacterSelect_ActivateSelectedInactive();
	else
		CharacterSelect_SelectCharacter(self.index);
		CharacterSelect_EnterWorld();
	end
end

function CharacterSelectListItemMixin:OnEnter()
	if not self.selected then
		self:LockHighlight();
	end

	if not CharacterSelect.viewingInactiveList and CharacterSelect.canSort then
		self.upButton:Show();
		self.downButton:Show();
	end

	if not CharacterSelect.viewingInactiveList and self.DeactivateButton and self.DeactivateButton.guid and self.DeactivateButton.guid ~= 0 then
		self.DeactivateButton:Show();
	end

	if self.tooltip then
		GlueTooltip:SetOwner(self, "ANCHOR_LEFT");
		GlueTooltip:SetText(self.tooltip, 1, 1, 1);
		GlueTooltip:Show();
	end
end

function CharacterSelectListItemMixin:OnLeave()
	local deactivateHovered = self.DeactivateButton and self.DeactivateButton:IsMouseOver();
	local moveHovered = (self.upButton and self.upButton:IsMouseOver()) or (self.downButton and self.downButton:IsMouseOver());

	if not self.selected and not deactivateHovered and not moveHovered then
		self:UnlockHighlight();
	end

	if self.tooltip then
		GlueTooltip:Hide();
	end

	if self.DeactivateButton and not (self.DeactivateButton:IsMouseOver() or moveHovered) then
		self.DeactivateButton:Hide();
	end

	if not CharacterSelect.viewingInactiveList then
		if not moveHovered then
			self.upButton:Hide();
			self.downButton:Hide();
		end
	end
end

function CharacterSelectListItemMixin:OnDragStart()
	if CharacterSelect.viewingInactiveList or not CharacterSelect.canSort then
		return;
	end

	CharacterSelect.dragOrigin = self.index;
	CharacterSelect.dragLastTarget = self.index;
	CharacterSelect.dragMoved = false;
	self.moved = true;
	self:LockHighlight();
	self:SetAlpha(0.7);
	self:SetScript("OnUpdate", self.OnDragUpdate);
end

function CharacterSelectListItemMixin:OnDragStop()
	if CharacterSelect.viewingInactiveList or not CharacterSelect.canSort then
		self:SetScript("OnUpdate", nil);
		self:SetAlpha(1);
		return;
	end

	if CharacterSelect.dragOrigin then
		if CharacterSelect.dragMoved then
			SendTranslationTable();
		end
	end

	CharacterSelect.dragOrigin = nil;
	CharacterSelect.dragLastTarget = nil;
	CharacterSelect.dragMoved = false;
	self.moved = nil;
	self:SetScript("OnUpdate", nil);
	self:SetAlpha(1);
	if not self.selected and not self:IsMouseOver() then
		self:UnlockHighlight();
	end
end

function CharacterSelectListItemMixin:OnDragUpdate()
	if CharacterSelect.viewingInactiveList or not CharacterSelect.canSort or not CharacterSelect.dragOrigin then
		return;
	end

	local targetIndex = nil;
	if CharacterSelect.list and CharacterSelect.list.ScrollFrame then
		local buttons = HybridScrollFrame_GetButtons(CharacterSelect.list.ScrollFrame);
		for _, button in ipairs(buttons) do
			if button:IsShown() and button:IsMouseOver() then
				targetIndex = button.index;
				break;
			end
		end
	end

	if targetIndex and targetIndex ~= CharacterSelect.dragOrigin then
		MoveCharacter(CharacterSelect.dragOrigin, targetIndex, true);
		CharacterSelect.dragOrigin = targetIndex;
		CharacterSelect.dragLastTarget = targetIndex;
		CharacterSelect.dragMoved = true;
		if CharacterSelect.list then
			CharacterSelect.list:RefreshScrollFrame();
		end
	end
end

function CharacterSelectListItemMixin:OnDeactivateClick()
	CharacterSelect_DeactivateButton_OnClick(self.DeactivateButton);
end

local function CharacterSelect_GetClassText(rawClass)
	local classFile;
	local className;

	if type(rawClass) == "number" and Enum and Enum.ClassFile then
		classFile = Enum.ClassFile[rawClass];
	elseif type(rawClass) == "string" then
		className = rawClass;
		local _, lookupFile = GetClassInfoByName(rawClass);
		if lookupFile then
			classFile = lookupFile;
		else
			-- Fallback to assuming the string is already a class file name
			classFile = rawClass;
		end
	end

	if not className and classFile then
		local maleNames = _G.LOCALIZED_CLASS_NAMES_MALE or {};
		local femaleNames = _G.LOCALIZED_CLASS_NAMES_FEMALE or maleNames;
		className = maleNames[classFile] or femaleNames[classFile] or classFile;
	end

	if className and classFile and RAID_CLASS_COLORS[classFile] then
		className = RAID_CLASS_COLORS[classFile]:WrapText(className);
	end

	return className, classFile;
end

function CharacterSelectListItemMixin:Update()
	local inactive = CharacterSelect.viewingInactiveList;
	self.tooltip = nil;
	self.selected = false;
	self.upButton:Hide();
	self.downButton:Hide();
	if self.DeactivateButton then
		self.DeactivateButton:Hide();
		self.DeactivateButton.guid = nil;
		self.DeactivateButton.deactivateGuid = nil;
		self.DeactivateButton.characterName = nil;
	end
	if self.ServiceButtons then
		self.ServiceButtons:Hide();
		if self.ServiceButtons.CustomizeButton then self.ServiceButtons.CustomizeButton:Hide(); end
		if self.ServiceButtons.RaceChangeButton then self.ServiceButtons.RaceChangeButton:Hide(); end
		if self.ServiceButtons.FactionChangeButton then self.ServiceButtons.FactionChangeButton:Hide(); end
	end

	if inactive then
		local entry = CharacterSelect.inactiveCharacters[self.index];
		if not entry then
			self:Hide();
			return;
		end

		local content = self.Content;
		local name = entry.name or UNKNOWNOBJECT;
		content.Name:SetText(name or "");

		local className = nil;
		local classFile = nil;
		if entry.class or entry.classFile or entry.className or entry.classLocalized then
			className, classFile = CharacterSelect_GetClassText(entry.class or entry.classFile or entry.className or entry.classLocalized);
		end

		if entry.level and className then
			if classFile and RAID_CLASS_COLORS[classFile] then
				className = RAID_CLASS_COLORS[classFile]:WrapText(className);
			end
			content.Info:SetFormattedText(CHARACTER_SELECT_INFO, entry.level, className);
		elseif entry.level then
			content.Info:SetFormattedText(CHARACTER_SELECT_INFO, entry.level, className or UNKNOWN);
		else
			content.Info:SetText("");
		end

		content.Location:SetText(CHARACTER_INACTIVE or entry.zone or "");
		content.GameMode:SetText("");

		self.Overlay.FactionIcon:Hide();
		self.StoreMailIndicationButton:SetShown(false);
		self.MailIndicationButton:SetShown(false);
		if self.ActivateButton then
			self.ActivateButton.guid = entry.guid;
			self.ActivateButton:SetShown(true);
			local maxCharacters, _, activeCharacters = C_CharacterList.GetCounts();
			if maxCharacters and activeCharacters then
				self.ActivateButton:SetEnabled(activeCharacters < maxCharacters);
			else
				self.ActivateButton:SetEnabled(CharacterSelect_CanCreateCharacter());
			end
		end
		self.selected = CharacterSelect.selectedInactiveIndex == self.index;
		self:LayoutContent();
		self:Show();
		self:SetHeight(self.baseHeight);
	else
		local charId = GetCharIDFromIndex(self.index);
		local name, race, class, level, zone, sex, ghost, PCC, PRC, PFC = GetCharacterInfo(charId);
		local listEntry = CharacterSelect_GetCharacterListEntry(charId, name);
		if listEntry then
			local function HasService(...)
				return CharacterSelect_IsTruthy(CharacterSelect_GetServiceFlag(listEntry, ...));
			end

			PCC = PCC or HasService("PCC", "pcc", "customize", "customization", "characterCustomization", "appearanceChange", "recustomization", "characterRecustomization", "paidCharacterCustomization", "paidCustomization", "appearanceChange");
			PRC = PRC or HasService("PRC", "prc", "raceChange", "racechange", "paidRaceChange", "characterRaceChange");
			PFC = PFC or HasService("PFC", "pfc", "factionChange", "factionchange", "paidFactionChange", "characterFactionChange", "factiontransfer", "factionTransfer");
		end
		if not name then
			self:Hide();
			return;
		end

		local content = self.Content;
		content.Name:SetText(name);

		local displayClass, classFile = CharacterSelect_GetClassText(class);
		if ghost then
			if classFile and RAID_CLASS_COLORS[classFile] then
				displayClass = RAID_CLASS_COLORS[classFile]:WrapText(displayClass);
			end
			content.Info:SetFormattedText(CHARACTER_SELECT_INFO_GHOST, level, displayClass);
		else
			if classFile and RAID_CLASS_COLORS[classFile] then
				displayClass = RAID_CLASS_COLORS[classFile]:WrapText(displayClass);
			end
			content.Info:SetFormattedText(CHARACTER_SELECT_INFO, level, displayClass or "nil");
		end
		content.Location:SetText(zone or "");

		local gameModeStr = "";
		local tooltip = nil;
		local factionIconAtlas = nil;

		local activeGameModes, enabledGameModes, teamId, isMercenary, rulesetId = GetCharacterSelectionGameModeData(charId);
		if activeGameModes and enabledGameModes then
			for mode, flag in pairs(Enum.GameMode) do
				if flag ~= Enum.GameMode.None and flag ~= Enum.GameMode.Random and flag ~= Enum.GameMode.FreepickRarities then
					if bit.contains(activeGameModes, flag) then
						local modeName = _G[mode:upper() .. "_MODE"] or mode;
						if bit.contains(enabledGameModes, flag) then
							gameModeStr = gameModeStr .. GAME_MODE_COLOR[mode]:WrapText(modeName) .. " ";
						else
							if tooltip then
								tooltip = tooltip .. "\n" .. format(GAME_MODE_DISABLE_FORMAT[mode], GAME_MODE_COLOR[mode]:WrapText(modeName));
							else
								tooltip = format(GAME_MODE_DISABLE_FORMAT[mode], GAME_MODE_COLOR[mode]:WrapText(modeName));
							end
							gameModeStr = gameModeStr .. RED_FONT_COLOR:WrapText(modeName) .. " ";
						end
					end
				end
			end
		end

		local isOutlaw = false;
		if isOutlaw then
			factionIconAtlas = "tormentors-event";
		else
			local ruleset = rulesetId;
			local faction = teamId;

			if faction and faction ~= Enum.CharacterSelect.Faction.Other then
				local highRisk = ruleset == Enum.CharacterSelect.Ruleset.HighRisk;

				if highRisk then
					if faction == Enum.CharacterSelect.Faction.Alliance then
						factionIconAtlas = "allianceassaultsmapbanner";
					else
						factionIconAtlas = "hordeassaultsmapbanner";
					end
				else
					if faction == Enum.CharacterSelect.Faction.Alliance then
						factionIconAtlas = "alliancewarfrontmapbanner";
					else
						factionIconAtlas = "hordewarfrontmapbanner";
					end
				end
			end
		end

		local hasMail, hasStoreMail = GetCharacterSelectionMailData(charId);

		content.GameMode:SetText(gameModeStr or "");
		if factionIconAtlas then
			self.Overlay.FactionIcon:SetAtlas(factionIconAtlas, Const.TextureKit.IgnoreAtlasSize);
			self.Overlay.FactionIcon:Show();
		else
			self.Overlay.FactionIcon:Hide();
		end

		if hasStoreMail then
			self.StoreMailIndicationButton:ClearAndSetPoint("LEFT", content.Name, "RIGHT", 0, -4);
		end
		if hasStoreMail and hasMail then
			self.StoreMailIndicationButton:ClearAndSetPoint("LEFT", content.Name, "RIGHT", 16, -4);
		end

		self.StoreMailIndicationButton:SetShown(hasStoreMail);
		self.MailIndicationButton:SetShown(hasMail);

		self.deactivateGuid = CharacterSelect_FindCharacterGuidByName(name);
		self.deactivateName = name;
		if self.DeactivateButton then
			self.DeactivateButton.guid = self.deactivateGuid;
			self.DeactivateButton.deactivateGuid = self.deactivateGuid;
			self.DeactivateButton.characterName = name;
		end
		if self.ActivateButton then
			self.ActivateButton:Hide();
			self.ActivateButton.guid = nil;
		end

		self.upButton:SetEnabled(self.index ~= 1);
		self.downButton:SetEnabled(self.index ~= #translationTable);

		if self.ServiceButtons then
			local svc = self.ServiceButtons;
			local hasService = false;
			if PFC and svc.FactionChangeButton then
				svc.FactionChangeButton:SetID(self.index);
				svc.FactionChangeButton:Show();
				hasService = true;
			end
			if PRC and svc.RaceChangeButton then
				svc.RaceChangeButton:SetID(self.index);
				svc.RaceChangeButton:Show();
				hasService = true;
			end
			if PCC and svc.CustomizeButton then
				svc.CustomizeButton:SetID(self.index);
				svc.CustomizeButton:Show();
				hasService = true;
			end
			svc:SetShown(hasService);
			if hasService and svc.Layout then
				svc:Layout();
			end
		end

		self.selected = CharacterSelect.selectedIndex == self.index;
		self.tooltip = tooltip;
		-- The scroll list enforces a uniform row height (CharacterSelect_GetRowHeight), which is
		-- sized to fit the game mode line, so all rows use baseHeight.
		self:SetHeight(self.baseHeight);
		self:LayoutContent();
		self:Show();
	end

	if self.selected then
		self:LockHighlight();
	else
		self:UnlockHighlight();
	end
end

function CharacterSelectListItemMixin:OnSelected()
	if CharacterSelect.viewingInactiveList then
		CharacterSelect_SelectInactiveCharacter(self.index);
	else
		CharacterSelect_SelectCharacter(self.index);
	end
end

local function CharacterSelect_EnsureCharacterButtons(maxCount)
	-- ScrollList manages its own buttons; no manual creation needed
end

local function CharacterSelect_ShouldShowInactiveToggle()
	if not IsConnectedToServer() then
		return false;
	end

	local inactiveCount = 0;
	if CharacterSelect and CharacterSelect.cachedEntryCounts and CharacterSelect.cachedEntryCounts.inactive then
		inactiveCount = CharacterSelect.cachedEntryCounts.inactive;
	elseif CharacterSelect and CharacterSelect.inactiveCharacters then
		inactiveCount = #CharacterSelect.inactiveCharacters;
	end

	if inactiveCount > 0 then
		return true;
	end

	return CharacterSelect and CharacterSelect.viewingInactiveList;
end

function CharacterSelect_OnLoad(self)
	self:SetSequence(0);
	self:SetCamera(0);

	self.createIndex = 0;
	self.selectedIndex = 0;
	self.selectedCharacterId = 0;
	self.selectLast = 0;
	self.currentModel = nil;
	self.pendingNewCharacterName = nil;
	self:RegisterEvent("ADDON_LIST_UPDATE");
	self:RegisterEvent("CHARACTER_LIST_UPDATE");
	self:RegisterEvent("UPDATE_SELECTED_CHARACTER");
	self:RegisterEvent("SELECT_LAST_CHARACTER");
	self:RegisterEvent("SELECT_FIRST_CHARACTER");
	self:RegisterEvent("SUGGEST_REALM");
	self:RegisterEvent("FORCE_RENAME_CHARACTER");
	self:RegisterEvent("CHARACTER_LIST_UPDATED");
	self:RegisterEvent("CHARACTER_ACTIVATE_RESULT");
	self:RegisterEvent("CHARACTER_DEACTIVATE_RESULT");

	self.inactiveCharacters = {};
	self.selectedInactiveIndex = 0;
	self.selectedInactiveGuid = 0;
	self.charListReady = false;
	self.viewingInactiveList = false;
	self.enterWorldButtonDefaultText = CharSelectEnterWorldButton:GetText();

	EventRegistry:RegisterCallback("CharacterCreate.NewCharacter", function(_, characterName)
		self.pendingNewCharacterName = characterName;
		self.selectLast = 1;
	end, self);

	-- CharacterSelect:SetModel("Interface\\Glues\\Models\\UI_Orc\\UI_Orc.m2");

	-- local fogInfo = CharModelFogInfo["ORC"];
	-- CharacterSelect:SetFogColor(fogInfo.r, fogInfo.g, fogInfo.b);
	-- CharacterSelect:SetFogNear(0);
	-- CharacterSelect:SetFogFar(fogInfo.far);

	SetCharSelectModelFrame("CharacterSelect");

	-- Color edit box backdrops
	local backdropColor = DEFAULT_TOOLTIP_COLOR;
	CharacterSelectCharacterFrame:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	CharacterSelectCharacterFrame:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6], 0.85);

	if CharacterSelectCharacterFrame and CharacterSelectCharacterFrame.List then
		local list = CharacterSelectCharacterFrame.List;
		CharacterSelect.list = list;
		list:SetGetNumResultsFunction(function()
			return CharacterSelect_GetListCount();
		end);
		list:SetTemplate("CharSelectScrollListItemTemplate");
		list.ScrollFrame.buttonHeight = CharacterSelect_GetRowHeight();
		list.ScrollFrame.stepSize = list.ScrollFrame.buttonHeight;
		HybridScrollFrame_SetDoNotHideScrollBar(list.ScrollFrame, false);
		HybridScrollFrame_SetDoNotHideScrollThumb(list.ScrollFrame, false);
		list:SetSelectedHighlightTexture(nil);
		list:GetSelectedHighlight():Hide();
		list:SetSelectedHighlightInset(0, 0, 0, 0);
		list:SetSelectionCallback(function(index)
			if CharacterSelect.viewingInactiveList then
				CharacterSelect_SelectInactiveCharacter(index or 0);
			else
				CharacterSelect_SelectCharacter(index or 0, 1, true);
			end
		end);
	end
end

function CharacterSelect_OnShow()
	-- Modified GlueXML.toc files won't load this function properly. It's rare but it locks people out of char select entirely if it happens.
	if LoadAscensionAddOns then
		LoadAscensionAddOns()
	end
	
	HelpTip:Show("GET_ADDONS_ON_LAUNCHER")
	-- request account data times from the server (so we know if we should refresh keybindings, etc...)
	ReadyForAccountDataTimes()

	CharacterSelectAddonsButton:SetShown(C_AddonPanel:HasConfigurableAddons())
	CharacterSelect.viewingInactiveList = false;
	CharacterSelect_UpdateToggleButtonVisibility();
	CharacterSelect_UpdateActionButtons();
	if CharacterSelect.list and CharacterSelect.list:IsInitialized() then
		CharacterSelect.list.ScrollFrame.buttonHeight = CharacterSelect_GetRowHeight();
		CharacterSelect.list:RefreshScrollFrame();
	end

	if CharacterSelect.viewingInactiveList then
		CharSelectCharacterName:Hide();
	else
		CharSelectCharacterName:Show();
	end

	local CurrentModel = CharacterSelect.currentModel;

	if (CurrentModel) then
		PlayGlueAmbience(GlueAmbienceTracks[strupper(CurrentModel)], 4.0);
	end

	local serverName, isPVP, isRP = GetServerName();
	local connected = IsConnectedToServer();
	local serverType = "";
	if (serverName) then
		if (not connected) then
			serverName = serverName .. "\n(" .. SERVER_DOWN .. ")";
		end
		if (isPVP) then
			if (isRP) then
				serverType = RPPVP_PARENTHESES;
			else
				serverType = PVP_PARENTHESES;
			end
		elseif (isRP) then
			serverType = RP_PARENTHESES;
		end
		CharSelectRealmName:SetText(serverName .. " " .. serverType);
		CharSelectRealmName:Show();
	else
		CharSelectRealmName:Hide();
	end

	if (connected) then
		CharacterSelect.charListReady = false;
		GetCharacterListUpdate();
	else
		UpdateCharacterList();
	end

	-- Gameroom billing stuff (For Korea and China only)
	if (SHOW_GAMEROOM_BILLING_FRAME) then
		local paymentPlan, hasFallBackBillingMethod, isGameRoom = GetBillingPlan();
		if (paymentPlan == 0) then
			-- No payment plan
			GameRoomBillingFrame:Hide();
			CharacterSelectRealmSplitButton:ClearAllPoints();
			CharacterSelectRealmSplitButton:SetPoint("TOP", CharacterSelectLogo, "BOTTOM", 0, -5);
		else
			local billingTimeLeft = GetBillingTimeRemaining();
			-- Set default text for the payment plan
			local billingText = _G["BILLING_TEXT" .. paymentPlan];
			if (paymentPlan == 1) then
				-- Recurring account
				billingTimeLeft = ceil(billingTimeLeft / (60 * 24));
				if (billingTimeLeft == 1) then
					billingText = BILLING_TIME_LEFT_LAST_DAY;
				end
			elseif (paymentPlan == 2) then
				-- Free account
				if (billingTimeLeft < (24 * 60)) then
					billingText = format(BILLING_FREE_TIME_EXPIRE, billingTimeLeft .. " " .. MINUTES_ABBR);
				end
			elseif (paymentPlan == 3) then
				-- Fixed but not recurring
				if (isGameRoom == 1) then
					if (billingTimeLeft <= 30) then
						billingText = BILLING_GAMEROOM_EXPIRE;
					else
						billingText = format(BILLING_FIXED_IGR, MinutesToTime(billingTimeLeft, 1));
					end
				else
					-- personal fixed plan
					if (billingTimeLeft < (24 * 60)) then
						billingText = BILLING_FIXED_LASTDAY;
					else
						billingText = format(billingText, MinutesToTime(billingTimeLeft));
					end
				end
			elseif (paymentPlan == 4) then
				-- Usage plan
				if (isGameRoom == 1) then
					-- game room usage plan
					if (billingTimeLeft <= 600) then
						billingText = BILLING_GAMEROOM_EXPIRE;
					else
						billingText = BILLING_IGR_USAGE;
					end
				else
					-- personal usage plan
					if (billingTimeLeft <= 30) then
						billingText = BILLING_TIME_LEFT_30_MINS;
					else
						billingText = format(billingText, billingTimeLeft);
					end
				end
			end
			-- If fallback payment method add a note that says so
			if (hasFallBackBillingMethod == 1) then
				billingText = billingText .. "\n\n" .. BILLING_HAS_FALLBACK_PAYMENT;
			end
			GameRoomBillingFrameText:SetText(billingText);
			GameRoomBillingFrame:SetHeight(GameRoomBillingFrameText:GetHeight() + 26);
			GameRoomBillingFrame:Show();
			CharacterSelectRealmSplitButton:ClearAllPoints();
			CharacterSelectRealmSplitButton:SetPoint("TOP", GameRoomBillingFrame, "BOTTOM", 0, -10);
		end
	end

	if (IsTrialAccount()) then
		CharacterSelectUpgradeAccountButton:Show();
	else
		CharacterSelectUpgradeAccountButton:Hide();
	end

	-- fadein the character select ui
	GlueFrameFadeIn(CharacterSelectUI, CHARACTER_SELECT_FADE_IN)

	RealmSplitCurrentChoice:Hide();
	RequestRealmSplitInfo();
	CharacterSelect_CheckMaintenance()
	CharacterSelect_UpdateCharacterListInfo()
end

function CharacterSelect_CheckMaintenance()
	local inMaintenance = false --GetRealmMaintenance()

	CharSelectEnterWorldButton:SetEnabled(not CharacterSelect.viewingInactiveList and not inMaintenance)
end

function CharacterSelect_OnHide()
	if RealmMerge then
		RealmMerge.HideChoiceDialog()
		RealmMerge.HideChangeTarget()
	end
	CharacterDeleteDialog:Hide();
	CharacterRenameDialog:Hide();
	if (DeclensionFrame) then
		DeclensionFrame:Hide();
	end
	SERVER_SPLIT_STATE_PENDING = -1;
end

function CharacterSelect_OnUpdate(elapsed)
	if (SERVER_SPLIT_STATE_PENDING > 0) then
		CharacterSelectRealmSplitButton:Show();

		if (SERVER_SPLIT_CLIENT_STATE > 0) then
			RealmSplit_SetChoiceText();
			RealmSplitPending:SetPoint("TOP", RealmSplitCurrentChoice, "BOTTOM", 0, -10);
		else
			RealmSplitPending:SetPoint("TOP", CharacterSelectRealmSplitButton, "BOTTOM", 0, 0);
			RealmSplitCurrentChoice:Hide();
		end

		if (SERVER_SPLIT_STATE_PENDING > 1) then
			CharacterSelectRealmSplitButton:Disable();
			CharacterSelectRealmSplitButtonGlow:Hide();
			RealmSplitPending:SetText(SERVER_SPLIT_PENDING);
		else
			CharacterSelectRealmSplitButton:Enable();
			CharacterSelectRealmSplitButtonGlow:Show();
			local datetext = SERVER_SPLIT_CHOOSE_BY .. "\n" .. SERVER_SPLIT_DATE;
			RealmSplitPending:SetText(datetext);
		end

		if (SERVER_SPLIT_SHOW_DIALOG and not GlueDialog:IsShown()) then
			SERVER_SPLIT_SHOW_DIALOG = false;
			local dialogString = format(SERVER_SPLIT, SERVER_SPLIT_DATE);
			if (SERVER_SPLIT_CLIENT_STATE > 0) then
				local serverChoice = RealmSplit_GetFormatedChoice(SERVER_SPLIT_REALM_CHOICE);
				local stringWithDate = format(SERVER_SPLIT, SERVER_SPLIT_DATE);
				dialogString = stringWithDate .. "\n\n" .. serverChoice;
				GlueDialog_Show("SERVER_SPLIT_WITH_CHOICE", dialogString);
			else
				GlueDialog_Show("SERVER_SPLIT", dialogString);
			end
		end
	else
		CharacterSelectRealmSplitButton:Hide();
	end

	-- Account Msg stuff
	if ((ACCOUNT_MSG_NUM_AVAILABLE > 0) and not GlueDialog:IsShown()) then
		if (ACCOUNT_MSG_HEADERS_LOADED) then
			if (ACCOUNT_MSG_BODY_LOADED) then
				local dialogString = AccountMsg_GetHeaderSubject(ACCOUNT_MSG_CURRENT_INDEX) .. "\n\n" .. AccountMsg_GetBody();
				GlueDialog_Show("ACCOUNT_MSG", dialogString);
			end
		end
	end
end

function CharacterSelect_OnKeyDown(self, key)
	if TutorialExpereinceSelect and TutorialExpereinceSelect:IsVisible() then
		return
	end
	
	if (key == "ESCAPE") then
		ToggleEscapeMenu();
	elseif (key == "ENTER") then
		if CharacterSelect.viewingInactiveList then
			CharacterSelect_ActivateSelectedInactive();
		elseif (CharSelectEnterWorldButton:IsEnabled() and CharacterSelect_IsCorrectClient()) then
			CharacterSelect_EnterWorld();
		end
	elseif (key == "PRINTSCREEN") then
		Screenshot();
	elseif (key == "UP" or key == "LEFT") then
		local numChars = GetNumCharacters();
		if (numChars > 1) then
			if (self.selectedIndex > 1) then
				CharacterSelect_SelectCharacter(self.selectedIndex - 1);
			else
				CharacterSelect_SelectCharacter(numChars);
			end
		end
	elseif (arg1 == "DOWN" or arg1 == "RIGHT") then
		local numChars = GetNumCharacters();
		if (numChars > 1) then
			if (self.selectedIndex < GetNumCharacters()) then
				CharacterSelect_SelectCharacter(self.selectedIndex + 1);
			else
				CharacterSelect_SelectCharacter(1);
			end
		end
	end
end

function CharacterSelect_OnEvent(self, event, ...)
	if (event == "ADDON_LIST_UPDATE") then
		ClearJsonCache() -- clear entire json cache
		self.CheckedJson = false
		CharacterSelectAddonsButton:SetShown(C_AddonPanel:HasConfigurableAddons())
	elseif (event == "CHARACTER_LIST_UPDATE") then
		self.charListReady = true;
		local sortOrder = GetCharacterSelectionSortOrder()
		CharSelectResetOrderButton:Hide()

		-- Check if we have a sort order
		if sortOrder then
			-- allow sorting characters
			CharacterSelect.canSort = true
			local displayMax = CharacterSelect_GetDisplayMax();
			local order = string.SplitToTable(sortOrder, " ", tonumber)

			if CharacterSelect.justDeleted then
				CharacterSelect.justDeleted = false
				order = tcopy(translationTable)
			end

			-- clear current translationTable
			wipe(translationTable)

			-- create list of character ids available to display
			local availableCharacters = {}

			for i = 1, displayMax do
				tinsert(availableCharacters, i)
			end

			local mustUpdate = false

			local numChars = GetNumCharacters()

			for i = 1, numChars do
				-- get character id from sort or i
				local characterId = order[i] or i

				-- character id is greater than our max characters. Reindex
				if characterId > numChars then
					mustUpdate = true
					characterId = characterId - 1
				end

				local found, index = tcontains(availableCharacters, characterId)
				if found then
					tremove(availableCharacters, index)
				else
					mustUpdate = true
					characterId = availableCharacters[1]
					tremove(availableCharacters, 1)
				end

				tinsert(translationTable, characterId)
			end

			if mustUpdate then
				SendTranslationTable()
			end
		else
			-- we have no json data, disallow sorting
			CharacterSelect.canSort = false
			wipe(translationTable)
			local displayMax = CharacterSelect_GetDisplayMax();
			for i = 1, displayMax do
				tinsert(translationTable, i)
			end
			if not self.CheckedJson then
				self.CheckedJson = true
				Timer.NewTicker(0.2, function(ticker)
					if GetCharacterSelectionSortOrder() then
						ticker:Cancel()
						CharacterSelect_OnEvent(self,
						                        event) -- refresh once just incase we failed to get json the first time.
					end
				end, 5) -- check 5 times every 0.2s (check over a period of 1 second)
			end
		end

		if not self.CheckedJson or self.selectedIndex == 0 then
			self.selectedIndex = GetIndexFromCharID(self.selectedCharacterId)
		end

		self.CheckedJson = true

		if self.pendingNewCharacterName then
			local foundIndex = nil;
			for i = 1, GetNumCharacters() do
				local name = GetCharacterInfo(GetCharIDFromIndex(i));
				if name == self.pendingNewCharacterName then
					foundIndex = i;
					break;
				end
			end
			if foundIndex then
				self.selectedIndex = foundIndex;
				self.selectedCharacterId = GetCharIDFromIndex(foundIndex);
				self.selectLast = 0;
			end
			self.pendingNewCharacterName = nil;
		end

		UpdateCharacterList();
		CharSelectCharacterName:SetText(GetCharacterInfo(self.selectedCharacterId));
		CharacterSelect_UpdateCharacterListInfo();

        if self.selectLast == 1 then
            self.selectLast = 0;
            self.selectedIndex = GetNumCharacters();
            self.selectedCharacterId = GetCharIDFromIndex(self.selectedIndex);
        end

        CharacterSelect_SelectCharacter(self.selectedIndex, 1)
	elseif (event == "UPDATE_SELECTED_CHARACTER") then
		local index = ...;
		if (index == 0) then
			CharSelectCharacterName:SetText("");
		else
			if self.CheckedJson then
				CharSelectCharacterName:SetText(GetCharacterInfo(index));
				self.selectedIndex = GetIndexFromCharID(index);
				self.selectedCharacterId = index
			else
				CharSelectCharacterName:SetText(GetCharacterInfo(index))
				self.selectedIndex = index
				self.selectedCharacterId = index
			end
			CharacterSelect.currentModel = GetSelectBackgroundModel(index);
			if CharacterSelect.currentModel then
				SetBackgroundModel(CharacterSelect, CharacterSelect.currentModel);
			end
		end
		UpdateCharacterSelection(self);
	elseif (event == "SELECT_LAST_CHARACTER") then
		self.selectLast = 1;
	elseif (event == "SELECT_FIRST_CHARACTER") then
		CharacterSelect_SelectCharacterID(1, 1);
	elseif (event == "SUGGEST_REALM") then
		if (RealmList:IsShown()) then
			RealmListUpdate();
		else
			RealmList:Show();
		end
	elseif (event == "FORCE_RENAME_CHARACTER") then
		local message = ...;
		CharacterRenameDialog:Show();
		CharacterRenameText1:SetText(_G[message]);
	elseif (event == "CHARACTER_LIST_UPDATED") then
		CharacterSelect_UpdateCharacterListInfo();
	elseif (event == "CHARACTER_ACTIVATE_RESULT") then
		local success, result = ...;
		if success then
			self.charListReady = false;
			GetCharacterListUpdate();
			if not CharacterSelect_CanCreateCharacter() then
				CharacterSelect_SetInactiveView(false);
			end
		else
			GlueDialog_Show("OKAY", _G[result] or result);
		end
	elseif (event == "CHARACTER_DEACTIVATE_RESULT") then
		local success, result = ...;
		if success then
			self.charListReady = false;
			GetCharacterListUpdate();
		else
			GlueDialog_Show("OKAY", _G[result] or result);
		end
	end
end

function CharacterSelect_UpdateModel(self)
	UpdateSelectionCustomizationScene();
	self:AdvanceTime();
end

function UpdateCharacterSelection(self)
	if not CharacterSelect.list or not CharacterSelect.list:IsInitialized() then
		return;
	end

	if CharacterSelect.viewingInactiveList then
		CharacterSelect.list:SetSelectedIndex(CharacterSelect.selectedInactiveIndex or 0);
	else
		CharacterSelect.list:SetSelectedIndex(CharacterSelect.selectedIndex or 0);
	end
end

function CharacterSelectButton_OnDragUpdate(self)
	-- Drag sorting is not supported with the ScrollList implementation
end

function CharacterSelectButton_OnDragStart(self)
	-- Drag sorting is not supported with the ScrollList implementation
end

function CharacterSelectButton_OnDragStop(self)
	-- Drag sorting is not supported with the ScrollList implementation
end

function SendTranslationTable()
	local sendTable = tcopy(translationTable)
	for i = 1, CharacterSelect_GetDisplayMax() do
		sendTable[i] = sendTable[i] or i
	end

	local sortOrder = makeprintable(unpack(sendTable))
	if sortOrder then
		SetCharacterSelectionSortOrder(sortOrder)
	end
end

function MoveCharacter(originIndex, targetIndex, fromDrag)
	if (not targetIndex or targetIndex < 1) then
		targetIndex = #translationTable;
	elseif (targetIndex > #translationTable) then
		targetIndex = 1;
	end
	if (originIndex == CharacterSelect.selectedIndex) then
		CharacterSelect.selectedIndex = targetIndex;
		CharacterSelect.selectedCharacterId = translationTable[targetIndex];
	elseif (targetIndex == CharacterSelect.selectedIndex) then
		CharacterSelect.selectedIndex = originIndex;
		CharacterSelect.selectedCharacterId = translationTable[originIndex];
	end
	translationTable[originIndex], translationTable[targetIndex] = translationTable[targetIndex], translationTable[originIndex];
	if not fromDrag then
		SendTranslationTable();
	end
	UpdateCharacterSelection(CharacterSelect);
	UpdateCharacterList();
end

function GetCharIDFromIndex(index)
	return translationTable[index] or 0;
end

function GetIndexFromCharID(charID)
	-- no need for lookup if the order hasn't changed
	for index = 1, #translationTable do
		if (translationTable[index] == charID) then
			return index;
		end
	end
	return 0;
end

function CharacterSelect_GetTotalCharacterCount()
	if C_CharacterList and C_CharacterList.GetCounts then
		local maxCount, totalCount, activeCount, inactiveCount = C_CharacterList.GetCounts();
		if maxCount and maxCount > 0 then
			if totalCount == 0 and GetNumCharacters() > 0 then
				totalCount = GetNumCharacters();
			end
			return totalCount, maxCount, activeCount, inactiveCount;
		end
	end

	return GetNumCharacters(), DEFAULT_MAX_CHARACTERS_PER_REALM, GetNumCharacters(), 0;
end

function CharacterSelect_GetCreateCharacterIndex()
	return math.min(GetNumCharacters() + 1, CharacterSelect_GetDisplayMax());
end

function CharacterSelect_FindCharacterGuidByName(name)
	if not name or not C_CharacterList or not C_CharacterList.GetEntries then
		return 0;
	end

	if CharacterSelect.activeGuidsByName and CharacterSelect.activeGuidsByName[name] then
		return CharacterSelect.activeGuidsByName[name];
	end

	local entries = C_CharacterList.GetEntries();
	for _, entry in ipairs(entries) do
		if entry.name == name and entry.active then
			return entry.guid;
		end
	end

	return 0;
end

function CharacterSelect_GetSelectedCharacterGuid()
	if not CharacterSelect.selectedIndex or CharacterSelect.selectedIndex == 0 then
		return 0;
	end

	local name = GetCharacterInfo(GetCharIDFromIndex(CharacterSelect.selectedIndex));
	return CharacterSelect_FindCharacterGuidByName(name);
end

function CharacterSelect_UpdateToggleButtonVisibility()
	if not CharSelectInactiveToggleButton then
		return;
	end

	local show = CharacterSelect_ShouldShowInactiveToggle();
	if show then
		CharSelectInactiveToggleButton:Show();
	else
		CharSelectInactiveToggleButton:Hide();
		if CharacterSelect.viewingInactiveList then
			CharacterSelect_SetInactiveView(false);
		end
	end
end

function CharacterSelect_RebuildInactiveCharacters()
	wipe(CharacterSelect.inactiveCharacters);
	if not CharacterSelect.activeGuidsByName then
		CharacterSelect.activeGuidsByName = {};
	end
	wipe(CharacterSelect.activeGuidsByName);
	CharacterSelect.cachedEntryCounts = CharacterSelect.cachedEntryCounts or { total = 0, active = 0, inactive = 0 };
	local counts = CharacterSelect.cachedEntryCounts;
	counts.total = 0;
	counts.active = 0;
	counts.inactive = 0;

	if not C_CharacterList or not C_CharacterList.GetEntries then
		return;
	end

	local entries = C_CharacterList.GetEntries();
	for _, entry in ipairs(entries) do
		counts.total = counts.total + 1;
		if not entry.active then
			tinsert(CharacterSelect.inactiveCharacters, entry);
			counts.inactive = counts.inactive + 1;
		else
			counts.active = counts.active + 1;
			if entry.name and entry.guid then
				CharacterSelect.activeGuidsByName[entry.name] = entry.guid;
			end
		end
	end
end

function CharacterSelect_UpdateCharacterListInfo()
	local maxCount, totalCount, activeCount, inactiveCount = 0, nil, nil, nil;
	if C_CharacterList and C_CharacterList.GetCounts then
		maxCount, totalCount, activeCount, inactiveCount = C_CharacterList.GetCounts();
	end

	CharacterSelect_RebuildInactiveCharacters();
	local cached = CharacterSelect.cachedEntryCounts or { total = 0, active = 0, inactive = 0 };

	local effectiveMax = maxCount or CharacterSelect.characterListMax or DEFAULT_MAX_CHARACTERS_PER_REALM;
	if not effectiveMax or effectiveMax <= 0 then
		effectiveMax = DEFAULT_MAX_CHARACTERS_PER_REALM;
	end
	CharacterSelect.characterListMax = math.min(effectiveMax, UI_MAX_CHARACTERS_DISPLAYED);
	CharacterSelect.characterListTotal = totalCount or cached.total or GetNumCharacters();
	CharacterSelect.characterListActive = activeCount or cached.active or GetNumCharacters();
	CharacterSelect.characterListInactive = inactiveCount or cached.inactive or 0;

	CharacterSelect_UpdateToggleButtonVisibility();
	CharacterSelect_UpdateActionButtons();

	if CharacterSelect.charListReady then
		UpdateCharacterList();
	end
end

function CharacterSelect_SelectInactiveCharacter(index, skipSound)
	if not CharacterSelect.viewingInactiveList then
		return;
	end

	local entry = CharacterSelect.inactiveCharacters[index];
	if not entry then
		CharacterSelect.selectedInactiveIndex = 0;
		CharacterSelect.selectedInactiveGuid = 0;
		CharacterSelect_UpdateActionButtons();
		UpdateCharacterSelection(CharacterSelect);
		return;
	end

	CharacterSelect.selectedInactiveIndex = index;
	CharacterSelect.selectedInactiveGuid = entry.guid or 0;
	CharacterSelect_UpdateActionButtons();
	UpdateCharacterSelection(CharacterSelect);
	if CharacterSelect.list and CharacterSelect.viewingInactiveList then
		CharacterSelect.list:ScrollToSelection();
	end

	if not skipSound then
		PlaySound("gsCharacterSelectionClick");
	end
end

function CharacterSelect_ActivateSelectedInactive()
	if not CharacterSelect.viewingInactiveList then
		return;
	end

	if not CharacterSelect_CanCreateCharacter() then
		GlueDialog_Show("OKAY", CHARACTER_LIST_FULL or CHAR_CREATE_SERVER_LIMIT or "Character list is full.");
		return;
	end

	if not CharacterSelect.selectedInactiveIndex or CharacterSelect.selectedInactiveIndex == 0 then
		return;
	end

	local entry = CharacterSelect.inactiveCharacters[CharacterSelect.selectedInactiveIndex];
	if not entry or not entry.guid then
		return;
	end

	C_CharacterList.RequestActivate(entry.guid);
end

function CharacterSelect_ActivateButton_OnClick(self)
	if not self.guid or self.guid == 0 then
		return;
	end

	if CharacterSelect.viewingInactiveList then
		CharacterSelect_SelectInactiveCharacter(self:GetParent().index, true);
		CharacterSelect.selectedInactiveGuid = self.guid;
	end
	C_CharacterList.RequestActivate(self.guid);
end

function CharacterSelect_RequestDeactivate(guid)
	if not guid or guid == 0 then
		return;
	end

	C_CharacterList.RequestDeactivate(guid);
end

function CharacterSelect_DeactivateSelectedCharacter()
	local guid = CharacterSelect_GetSelectedCharacterGuid();
	if not guid or guid == 0 then
		return;
	end

	local name = GetCharacterInfo(GetCharIDFromIndex(CharacterSelect.selectedIndex));
	GlueDialog_Show("CONFIRM_DEACTIVATE_CHARACTER", name or "", { guid = guid, name = name });
end

function CharacterSelect_DeactivateButton_OnClick(self)
	if CharacterSelect.viewingInactiveList then
		return;
	end

	local guid = self.guid or (self:GetParent() and self:GetParent().deactivateGuid);
	if not guid or guid == 0 then
		return;
	end

	local name = self.characterName or (self:GetParent() and self:GetParent().deactivateName);
	if not name or name == "" then
		local parentIndex = self:GetParent() and self:GetParent().index;
		if parentIndex then
			name = GetCharacterInfo(GetCharIDFromIndex(parentIndex));
		end
	end

	GlueDialog_Show("CONFIRM_DEACTIVATE_CHARACTER", name or "", { guid = guid, name = name });

	local parent = self:GetParent();
	if parent then
		parent.upButton:Hide();
		parent.downButton:Hide();
		self:Hide();
		if not parent.selected then
			parent:UnlockHighlight();
		end
	end
end

function CharacterSelect_SetInactiveView(enable)
	if enable and not CharacterSelect_ShouldShowInactiveToggle() then
		enable = false;
	end

	if CharacterSelect.viewingInactiveList == enable then
		return;
	end
    CharacterSelect.InactiveBackdrop:SetShown(enable);
	CharacterSelect.viewingInactiveList = enable;

	if enable then
		CharacterSelect.activeSelectedCharacterId = CharacterSelect.selectedCharacterId;
		CharacterSelect.selectedIndex = 0;
		CharacterSelect.selectedCharacterId = 0;
		if CharacterSelect.list then
			CharacterSelect.list:ScrollToBegin();
		end
		if #CharacterSelect.inactiveCharacters > 0 then
			if CharacterSelect.selectedInactiveIndex > #CharacterSelect.inactiveCharacters then
				CharacterSelect.selectedInactiveIndex = #CharacterSelect.inactiveCharacters;
			end
			if CharacterSelect.selectedInactiveIndex == 0 then
				CharacterSelect.selectedInactiveIndex = 1;
			end
			CharacterSelect.selectedInactiveGuid = CharacterSelect.inactiveCharacters[CharacterSelect.selectedInactiveIndex].guid or 0;
		else
			CharacterSelect.selectedInactiveIndex = 0;
			CharacterSelect.selectedInactiveGuid = 0;
		end
	else
		CharacterSelect.selectedInactiveIndex = 0;
		CharacterSelect.selectedInactiveGuid = 0;

		local restoreId = CharacterSelect.activeSelectedCharacterId;
		CharacterSelect.activeSelectedCharacterId = nil;
		if restoreId and restoreId ~= 0 then
			CharacterSelect.selectedCharacterId = restoreId;
			CharacterSelect.selectedIndex = GetIndexFromCharID(restoreId) or 0;
		end
	end

	CharacterSelect_UpdateToggleButtonVisibility();
	CharacterSelect_UpdateActionButtons();
	UpdateCharacterSelection(CharacterSelect);
	UpdateCharacterList();

	if not enable and CharacterSelect.selectedIndex and CharacterSelect.selectedIndex > 0 then
		CharacterSelect_SelectCharacter(CharacterSelect.selectedIndex, 1);
	end
end

function CharacterSelect_UpdateActionButtons()
	if not CharSelectEnterWorldButton then
		return;
	end

	local connected = IsConnectedToServer();
	local totalCount, maxCount = CharacterSelect_GetTotalCharacterCount();
	local canCreate = CharacterSelect_CanCreateCharacter();

	if CharacterSelect.viewingInactiveList then
		CharSelectEnterWorldButton:SetText(CharacterSelect.enterWorldButtonDefaultText or ENTER_WORLD);
		CharSelectEnterWorldButton:SetScript("OnClick", CharacterSelect_EnterWorld);
		CharSelectEnterWorldButton:Disable();
		if CharacterSelectDeleteButton then
			CharacterSelectDeleteButton:Disable();
		end
		if CharSelectCreateCharacterButton then
			CharSelectCreateCharacterButton:Disable();
			CharSelectCreateCharacterButton:Hide();
		end
		if CharSelectResetOrderButton then
			CharSelectResetOrderButton:Disable();
		end
		CharSelectCharacterName:Hide();
	else
		CharSelectEnterWorldButton:SetText(CharacterSelect.enterWorldButtonDefaultText or ENTER_WORLD);
		CharSelectEnterWorldButton:SetScript("OnClick", CharacterSelect_EnterWorld);
		if CharacterSelectDeleteButton then
			CharacterSelectDeleteButton:SetEnabled(GetNumCharacters() > 0);
		end
		CharSelectCharacterName:Show();
	end

	if CharSelectCreateCharacterButton then
		CharSelectCreateCharacterButton:SetShown(not CharacterSelect.viewingInactiveList and canCreate and connected);
		CharSelectCreateCharacterButton:SetEnabled(not CharacterSelect.viewingInactiveList and canCreate and connected);
	end
end

function UpdateCharacterList()
	CharacterSelect_RebuildInactiveCharacters();

	local list = CharacterSelect.list;
	if list and list.ScrollFrame then
		list.ScrollFrame.buttonHeight = CharacterSelect_GetRowHeight();
		list.ScrollFrame.stepSize = list.ScrollFrame.buttonHeight;
	end

	if CharacterSelect.viewingInactiveList then
		local count = #(CharacterSelect.inactiveCharacters or {});
		if CharacterSelect.selectedInactiveIndex > count then
			CharacterSelect.selectedInactiveIndex = count;
		end
		if CharacterSelect.selectedInactiveIndex == 0 and count > 0 then
			CharacterSelect.selectedInactiveIndex = 1;
		end
	else
		local numChars = GetNumCharacters();
		if CharacterSelect.selectedIndex == 0 and numChars > 0 then
			CharacterSelect.selectedIndex = 1;
			CharacterSelect.selectedCharacterId = GetCharIDFromIndex(1);
		end
	end

	if list then
		list:RefreshScrollFrame();
		UpdateCharacterSelection(CharacterSelect);
	end

	local numChars = GetNumCharacters();
	local totalCount, maxCount = CharacterSelect_GetTotalCharacterCount();

	-- reset order button
	local needsReset = false;
	if not CharacterSelect.viewingInactiveList then
		for i = 1, numChars do
			if GetCharIDFromIndex(i) ~= i then
				needsReset = true;
				break;
			end
		end
	end
	CharSelectResetOrderButton:SetShown(not CharacterSelect.viewingInactiveList and needsReset);
	if CharacterSelect.viewingInactiveList then
		CharSelectResetOrderButton:Disable();
	else
		CharSelectResetOrderButton:SetEnabled(needsReset);
	end

	if CharacterSelect.viewingInactiveList and CharacterSelectDeleteButton then
		CharacterSelectDeleteButton:Disable();
	end

	CharacterSelect_UpdateActionButtons();
	CharacterSelect_UpdateToggleButtonVisibility();
	CharacterSelect_CheckMaintenance();

	CharacterSelect.createIndex = 0;
	CharSelectCreateCharacterButton:Hide();

	if CharacterSelect.viewingInactiveList then
		CharacterSelect.createIndex = 0;
		CharSelectCreateCharacterButton:Hide();
		CharSelectCreateCharacterButton:Disable();
	else
		local connected = IsConnectedToServer();
		local canCreate = CharacterSelect_CanCreateCharacter();

		if canCreate then
			CharacterSelect.createIndex = numChars + 1;
			if connected then
				CharSelectCreateCharacterButton:SetID(CharacterSelect.createIndex);
				CharSelectCreateCharacterButton:Show();
				CharSelectCreateCharacterButton:Enable();
				CharSelectCreateCharacterButton:ClearAllPoints();
				local hasAdjacentButton = CharSelectInactiveToggleButton and CharSelectInactiveToggleButton:IsShown();
				if hasAdjacentButton then
					CharSelectCreateCharacterButton:SetPoint("BOTTOM", -28, 14);
				else
					CharSelectCreateCharacterButton:SetPoint("BOTTOM", 0, 14);
				end
			end
		end
	end

	if (numChars == 0) and connected and not CharacterSelect.viewingInactiveList then
		CharacterSelect.selectedIndex = 0;
		CharacterSelect.selectedCharacterId = 0;
		CharacterSelect_SelectCharacter(CharacterSelect.selectedIndex, 1);

		if CharacterSelect_IsCorrectClient() and not RealmMerge.CheckForRealmMerge() then
			if not CHARACTER_SELECT_BACK_FROM_CREATE and CONNECTED_SAFE_CHECK then
				CharSelectCreateCharacterButton:GetScript("OnClick")(CharSelectCreateCharacterButton)
			end

			CHARACTER_SELECT_BACK_FROM_CREATE = false
		end
	end
end

function CharacterSelectButton_OnClick(self)
	local id = self:GetID();
	if CharacterSelect.viewingInactiveList then
		local dataIndex = self.dataIndex or id;
		CharacterSelect_SelectInactiveCharacter(dataIndex);
		UpdateCharacterSelection(CharacterSelect);
		return;
	end

	if (id ~= CharacterSelect.selectedIndex) then
		CharacterSelect_SelectCharacter(id);
	end
end

function CharacterSelectButton_OnDoubleClick(self)
	local id = self:GetID();
	if CharacterSelect.viewingInactiveList then
		local dataIndex = self.dataIndex or id;
		CharacterSelect_SelectInactiveCharacter(dataIndex);
		CharacterSelect_ActivateSelectedInactive();
		return;
	end

	if (id ~= CharacterSelect.selectedIndex) then
		CharacterSelect_SelectCharacter(id);
	end
	CharacterSelect_EnterWorld();
end

function CharacterSelect_TabResize(self)
	local buttonMiddle = _G[self:GetName() .. "Middle"];
	local buttonMiddleDisabled = _G[self:GetName() .. "MiddleDisabled"];
	local width = self:GetTextWidth() - 8;
	local leftWidth = _G[self:GetName() .. "Left"]:GetWidth();
	buttonMiddle:SetWidth(width);
	buttonMiddleDisabled:SetWidth(width);
	self:SetWidth(width + (2 * leftWidth));
end

function CharacterSelect_SelectCharacter(id, noCreate, skipListUpdate)
	if CharacterSelect.viewingInactiveList then
		return;
	end

	if (id == CharacterSelect.createIndex) then
		if (not noCreate) then
			PlaySound("gsCharacterSelectionCreateNew");
			SetGlueScreen("charcreate");
		end
	else
		CharacterSelect.selectedIndex = id;
		CharacterSelect.selectedCharacterId = GetCharIDFromIndex(id);
		CharacterSelect.currentModel = GetSelectBackgroundModel(GetCharIDFromIndex(id));
		SetBackgroundModel(CharacterSelect, CharacterSelect.currentModel);

		SelectCharacter(GetCharIDFromIndex(id));
		if CharacterSelect.list and not skipListUpdate then
			CharacterSelect.list:SetSelectedIndex(id);
			CharacterSelect.list:ScrollToSelection();
		end
	end
end

function CharacterSelect_SelectCharacterID(id, noCreate)
	if CharacterSelect.viewingInactiveList then
		return;
	end

	if (id == CharacterSelect.createIndex) then
		if (not noCreate) then
			PlaySound("gsCharacterSelectionCreateNew");
			SetGlueScreen("charcreate");
		end
	else
		CharacterSelect.currentModel = GetSelectBackgroundModel(id);
		SetBackgroundModel(CharacterSelect, CharacterSelect.currentModel);

		SelectCharacter(id);
	end
end

function CharacterDeleteDialog_OnShow()
	local name, race, class, level = GetCharacterInfo(GetCharIDFromIndex(CharacterSelect.selectedIndex));
	CharacterDeleteText1:SetFormattedText(CONFIRM_CHAR_DELETE, name, level, class);
	CharacterDeleteBackground:SetHeight(16 + CharacterDeleteText1:GetHeight() + CharacterDeleteText2:GetHeight() + 23 + CharacterDeleteEditBox:GetHeight() + 8 + CharacterDeleteButton1:GetHeight() + 16);
	CharacterDeleteButton1:Disable();
end

function CharacterSelect_EnterWorld()
	if CharacterSelect.viewingInactiveList then
		CharacterSelect_ActivateSelectedInactive();
		return;
	end

	if not CharacterSelect_IsCorrectClient() then
		return;
	end

	C_Hook:SendEvent("PLAYER_ENTERING_WORLD")
	PlaySound("gsCharacterSelectionEnterWorld");
	StopGlueAmbience();
	C_AddonPanel:EnableHiddenAddons()
	EnterWorld();
end

function CharacterSelect_Exit()
	PlaySound("gsCharacterSelectionExit");
	DisconnectFromServer();
	SetGlueScreen("login");
end

function CharacterSelect_AccountOptions()
	PlaySound("gsCharacterSelectionAcctOptions");
end

function CharacterSelect_TechSupport()
	PlaySound("gsCharacterSelectionAcctOptions");
	LaunchURL(TECH_SUPPORT_URL);
end

function CharacterSelect_Delete()
	PlaySound("gsCharacterSelectionDelCharacter");
	if CharacterSelect.viewingInactiveList then
		return;
	end
	if (CharacterSelect.selectedIndex > 0) then
		CharacterDeleteDialog:Show();
	end
end

function CharacterSelect_DeleteSelectedCharacter()
	if CharacterSelect.viewingInactiveList then
		return;
	end
	if not CharacterSelect.selectedIndex then return end
	tremove(translationTable, CharacterSelect.selectedIndex)
	for i = 1, #translationTable do
		if translationTable[i] > CharacterSelect.selectedCharacterId then
			translationTable[i] = translationTable[i] - 1
		end
	end
	if HasJsonCacheData("CHARACTER_SELECTION_SORT_ORDER_PAYLOAD", 0) then
		SendTranslationTable()
	end
	CharacterSelect.justDeleted = true
	DeleteCharacter(CharacterSelect.selectedCharacterId);
	CharacterDeleteDialog:Hide();
	PlaySound("gsTitleOptionOK");
end

function CharacterSelect_ChangeRealm()
	PlaySound("gsCharacterSelectionDelCharacter");
	RequestRealmList(1);
end

function CharacterSelectFrame_OnMouseDown(button)
	if (button == "LeftButton") then
		CHARACTER_SELECT_ROTATION_START_X = GetCursorPosition();
		CHARACTER_SELECT_INITIAL_FACING = GetCharacterSelectFacing();
	end
end

function CharacterSelectFrame_OnMouseUp(button)
	if (button == "LeftButton") then
		CHARACTER_SELECT_ROTATION_START_X = nil
	end
end

function CharacterSelectFrame_OnUpdate()
	if (CHARACTER_SELECT_ROTATION_START_X) then
		local x = GetCursorPosition();
		local diff = (x - CHARACTER_SELECT_ROTATION_START_X) * CHARACTER_ROTATION_CONSTANT;
		CHARACTER_SELECT_ROTATION_START_X = GetCursorPosition();
		SetCharacterSelectFacing(GetCharacterSelectFacing() + diff);
	end
end

function CharacterSelectRotateRight_OnUpdate(self)
	if (self:GetButtonState() == "PUSHED") then
		SetCharacterSelectFacing(GetCharacterSelectFacing() + CHARACTER_FACING_INCREMENT);
	end
end

function CharacterSelectRotateLeft_OnUpdate(self)
	if (self:GetButtonState() == "PUSHED") then
		SetCharacterSelectFacing(GetCharacterSelectFacing() - CHARACTER_FACING_INCREMENT);
	end
end

function CharacterSelect_ManageAccount()
	PlaySound("gsCharacterSelectionAcctOptions");
	LaunchURL(AUTH_NO_TIME_URL);
end

function RealmSplit_GetFormatedChoice(formatText)
	if (SERVER_SPLIT_CLIENT_STATE == 1) then
		realmChoice = SERVER_SPLIT_SERVER_ONE;
	else
		realmChoice = SERVER_SPLIT_SERVER_TWO;
	end
	return format(formatText, realmChoice);
end

function RealmSplit_SetChoiceText()
	RealmSplitCurrentChoice:SetText(RealmSplit_GetFormatedChoice(SERVER_SPLIT_CURRENT_CHOICE));
	RealmSplitCurrentChoice:Show();
end

function CharacterSelect_PaidServiceOnClick(self, button, down, service)
	PAID_SERVICE_CHARACTER_ID = GetCharIDFromIndex(self:GetID());
	PAID_SERVICE_TYPE = service;
	PlaySound("gsCharacterSelectionCreateNew");
	SetGlueScreen("charcreate");
end

function CharacterSelect_ResetCharacterOrder()
	wipe(translationTable)
	for i = 1, GetNumCharacters() do
		translationTable[i] = i
	end
	SendTranslationTable()
	UpdateCharacterList()
	CharacterSelect_SelectCharacter(1)
end

function CharacterSelect_IsCorrectClient()
	if false --[[GetRealmMaintenance()]] then
		return false, "This realm is currently in maintenance and will be available soon.|nCheck the Ascension Discord for more information."
	elseif HasVisitedArea52ThisSession() and GetRealmId() ~= 11 then
		return false, "You must restart your client before entering another realm."
	elseif IsGMClient then
		return true
	elseif PTR_CLIENT and not C_Realm.IsPTR() then
		return false, "PTR Client Cannot Connect to Live Realms! Use the Live Client from the Launcher!"
	elseif not PTR_CLIENT and C_Realm.IsPTR() and GetRealmId() ~= 8 then
		return false, "Live Client Cannot Connect to PTR Realms! Use the PTR Client from the Launcher!"
	end
	
	return true
end

function CharacterSelect_CheckRealmMask(button)
	local isCorrect = CharacterSelect_IsCorrectClient()
	local allow = isCorrect and not CharacterSelect.viewingInactiveList
	button:SetEnabled(allow)
end

CharacterSelectMailIndicationButtonMixin = {}

function CharacterSelectMailIndicationButtonMixin:OnLoad()
	self:SetMailSenders()
end

function CharacterSelectMailIndicationButtonMixin:OnEnter()
	GlueTooltip:SetOwner(self, "ANCHOR_LEFT")
	GlueTooltip:SetText("Unread Mail")
	GlueTooltip:Show()

	-- cant actually handle senders server side atm
	--[[if #self.mailSenders >= 1 then
		GlueTooltip:SetOwner(self, "ANCHOR_LEFT")
		local str = HAVE_MAIL_FROM .. "|cffFFFFFF"
		for _, sender in ipairs(self.mailSenders) do
			str = str .. "\n" .. sender
		end
		
		str = str.."|r"
		
		GlueTooltip:SetText(str)
		GlueTooltip:Show()
	end]]
end

function CharacterSelectMailIndicationButtonMixin:OnLeave()
	GlueTooltip:Hide()
end

function CharacterSelectMailIndicationButtonMixin:SetMailSenders(mailSenders)
	if not mailSenders then
		mailSenders = {}
	end
	self.mailSenders = mailSenders
end
