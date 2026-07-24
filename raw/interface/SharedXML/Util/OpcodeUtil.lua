OpcodeUtil = {}

local SecureFrame = CreateFrame("Frame")

local OPCODE_DEFINITIONS = {}

local function HandlePacket(event, sendEvent, ...)
    if sendEvent then
        SignalEvent(event, ...)
    end
end

local function OnPacketReceived(opcode, packet)
    if OPCODE_DEFINITIONS[opcode] then
        for _, v in ipairs(OPCODE_DEFINITIONS[opcode]) do
            local event, handler = unpack(v)
            HandlePacket(event, handler(packet))
        end
    end
end

SecureFrame:SetScript("OnAttributeChanged", function(self, attribute, value)
    if attribute == "register-opcode" then
        RegisterPacket(value, OnPacketReceived)
        OPCODE_DEFINITIONS[value] = {}
    elseif attribute == "register-event" then
        local event = value
        local opcode = self:GetAttribute("register-event-opcode")
        local handler = self:GetAttribute("register-event-handler")
        if event and opcode and handler and OPCODE_DEFINITIONS[opcode] then
            table.insert(OPCODE_DEFINITIONS[opcode], {event, handler})
        end
    elseif attribute == "unregister-event" then
        local event = value
        local opcode = self:GetAttribute("unregister-event-opcode")
        if event and opcode and OPCODE_DEFINITIONS[opcode] then
            for i, v in ipairs(OPCODE_DEFINITIONS[opcode]) do
                if v[1] == event then
                    table.remove(OPCODE_DEFINITIONS[opcode], i)
                    break
                end
            end
        end
    end
end)

function SecureFrame:RegisterOpcode(opcode)
    self:SetAttribute("register-opcode", opcode)
end

function SecureFrame:InsertEventHandler(opcode, event, handler)
    if not OPCODE_DEFINITIONS[opcode] then
        SecureFrame:RegisterOpcode(opcode)
    end
    
    self:SetAttribute("register-event-opcode", opcode)
    self:SetAttribute("register-event-handler", handler)
    self:SetAttribute("register-event", event)
end

function SecureFrame:UnregisterEventHandler(opcode, event)
    if not OPCODE_DEFINITIONS[opcode] then
        return
    end
    
    self:SetAttribute("unregister-event-opcode", opcode)
    self:SetAttribute("unregister-event", event)
end

-- Registers an opcode event. 
-- When an opcode is received, the event will be triggered, using Handler to process the packet into args.
-- first return value should be if the event should fire or not
function OpcodeUtil.RegisterOpcodeEvent(opcode, event, handler)
    if not issecure() then return end
    SecureFrame:InsertEventHandler(opcode, event, handler)
end 

-- Removes an opcode event.
function OpcodeUtil.RemoveOpcodeEvent(opcode, event)
    if not issecure() then return end
    SecureFrame:UnregisterEventHandler(opcode, event)
end