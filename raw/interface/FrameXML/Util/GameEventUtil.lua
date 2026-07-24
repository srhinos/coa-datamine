--
-- General Game Event functions
--

GameEventUtil = {}

function GameEventUtil.IsEventActive(eventID)
	local event = GetGameEventInfo(eventID)
	return event and event.active
end

function GameEventUtil.IsAnyEventActive(...)
	for i = 1, select("#", ...) do
		local eventID = select(i, ...)
		if GameEventUtil.IsEventActive(eventID) then
			return true
		end
	end

	return false
end

function GameEventUtil.GetTimeRemaining(eventID)
	local event = GetGameEventInfo(eventID)
	if event then
		return event.endTime
	end
end

function GameEventUtil.GetTimeUntil(eventID)
	local event = GetGameEventInfo(eventID)
	if event then
		return event.startTime
	end
end

function GameEventUtil.GetState(eventID)
	local event = GetGameEventInfo(eventID)
	if event then
		return event.eventState
	end
end