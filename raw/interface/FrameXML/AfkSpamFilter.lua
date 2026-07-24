local Alastor_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler; 
function ChatFrame_MessageEventHandler(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15)
    local ActionTaken = false;  
    if event=="CHAT_MSG_SYSTEM" then
        if arg1:find("You have been inactive for some time and will be logged out") or arg1:find("You can only logout while rested in High Risk!") then
            ActionTaken = true                                             -- Hide server chat messages.
        end
    end
    if not ActionTaken then
        Alastor_ChatFrame_MessageEventHandler(frame, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15);
    end
end