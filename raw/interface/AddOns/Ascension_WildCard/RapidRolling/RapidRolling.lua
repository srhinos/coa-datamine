local addonName = ...

WC_RAPID_ROLL_SCROLLS_SPENT = WC_RAPID_ROLL_SCROLLS_SPENT or "Scrolls Used: %s"

WildCardRapidRollingMixin = WildCardRapidRollingMixin or {}

function WildCardRapidRollingMixin:OnLoad()
    self:CoordinateLayout()
    BasicFrame_SetTitle(self, CA_RAPID_ROLLING)
    self.RollingFrame.Bg:SetAtlas("wcmr-bg", Const.TextureKit.IgnoreAtlasSize)

    self.DesiredAbilities.InsetFrame.Bg:SetTexture("Interface\\darkmoon\\bg_256", "REPEAT", "REPEAT")
    self.UndesiredAbilities.InsetFrame.Bg:SetTexture("Interface\\darkmoon\\bg_256", "REPEAT", "REPEAT")

    self:EnableMouse(true)
    self:EnableMouseWheel(true)

    self.DesiredAbilities:SetGetNumResultsFunction(function()
        local numDesired = C_Wildcard.GetNumFilteredDesiredEntries()
        self.DesiredAbilities.NoResultsText:SetShown(numDesired == 0)
        return numDesired
    end)
    self.DesiredAbilities:SetSelectedHighlightAtlas("spell-list-button-selected")
    self.DesiredAbilities:SetTemplate("RapidRollDesiredSpellListItemTemplate")

    self.UndesiredAbilities:SetGetNumResultsFunction(function()
        local numUndesired = C_Wildcard.GetNumFilteredUndesiredEntries()
        self.UndesiredAbilities.NoResultsText:SetShown(numUndesired == 0)
        return numUndesired
    end)
    self.UndesiredAbilities:SetSelectedHighlightAtlas("spell-list-button-selected")
    self.UndesiredAbilities:SetTemplate("RapidRollUndesiredSpellListItemTemplate")

    CharacterAdvancementUtil.InitializeFilter(self.DesiredFilter, function() self:DesiredSearch() end, true)
    CharacterAdvancementUtil.InitializeFilter(self.UndesiredFilter, function() self:UndesiredSearch()  end, true)
    UIDropDownMenu_Initialize(self.HeroArchitectImport.DropDown, GenerateClosure(self.GenerateHeroArchitectImportDropDown, self), "MENU", 1)
end 

function WildCardRapidRollingMixin:OnShow()
    self.completingSession = nil
    self:CoordinateLayout()
    self:RestoreSavedSelections()
    self:RestoreFilterState()
    
    self:RegisterEvent("WILDCARD_DESIRED_ENTRIES_CHANGED")
    self:RegisterEvent("WILDCARD_UNDESIRED_ENTRIES_CHANGED")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:RegisterEvent("WILDCARD_RAPID_ROLL_RESULT")
    self:RegisterEvent("WILDCARD_RAPID_ROLL_LEARNED")
    self:RegisterEvent("WILDCARD_RAPID_ROLL_UNLEARNED")
    self:RegisterEvent("WILDCARD_RAPID_ROLL_STATE_CHANGED")
    self:RegisterEvent("TOKEN_UPDATED")
    self:RegisterEvent("SCROLL_OF_FORTUNE_LIMITS_UPDATED")
    self:RegisterEvent("SCROLL_OF_FORTUNE_REWARDS_LIST_UPDATED")
    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    
    CharacterAdvancement.InputBlocker:Show()
    CharacterAdvancement:UnregisterUpdateEvents()
    
    local maxRolls = C_Wildcard.GetMaximumRapidRolls()
    self.RollingFrame.RollButton:SetFormattedText(CA_WCMR_START_PROCESSING, maxRolls)

    self:Refresh()
    self:UpdatePreviousUpgradeResultDisplay()

    self:AttachDice()
    self:TriggerWalkthrough()
end

function WildCardRapidRollingMixin:OnHide()
    self.currentScrolls = nil
    self.currentTalentScrolls = nil
    self:ClearPreviousUpgradeResultDisplay()
    self:UnregisterEvent("WILDCARD_DESIRED_ENTRIES_CHANGED")
    self:UnregisterEvent("WILDCARD_UNDESIRED_ENTRIES_CHANGED")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:UnregisterEvent("TOKEN_UPDATED")
    self:UnregisterEvent("SCROLL_OF_FORTUNE_LIMITS_UPDATED")
    self:UnregisterEvent("SCROLL_OF_FORTUNE_REWARDS_LIST_UPDATED")
    self:UnregisterEvent("WILDCARD_RAPID_ROLL_RESULT")
    self:UnregisterEvent("WILDCARD_RAPID_ROLL_LEARNED")
    self:UnregisterEvent("WILDCARD_RAPID_ROLL_UNLEARNED")
    self:UnregisterEvent("WILDCARD_RAPID_ROLL_STATE_CHANGED")
    self:UnregisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")

    StaticPopup_Hide("CONFIRM_WILDCARD_MASS_ROLL")

    CharacterAdvancement.InputBlocker:Hide()
    CharacterAdvancement:RegisterUpdateEvents()
    if CharacterAdvancement:IsShown() then
        CharacterAdvancement:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    end

    self.RollingFrame.ErrorFrame:Hide()
    self:DetachDice()
    self.savedBuild = nil
    self:SaveFilterState()

    if SaveSavedVariables then
        SaveSavedVariables(addonName)
    end
end

function WildCardRapidRollingMixin:WILDCARD_DESIRED_ENTRIES_CHANGED()
    self.DesiredAbilities:RefreshScrollFrame()
    self:UpdateRollButton()
    self:UpdateUndesireAllButton()
end

function WildCardRapidRollingMixin:WILDCARD_UNDESIRED_ENTRIES_CHANGED()
    self.UndesiredAbilities:RefreshScrollFrame()
    self:UpdateRollButton()
    self:UpdateUndesireAllButton()
end

function WildCardRapidRollingMixin:TOKEN_UPDATED()
    self:UpdateCurrency()
    self:UpdateRollButton()
    self:UpdateUndesireAllButton()
end 

function WildCardRapidRollingMixin:RefreshScrollOfFortuneRerollDisplay()
    self:UpdateCurrency()
    self:UpdateRollButton()
    self:UpdateUndesireAllButton()
end

function WildCardRapidRollingMixin:SCROLL_OF_FORTUNE_LIMITS_UPDATED()
    self:RefreshScrollOfFortuneRerollDisplay()
end

function WildCardRapidRollingMixin:SCROLL_OF_FORTUNE_REWARDS_LIST_UPDATED()
    self:RefreshScrollOfFortuneRerollDisplay()
end

function WildCardRapidRollingMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    if self.undesireAll and self.savedBuild then
        self:UndesireBuildAllSpells(self.savedBuild)
    else
        self:Refresh(true)
    end
end

function WildCardRapidRollingMixin:CHARACTER_ADVANCEMENT_LOCK_ENTRY_RESULT()
    self:Refresh()
end

function WildCardRapidRollingMixin:WILDCARD_RAPID_ROLL_STATE_CHANGED()
    self:UpdateFromRapidRollingState(true)
end

function WildCardRapidRollingMixin:WILDCARD_RAPID_ROLL_LEARNED(internalID, newRank, preRollRank, reason)
    self:UpdateFromRapidRollingState(true)
    if reason == "STOP_RAPID_ROLLING_COULD_NOT_UNLEARN_ABILITY" or reason == "STOP_RAPID_ROLLING_COULD_NOT_UNLEARN_TALENT" then
        self:ShowRapidRollingError(reason)
    end

    if reason == self.STOP_RAPID_ROLLING_TALENT_UPGRADE_LEARNED
        or reason == self.STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_PENDING then
        self:CachePreviousUpgradeResultDisplay(internalID, newRank, preRollRank)
    end

    if reason == "STOP_RAPID_ROLLING_DESIRED_ENTRY_LEARNED" and not self.rapidRollingState then
        WildCardDice:SetRapidRollIsDesired(true)
    end

    -- Auto-roll chaining for talent upgrades during rapid rolling
    if preRollRank and preRollRank > 0 and WildCardDice.isRapidRolling then
        Timer.After(0.1, function()
            if self:IsShown() and self:IsAwaitingRapidRollingTalentUpgradeRoll() then
                self:Roll(true)
            end
        end)
    end
end

function WildCardRapidRollingMixin:WILDCARD_RAPID_ROLL_UNLEARNED(internalID, rank, reason)
    if not reason then
        self:UpdateFromRapidRollingState(true)
        return
    end

    if reason ~= "CA_UNLEARN_OK" then
        self:ShowRapidRollingError(reason)
    end

    self:UpdateFromRapidRollingState(true)
end

function WildCardRapidRollingMixin:WILDCARD_RAPID_ROLL_RESULT(result)
    self:RegisterEvent("TOKEN_UPDATED")
    self:UpdateFromRapidRollingState(true)
    self:ShowRapidRollingError(result)
end

function WildCardRapidRollingMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED()
    if C_Wildcard.CanUseRapidRolling() then
        self:ClearPreviousUpgradeResultDisplay()
        self:RestoreSavedSelections()
        self:RestoreFilterState()
        self:Refresh()
    else
        self:Hide()
    end
end

function WildCardRapidRollingMixin:ToggleLocked()
    local internalID = WildCardDice:GetInternalID()
    if not internalID then
        return
    end

    local locked = C_CharacterAdvancement.IsLockedID(internalID)

    if locked then
        local spellID = CharacterAdvancementUtil.GetSpellByID(internalID)
        StaticPopup_Show("UNLOCK_SPELL_CONFIRM", LinkUtil:GetSpellLink(spellID), nil, internalID)
    else
        C_CharacterAdvancement.LockID(internalID)
    end
end

function WildCardRapidRollingMixin:MarkForUnlearn()
    local internalID = WildCardDice:GetInternalID()
    if not internalID then
        return
    end

    local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)
    if not entry then
        return
    end

    local canAdd, reason = C_Wildcard.CanAddUndesiredID(entry.ID, entry.Type)
    if canAdd or reason == "ADD_WILDCARD_UNDESIRED_ENTRY_ALREADY_UNDESIRED" then
        self:SaveUndesiredEntry(entry.ID, entry.Type)
        self:Refresh()
        if self:IsAwaitingRapidRollingContinue(self:GetRapidRollingState()) then
            self:Roll(true)
        else
            self:UpdateRollButton()
        end
    end
end

function WildCardRapidRollingMixin:Roll(skipConfirm)
    local state = self:GetRapidRollingState()
    local awaitingContinue = self:IsAwaitingRapidRollingContinue(state)
    local inFlight = self:IsRapidRollingInFlight(state)
    local terminalResult = self:IsRapidRollingTerminalResult(state)
    local diceIsActive = self:IsRapidRollingDiceActive(state)

    if inFlight or (diceIsActive and not awaitingContinue and not terminalResult) then
        self:UpdateRollButton()
        return
    end

    if terminalResult and not self:IsAwaitingRapidRollingTalentUpgradeRoll() then
        -- Terminate the rapid rolling session on the server to prevent being hard stuck in active session state.
        -- We flag completingSession to suppress redundant backend errors (e.g. ROLL_ABILITIES_NO_ROLL) triggered by cancelling a terminal session.
        self.completingSession = true
        if type(C_Wildcard.CancelRapidRolling) == "function" then
            C_Wildcard.CancelRapidRolling()
        end
        self:ClearPreviousUpgradeResultDisplay()
        WildCardDice:Hide()
        self:UpdateRollButton()
        return
    end

    skipConfirm = skipConfirm or self.skipConfirm

    if not awaitingContinue and not self:IsAwaitingRapidRollingTalentUpgradeRoll() and not skipConfirm then
        StaticPopup_Show("CONFIRM_WILDCARD_MASS_ROLL", nil, nil, function(skipFutureConfirm)
            self.skipConfirm = skipFutureConfirm
            self:Roll(true)
        end)
        return
    end

    self:UnregisterEvent("TOKEN_UPDATED") -- We don't want to update the currency while rolling its laggy and breaks animations
    self.RollingFrame.RollButton:Disable()
    PlaySound(SOUNDKIT.GO_8FX_VISIONS_TITAN_CLEANSINGLIGHT_OPEN_START_02)

    local ok, reason
    if awaitingContinue or self:IsAwaitingRapidRollingTalentUpgradeRoll() then
        if state and state.StopCode == self.STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_LEARNED then
            self:ClearPreviousUpgradeResultDisplay()
        end

        if self:IsAwaitingRapidRollingTalentUpgradeRoll() and C_Wildcard.CanRollAbilities() then
            ok = C_Wildcard.RollAbilities()
            reason = ok and nil or "ROLL_ABILITIES_NO_ROLL"
        else
            if type(C_Wildcard.ContinueRapidRolling) ~= "function" then
                self:RegisterEvent("TOKEN_UPDATED")
                self:UpdateRollButton()
                return
            end
            ok, reason = C_Wildcard.ContinueRapidRolling()
        end
    else
        self.completingSession = nil
        self:ClearPreviousUpgradeResultDisplay()
        WildCard:ClearSoFRoll()
        ok, reason = C_Wildcard.StartRapidRolling()
    end

    if not ok then
        self:RegisterEvent("TOKEN_UPDATED")
        self:ClearPreviousUpgradeResultDisplay()
        self:ShowRapidRollingError(reason)
        self:UpdateRollButton()
    end
end
