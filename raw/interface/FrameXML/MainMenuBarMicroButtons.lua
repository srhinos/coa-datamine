function LoadMicroButtonTextures(self, name)
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	self:RegisterEvent("UPDATE_BINDINGS");
	local prefix = "Interface\\Buttons\\UI-MicroButton-";
	self:SetNormalTexture(prefix..name.."-Up");
	self:SetPushedTexture(prefix..name.."-Down");
	self:SetDisabledTexture(prefix..name.."-Disabled");
	self:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight");
end

function MicroButtonTooltipText(text, action)
	if ( GetBindingKey(action) ) then
		return text.." "..NORMAL_FONT_COLOR_CODE.."("..GetBindingText(GetBindingKey(action), "KEY_")..")"..FONT_COLOR_CODE_CLOSE;
	else
		return text;
	end
	
end

-- Draft picks and a ready Wild Card roll share this button; the active mode
-- drives its icon, tooltip and click action.
local function ConfigureDraftMicroButtonForMode(button, mode)
	if button.pendingMode == mode then
		return
	end
	button.pendingMode = mode

	if mode == "wildcard" then
		button:GetNormalTexture():SetPortraitTexture(GetItemIcon(ItemData.DICE_OF_DESTINY) or "Interface\\Icons\\inv_misc_dice_02")
		button.tooltipTitle = WILDCARD_ROLL_ABILITIES or "WILDCARD_ROLL_ABILITIES"
		button.tooltipText = TOGGLE_WILDCARD_ROLL_TOOLTIP or "TOGGLE_WILDCARD_ROLL_TOOLTIP"
	else
		button:GetNormalTexture():SetPortraitTexture("Interface\\Icons\\inv_misc_dmc_destructiondeck")
		button.tooltipTitle = TOGGLE_DRAFT_CARDS
		button.tooltipText = TOGGLE_DRAFT_CARDS_TOOLTIP
	end
end

function UpdateDraftMicroButton()
	local hasDraftPicks = DraftUtil.HasAnyPicks()
	-- Only when a roll is pending and the dice isn't already on screen.
	local hasWildCardRoll = not hasDraftPicks and WildCardUtil.CanShowRollDice() and not WildCardUtil.IsDiceVisible()
	local shouldShow = hasDraftPicks or hasWildCardRoll

	if shouldShow then
		ConfigureDraftMicroButtonForMode(DraftModeMicroButton, hasDraftPicks and "draft" or "wildcard")
	end

	local wasShown = DraftModeMicroButton:IsShown()
	DraftModeMicroButton:SetShown(shouldShow)
	if wasShown ~= shouldShow then
		UpdateMicroButtons()
	end
end

function DraftModeMicroButton_OnEvent(self, event)
	if event == "PLAYER_ENTERING_WORLD" or event == "ASCENSION_CUSTOM_GAME_MODE_CHANGED" or event == "WILDCARD_ROLL_READY" then
		UpdateDraftMicroButton()
	end
end

function CheckUnspentEssences()
	if TalentMicroButton.pulseOn == nil and not Collections:IsShown() then
		if GetItemCount(ItemData.TALENT_ESSENCE) > 1 then
			SetButtonPulse(TalentMicroButton, nil, 1)
			HelpTip:Show("UNSPENT_TALENT_ESSENCE_NEW")
		elseif GetItemCount(ItemData.ABILITY_ESSENCE) > 5 then
            -- default classes dont spend AE
            if not C_Player:IsDefaultClass() then
                SetButtonPulse(TalentMicroButton, nil, 1)
                HelpTip:Show("UNSPENT_ABILITY_ESSENCE_NEW")
            end
		end
	end
end

function CheckPlayerPoll()
    if C_Player:GetLevel() < 10 then
        return
    end
    if HelpMicroButton.pulseOn == nil and (not HelpFrame or not HelpFrame:IsShown()) then
        if C_PlayerPoll.HasUnansweredQuestions() then
            HelpTip:Show("UNANSWERED_PLAYER_POLL_QUESTIONS")
        end
    end
end

function UpdateMicroButtons(level)
	local playerLevel = level or UnitLevel("player");
	if ( AscensionCharacterFrame:IsShown() ) then
		CharacterMicroButton:SetButtonState("PUSHED", 1);
		CharacterMicroButton_SetPushed();
	else
		CharacterMicroButton:SetButtonState("NORMAL");
		CharacterMicroButton_SetNormal();
	end
	
	if ( AscensionSpellbookFrame:IsShown() ) then
		SpellbookMicroButton:SetButtonState("PUSHED", 1);
	else
		SpellbookMicroButton:SetButtonState("NORMAL");
	end

	if ( QuestLogFrame:IsShown() ) then
		QuestLogMicroButton:SetButtonState("PUSHED", 1);
	else
		QuestLogMicroButton:SetButtonState("NORMAL");
	end
	
	if ( ( EscapeMenu:IsShown() ) 
		or ( InterfaceOptionsFrame:IsShown()) 
		or ( KeyBindingFrame and KeyBindingFrame:IsShown()) 
		or ( MacroFrame and MacroFrame:IsShown()) ) then
		MainMenuMicroButton:SetButtonState("PUSHED", 1);
		MainMenuMicroButton_SetPushed();
	else
		MainMenuMicroButton:SetButtonState("NORMAL");
		MainMenuMicroButton_SetNormal();
	end

	if PathToAscensionFrame and PathToAscensionFrame:IsVisible() then
		PathToAscensionMicroButton:SetButtonState("PUSHED", 1)
	else
		local enabled = TutorialUtil.CanOpenPathToAscension()

		if enabled then
			PathToAscensionMicroButton:Enable()
			PathToAscensionMicroButton:SetButtonState("NORMAL")
		else
			PathToAscensionMicroButton:Disable()
		end
	end
	
	if ( FriendsFrame:IsShown() ) then
		SocialsMicroButton:SetButtonState("PUSHED", 1);
	else
		SocialsMicroButton:SetButtonState("NORMAL");
	end

	if ( AscensionLFGFrame:IsVisible() ) then
		LFDMicroButton:SetButtonState("PUSHED", 1);
	else
		if playerLevel >= SHOW_LFD_LEVEL or playerLevel >= SHOW_PVP_LEVEL then
			LFDMicroButton:Enable();
			LFDMicroButton:SetButtonState("NORMAL");
		else
			LFDMicroButton:Disable();
		end
	end

	if ChallengesFrame and ChallengesFrame:IsShown() then
		ChallengesMicroButton:SetButtonState("PUSHED", 1);
	else
		ChallengesMicroButton:SetButtonState("NORMAL");
	end

	if ( HelpMenuFrame and HelpMenuFrame:IsShown() ) then
		HelpMicroButton:SetButtonState("PUSHED", 1);
	else
		HelpMicroButton:SetButtonState("NORMAL");
	end
	
	if ( AchievementFrame and AchievementFrame:IsShown() ) then
		AchievementMicroButton:SetButtonState("PUSHED", 1);
	else
		if ( playerLevel >= 10 and CanShowAchievementUI() ) then
			AchievementMicroButton:Enable();
			AchievementMicroButton:SetButtonState("NORMAL");
		else
			AchievementMicroButton:Disable();
		end
	end

	-- Keyring microbutton
	if ( IsBagOpen(KEYRING_CONTAINER) ) then
		KeyRingButton:SetButtonState("PUSHED", 1);
	else
		KeyRingButton:SetButtonState("NORMAL");
	end

	if Collections:IsShown() then
		if TalentMicroButton.pulseOn ~= nil then
			ButtonPulse_StopPulse(TalentMicroButton)
		end
		--HelpTip:Acknowledge("UNSPENT_TALENT_ESSENCE")
		--HelpTip:Acknowledge("UNSPENT_ABILITY_ESSENCE")
		HelpTip:Hide("UNSPENT_TALENT_ESSENCE_NEW")
		HelpTip:Hide("UNSPENT_ABILITY_ESSENCE_NEW")
		TalentMicroButton:SetButtonState("PUSHED", 1);
	else
		TalentMicroButton:Enable();
		TalentMicroButton:SetButtonState("NORMAL");
	end

	if C_Spell:HasNotMaxedRanks() then
		SpellbookMicroButton.RankUp:Show()
	else
		SpellbookMicroButton.RankUp:Hide()
	end
end

function AchievementMicroButton_OnEvent(self, event, ...)
	if ( event == "UPDATE_BINDINGS" ) then
		AchievementMicroButton.tooltipText = MicroButtonTooltipText(ACHIEVEMENT_BUTTON, "TOGGLEACHIEVEMENT");
	else
		UpdateMicroButtons();
	end
end

function CharacterMicroButton_OnLoad(self)
	self:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Up");
	self:SetPushedTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Down");
	self:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight");
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE");
	self:RegisterEvent("UPDATE_BINDINGS");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self.tooltipText = MicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0");
	self.newbieText = NEWBIE_TOOLTIP_CHARACTER;
end

function CharacterMicroButton_OnEvent(self, event, ...)
	if ( event == "UNIT_PORTRAIT_UPDATE" ) then
		local unit = ...;
		if ( unit == "player" ) then
			SetPortraitTexture(MicroButtonPortrait, unit);
		end
		return;
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		SetPortraitTexture(MicroButtonPortrait, "player");
	elseif ( event == "UPDATE_BINDINGS" ) then
		self.tooltipText = MicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0");
	end
end

function CharacterMicroButton_SetPushed()
	MicroButtonPortrait:SetTexCoord(0.2666, 0.8666, 0, 0.8333);
	MicroButtonPortrait:SetAlpha(0.5);
end

function CharacterMicroButton_SetNormal()
	MicroButtonPortrait:SetTexCoord(0.2, 0.8, 0.0666, 0.9);
	MicroButtonPortrait:SetAlpha(1.0);
end

function MainMenuMicroButton_SetPushed()
	MainMenuMicroButton:SetButtonState("PUSHED", 1);
	MainMenuBarPerformanceBar:SetPoint("TOPLEFT", MainMenuMicroButton, "TOPLEFT", 9, -18);
end

function MainMenuMicroButton_SetNormal()
	MainMenuMicroButton:SetButtonState("NORMAL");
	MainMenuBarPerformanceBar:SetPoint("TOPLEFT", MainMenuMicroButton, "TOPLEFT", 10, -16);
end

--Talent button specific functions
function TalentMicroButton_OnEvent(self, event, ...)
	if ( event == "UPDATE_BINDINGS" ) then
		self.tooltipText =  MicroButtonTooltipText(TALENTS_BUTTON, "TOGGLETALENTS");
	end
end
