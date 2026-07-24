SECONDS_PER_MIN = 60
SECONDS_PER_HOUR = 60 * SECONDS_PER_MIN
SECONDS_PER_DAY = 24 * SECONDS_PER_HOUR
SECONDS_PER_MONTH = 30 * SECONDS_PER_DAY
SECONDS_PER_YEAR = 12 * SECONDS_PER_MONTH

function SecondsToMinutes(seconds)
	return seconds / SECONDS_PER_MIN
end

function MinutesToSeconds(minutes)
	return minutes * SECONDS_PER_MIN
end

function HasTimePassed(testTime, amountOfTime)
	return ((time() - testTime) >= amountOfTime)
end

function ConvertSecondsToUnits(timestamp)
	timestamp = math.max(timestamp, 0)
	local days = math.floor(timestamp / SECONDS_PER_DAY)
	timestamp = timestamp - (days * SECONDS_PER_DAY)
	local hours = math.floor(timestamp / SECONDS_PER_HOUR)
	timestamp = timestamp - (hours * SECONDS_PER_HOUR)
	local minutes = math.floor(timestamp / SECONDS_PER_MIN)
	timestamp = timestamp - (minutes * SECONDS_PER_MIN)
	local seconds = math.floor(timestamp)
	local milliseconds = timestamp - seconds
	return {
		days=days,
		hours=hours,
		minutes=minutes,
		seconds=seconds,
		milliseconds=milliseconds,
	}
end

function SecondsToTime(seconds, noSeconds, notAbbreviated, maxCount)
	local time = ""
	local count = 0
	local tempTime
	seconds = floor(seconds)
	maxCount = maxCount or 2
	if ( seconds >= 86400  ) then
		tempTime = floor(seconds / 86400)
		if ( notAbbreviated ) then
			time = format(D_DAYS,tempTime)
		else
			time = format(DAYS_ABBR,tempTime)
		end
		seconds = mod(seconds, 86400)
		count = count + 1
	end
	if ( count < maxCount and seconds >= 3600  ) then
		if ( time ~= "" ) then
			time = time..TIME_UNIT_DELIMITER
		end
		tempTime = floor(seconds / 3600)
		if ( notAbbreviated ) then
			time = time..format(D_HOURS, tempTime)
		else
			time = time..format(HOURS_ABBR, tempTime)
		end
		seconds = mod(seconds, 3600)
		count = count + 1
	end
	if ( count < maxCount and seconds >= 60  ) then
		if ( time ~= "" ) then
			time = time..TIME_UNIT_DELIMITER
		end
		tempTime = floor(seconds / 60)
		if ( notAbbreviated ) then
			time = time..format(D_MINUTES, tempTime)
		else
			time = time..format(MINUTES_ABBR, tempTime)
		end
		seconds = mod(seconds, 60)
		count = count + 1
	end
	if ( count < maxCount and seconds > 0 and not noSeconds ) then
		if ( time ~= "" ) then
			time = time..TIME_UNIT_DELIMITER
		end
		seconds = format("%d", seconds)
		if ( notAbbreviated ) then
			time = time..format(D_SECONDS, seconds)
		else
			time = time..format(SECONDS_ABBR, seconds)
		end
	end
	return time
end

function SecondsToTimeAbbrev(seconds)
	local tempTime
	if ( seconds >= 86400  ) then
		tempTime = ceil(seconds / 86400)
		return DAY_ONELETTER_ABBR, tempTime
	end
	if ( seconds >= 3600  ) then
		tempTime = ceil(seconds / 3600)
		return HOUR_ONELETTER_ABBR, tempTime
	end
	if ( seconds >= 60  ) then
		tempTime = ceil(seconds / 60)
		return MINUTE_ONELETTER_ABBR, tempTime
	end
	return SECOND_ONELETTER_ABBR, seconds
end

function SecondsToTimeAbbrevPrecise(seconds)
	local tempTime
	if ( seconds >= 86400  ) then
		tempTime = ceil(seconds / 86400)
		return DAY_ONELETTER_ABBR, tempTime
	end
	if ( seconds >= 3600  ) then
		tempTime = ceil(seconds / 3600)
		return HOUR_ONELETTER_ABBR, tempTime
	end
	if ( seconds >= 60  ) then
		tempTime = ceil(seconds / 60)
		return MINUTE_ONELETTER_ABBR, tempTime
	end
	if seconds < 2 then
		return "%.1f s", seconds
	end
	return SECOND_ONELETTER_ABBR, seconds
end

function RecentTimeDate(year, month, day, hour)
	local lastOnline
	if ( (year == 0) or (year == nil) ) then
		if ( (month == 0) or (month == nil) ) then
			if ( (day == 0) or (day == nil) ) then
				if ( (hour == 0) or (hour == nil) ) then
					lastOnline = LASTONLINE_MINS
				else
					lastOnline = format(LASTONLINE_HOURS, hour)
				end
			else
				lastOnline = format(LASTONLINE_DAYS, day)
			end
		else
			lastOnline = format(LASTONLINE_MONTHS, month)
		end
	else
		lastOnline = format(LASTONLINE_YEARS, year)
	end
	return lastOnline
end

function SecondsToClock(seconds, displayMS, displayZeroHours)
	local units = ConvertSecondsToUnits(seconds);
	if units.hours > 0 or displayZeroHours then
		if displayMS then
			return format((HOURS_MINUTES_SECONDS_MILLISECONDS or "%d:%d:%d.%d"), units.hours, units.minutes, units.seconds, units.milliseconds)
		end
		return format((HOURS_MINUTES_SECONDS or "%d:%d:%d"), units.hours, units.minutes, units.seconds);
	else
		if displayMS then
			return format((MINUTES_SECONDS_MILLISECONDS or "%d:%d.%d"), units.minutes, units.seconds, units.milliseconds)
		end
		return format((MINUTES_SECONDS or "%d:%d"), units.minutes, units.seconds);
	end
end

function FormatDateTimestamp(timestamp, includeTimespan, onlyOneDayTimespan, onlyOneDayClock, clockFormat, dateFormat, timespanFormat)
	if not clockFormat then
		clockFormat = "%I:%M%p"
	end
	if not dateFormat then
		dateFormat = "%x"
	end
	if not timespanFormat then
		timespanFormat = " - " .. TIME_S_AGO
	end

	local timeSince = math.abs(time() - timestamp)

	if not includeTimespan or (timeSince >= 86400 and onlyOneDayTimespan) then
		if timeSince >= 86400 and onlyOneDayClock then
			return date(dateFormat, timestamp)
		else
			return date(clockFormat .. " - " .. dateFormat, timestamp)
		end
	end
	
	local timeSinceMessage = SecondsToTime(timeSince, timeSince > 60, false)
	if timeSince >= 86400 and onlyOneDayClock then
		return format("%s"..timespanFormat, date(dateFormat, timestamp), timeSinceMessage)
	else
		return format("%s".. timespanFormat, date(clockFormat .. " - "..dateFormat, timestamp), timeSinceMessage)
	end
end

TimeSince = {}

local TimeSincePrototype = {}
local TimeSinceMetatable = {__index = TimeSincePrototype, __metatable = true, __mode = "kv"}

-- call as either
-- TSStartTime = TimeSince:Now()
-- TSStartTime(10) -- check if TSStartTime >= 10
-- or
-- TSStartTime:EqualOrGreaterThan(10) -- check if TSStartTime >= 10
function TimeSinceMetatable.__call(self, value)
	return self:elapsed() >= value
end

TimeSincePrototype.Equal = function(a, b) return a:elapsed() == b end
TimeSincePrototype.LessThan = function(a, b) return a:elapsed() < b end
TimeSincePrototype.GreaterThan = function(a, b) return a:elapsed() > b end
TimeSincePrototype.EqualOrLessThan = function(a, b) return a:elapsed() <= b end
TimeSincePrototype.EqualOrGreaterThan = function(a, b) return a:elapsed() >= b end
TimeSincePrototype.NotEqual = function(a, b) return a:elapsed() ~= b end


function TimeSincePrototype:elapsed()
	return GetTime() - self.time
end

function TimeSincePrototype:ResetToNow()
	self:ResetTo(0)
end

function TimeSincePrototype:ResetTo(offset)
	offset = offset or 0
	self.time = GetTime() + offset
end

function TimeSince:Create(offset)
	local ts = {}
	setmetatable(ts, TimeSinceMetatable)
	ts:ResetTo(offset)
	return ts
end

function TimeSince:Now()
	return self:Create(0)
end