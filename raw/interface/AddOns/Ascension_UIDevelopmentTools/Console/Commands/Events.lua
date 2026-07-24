local function ShowEvents()
	for event in pairs(C_Hook.events) do
		DevConsole:Print("|cff00DDFF" .. event .. "|r")
	end
end

local function ListenForEvent(event)
	if not event or event == "" then
		DevConsole:Print("Currently Listening to Events:")
		if C_Hook.allListener[DevConsole] then
			return DevConsole:Print("|cff00DDFFALL|r")
		elseif C_Hook.refs[self] then
			for event in pairs(C_Hook.refs[self]) do
				DevConsole:Print("|cff00DDFF" .. event .. "|r")
			end
			return
		else
			return DevConsole:Print("|cff00DDFFNone|r")
		end
	end
	if event:lower() == "all" then
		C_Hook:RegisterAllEvents(DevConsole, "OnEvent")
	else
		C_Hook:Register(DevConsole, event, "OnEvent")
	end
end

local function StopListeningEvent(event)
	if event:lower() == "all" then
		C_Hook:Unregister(DevConsole)
	elseif C_Hook.allListener[DevConsole] then
		DevConsole:PrintError("Cannot unregister from "..event.." when listening to all events. Try `stopevent all` first")
	else
		C_Hook:Unregister(DevConsole, event)
	end
end

local function ToggleETrace(msg)
	AscensionEventTrace:SetShown(not AscensionEventTrace:IsShown())
end

DevConsole:RegisterCommand("etrace", "show event trace window", ToggleETrace)
DevConsole:RegisterCommand("event", "Listens for the event specified. `all` will listen for all events", ListenForEvent)
DevConsole:RegisterCommand("listevent", "Lists all Custom C_Hook UI events *that are registered*", ShowEvents)
DevConsole:RegisterCommand("stopevent", "Stop listening for the event specified. `all` will stop all events", StopListeningEvent)
	