-- RapidRollingRender.lua
-- Event-driven rendering and dirty-flag state presentation for Rapid Rolling UI.

WildCardRapidRollingMixin = WildCardRapidRollingMixin or {}

-- State/Phase Constants
WildCardRapidRollingMixin.STOP_RAPID_ROLLING_TALENT_UPGRADE_LEARNED = "STOP_RAPID_ROLLING_TALENT_UPGRADE_LEARNED"
WildCardRapidRollingMixin.STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_PENDING = "STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_PENDING"
WildCardRapidRollingMixin.STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_LEARNED = "STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_LEARNED"

local RAPID_ROLLING_IN_FLIGHT_PHASES = {
    WaitingForUnlearn = true,
    WaitingForRoll = true,
    WaitingForLearn = true,
    Revealing = true,
}

local RAPID_ROLLING_SUPPRESSED_START_REASONS = {
    RAPID_ROLLING_SESSION_ACTIVE = true,
    RAPID_ROLLING_REQUEST_IN_FLIGHT = true,
}

local RAPID_ROLLING_TERMINAL_RESULT_PHASES = {
    Completed = true,
    Failed = true,
    Cancelled = true,
}

local RAPID_ROLLING_CONTINUE_PHASES = {
    AwaitingContinue = true,
}

-- State Inspection Mixin APIs
function WildCardRapidRollingMixin:IsAwaitingRapidRollingContinue(state)
    return state and RAPID_ROLLING_CONTINUE_PHASES[state.Phase]
end

function WildCardRapidRollingMixin:IsRapidRollingInFlight(state)
    return state and RAPID_ROLLING_IN_FLIGHT_PHASES[state.Phase]
end

function WildCardRapidRollingMixin:IsRapidRollingTerminalResult(state)
    return state and RAPID_ROLLING_TERMINAL_RESULT_PHASES[state.Phase]
end

function WildCardRapidRollingMixin:IsSuppressedRapidRollingStartReason(reason)
    return reason and RAPID_ROLLING_SUPPRESSED_START_REASONS[reason]
end

function WildCardRapidRollingMixin:IsAwaitingRapidRollingTalentUpgradeRoll()
    return type(C_Wildcard.IsAwaitingRapidRollingTalentUpgradeRoll) == "function"
        and C_Wildcard.IsAwaitingRapidRollingTalentUpgradeRoll()
end

function WildCardRapidRollingMixin:IsRapidRollingDiceActive(state)
    if not WildCardDice:IsShown() then
        return false
    end

    local diceCore = WildCardDice.Core
    local diceState = diceCore and diceCore:GetState()
    if state and state.Phase == "Idle" and diceCore
        and diceState == diceCore.State.IDLE
        and not WildCardDice.pendingReveal then
        return false
    end

    return true
end

function WildCardRapidRollingMixin:IsRapidRollingReasonOK(reason)
    return not reason
        or reason == ""
        or reason == "CAN_START_RAPID_ROLLING_OK"
        or reason == "CA_UNLEARN_OK"
        or reason == "ROLL_ABILITIES_OK"
        or reason == "WAITING_FOR_UNLEARN"
        or reason == "WAITING_FOR_TALENT_UPGRADE_ROLL"
        or reason == "STOP_RAPID_ROLLING_NONE"
        or reason == "STOP_RAPID_ROLLING_DESIRED_ENTRY_LEARNED"
        or reason == "STOP_RAPID_ROLLING_COUNT_DEPLETED"
        or reason == self.STOP_RAPID_ROLLING_TALENT_UPGRADE_LEARNED
        or reason == self.STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_PENDING
        or reason == self.STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_LEARNED
        or self:IsSuppressedRapidRollingStartReason(reason)
end

function WildCardRapidRollingMixin:IsRapidRollingTalentUpgradeOverlapState(state)
    if not state then
        return false
    end

    if self:IsRapidRollingTerminalResult(state) then
        return false
    end

    return state.StopCode == self.STOP_RAPID_ROLLING_TALENT_UPGRADE_LEARNED
        or state.StopCode == self.STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_PENDING
        or state.StopCode == self.STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_LEARNED
end

-- Refresh UI (with throttled dirty flags during flight)
function WildCardRapidRollingMixin:Refresh(clearSearch)
    if clearSearch then
        self:SaveFilterState()
        self:RestoreFilterState()
    end

    local state = self:GetRapidRollingState()
    local inFlight = self:IsRapidRollingInFlight(state)

    if inFlight then
        -- Throttled dirty-flag updates while rolling in progress to prevent lag spikes
        self.listsDirty = true
        self.currencyDirty = true
    else
        self:DesiredSearch()
        self:UndesiredSearch()
        self:UpdateCurrency()
        self.listsDirty = nil
        self.currencyDirty = nil
    end

    self:UpdateRollButton()
    self:UpdateUndesireAllButton()
end

function WildCardRapidRollingMixin:DesiredSearch(text)
    if not text then
        text = self.DesiredSearchBox:GetText():trim()
    end
    C_Wildcard.SetFilteredDesiredEntries(text, self.DesiredFilter:GetFilter())
    self.DesiredAbilities:RefreshScrollFrame()
    self:SaveFilterState()
end

function WildCardRapidRollingMixin:UndesiredSearch(text)
    if not text then
        text = self.UndesiredSearchBox:GetText():trim()
    end
    C_Wildcard.SetFilteredUndesiredEntries(text, self.UndesiredFilter:GetFilter())
    self.UndesiredAbilities:RefreshScrollFrame()
    self:SaveFilterState()
end

-- Currency Presentation (Handles Throttling during Active Roll)
function WildCardRapidRollingMixin:UpdateCurrency()
    local state = self:GetRapidRollingState()
    local inFlight = self:IsRapidRollingInFlight(state)

    if inFlight then
        self.currencyDirty = true
        return
    end

    local specID = SpecializationUtil.GetActiveSpecialization()
    if not specID then
        return
    end

    -- General Scrolls
    local tokenType = TokenUtil.GetScrollOfFortuneForSpec(specID)
    local tokenCount = TokenUtil.GetTokenCount(tokenType)
    local textColor = (tokenCount > 0) and GREEN_FONT_COLOR or GRAY_FONT_COLOR
    local token = TokenUtil.CreateFromTokenType(tokenType)

    self.RollingFrame.GeneralScrollLabel:SetText(token:GetName())
    self.RollingFrame.GeneralScrollLabel:SetTextColor(textColor:GetRGB())
    self.RollingFrame.GeneralScrollCount:SetText(tokenCount)

    if self.currentScrolls and tokenCount < self.currentScrolls then
        local currentRolls = C_Wildcard.GetRapidRollAbilityBreakpointInfo()
        local diff = self.currentScrolls - tokenCount
        self.RollingFrame.ScrollsSpentLabel:SetText(string.format(WC_RAPID_ROLL_SCROLLS_SPENT, (currentRolls == diff) and "|cffFFFFFF"..diff.."|r" or "|cff00FF00"..diff.."|r"))
        self.RollingFrame.GeneralScrollMinus:SetText("-" .. diff)
        self.RollingFrame.GeneralScrollMinus.Anim:Play()
    end
    self.currentScrolls = tokenCount

    -- Talent Scrolls
    tokenType = TokenUtil.GetScrollOfFortuneTalentsForSpec(specID)
    tokenCount = TokenUtil.GetTokenCount(tokenType)
    textColor = (tokenCount > 0) and GREEN_FONT_COLOR or GRAY_FONT_COLOR
    token = TokenUtil.CreateFromTokenType(tokenType)

    self.RollingFrame.TalentScrollLabel:SetText(token:GetName())
    self.RollingFrame.TalentScrollLabel:SetTextColor(textColor:GetRGB())
    self.RollingFrame.TalentScrollCount:SetText(tokenCount)

    if self.currentTalentScrolls and tokenCount < self.currentTalentScrolls then
        local currentRolls = C_Wildcard.GetRapidRollTalentBreakpointInfo()
        local diff = self.currentTalentScrolls - tokenCount
        self.RollingFrame.ScrollsSpentLabel:SetText(string.format(WC_RAPID_ROLL_SCROLLS_SPENT, (currentRolls == diff) and "|cffFFFFFF"..diff.."|r" or "|cff00FF00"..diff.."|r"))
        self.RollingFrame.TalentScrollMinus:SetText("-" .. diff)
        self.RollingFrame.TalentScrollMinus.Anim:Play()
    end
    self.currentTalentScrolls = tokenCount

    self.currencyDirty = nil
end

-- Error Handling
function WildCardRapidRollingMixin:ShowRapidRollingError(reason)
    if self.completingSession then
        self.RollingFrame.ErrorFrame:Hide()
        return
    end

    if reason == "" then
        reason = "ROLL_ABILITIES_NO_ROLL"
        aprint("|cffFF0000[WILDCARD] Rapid rolling entered a failed state with an empty reason.|r")
    end

    if reason == "CAN_START_RAPID_ROLLING_UNSPENT_TALENT_ESSENCE"
        and self:IsAwaitingRapidRollingTalentUpgradeRoll()
        and C_Wildcard.CanRollAbilities() then
        self.RollingFrame.ErrorFrame:Hide()
        return
    end

    if self:IsRapidRollingReasonOK(reason) then
        self.RollingFrame.ErrorFrame:Hide()
        return
    end

    self.RollingFrame.ErrorFrame:Show()
    self.RollingFrame.ErrorFrame:SetText(RAPID_ROLL_FAILED, _G[reason] or reason)
end

-- Previous Upgrade Result Display cache/render
function WildCardRapidRollingMixin:CachePreviousUpgradeResultDisplay(internalID, newRank, preRollRank)
    if not internalID or internalID == 0 then
        return
    end

    local displayRank = newRank or preRollRank or 1
    local spellID = CharacterAdvancementUtil.GetTalentRankSpellByID(internalID, displayRank)
    if not spellID then
        return
    end

    local name, _, icon = GetSpellInfo(spellID)
    if not name then
        return
    end

    local _, maxRank = C_CharacterAdvancement.GetTalentRankByID(internalID)
    self.previousUpgradeResultDisplay = {
        Icon = icon,
        Name = name,
        Rank = displayRank,
        MaxRank = maxRank,
    }

    self:UpdatePreviousUpgradeResultDisplay()
end

function WildCardRapidRollingMixin:UpdatePreviousUpgradeResultDisplay()
    local frame = self.RollingFrame and self.RollingFrame.PreviousUpgradeFrame
    if not frame then
        return
    end

    local data = self.previousUpgradeResultDisplay
    if not data then
        frame:Hide()
        return
    end

    self.RollingFrame.RollButton.SpellTypeText:Hide()
    self.RollingFrame.RollButton.CoreIcon:Hide()
    self.RollingFrame.RollButton.OptimalIcon:Hide()
    self.RollingFrame.RollButton.EmpoweringIcon:Hide()
    self.RollingFrame.RollButton.SynergisticIcon:Hide()
    frame.Icon:SetTexture(data.Icon)
    frame.Name:SetText(data.Name)
    if data.MaxRank and data.MaxRank > 0 then
        frame.Rank:SetText(data.Rank .. "/" .. data.MaxRank)
    else
        frame.Rank:SetText(data.Rank)
    end
    frame:Show()
end

function WildCardRapidRollingMixin:ClearPreviousUpgradeResultDisplay()
    self.previousUpgradeResultDisplay = nil
    self:UpdatePreviousUpgradeResultDisplay()
end

-- State Sync Update
function WildCardRapidRollingMixin:UpdateFromRapidRollingState(refreshLists)
    self.rapidRollingState = self:GetRapidRollingState()

    if not self:IsRapidRollingTalentUpgradeOverlapState(self.rapidRollingState)
        and not self:IsAwaitingRapidRollingTalentUpgradeRoll() then
        self:ClearPreviousUpgradeResultDisplay()
    end

    if self.rapidRollingState then
        if self.rapidRollingState.IsDesired ~= nil then
            WildCardDice:SetRapidRollIsDesired(self.rapidRollingState.IsDesired)
        end
        self:ShowRapidRollingError(self.rapidRollingState.Reason)
    end

    if refreshLists then
        local state = self:GetRapidRollingState()
        local inFlight = self:IsRapidRollingInFlight(state)
        if inFlight then
            self.listsDirty = true
        else
            self.DesiredAbilities:RefreshScrollFrame()
            self.UndesiredAbilities:RefreshScrollFrame()
            self.listsDirty = nil
        end
    end

    self:UpdateCurrency()
    self:UpdateRollButton()
    self:UpdateUndesireAllButton()
end

-- State-driven Roll Button Presentation (OnUpdate POLLING REMOVED)
function WildCardRapidRollingMixin:UpdateRollButtonEnabled()
    local state = self:GetRapidRollingState()
    self.rapidRollingState = state
    local awaitingContinue = self:IsAwaitingRapidRollingContinue(state)
    local inFlight = self:IsRapidRollingInFlight(state)
    local terminalResult = self:IsRapidRollingTerminalResult(state)
    local canRoll = state and state.CanStart
    local reason = state and state.CanStartReason

    if canRoll == nil then
        canRoll, reason = C_Wildcard.CanStartRapidRolling()
    end

    local diceIsActive = self:IsRapidRollingDiceActive(state)
    if diceIsActive or awaitingContinue or inFlight or terminalResult or self:IsAwaitingRapidRollingTalentUpgradeRoll() then
        self.RollingFrame.ScrollsSpentLabel:Show()
        self.RollingFrame.RollButton.SpellTypeText:Hide()
        self.RollingFrame.RollButton.CoreIcon:Hide()
        self.RollingFrame.RollButton.OptimalIcon:Hide()
        self.RollingFrame.RollButton.EmpoweringIcon:Hide()
        self.RollingFrame.RollButton.SynergisticIcon:Hide()

        local spendingTalentUpgradeRoll = self:IsAwaitingRapidRollingTalentUpgradeRoll()
            and (C_Wildcard.CanRollAbilities() or WildCardDice.pendingReveal)
        local isEnabled = (awaitingContinue or terminalResult or spendingTalentUpgradeRoll) and not inFlight
        self.RollingFrame.RollButton:SetEnabled(isEnabled)

        if self.savedBuild and (awaitingContinue or terminalResult) and WildCardDice:GetSpellID() then
            local spell = C_BuildCreator.GetSpell(self.savedBuild.ID, WildCardDice:GetSpellID()) 

            if spell then
                self.RollingFrame.RollButton.CoreIcon:SetShown(spell.IsCoreAbility)
                self.RollingFrame.RollButton.OptimalIcon:SetShown(spell.IsOptimalAbility)
                self.RollingFrame.RollButton.EmpoweringIcon:SetShown(spell.IsEmpoweringAbility)
                self.RollingFrame.RollButton.SynergisticIcon:SetShown(spell.IsSynergisticAbility)

                if spell.IsCoreAbility or spell.IsOptimalAbility or spell.IsEmpoweringAbility or spell.IsSynergisticAbility then
                    self.RollingFrame.RollButton.SpellTypeText:Show()
                    self.RollingFrame.RollButton.SpellTypeText:SetText((spell.IsCoreAbility and BUILD_CORE_SPELL) or (spell.IsOptimalAbility and BUILD_OPTIMAL_SPELL) or (spell.IsEmpoweringAbility and BUILD_EMPOWERING_SPELL) or (spell.IsSynergisticAbility and BUILD_SYNERGISTIC_SPELL))
                end
            end
        end

        if self.previousUpgradeResultDisplay then
            self.RollingFrame.RollButton.SpellTypeText:Hide()
            self.RollingFrame.RollButton.CoreIcon:Hide()
            self.RollingFrame.RollButton.OptimalIcon:Hide()
            self.RollingFrame.RollButton.EmpoweringIcon:Hide()
            self.RollingFrame.RollButton.SynergisticIcon:Hide()
        end

        self.RollingFrame.RollButton:SetText((terminalResult and not self:IsAwaitingRapidRollingTalentUpgradeRoll()) and (COMPLETE or "COMPLETE") or CONTINUE)
        local internalID = WildCardDice:GetInternalID()
        local learnedEntryID = state and state.LearnedEntryID
        local stopCode = state and state.StopCode
        if internalID and learnedEntryID and internalID == learnedEntryID
            and stopCode ~= self.STOP_RAPID_ROLLING_TALENT_UPGRADE_LEARNED
            and stopCode ~= self.STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_LEARNED then
            self.RollingFrame.LockButton:Show()
            if C_CharacterAdvancement.IsLockedID(internalID) then
                self.RollingFrame.UnlearnButton:Hide()
                self.RollingFrame.LockButton:SetAtlas("spell-list-locked", Const.TextureKit.IgnoreAtlasSize)
                self.RollingFrame.LockButton:SetTooltipInfo(UNLOCK_SPELL, UNLOCK_SPELL_TOOLTIP)
            else
                self.RollingFrame.UnlearnButton:Show()
                self.RollingFrame.LockButton:SetAtlas("spell-list-unlocked", Const.TextureKit.IgnoreAtlasSize)
                self.RollingFrame.LockButton:SetTooltipInfo(LOCK_SPELL, LOCK_SPELL_TOOLTIP)
            end
        else
            self.RollingFrame.UnlearnButton:Hide()
            self.RollingFrame.LockButton:Hide()
        end
    else
        self.RollingFrame.ScrollsSpentLabel:Hide()
        self.RollingFrame.RollButton.SpellTypeText:Hide()
        self.RollingFrame.RollButton.CoreIcon:Hide()
        self.RollingFrame.RollButton.OptimalIcon:Hide()
        self.RollingFrame.RollButton.EmpoweringIcon:Hide()
        self.RollingFrame.RollButton.SynergisticIcon:Hide()
            
        self.RollingFrame.RollButton:SetEnabled(canRoll and not inFlight)
    end
    self.RollingFrame.RollButton.Error:SetShown(not canRoll and not diceIsActive and not awaitingContinue and not inFlight and not terminalResult and not self:IsAwaitingRapidRollingTalentUpgradeRoll() and not self:IsSuppressedRapidRollingStartReason(reason))
    self.RollingFrame.RollButton.Error:SetText(reason and _G[reason] or reason)
end

function WildCardRapidRollingMixin:UpdateRollButton()
    local state = self:GetRapidRollingState()
    local awaitingContinue = self:IsAwaitingRapidRollingContinue(state)
    local inFlight = self:IsRapidRollingInFlight(state)
    local terminalResult = self:IsRapidRollingTerminalResult(state)
    local diceIsActive = self:IsRapidRollingDiceActive(state)

    -- Process dirty-flag flushing if transitioning out of rolling flight
    if not inFlight then
        if self.currencyDirty then
            self:UpdateCurrency()
        end
        if self.listsDirty then
            self.DesiredAbilities:RefreshScrollFrame()
            self.UndesiredAbilities:RefreshScrollFrame()
            self.listsDirty = nil
        end
    end

    self:UpdateRollButtonEnabled()

    if not (diceIsActive or awaitingContinue or inFlight or terminalResult or self:IsAwaitingRapidRollingTalentUpgradeRoll()) then
        local maxRolls = C_Wildcard.GetMaximumRapidRolls()
        self.RollingFrame.RollButton:SetFormattedText(CA_WCMR_START_PROCESSING, maxRolls)
        self.RollingFrame.UnlearnButton:Hide()
        self.RollingFrame.LockButton:Hide()
    end

    -- Abilities Breakpoint Info
    local currentRolls, rollsRequired, nextMaxRoll = C_Wildcard.GetRapidRollAbilityBreakpointInfo()
    if rollsRequired and rollsRequired > 0 then
        self.RollingFrame.ScrollProgress:Show()
        self.RollingFrame.ScrollProgress:SetText(currentRolls .. "/" .. rollsRequired)
        self.RollingFrame.ScrollProgress.RewardText:SetFormattedText(NEXT_SPELL_ROLL_LIMIT, nextMaxRoll)
        self.RollingFrame.ScrollProgress:SetMinMaxValues(0, rollsRequired)
        self.RollingFrame.ScrollProgress:SetValue(currentRolls)
    else
        self.RollingFrame.ScrollProgress:Hide()
    end
    
    -- Talents Breakpoint Info
    currentRolls, rollsRequired, nextMaxRoll = C_Wildcard.GetRapidRollTalentBreakpointInfo()
    if rollsRequired and rollsRequired > 0 then
        self.RollingFrame.TalentScrollProgress:Show()
        self.RollingFrame.TalentScrollProgress:SetText(currentRolls .. "/" .. rollsRequired)
        self.RollingFrame.TalentScrollProgress.RewardText:SetFormattedText(NEXT_TALENT_ROLL_LIMIT, nextMaxRoll)
        self.RollingFrame.TalentScrollProgress:SetMinMaxValues(0, rollsRequired)
        self.RollingFrame.TalentScrollProgress:SetValue(currentRolls)
    else
        self.RollingFrame.TalentScrollProgress:Hide()
    end
end

function WildCardRapidRollingMixin:UpdateUndesireAllButton()
    local show = self.undesireAll
    self.UndesireAllButton:SetShown(show)

    self.UndesireSynergistic:SetPoint("RIGHT", self.UndesireAllButton, "LEFT", -(self.UndesireSynergistic.Text:GetStringWidth() + 10), 1)
    self.UndesireSynergistic:SetShown(show)
    self.UndesireEmpowering:SetPoint("RIGHT", self.UndesireSynergistic, "LEFT", -(self.UndesireEmpowering.Text:GetStringWidth() + 10), 0)
    self.UndesireEmpowering:SetShown(show)
end

-- Secure hooks for Dice Animation Lifecycle state presentation
local function OnDiceStateChanged()
    if WildCardDice.isRapidRolling and WildCardRapidRollingFrame and WildCardRapidRollingFrame:IsShown() then
        WildCardRapidRollingFrame:UpdateRollButton()
    end
end

hooksecurefunc(WildCardDice, "Show", OnDiceStateChanged)
hooksecurefunc(WildCardDice, "Hide", OnDiceStateChanged)
hooksecurefunc(WildCardDice, "OnPlayRoll", OnDiceStateChanged)
hooksecurefunc(WildCardDice, "OnFinishedRoll", OnDiceStateChanged)
hooksecurefunc(WildCardDice, "OnPlayCollapse", OnDiceStateChanged)
hooksecurefunc(WildCardDice, "OnFinishedCollapse", OnDiceStateChanged)
hooksecurefunc(WildCardDice, "OnPlayCrack", OnDiceStateChanged)
hooksecurefunc(WildCardDice, "OnFinishedCrack", OnDiceStateChanged)
hooksecurefunc(WildCardDice, "OnFinished", OnDiceStateChanged)
hooksecurefunc(WildCardDice, "SetInternalID", OnDiceStateChanged)
