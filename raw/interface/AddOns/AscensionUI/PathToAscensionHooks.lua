local Addon = select(2, ...)

local SentMessages = {}

local function SendMessage(message)
    SentMessages[message] = true
    SendAddonMessage("ASC_PATH_TO_ASCENSION", message, "WHISPER", UnitName("player"))
end

local function HookSendMessageOnEvent(target, event, messageToSend, check)
    target:HookScript(event, function()
        if not check or check() then
            --if SentMessages[messageToSend] then return end -- cant use this since players might click stuff before messages
            SendMessage(messageToSend)
        end
    end)
end


local listener = CreateFrame("Frame")

listener:RegisterEvent("ADDON_LOADED")
listener:SetScript("OnEvent", function(self, event, ...)
    if event =="ADDON_LOADED" then
        if ... == "Blizzard_TalentUI" then
            HookSendMessageOnEvent(PlayerTalentFrame, "OnShow", "ACTION_OPEN_PET_TALENTS", function()
                return HasPetUI() == 1
            end)
            for i = 1, MAX_NUM_TALENTS do
                local button = _G["PlayerTalentFrameTalent"..i];
                button:HookScript("OnClick", function()
                    if HasPetUI() then
                        SendMessage("ACTION_SELECT_A_PET_TALENT")
                    end
                end)
            end
        end
    end
end)