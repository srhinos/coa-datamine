-------------------------------------------------------------------------------
--                        Wildcard Dice Core State Machine                   --
-------------------------------------------------------------------------------
WildCardDiceCore = {}

WildCardDiceCore.State = {
	IDLE = "IDLE",
	APPEARING = "APPEARING",
	READY_TO_ROLL = "READY_TO_ROLL",
	AWAITING_SERVER = "AWAITING_SERVER",
	REVEALING = "REVEALING",
	DECISION_PENDING = "DECISION_PENDING",
	STARTING_CHOICE = "STARTING_CHOICE",
}

function WildCardDiceCore:Initialize(diceFrame)
	self.frame = diceFrame
	self.currentState = self.State.IDLE
	self.clickWatchdogToken = 0
	self.timeoutTimer = nil
end

function WildCardDiceCore:TransitionTo(newState, data)
	local oldState = self.currentState
	if oldState == newState then
		-- A second learn result can restart the crack animation while the first
		-- reveal is still active. Re-enter REVEALING with the newest result so
		-- the roulette/collapse chain cannot be left inert.
		if newState == self.State.REVEALING then
			self:OnEnterState(newState, data)
		end
		return
	end

	dprint(string.format("[WILDCARD CORE] Transition: %s -> %s", tostring(oldState), tostring(newState)))

	-- 1. Exit current state
	self:OnExitState(oldState)

	-- 2. Commit new state
	self.currentState = newState

	-- 3. Enter new state
	self:OnEnterState(newState, data)
end

function WildCardDiceCore:GetState()
	return self.currentState
end

function WildCardDiceCore:IsBusy()
	local state = self.currentState
	return state == self.State.REVEALING 
		or state == self.State.DECISION_PENDING 
		or state == self.State.STARTING_CHOICE
		or state == self.State.AWAITING_SERVER
end

function WildCardDiceCore:StopRevealAnimations()
	local scrollFrame = self.frame.ScrollFrame
	local animationGroup = scrollFrame and scrollFrame.Content and scrollFrame.Content.AnimationGroup
	if animationGroup and animationGroup:IsPlaying() then
		animationGroup:Stop()
	end
	self.frame:HideFlipBooks()
end

function WildCardDiceCore:PrepareForIncomingReveal()
	if self.currentState == self.State.REVEALING then
		self:StopRevealAnimations()
	end
end

-- A reveal is about to be replayed from the start because the dice was hidden
-- mid-flight. The watchdog armed for the interrupted attempt outlives the hide and
-- would clear pendingReveal partway through the replay, so drop it here; entering
-- REVEALING again arms a fresh one.
function WildCardDiceCore:PrepareForRestoredReveal()
	self:StopTimeoutTimer()
	self:StopRevealAnimations()
end

function WildCardDiceCore:OnExitState(state)
	if state == self.State.AWAITING_SERVER or state == self.State.REVEALING then
		self:StopTimeoutTimer()
	elseif state == self.State.READY_TO_ROLL then
		self.frame:UnregisterOnClick()
	elseif state == self.State.STARTING_CHOICE then
		self.frame:HideStartingChoicePanel()
	end
end

function WildCardDiceCore:OnEnterState(state, data)
	if state == self.State.IDLE then
		self.frame:ResetVisual()
	elseif state == self.State.APPEARING then
		self.frame:UnregisterOnClick()
		self.frame:ResetVisual()
		self.frame.Visuals:PlayAppear()
	elseif state == self.State.READY_TO_ROLL then
		self.frame:ResetVisual()
		self.frame:RegisterOnClick()
		self.frame.Visuals:ShowHint()
	elseif state == self.State.AWAITING_SERVER then
		self.frame:UnregisterOnClick()
		self:StartTimeoutTimer(3.0)
	elseif state == self.State.REVEALING then
		self.frame:UnregisterOnClick()
		self:StartTimeoutTimer(6.0)
		self.frame.Visuals:PlayReveal(data)
	elseif state == self.State.DECISION_PENDING then
		self.frame:RegisterOnClick()
		self.frame:Expand()
		self.frame.Visuals:ShowDecision(data)
	elseif state == self.State.STARTING_CHOICE then
		self.frame:UnregisterOnClick()
		self.frame:Expand()
		self.frame.StartingChoice:ShowChoice(data)
	end
end

function WildCardDiceCore:StartTimeoutTimer(seconds)
	self:StopTimeoutTimer()
	self.clickWatchdogToken = self.clickWatchdogToken + 1
	local currentToken = self.clickWatchdogToken

	self.timeoutTimer = Timer.After(seconds, function()
		if self.clickWatchdogToken ~= currentToken then return end
		if self.currentState == self.State.AWAITING_SERVER or self.currentState == self.State.REVEALING then
			aprint("|cffFF0000[WILDCARD] Server response timeout. Recovering state machine safely.|r")
			self.frame.pendingReveal = nil
			self:StopRevealAnimations()
			self:TransitionTo(self.State.READY_TO_ROLL)
		end
	end)
end

function WildCardDiceCore:StopTimeoutTimer()
	self.clickWatchdogToken = self.clickWatchdogToken + 1
	if self.timeoutTimer then
		-- In 3.3.5a Timer.After has no cancel API unless wrapped,
		-- but we increment clickWatchdogToken to invalidate callback execution.
		self.timeoutTimer = nil
	end
end
