TaxiUtil = CreateFromMixins(CallbackRegistryMixin)
CallbackRegistryMixin.OnLoad(TaxiUtil)
TaxiUtil:GenerateCallbackEvents(
{
	"TAXI_STARTED",
	"TAXI_FINISHED",
})

local CheckingForTaxiTimer

function TaxiUtil.IsOnTaxi()
	return UnitOnTaxi("player")
end

function TaxiUtil.CanStopTaxi()
	return TaxiRequestEarlyLanding and TaxiUtil.IsOnTaxi() and not TaxiIsEarlyLanding()
end

--
-- Taxi Status Tracking
--
local function OnTaxiFinishedCallback()
	CheckingForTaxiTimer = nil
	TaxiUtil:TriggerEvent("TAXI_FINISHED")
end

local function OnTaxiCallback(onTaxi)
	CheckingForTaxiTimer = nil
	if not onTaxi then return end
	TaxiUtil:TriggerEvent("TAXI_STARTED")
	-- wait until off taxi then trigger taxi finished
	CheckingForTaxiTimer = Timer.WaitFor(0.1, function() return not TaxiUtil.IsOnTaxi() end, OnTaxiFinishedCallback)
end

-- listens for taxi map closing or enter world
-- if on taxi up to 2s after these events, trigger taxi started event
C_Hook:Register(TaxiUtil, "TAXIMAP_CLOSED, PLAYER_ENTERING_WORLD", function()
	if CheckingForTaxiTimer then
		return
	end
	CheckingForTaxiTimer = Timer.WaitFor(0.1, TaxiUtil.IsOnTaxi, OnTaxiCallback, 2)
end)