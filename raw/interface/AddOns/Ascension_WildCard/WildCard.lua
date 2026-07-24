local AddonName, Addon = ...
-------------------------------------------------------------------------------
--                                  General                                  --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
WildCard = CreateFrame("FRAME")
WildCard:HookEvent("ADDON_LOADED")
WildCard:SetScript("OnEvent", OnEventToMethod)

function WildCard:RegisterEvents()
	dprint("WildCard:RegisterEvents()")

	self:RegisterEvent("WILDCARD_ROLL_READY")
	self:RegisterEvent("WILDCARD_UNLEARN_ABILITY_RESULT")
	self:RegisterEvent("DICE_OF_DESTINY_USED")
	self:RegisterEvent("WILDCARD_ENTRY_LEARNED")
	self:RegisterEvent("WILDCARD_RAPID_ROLL_LEARNED")
	self:RegisterEvent("WILDCARD_RAPID_ROLL_UNLEARNED")
	C_Hook:RegisterBucket(WildCard, {"ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED", "PLAYER_SPECIALIZATION_CHANGED"}, 0.1, "SPECIALIZATION_CHANGED")
end

function WildCard:UnregisterEvents()
	dprint("WildCard:UnregisterEvents()")

	self:UnregisterEvent("WILDCARD_ROLL_READY")
	self:UnregisterEvent("WILDCARD_UNLEARN_ABILITY_RESULT")
	self:UnregisterEvent("DICE_OF_DESTINY_USED")
	self:UnregisterEvent("WILDCARD_ENTRY_LEARNED")
	self:UnregisterEvent("WILDCARD_RAPID_ROLL_LEARNED")
	self:UnregisterEvent("WILDCARD_RAPID_ROLL_UNLEARNED")
	C_Hook:Unregister(WildCard)
end

function WildCard:ShowLevelingDice()
	if ForcedPrimaryStatFrame and (ForcedPrimaryStatFrame:IsVisible()) then
		return
	end

	if WildCardDice:DeferShowForStaticPopup("leveling-dice") then
		return
	end

	WildCardDice:PlayFlipBook("DiceAppearFlipBook")
	self:HideNotifications()
end

function WildCard:HideDices()
	if (WildCardDice:IsVisible()) then
		WildCardDice:UnregisterOnClick()
		BaseFrameFadeOut(WildCardDice)
	end
end

-- Busy = a reveal is in flight (pendingReveal set during crack/scroll/collapse)
-- or a rolled result is on screen waiting for the player's confirm/reroll
-- decision (RollButton visible). Idle covers empty-waiting and mid-appear.
function WildCard:IsDiceBusy()
	if not WildCardDice:IsVisible() then
		return false
	end
	if WildCardDice.StartingChoice and WildCardDice.StartingChoice:IsVisible() then
		return true
	end
	if WildCardDice.pendingReveal then
		return true
	end
	if WildCardDice.RollButton and WildCardDice.RollButton:IsVisible() then
		return true
	end
	return false
end

-- Hide the dice only when it's safe to interrupt. Used by overlapping UIs
-- (e.g. ForcedPrimaryStatFrame) that share the top-center anchor: they want
-- the dice out of the way but must not cancel an in-flight roll or discard
-- a rolled result the player hasn't acted on yet.
function WildCard:HideDicesIfIdle()
	if self:IsDiceBusy() then
		return false
	end
	self:HideDices()
	return true
end

function WildCard:RevealDice(skipClick)
	if not(WildCardDice:IsVisible()) or WildCardDice.isRapidRolling then
		if (skipClick) then

			if self:CanRoll() then
				WildCardDice:HideFlipBooks()
				WildCardDice:OnClick()
				WildCardDice:OnPlayAppear()
			end

			return
		end

		if self:CanRoll() then
			self:ShowLevelingDice()
		end
	elseif skipClick and self:CanRoll() then
		-- SoF reroll with the dice still showing the previous preview: drive
		-- through OnClick so the roll animation plays and RollAbilities fires,
		-- producing the WILDCARD_ENTRY_LEARNED that triggers the crack/reveal.
		-- Guard: if the dice is already rolling away (DiceEmptyEnter hidden) do
		-- nothing; DICE_OF_DESTINY_USED or OnFinishedRoll has already handled it.
		if WildCardDice.DiceEmptyEnter:IsVisible() then
			WildCardDice:OnClick()
		end
	end
end

function WildCard:CanRoll()
	if not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		return false
	end

	-- A pending reveal keeps the dice rollable so in-flight animations finish cleanly.
	return C_Wildcard.CanRollAbilities() or (WildCardDice and WildCardDice.pendingReveal ~= nil)
end

function WildCard:CanShowStartingChoice()
	return C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)
		and C_Wildcard.CanShowStartingChoice
		and C_Wildcard.CanShowStartingChoice()
end

function WildCard:IsSoFRoll()
	return self:CanRoll() and self.isSoFRoll
end

function WildCard:CheckForRolls()
	dprint("WildCard:CheckForRolls CALLED")
	UpdateDraftMicroButton() -- keep the pending-roll micro button in sync
	if not(C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)) then
		self:HideDices()
		return false
	elseif self:CanShowStartingChoice() and WildCardDice:ShowStartingChoicePanel("check") then
		dprint("WildCard:CheckForRolls: ShowStartingChoicePanel()")
		return true
	elseif self:IsSoFRoll() then
		if self.lastRapidRollResult == "STOP_RAPID_ROLLING_COULD_NOT_UNLEARN_ABILITY" then
			self.lastRapidRollResult = nil
			dprint("WildCard:CheckForRolls: Last Rapid Roll Server Error STOP_RAPID_ROLLING_COULD_NOT_UNLEARN_ABILITY")
			dprint("WildCard:CheckForRolls: HideDices()")
			self:ClearSoFRoll()
			self:HideDices()
			return false
		elseif self.lastRapidRollResult == "STOP_RAPID_ROLLING_COULD_NOT_UNLEARN_TALENT" then
			self.lastRapidRollResult = nil
			dprint("WildCard:CheckForRolls: Last Rapid Roll Server Error STOP_RAPID_ROLLING_COULD_NOT_UNLEARN_TALENT")
			dprint("WildCard:CheckForRolls: HideDices()")
			self:ClearSoFRoll()
			self:HideDices()
			return false
		end
		dprint("WildCard:CheckForRolls: IsSoFRoll")
		dprint("WildCard:CheckForRolls: RevealDice()")
		-- Reveal without auto-click. The roll itself is sent by the DLL on
		-- SMSG_WILDCARD_UNLEARN_ABILITY_RESULT(OK) (see
		-- WildcardModeMgr::HandleWildcardUnlearnAbilityResultOpcode). The
		-- previous RevealDice(true) path drove C_Wildcard.RollAbilities via
		-- a programmatic OnClick, which silently dropped at low levels when
		-- canRoll never transitioned false->true.
		self:RevealDice()
		return true
	elseif self:CanRoll() then
		dprint("WildCard:CheckForRolls: CanRoll")
		dprint("WildCard:CheckForRolls: RevealDice()")
		self:RevealDice()
		return true
	else
		dprint("WildCard:CheckForRolls: HideDices()")
		self:HideDices()
		return false
	end

	return false
end

function WildCard:OnHideDice() -- here self is a dice, not WildCard TODO: Maybe change to callback later
	if self.OnHide then
		self:OnHide()
	end

	if self.hidingForStaticPopup then
		return
	end

	WildCard:CheckForRolls()
end

function WildCard:OnSpellReveal()
	if self.isSoFRoll then
		self:ClearSoFRoll()
	end
end

function WildCard:WillRollFirstNonStartingAbility()
	return C_Wildcard.WillRollFirstNonStartingAbility and C_Wildcard.WillRollFirstNonStartingAbility()
end

--
-- skip click on a dice if single ability is unlearned
--
function WildCard:SetSoFRoll()
	self.isSoFRoll = true
	EventRegistry:TriggerEvent("WildCard.OnSetSoFRoll")
end

function WildCard:ClearSoFRoll()
	self.isSoFRoll = false
end

function WildCard:HideNotifications()
	if _G["StoreNewItemInCollection"] and _G["StoreNewItemInCollection"]:IsVisible() then
		_G["StoreNewItemInCollection"]:GetScript("OnClick")(_G["StoreNewItemInCollection"])
	end

	--[[if ForcedPrimaryStatFrame and (ForcedPrimaryStatFrame:IsVisible()) then
		BaseFrameFadeOut(ForcedPrimaryStatFrame)
	end]]--

	StaticPopup_EscapePressed()
end
--
-- Events
--
function WildCard:WILDCARD_ROLL_READY()
	dprint("WildCard:WILDCARD_ROLL_READY")
	self:CheckForRolls()
end

function WildCard:SPECIALIZATION_CHANGED()
	dprint("WildCard:SPECIALIZATION_CHANGED")
	self:ClearSoFRoll()
	self:HideDices()
end

function WildCard:DICE_OF_DESTINY_USED(skipForceClick)
	dprint("WildCard:DICE_OF_DESTINY_USED")

	if self:CanShowStartingChoice() then
		if WildCardDice then
			if WildCardDice.ClearStartingChoiceKept then
				WildCardDice:ClearStartingChoiceKept()
			end
			if WildCardDice.ShowStartingChoicePanel then
				WildCardDice:ShowStartingChoicePanel("finished")
			end
		end
		return
	end

	if not(skipForceClick) and WildCardDice:IsVisible() then -- force trigger click
		if WildCardDice:IsMouseEnabled() then -- spam safe
			WildCardDice:OnClick()
		end
	end

	if not self:CanRoll() then
		UIErrorsFrame:AddMessage(WILDCARD_DICE_USAGE_ERROR, 1, 0, 0)
		SendSystemMessage("|cffFF0000"..WILDCARD_DICE_USAGE_ERROR.."|r")
	end
end

function WildCard:WILDCARD_UNLEARN_ABILITY_RESULT(result)
	dprint("WildCard:WILDCARD_UNLEARN_ABILITY_RESULT")
	if result == "CA_UNLEARN_OK" then
		self:SetSoFRoll()
	else
		self:ClearSoFRoll()
	end

	-- Surface a failed Scroll of Fortune reroll to the player as a red error message,
	-- using the error's global string directly (same convention as CharacterAdvancement).
	if result and result ~= "CA_UNLEARN_OK" then
		local message = _G[result] or result
		UIErrorsFrame:AddMessage(message, 1, 0, 0)
		SendSystemMessage("|cffFF0000"..message.."|r")
	end
end

function WildCard:WILDCARD_RAPID_ROLL_UNLEARNED(internalID, rank)
	self.lastRapidRollUnlearn = { internalID, rank }
end

function WildCard:WILDCARD_RAPID_ROLL_LEARNED(internalID, newRank, preRollRank, reason)
	self.lastRapidRollResult = nil
	if internalID and internalID > 0 then
		local state
		if type(C_Wildcard.GetRapidRollingState) == "function" then
			state = C_Wildcard.GetRapidRollingState()
		end
		local isTalentUpgradeBonusResult = state and state.StopCode == "STOP_RAPID_ROLLING_TALENT_UPGRADE_BONUS_LEARNED"
		-- Dedupe unlearn-then-relearn-same-rank: the unlearn event stores the rank
		-- the player had pre-unlearn, which equals newRank when the reroll lands
		-- on the same rank (since preRollRank is 0 post-unlearn).
		if not isTalentUpgradeBonusResult and self.lastRapidRollUnlearn and self.lastRapidRollUnlearn[1] == internalID and self.lastRapidRollUnlearn[2] == newRank then
			self.lastRapidRollUnlearn = nil
			return
		end
		self.lastRapidRollResult = reason
		if state then
			if state.LearnedEntryID == internalID and state.IsDesired ~= nil then
				WildCardDice:SetRapidRollIsDesired(state.IsDesired)
			end
		elseif reason == "STOP_RAPID_ROLLING_DESIRED_ENTRY_LEARNED" then
			WildCardDice:SetRapidRollIsDesired(true)
		end
		self:WILDCARD_ENTRY_LEARNED(internalID, newRank, preRollRank)
	end
	self.lastRapidRollUnlearn = nil
end

function WildCard:WILDCARD_ENTRY_LEARNED(internalID, newRank, preRollRank)
	dprint("WildCard:WILDCARD_ENTRY_LEARNED: "..(internalID or "NO INTERNALID").." newRank: "..(newRank or "NO RANK").." preRollRank: "..(preRollRank or "NO PRE ROLL RANK"))

	if not internalID then
		aprint("|cffFF0000[WILDCARD] WILDCARD_ENTRY_LEARNED RECEIVED WITH NO INTERNALID -- REVEAL CHAIN ABORTED, DICE LIKELY STUCK UNCLICKABLE|r")
		return
	end

	if WildCardDice and WildCardDice:HandleStartingChoiceLearned(internalID, newRank, preRollRank) then
		return
	end

	if WildCardDice and WildCardDice.Core then
		WildCardDice.Core:PrepareForIncomingReveal()
	end

	local isUpgrade = preRollRank and preRollRank > 0

	if isUpgrade then
		WildCardDice.pendingReveal = {internalID, newRank, preRollRank}
		dprint("WildCard:WILDCARD_ENTRY_LEARNED: |cffFF00FFInternalID is already known, show first original rank "..preRollRank.." -> "..newRank.."|r")
	else
		WildCardDice.pendingReveal = {internalID, newRank or 1}
	end

	-- Drive the reveal animation off the learn event so pendingReveal is
	-- guaranteed populated before the roulette latches its center icon.
	if WildCardDice:IsVisible() then
		WildCardDice:PlayFlipBook("DiceCrackFlipBook")
	end
end

function WildCard:ADDON_LOADED(addon)
	if addon ~= AddonName then return end

	self.isSoFRoll = false

	local item = Item:CreateFromID(ItemData.DICE_OF_DESTINY)
	HelpTips["WILDCARD_DICE_OF_DESTINY"].text = string.format(WILDCARD_DICE_HINT, item:GetLink() or "Dice of Destiny")

	self:RegisterEvents()

	-- to pass CanRollAbilities check
	Timer.After(0.5, function()
		self:CheckForRolls()
	end)
end
-------------------------------------------------------------------------------
--                                     UI                                    --
-------------------------------------------------------------------------------
HelpTips["WILDCARD_DICE_OF_DESTINY"] = {
    text = WILDCARD_DICE_HINT,
    parent  = "MainMenuBarBackpackButton",
    targetPoint = HelpTip.Point.TopEdgeCenter,
}

WildCardDice = CreateFrame("BUTTON", "WildCardDice", UIParent, nil)
WildCardDice:SetSize(128, 128)
WildCardDice:SetPoint("TOP", 0, -96)
WildCardDice:Hide()
MixinAndLoadScripts(WildCardDice, WildCardDiceMixin)

WildCardDice:SetFrameStrata("FULLSCREEN_DIALOG")
WildCardDice:SetScript("OnHide", GenerateClosure(WildCard.OnHideDice, WildCardDice))
WildCardDice:RegisterCallback("OnSpellReveal", GenerateClosure(WildCard.OnSpellReveal, WildCard))

-- Hide the micro button while the dice is up (HookScript to keep the mixin's OnShow).
WildCardDice:HookScript("OnShow", UpdateDraftMicroButton)
