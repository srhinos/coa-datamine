FelCommutationUtil = {}

local function GameObjectUsed(callbackID, objectID)
    if objectID == Enum.GameObject.FelCommutationPortal then
        local isFelCommutated = C_HighRisk.IsFelCommutationActive()
        local canToggle, reason = C_HighRisk.CanToggleFelCommutation(not isFelCommutated)
        if canToggle then
            C_HighRisk.ToggleFelCommutation(not isFelCommutated)
            return
        else
            UIErrorsFrame:AddMessage(_G[reason] or reason, 1, 0, 0, 1)
        end
    end
end

local function OnFelCommutationStatusResult(callbackID, result)
    if result:endswith("_OK") then
        local isActive = C_HighRisk.IsFelCommutationActive()
        local specificResult = (result or "")..(isActive and "_ACTIVATED" or "_DISABLED")
        local message = _G[specificResult] or specificResult or ""
        SendSystemMessage(message)
        if isActive then
            PlaySound(SOUNDKIT.SPELL_DH_SHEAR_FELBLADE_CAST_01)
            UIErrorsFrame:AddMessage(message, GREEN_FONT_COLOR:GetRGBA())
        else
            PlaySound(SOUNDKIT.FX_MAGIC_ARCANE_CAST_SMALL_01)
            UIErrorsFrame:AddMessage(message, RED_FONT_COLOR:GetRGBA())
        end
    else
        local message = _G[result] or result or ""
        SendSystemMessage(message)
        UIErrorsFrame:AddMessage(message, RED_FONT_COLOR:GetRGBA())
    end
end

EventRegistry:RegisterFrameEventAndCallback("TOGGLE_FEL_COMMUTATION_STATUS_RESULT", OnFelCommutationStatusResult)
EventRegistry:RegisterFrameEventAndCallback("GAMEOBJECT_USED", GameObjectUsed)