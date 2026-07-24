C_TrinityCore = {
    listeningFor = {},
    index = 1,
    lastCommand = nil,
}

local EventDelegate = CreateFrame("Frame")
EventDelegate:RegisterEvent("CHAT_MSG_ADDON")

EventDelegate:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, command, chatType, name = ...
        if prefix == "ASCENSION_LUA" then
            C_TrinityCore:ASCENSION_LUA(command, chatType, name)
        end
    end
end)

function C_TrinityCore:ConvertBagSlots(bag, slot)
    if bag == 255 then
        return bag, slot
    end

    if bag == 0 then
        bag = 255
        slot = slot + 22
        return bag, slot
    end

    bag = bag + 18
    slot = slot - 1
    return bag, slot
end

local MSG_PREFIX = "ASCENSION_LUA"
function C_TrinityCore:RequestPlayerVersion(player)
    SendAddonMessage(MSG_PREFIX, "VERSION", "WHISPER", player)
end

function C_TrinityCore:MSG_VERSION(data, chatType, name)
    SendAddonMessage(MSG_PREFIX, format("VERSION_REPLY:%s@%s %s", GetClientVersion()), chatType, name)
end

function C_TrinityCore:MSG_VERSION_REPLY(data, chatType, name)
    SendSystemMessage(format("%s's %s: %s", name, GAME_VERSION_LABEL, data))
end

function C_TrinityCore:ASCENSION_LUA(command, chatType, name)
    if chatType == "WHISPER" --[[and name ~= UnitName("player") ]] then
        local func, data = command:match("([^:]*):?(.*)")
        if self["MSG_"..func] then
            self["MSG_"..func](self, data, chatType, name)
        end
    end
end