if not SendWindowsFlash then return end

local _SendWindowsFlash = SendWindowsFlash
function SendWindowsFlash()
    if C_CVar.GetBool("flashWindow") then
        _SendWindowsFlash()
    end
end

local events = {
    "LFG_PROPOSAL_SHOW",
    "CHAT_MSG_WHISPER",
    "PLAYER_REGEN_DISABLED",
    "TRADE_SHOW",
    "READY_CHECK",
    "PLAYER_LOGOUT",
    "PLAYER_LOGIN",
    "GMRESPONSE_RECEIVED",
}

local FlashTaskBar = {}

C_Hook:Register(FlashTaskBar, events, SendWindowsFlash)
TaxiUtil:RegisterCallback("TAXI_FINISHED", SendWindowsFlash)
C_Hook:Register(FlashTaskBar, "MIRROR_TIMER_START")

function FlashTaskBar:MIRROR_TIMER_START(name, value, maxvalue, step)
    if (name == "EXHAUSTION" and step == -1) then
        SendWindowsFlash()
    end
end

StaticPopup1:HookScript("OnShow", SendWindowsFlash)