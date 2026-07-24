local setmetatable = setmetatable
local type = type
local tinsert = table.insert
local tremove = table.remove

Timer = {}
Timer._version = 3

local TickerPrototype = {}
local TickerMetatable = {__index = TickerPrototype, __metatable = true}

local WaitPrototype = {}
local WaitMetatable = {__index = WaitPrototype, __metatable = true}

local WaitEventPrototype = {}
local WaitEventMetatable = {__index = WaitEventPrototype, __metatable = true}

local waitTable = {}
local secureWaitTable = {}
local waitCombat = {}
local secureWaitCombat = {}
local waitFrame = CreateFrame("Frame", "AscensionTimer", UIParent)

waitFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
waitFrame:RegisterEvent("PLAYER_UNGHOST")
waitFrame:RegisterEvent("PLAYER_ALIVE")

local function RunCallback(ticker)
	if ticker._noArg then
		ticker._callback()
	else
		ticker._callback(ticker)
	end
end

local function OnUpdate(self, elapsed, tickers)
	local total = #tickers
	local i = 1

	while i <= total do
		local ticker = tickers[i]

		if ticker._cancelled then
			tremove(tickers, i)
			total = total - 1
		elseif ticker._delay > elapsed then
			ticker._delay = ticker._delay - elapsed
			i = i + 1
		else
			securecall(RunCallback, ticker)

			if ticker._remainingIterations == -1 then
				ticker._delay = ticker._duration
				i = i + 1
			elseif ticker._remainingIterations > 1 then
				ticker._remainingIterations = ticker._remainingIterations - 1
				ticker._delay = ticker._duration
				i = i + 1
			elseif ticker._remainingIterations == 1 then
				ticker._cancelled = true
				tremove(tickers, i)
				total = total - 1
			end
		end
	end
end

local function OnEvent(event, combatTimers)
	if event == "PLAYER_REGEN_ENABLED" then
		if not C_Player:IsDead() then
			for _, waiter in ipairs(combatTimers) do
				securecall(RunCallback, waiter)
			end

			wipe(combatTimers)
		end
	elseif event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE" then
		if not C_Player:IsDead() and not C_Player:InCombat() then
			for _, waiter in ipairs(combatTimers) do
				securecall(RunCallback, waiter)
			end

			wipe(combatTimers)
		end
	end
end

waitFrame:SetScript("OnUpdate", function(self, elapsed)
	securecall(OnUpdate, self, elapsed, secureWaitTable)
	securecall(OnUpdate, self, elapsed, waitTable)

	if #waitTable == 0 and #secureWaitTable == 0 then
		self:Hide()
	end
end)

waitFrame:SetScript("OnEvent", function(self, event)
	securecall(OnEvent, event, secureWaitCombat)
	securecall(OnEvent, event, waitCombat)
end)

local function DelayedCall(ticker, oldTicker)
	if oldTicker and type(oldTicker) == "table" then ticker = oldTicker end

	if issecure() then
		ticker._secure = true
		tinsert(secureWaitTable, ticker)
	else
		tinsert(waitTable, ticker)
	end

	waitFrame:Show()
end

local function CreateTicker(duration, callback, iterations)
	local ticker = setmetatable({}, TickerMetatable)
	ticker._remainingIterations = iterations or -1
	ticker._duration = duration
	ticker._delay = duration
	ticker._callback = callback

	DelayedCall(ticker)

	return ticker
end

function Timer.After(duration, callback)
	assert(callback, "Timer.After: No callback provided")
    DelayedCall({_remainingIterations = 1, _delay = duration, _callback = callback, _noArg = true})
end

function Timer.AfterCombat(callback)
	assert(callback, "Timer.AfterCombat: No callback provided")
	local waiter = setmetatable({}, WaitMetatable)
	if C_Player:InCombat() or C_Player:IsDead() then
		waiter._callback = callback
		if issecure() then
			waiter._secure = true
			tinsert(secureWaitCombat, waiter)
		else
			tinsert(waitCombat, waiter)
		end
		
		return waiter
	else
		callback()
	end
end

function Timer.NewTimer(duration, callback)
	assert(callback, "Timer.NewTimer: No callback provided")
    return CreateTicker(duration, callback, 1)
end

function Timer.NewTicker(duration, callback, iterations)
	assert(callback, "Timer.NewTicker: No callback provided")
    return CreateTicker(duration, callback, iterations)
end

function Timer.WaitFor(duration, condition, callback, maxWaitSeconds)
	assert(callback, "Timer.WaitFor: No callback provided")

	local ticker = Timer.NewTicker(duration, function(self)
		if self.check() then
			self:Cancel()
			self.onFinish(true)
		end
	end)

	ticker.check = condition
	ticker.onFinish = callback

	if maxWaitSeconds and maxWaitSeconds > 0 then
		Timer.After(maxWaitSeconds, function()
			if ticker and not ticker._cancelled then
				ticker:Cancel()
				callback(false)
			end
		end)
	end

	return ticker
end

function Timer.AfterEvent(event, callback, count)
	assert(callback, "Timer.AfterEvent: No callback provided")
	local waiter = setmetatable({}, WaitEventMetatable)
	waiter.count = count or 1
	C_Hook:Register(waiter, event, function(...)
		waiter.count = waiter.count - 1
		if waiter.count > 0 then return end

		C_Hook:Unregister(waiter)
		callback(...)
	end)
	
	return waiter
end

function Timer.NextFrame(callback)
	assert(callback, "Timer.NextFrame: No callback provided")
	Timer.After(0, callback)
end

function TickerPrototype:Cancel()
    self._cancelled = true
end

function TickerPrototype:IsCancelled()
	return self._cancelled
end

function WaitPrototype:Cancel()
	self._cancelled = true
	if issecure() and self._secure then
		tremoveItem(secureWaitCombat, self)
		return
	end
	tremoveItem(waitCombat, self)
end

function WaitPrototype:IsCancelled()
	return self._cancelled
end

function WaitEventPrototype:Cancel()
	self._cancelled = true
	C_Hook:Unregister(self)
end

function WaitEventPrototype:IsCancelled()
	return self._cancelled
end

C_Timer = {}
-- this should allow addons to ruin C_Timer but not Timer zzzz
setmetatable(C_Timer, {__index = Timer})