EventTrace = CreateFromMixins(CallbackRegistryMixin)
EventTrace.searchStr = ""
CallbackRegistryMixin.OnLoad(EventTrace)

EVENT_TRACE_SHOW_EVENT_REGISTRY = false

local EventArgNames = {}

local EventFrame = CreateFrame("Frame")
EventFrame:SetScript("OnEvent", function(self, ...) EventTrace.AddEvent(...) end)
hooksecurefunc(EventRegistry, "TriggerEvent", function(registry, event, ...)
    if not EventTrace.IsPaused() and EventTrace.LogEventRegistry() then
        EventTrace.AddEvent(event, ...)
    end
end);

EventTrace:GenerateCallbackEvents(
    {
        "ClearedSearch",
        "EventsChanged",
        "FiltersChanged",
        "Started",
        "Stopped",
    }
)

local events = {}
local eventsSearched
local filters = {}
local filteredEvents = {}

local PAUSED_MESSAGE = "--- Event Logging Paused ---"
local STARTED_MESSAGE = "--- Event Logging Started ---"
local MARKER_MESSAGE = "--- Marker ---"

local function UpdateSearchedEvents()
    if EventTrace.searchStr:len() == 0 then
        eventsSearched = nil
        return
    end

    eventsSearched = eventsSearched and wipe(eventsSearched) or {}
    for i, event in ipairs(events) do
        if event[1]:startswith("---") then
            tinsert(eventsSearched, event)
        else
            local eventText = (event[1] .. " " .. TableUtil.PrettyPrint(event[2])):lower()
            if eventText:find(EventTrace.searchStr) or event[1]:lower():gsub("%_", " "):find(EventTrace.searchStr) then
                tinsert(eventsSearched, event)
            end
        end
    end
end

function EventTrace.AddEvent(event, ...)
    if filteredEvents[event] then
        return
    end
    local entry = { event, { ... }, GetTime() }
    tinsert(events, entry)

    if EventTrace.IsSearching() then
        local eventText = (event .. " " .. TableUtil.PrettyPrint(entry[2])):lower()
        if eventText:find(EventTrace.searchStr) or entry[1]:lower():gsub("%_", " "):find(EventTrace.searchStr) then
            tinsert(eventsSearched, entry)
        end
    end

    EventTrace:TriggerEvent("EventsChanged")
end

function EventTrace.AddMarker()
    EventTrace.AddEvent(MARKER_MESSAGE)
end

function EventTrace.RemoveEventAtIndex(index)
    tremove(events, index)
    if EventTrace.IsSearching() then
        UpdateSearchedEvents()
    end
    EventTrace:TriggerEvent("EventsChanged")
end

function EventTrace.GetEventAtIndex(index)
    local event
    if EventTrace.IsSearching() then
        event = eventsSearched[index]
    else
        event = events[index]
    end
    return unpack(event)
end

function EventTrace.GetNumEvents()
    if EventTrace.IsSearching() then
        return #eventsSearched
    else
        return #events
    end
end

function EventTrace.SetSearch(search)
    local text = search:lower():trim()
    if EventTrace.searchStr == text then
        return
    end
    EventTrace.searchStr = text
    UpdateSearchedEvents()
    EventTrace:TriggerEvent("EventsChanged")
end

function EventTrace.AddFilter(filter)
    if not filteredEvents[filter] then
        tinsert(filters, filter)
        filteredEvents[filter] = true
        EventTrace:TriggerEvent("FiltersChanged")
    end
    
    for i = #events, 1, -1 do
        if events[i][1] == filter then
            tremove(events, i)
        end
    end

    if EventTrace.IsSearching() then
        for i = #eventsSearched, 1, -1 do
            if eventsSearched[i][1] == filter then
                tremove(eventsSearched, i)
            end
        end
    end
    
    EventTrace:TriggerEvent("EventsChanged")
end

function EventTrace.RemoveFilterAtIndex(index)
    local filter = filters[index]
    tremove(filters, index)
    filteredEvents[filter] = nil
    EventTrace:TriggerEvent("FiltersChanged")
end

function EventTrace.GetFilterAtIndex(index)
    return filters[index]
end

function EventTrace.GetNumFilters()
    return #filters
end

function EventTrace.IsPaused()
    return not EventFrame.Active
end

function EventTrace.Start(event, ...)
    EventTrace.AddEvent(STARTED_MESSAGE)
    if event then
        EventFrame:UnregisterAllEvents()
        EventFrame:RegisterEvent(event)
        for i = 1, select("#", ...) do
            EventFrame:RegisterEvent(select(i, ...))
        end
    else
        EventFrame:RegisterAllEvents()
    end
    EventFrame.Active = true
    AscensionEventTrace:Show()
    EventTrace:TriggerEvent("Started")
end

function EventTrace.Stop()
    EventFrame:UnregisterAllEvents()
    EventFrame.Active = false
    EventTrace.AddEvent(PAUSED_MESSAGE)
    EventTrace:TriggerEvent("Stopped")
end

function EventTrace.RegisterEvent(event, ...)
    if EventFrame.Active then
        EventFrame:RegisterEvent(event)
        for i = 1, select("#", ...) do
            EventFrame:RegisterEvent(select(i, ...))
        end
    end
end

function EventTrace.UnregisterEvent(event, ...)
    if EventFrame.Active then
        EventFrame:UnregisterEvent(event)
        for i = 1, select("#", ...) do
            EventFrame:UnregisterEvent(select(i, ...))
        end
    end
end

function EventTrace.TogglePaused()
    if EventTrace.IsPaused() then
        EventTrace.Start()
    else
        EventTrace.Stop()
    end
end

function EventTrace.Clear()
    wipe(events)
    if EventTrace.IsSearching() then
        wipe(eventsSearched)
        EventTrace:TriggerEvent("ClearedSearch")
    end
    EventTrace:TriggerEvent("EventsChanged")
end 

function EventTrace.IsSearching()
    return eventsSearched ~= nil
end

function EventTrace.LogEventRegistry()
    return EVENT_TRACE_SHOW_EVENT_REGISTRY
end
