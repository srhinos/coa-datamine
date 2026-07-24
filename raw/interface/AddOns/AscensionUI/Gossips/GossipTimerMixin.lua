-------------------------------------------------------------------------------
--                                   Timer                                   --
-------------------------------------------------------------------------------
gossipTimer = {
	parent = nil,
	isRunning = false,
	endTime = 0,
	onTickFunction = function()
	end,
	onExitFunction = function()
	end,
	MSGS = { -- TODO: Localize
		DAY 										= "Day",
		DAYS 										= "Days",
		HOUR 										= "Hour",
		HOURS 										= "Hours",
		MINUTE 										= "Minute",
		MINUTES 									= "Minutes",
		SECOND 										= "Second",
		SECONDS 									= "Seconds",
	},
}

function gossipTimer:OnTick()
	if (self.onTickFunction) then
		self:onTickFunction()
	end
end

function gossipTimer:Tick()
	if not(self.parent:IsVisible()) then
		self.isRunning = false
		self:onExitFunction()
		return
	end

    if self.endTime <= 0 then
    	self.isRunning = false
    	self:onExitFunction()
        return
    end

    self.endTime = self.endTime - 1

    self:OnTick()

	Timer.After(1, function()
		self:Tick()
 	end)
end

function gossipTimer:GetTimeValues()
	return floor(self.endTime/86400), floor(mod(self.endTime, 86400)/3600), floor(mod(self.endTime,3600)/60), floor(mod(self.endTime,60))
end

function gossipTimer:Run(endTime)
	if (self.isRunning) then
		--dprint(self.parent:GetName().." timer is running, don't run new")
		return true
	end

	--dprint(self.parent:GetName().." run timer, endtime is "..endTime)

	if (endTime < 0) then -- smth got wrong 
		return false
	end

	self.endTime = endTime or 0
	self.endTime = self.endTime + 1
	self.isRunning = true
	self:Tick()

	return true
end