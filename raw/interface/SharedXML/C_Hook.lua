-- Allows sending and receiving custom and regular events.
-- custom events will be broken down to their sub event
-- json custom sub events will be broken down to broadcast just the json payload name and cache data for the updated index

C_Hook = {
	refs = {},
	events = {},
	buckets = {},
	allListener = {},
}

local issecure = issecure
local playerName = UnitName and UnitName("player")

local HookHandler = CreateFrame("Frame")

-- Copied from SharedXML/SharedPanelTemplates.lua
-- Cannot load SharedPanelTemplates before C_Hook
-- Also removes json conversions
function HookHandler:SecureSetValues(attribute, ...)
	if not attribute or not select("#", ...) == 0 then return end
	
	attribute = attribute:lower()
	self:ClearValues(attribute)

	for i = 1, select("#", ...) do
		self:SetAttribute(attribute .. "-arg" .. i, select(i, ...))
	end
	
	self:SetAttribute(attribute.."-update", true)
end

function HookHandler:SecureSetValue(attribute, value)
	if not attribute then return end
	attribute = attribute:lower()
	self:ClearValues(attribute)

	local v = value

	self:SetAttribute(attribute .. "-arg1", v)
	self:SetAttribute(attribute.."-update", true)
end

function HookHandler:ClearValues(attribute)
	self:SetAttribute(attribute:lower() .. "-wipe", true)
end

function HookHandler:OnAttributeChanged(name, value)
	local attribute, key = name:match("([%w_]*)%-([%w_]*)")
	
	if not attribute or not key then return end

	if key == "update" then
		local attr = attribute:upper()
		if self[attr.."_Update"] then
			self[attr.."_Update"](self, self[attribute])
		end
	elseif key == "wipe" then
		if self[attribute] then
			wipe(self[attribute])
		end
	else
		local id = key:match("arg(%d*)")
		id = tonumber(id)
		if id then
			self[attribute] = self[attribute] or {}
			tinsert(self[attribute], id, value)
		end
	end
end

function HookHandler:REGISTER_Update(data)
	C_Hook:Register(unpack(data))
end

function HookHandler:ALL_Update(data)
	C_Hook:RegisterAllEvents(unpack(data))
end

function HookHandler:BUCKET_Update(data)
	C_Hook:RegisterBucket(unpack(data))
end

function HookHandler:UNREGISTER_Update(data)
	C_Hook:Unregister(unpack(data))
end

function HookHandler:EVENT_Update(data)
	C_Hook:SendEvent(unpack(data))
end

function HookHandler:BLIZZEVENT_Update(data)
	C_Hook:SendBlizzardEvent(unpack(data))
end

function HookHandler:PROFILE_Update(start)
	if start then
		C_Hook.EVENT_TIMES = {}
	else
		C_Hook.EVENT_TIMES = nil
	end
end

HookHandler:SetScript("OnAttributeChanged", HookHandler.OnAttributeChanged)

-- These events will broadcast as the first parameter after event rather than the event itself.
-- ex: [COMMENTATOR_SKIRMISH_QUEUE_REQUEST: subEvent, ...] will boradcast SendEvent(subEvent, ...)
local USE_SUB_EVENT = {
	["COMMENTATOR_SKIRMISH_QUEUE_REQUEST"] = true,
	--["SERVER_SPLIT_NOTICE"] = true,
}

HookHandler:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		PLAYER_ENTERED_WORLD = true
	end
	
	-- don't allow other players CHAT_MSG_ADDON to call hook events remotely
	if event == "CHAT_MSG_ADDON" then
		local prefix, _, channel, sender = ...

		if sender == playerName and channel == "WHISPER" then
			C_Hook:SendEvent(prefix, select(2, ...))
		end
		
	elseif USE_SUB_EVENT[event] then
		event = ...

		-- get sub-sub event from json payload
		if event:find("ASCENSION_CUSTOM_JSON") then
			local data = select(2, ...)
			event = event:match("ASCENSION_CUSTOM_JSON_(.*)_UPDATE")
			local id = data

			if not HasJsonCacheData(event, id) then
				return
			end

			data = GetJsonCacheData(event, id)
			C_Hook:SendEvent(event, data)
		else
			C_Hook:SendEvent(event, select(2, ...))
		end
	else
		C_Hook:SendEvent(event, ...)
	end
end)

HookHandler:RegisterAllEvents()

local function GetEventsTable(events)
	if type(events) == "string" then
		if events:find(",") then
			events = events:SplitToTable(", ")
		else
			events = { events }
		end
	end
	
	return events
end

-- Register a callback for a specific event
-- Ref = Any value to reference this register by
--
-- events = events to register
-- must be 'table' or 'string'
-- ex: { "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT" } = "PLAYER_ENTERING_WORLD, PLAYER_LOGOUT"
--
-- callback = handling of this event
-- If callback is a 'function' calls 'callback(...)'
-- if callback is a 'table' calls 'callback[event](callback, ...)'
-- if ref is a 'table' and callback is a 'string' calls 'ref[callback](ref, ...)'
-- otherwise, if ref is a 'table' calls 'ref[event](ref, ...)'
function C_Hook:Register(ref, events, callback)
	if not issecure() then
		HookHandler:SecureSetValues("register", ref, events, callback)
		return
	end

	assert(ref ~= nil, "Ref cannot be nil for C_Hook:Register")
	
	events = GetEventsTable(events)
	
	assert(type(events) == "table", "Events must be a comma separated string, or table of events for C_Hook:Register")

	if not self.refs[ref] then
		self.refs[ref] = {}
	end

	for _, event in ipairs(events) do
		self.refs[ref][event] = callback or true
		if not self.events[event] then
			self.events[event] = {}
		end
		self.events[event][ref] = callback or true
	end
end

-- Registers a callback for a specific event
-- Ref = Any value to reference this register by
--
-- Buckets will delay callback until after the period is up.
-- period is 0.1s if unset
-- args will be a table of tables with the args of each event. Ex: { { event 1 args }, { event 2 args } }
--
-- This allows handling of large bursts of events as a single event
--
-- events = events to register
-- must be 'table' or 'string'
-- ex: { "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT" } = "PLAYER_ENTERING_WORLD, PLAYER_LOGOUT"
--
-- callback = handling of this event
-- If callback is a 'function' calls 'callback(...)'
-- if callback is a 'table' calls 'callback[event](callback, ...)'
-- if ref is a 'table' and callback is a 'string' calls 'ref[callback](ref, ...)'
-- otherwise, if ref is a 'table' calls 'ref[event](ref, ...)'
function C_Hook:RegisterBucket(ref, events, period, callback)
	if not issecure() then
		HookHandler:SecureSetValues("bucket", ref, events, period, callback)
		return
	end

	events = GetEventsTable(events)

	C_Hook:Register(ref, events, callback)

	self.buckets[ref] = self.buckets[ref] or {}

	for _, event in ipairs(events) do
		self.buckets[ref][event] = {}
		self.buckets[ref]["DURATION_"..event] = period or 0.1
	end
end

function C_Hook:RegisterAllEvents(ref, callback)
	if not issecure() then
		HookHandler:SecureSetValues("all", ref, callback)
		return
	end
	
	self.allListener[ref] = callback
end

-- Unregister a ref and all its events, or a specific event for a ref.
function C_Hook:Unregister(ref, events)
	if not ref then return end

	if not issecure() then
		HookHandler:SecureSetValues("unregister", ref, events)
		return
	end

	if self.allListener[ref] then
		self.allListener[ref] = nil
	end

    if not self.refs[ref] then return end

	if events then -- unregister just these events
		events = GetEventsTable(events)

		for _, event in ipairs(events) do
			self.refs[ref][event] = nil

			-- check if we should remove this ref entirely
			if not next(self.refs[ref]) then
				self.refs[ref] = nil
			end

			if self.events[event] then
				self.events[event][ref] = nil

				-- check if we should remove this event entirely
				if not next(self.events[event]) then
					self.events[event] = nil
				end
			end

			if self.buckets[ref] and self.buckets[ref][event] then
				self.buckets[ref]["DURATION_"..event] = nil
				if self.buckets[ref]["TIMER_"..event] then
					self.buckets[ref]["TIMER_"..event]:Cancel()
					self.buckets[ref]["TIMER_"..event] = nil
				end
				self.buckets[ref][event] = nil
			end
		end
	else -- unregister entire ref
		for event in pairs(self.refs[ref]) do
			self.events[event][ref] = nil

			if not next(self.events[event]) then
				self.events[event] = nil
			end
		end

		if self.buckets[ref] then
			local event, data = next(self.buckets[ref])

			while event and data do
				if type(data) == "table" and data.Cancel then
					data:Cancel()
				end
				
				self.buckets[ref][event] = nil

				event, data = next(self.buckets[ref])
			end
		end

		self.refs[ref] = nil
	end
end

local function HandleCallback(ref, event, callback, ...)
	if type(callback) == "function" then
		local ok, error = pcall(callback, ...)
		if not ok then
			C_Logger.Error("%s %s %s", tostring(ref), tostring(event), tostring(error))
		end
		return
	end

	if type(callback) == "table" then
		if callback[event] then
			local ok, error = pcall(callback[event], callback, ...)
			if not ok then
				C_Logger.Error("%s %s %s", tostring(ref), tostring(event), tostring(error))
			end
		end
		
		return
	end

	if type(ref) == "table" then
		if type(callback) == "string" then
			if ref[callback] then
				local ok, error = pcall(ref[callback], ref, event, ...)
				if not ok then
					C_Logger.Error("%s %s %s", tostring(ref), tostring(event), tostring(error))
				end
			end
			return
		end

		if ref[event] then
			local ok, error = pcall(ref[event], ref, ...)
			if not ok then
				C_Logger.Error("%s %s %s", tostring(ref), tostring(event), tostring(error))
			end
		end
	end
end

local function SendBucketEvent(ref, event, callback, ...)
	local bucket = C_Hook.buckets[ref]
	if not bucket then return end

	tinsert(bucket[event], { ... })
	if bucket["TIMER_"..event] then
		return
	end

	local period = bucket["DURATION_"..event]
	bucket["TIMER_"..event] = Timer.NewTimer(period, function()
		-- wipe timer
		bucket["TIMER_"..event] = nil
		
		-- copy then wipe event data
		local data = tcopy(bucket[event])
		wipe(bucket[event])

		securecall(HandleCallback, ref, event, callback, data)
	end)
end

function C_Hook:StartProfiling()
	HookHandler:SecureSetValue("profile", true)
end

function C_Hook:StopProfiling()
	HookHandler:SecureSetValue("profile", false)
end

function C_Hook:DumpProfiling()
	if not self.EVENT_TIMES then return end
	local t = {}
	for _, data in pairs(self.EVENT_TIMES) do
		tinsert(t, data)
	end

	table.sort(t, function(l,r)
		return l[1] > r[1]
	end)

	for _, eventData in ipairs(t) do
		print("|cffFFD100Time:", format("%.4f", eventData[1]), "|cFF00FF00" .. eventData[3] .. "|r", "x", eventData[2])
	end
end

-- Send an event for all registered callbacks
function C_Hook:SendEvent(event, ...)
	local t
	if self.EVENT_TIMES and issecure() then
		self.EVENT_TIMES[event] = self.EVENT_TIMES[event] or {0, 0, event}
		self.EVENT_TIMES[event][2] = self.EVENT_TIMES[event][2] + 1
		t = TimeSince:Now()
	end
	if next(self.allListener) then
		if not issecure() then
			HookHandler:SecureSetValues("event", event, ...)
			return
		end

		for ref, callback in pairs(self.allListener) do
			securecall(HandleCallback, ref, event, callback, ...)
		end
		if t then
			self.EVENT_TIMES[event][1] = self.EVENT_TIMES[event][1] + t:elapsed()
			t:ResetToNow()
		end
	end

	if not self.events[event] then return end

	if not issecure() then
		HookHandler:SecureSetValues("event", event, ...)
		return
	end

	for ref, callback in pairs(self.events[event]) do
		-- handle buckets
		if self.buckets[ref] and self.buckets[ref][event] then
			SendBucketEvent(ref, event, callback, ...)
		else -- handle everything else
			securecall(HandleCallback, ref, event, callback, ...)
		end
	end
	if t then
		self.EVENT_TIMES[event][1] = self.EVENT_TIMES[event][1] + t:elapsed()
	end
end

local function SendBlizzardEvent(frame, event, ...)
	if frame.CallScript then
		local ok, error = pcall(frame.CallScript, frame, "OnEvent", event, ...)
		if not ok then
			C_Logger.Error("BlizzEvent: %s %s %s", tostring(frame), tostring(event), tostring(error))
		end
	end
end

-- Tries to send a blizzard event using GetFramesRegisteredForEvent(event)
function C_Hook:SendBlizzardEvent(event, ...)
	if not issecure() then
		HookHandler:SecureSetValues("blizzevent", event, ...)
		return
	end

	local listeners = { GetFramesRegisteredForEvent(event) }
	for _, frame in ipairs(listeners) do
		securecall(SendBlizzardEvent, frame, event, ...)
	end
end

-- returns if a ref is registered for any events
-- returns if event is specified, returns if the given ref is registered for that specific event
function C_Hook:IsRegistered(ref, event)
	if not ref then return false end

	if self.refs[ref] then
		if not event and next(self.refs[ref]) then return true end
		if event and self.refs[ref][event] ~= nil then return true end
	end
	
	return false
end 