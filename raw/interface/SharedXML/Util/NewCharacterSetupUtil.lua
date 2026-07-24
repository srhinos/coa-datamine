NewCharacterSetupUtil = {}

local ReadCustomWTF, WriteCustomWTF = ReadCustomWTF, WriteCustomWTF
local SAVED_FILE_NAME = "NewCharacterSetup"
local data = {}

local f = CreateFrame("Frame")
function f:Update()
    self:SetScript("OnUpdate", nil)
    local compressed = C_Serialize:SerializeCompressForPrint(data)
    if not string.isNilOrEmpty(compressed) then
        WriteCustomWTF(SAVED_FILE_NAME, compressed)
    end
    self:Hide()
end

local function LoadCharacterData()
    local compressed = ReadCustomWTF(SAVED_FILE_NAME)
    if not string.isNilOrEmpty(compressed) then
        data = C_Serialize:DeserializeDecompressFromPrint(compressed) or {}
    end
end

local function SaveCharacterData()
    f:SetScript("OnUpdate", f.Update)
    f:Show()
end

function NewCharacterSetupUtil.WipeCharacterData()
    assert(CanPerformAction(Enum.UIActionType.Forbidden))
    wipe(data)
    SaveCharacterData()
end

function NewCharacterSetupUtil.GetCharacterData(characterName, key)
    local realm = GetRealmName()
    if string.isNilOrEmpty(characterName) or string.isNilOrEmpty(realm) then
        return
    end

    characterName = characterName:lower()

    local realmData = data[realm]
    local characterData = realmData and realmData[characterName]
    return characterData and characterData[key]
end

function NewCharacterSetupUtil.SetCharacterData(characterName, key, value)
    assert(CanPerformAction(Enum.UIActionType.Forbidden))

    local realm = GetRealmName()
    if string.isNilOrEmpty(characterName) or  string.isNilOrEmpty(realm) then
        return
    end

    characterName = characterName:lower()

    local realmData = data[realm]
    if not realmData then
        realmData = {}
        data[realm] = realmData
    end

    local characterData = realmData[characterName]
    if not characterData then
        characterData = {}
        realmData[characterName] = characterData
    end
    
    characterData[key] = value
    
    -- clean up table as needed
    if value == nil then
        if table.isNilOrEmpty(characterData) then
            realmData[characterName] = nil

            if table.isNilOrEmpty(realmData) then
                data[realm] = nil
            end
        end
    end
    
    SaveCharacterData()
end

LoadCharacterData()

if InGlue() then
    -- GlueXML
    local pendingData = {}
    function NewCharacterSetupUtil.SetPendingKeyValue(key, value)
        pendingData[key] = value
    end

    function NewCharacterSetupUtil.ClearPendingData()
        wipe(pendingData)
    end

    local pendingCharacterName
    EventRegistry:RegisterFrameEventAndCallback("UPDATE_STATUS_DIALOG", function(callbackID, arg1)
        if arg1 == CHAR_CREATE_SUCCESS and pendingCharacterName  then
            EventRegistry:TriggerEvent("CharacterCreate.NewCharacter", pendingCharacterName:firstUpper())
            NewCharacterSetupUtil.SetCharacterData(pendingCharacterName, "recolor-newcomers", true)
            if not table.isNilOrEmpty(pendingData) then
                for key, value in pairs(pendingData) do
                    NewCharacterSetupUtil.SetCharacterData(pendingCharacterName, key, value)
                end
                NewCharacterSetupUtil.ClearPendingData()
            end
            pendingCharacterName = nil
        end
    end)

    local _CreateCharacter = CreateCharacter
    function CreateCharacter(characterName, ...)
        pendingCharacterName = characterName
        _CreateCharacter(characterName, ...)
    end
else
    -- FrameXML
    local hasSetLocaleNewcomersColor
    local loginEvent
    loginEvent = EventRegistry:RegisterFrameEventAndCallbackWithHandle("PLAYER_LOGIN", function()
        loginEvent:Unregister()

        local playerName = UnitName("player")
        
        local enableTransmog = NewCharacterSetupUtil.GetCharacterData(playerName, "enableTransmog")
        if enableTransmog ~= nil then
            C_Appearance.SetCanSeeAppearances(enableTransmog, enableTransmog)
            NewCharacterSetupUtil.SetCharacterData(playerName, "enableTransmog", nil)
        end

        local enableLevelScaling = NewCharacterSetupUtil.GetCharacterData(playerName, "enableLevelScaling")
        if enableLevelScaling ~= nil then
            SetLevelScaling(enableLevelScaling)
            NewCharacterSetupUtil.SetCharacterData(playerName, "enableLevelScaling", nil)
        end

        local buildID = NewCharacterSetupUtil.GetCharacterData(playerName, "archetypeBuildID")

        if buildID ~= nil then
            dprint("Found build for "..playerName.." activating "..buildID)

            if UnitLevel("player") == 1 then -- for not to mess up anything 
                C_BuildCreator.ActivateBuild(buildID, true, true)
            end

            NewCharacterSetupUtil.SetCharacterData(playerName, "archetypeBuildID", nil)
        end

        -- locale based newcomer chat
        if not C_CVar.GetBool("joinedDefaultChats") then
            C_CVar.Set("joinedDefaultChats", "1")
            local LOCALE_CLIENT = GetLocale()
            local LocaleChatChannels = {
                ["zhCN"] = { "chinese", "NewcomersCN" },
                ["zhTW"] = { "chinese", "NewcomersCN" },
                ["deDE"] = { "german", "NewcomersDE" },
                ["ruRU"] = { "russian", "NewcomersRU" },
                ["esES"] = { "spanish", "NewcomersES" },
                ["esMX"] = { "spanish", "NewcomersES" },
                ["frFR"] = { "french", "NewcomersFR" },
                ["koKR"] = { "korean", "NewcomersKR" },
            }
            if (LOCALE_CLIENT ~= "enUS") and (LOCALE_CLIENT ~= "enGB") and LocaleChatChannels[LOCALE_CLIENT] then
                for _, channel in ipairs(LocaleChatChannels[LOCALE_CLIENT]) do
                    if GetChannelName(channel) == 0 then
                        JoinPermanentChannel(channel, nil, nil, 0)
                    end
                end
                
            end
        end
    end)

    -- color newcomers chat(s)
    EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_CHANNEL_NOTICE", function(_, ...)
        local arg1, _, _, _, _, _, _, _, channelName = ...
        if arg1 == "YOU_JOINED" then
            if (channelName:lower():startswith("newcomers")) then
                local id = GetChannelName(channelName)
                if id ~= 0 then
                    if channelName:lower() == "newcomers" then
                        if NewCharacterSetupUtil.GetCharacterData(UnitName("player"), "recolor-newcomers") then
                            ChangeChatColor("CHANNEL"..id, 0, 1, 0.82) -- change color to newcomers channel
                            NewCharacterSetupUtil.SetCharacterData(UnitName("player"), "recolor-newcomers", nil)
                        end
                    elseif not C_CVar.GetBool("coloredLocaleNewcomersChat") then
                        C_CVar.Set("coloredLocaleNewcomersChat", "1")
                        ChangeChatColor("CHANNEL"..id, 0, 1, 0.82) -- locale newcomers
                    end
                end
            end
        end
    end)
end 