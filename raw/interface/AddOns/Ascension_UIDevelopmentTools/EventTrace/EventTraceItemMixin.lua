EventTraceItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

local function GetTooltip()
    return GameTooltip or GlueTooltip
end

local function CreateClock(timestamp)
    local units = ConvertSecondsToUnits(timestamp);
    local seconds = units.seconds + units.milliseconds;
    if units.hours > 0 then
        return string.format("%.2d:%.2d:%06.3fs", units.hours, units.minutes, seconds);
    elseif units.minutes > 0 then
        return string.format("%.2d:%06.3fs", units.minutes, seconds);
    else 
        return string.format("%06.3fs", seconds);
    end
end

local function GetArgName(event, args, index)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED" or event == "COMBAT_LOG_EVENT") and index > 8 then
        return EventTrace.GetCombatLogSubEventArgName(args[2], index)
    else
        return EventTrace.GetArgName(event, index)
    end
end

local ArgPool = CreateFramePool("Frame", nil, "EventTraceArgTemplate")

function EventTraceItemMixin:OnLoad()
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function EventTraceItemMixin:Update()
    self.Alternate:SetShown(self.index % 2 == 0)
    local event, args, timestamp = EventTrace.GetEventAtIndex(self.index)
    
    local lastTimestamp
    if self.index > 1 then
        lastTimestamp = select(3, EventTrace.GetEventAtIndex(self.index - 1))
    else
        lastTimestamp = timestamp
    end
    
    if event:startswith("---") then
        self.LeftLabel:SetFormattedText("|cff994400%s|r", event)
        self.FilterButton:Hide()
    else
        local text = event
        if C_CVar.GetBool("eventTraceCount") then
            text = "|cff888888("..self.index..")|r " .. text
        end
        if C_CVar.GetBool("eventTraceArgs") then
            text = text .. " " .. TableUtil.PrettyPrint(args)
        end
        self.LeftLabel:SetText(text)
        self.FilterButton:Show()
    end

    self.RightLabel:SetText("+" .. CreateClock(timestamp - lastTimestamp))

    if self:IsMouseOver() and self:IsVisible() then
        self:OnEnter()
    end

    ArgPool:ReleaseAllWithParent(self)

    if self:IsExpanded() then
        -- add event name first
        local argFrame = ArgPool:Acquire()
        argFrame:SetParent(self)
        argFrame:SetWidth(self:GetWidth())
        argFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -20)
        argFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -20)
        argFrame.text = tostring(event)
        argFrame.Label:SetText("Event:")
        argFrame.Arg:SetText(event)
        argFrame.Alternate:Hide()
        argFrame:Show()
        -- add timestamp arg second
        argFrame = ArgPool:Acquire()
        argFrame:SetParent(self)
        argFrame:SetWidth(self:GetWidth())
        argFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -40)
        argFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -40)
        argFrame.text = tostring(timestamp)
        argFrame.Label:SetText("timestamp:")
        argFrame.Arg:SetText(timestamp)
        argFrame.Alternate:Show()
        argFrame:Show()

        local arg, indexOffset
        for i = 1, #args do
            arg = args[i]
            indexOffset = i + 2
            argFrame = ArgPool:Acquire()
            argFrame:SetParent(self)
            argFrame:SetWidth(self:GetWidth())
            argFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, (-20 * indexOffset))
            argFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, (-20 * indexOffset))
            argFrame.text = tostring(arg)
            argFrame.Label:SetText(GetArgName(event, args, i))
            argFrame.Arg:SetText(TableUtil.PrettyPrint(arg))
            argFrame.Alternate:SetShown(indexOffset % 2 == 0)
            argFrame:Show()
        end
    end
end 

function EventTraceItemMixin:OnEnter()
    local tooltip = GetTooltip()
    local event, args, timestamp = EventTrace.GetEventAtIndex(self.index)
    tooltip:SetOwner(self, "ANCHOR_RIGHT")
    tooltip:SetText(event, 1, 0.82, 0)
    local prettyArgs = TableUtil.Prettify(args)
    tooltip:AddDoubleLine("timestamp:", timestamp, 1, 1, 1, 1, 1, 1)
    for i = 1, #prettyArgs do
        tooltip:AddDoubleLine(GetArgName(event, args, i), prettyArgs[i], 1, 1, 1, 1, 1, 1)
    end
    tooltip:Show()
end 

function EventTraceItemMixin:OnLeave()
    GetTooltip():Hide()
end 

function EventTraceItemMixin:OnSelected()
    local _, args = EventTrace.GetEventAtIndex(self.index)
    self:ToggleExpanded(((#args + 2) * 20) + 20)
end

function EventTraceItemMixin:OnRightClick()
    if IsControlKeyDown() then
        EventTrace.RemoveEventAtIndex(self.index)
    end
end

function EventTraceItemMixin:FilterEvent()
    local event = EventTrace.GetEventAtIndex(self.index)
    EventTrace.AddFilter(event)
end 