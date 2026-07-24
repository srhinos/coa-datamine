--
-- Game mode events / checking
--
C_GameMode = CreateFromMixins(CallbackRegistryMixin)
CallbackRegistryMixin.OnLoad(C_GameMode)
C_GameMode:GenerateCallbackEvents(
{
	"OnGameModeChanged",
})

function C_GameMode:IsGameModeActive(...)
	local activeModes = GetCustomGameMode()
	for i = 1, select("#", ...) do
		local mode = select(i, ...)
		if bit.contains(activeModes, mode) then
			return true
		end
	end

	return false
end

function C_GameMode:IsAnyGameModeActive()
	return GetCustomGameMode() ~= Enum.GameMode.None
end

function C_GameMode:GetActiveGameModes()
	local modes = {
		None = true
	}

	local activeModes = GetCustomGameMode()
	for mode, value in pairs(Enum.GameMode) do
		if value ~= Enum.GameMode.None then
			if bit.contains(activeModes, value) then
				modes[mode] = true
				modes.None = nil
			end
		end
	end

	return modes
end

function C_GameMode:ASCENSION_CUSTOM_GAME_MODE_CHANGED()
	self:TriggerEvent("OnGameModeChanged")
	C_Hook:SendEvent("GAME_MODE_UPDATE")
end

function C_GameMode:PLAYER_ENTERING_WORLD()
	self:ASCENSION_CUSTOM_GAME_MODE_CHANGED()
	C_Hook:Unregister("PLAYER_ENTERING_WORLD")
end

C_Hook:Register(C_GameMode, "ASCENSION_CUSTOM_GAME_MODE_CHANGED, PLAYER_ENTERING_WORLD")