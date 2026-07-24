--
-- Overwrite PlaySound to handle Sound kit tables
--
local secureSoundHandler = CreateFrame("Frame")
secureSoundHandler:SetScript("OnAttributeChanged", function(self, name, value)
	if name == "increment" then
		value.index = value.index or 1
		if value.index >= #value then
			value.index = 1
		else
			value.index = value.index + 1
		end
	end
end)

_PlaySound = _PlaySound or PlaySound
function PlaySound(soundFile, dontAllowMultiple, chanellingSound)
	--[[if (secureSoundHandler.chanellingSound) and StopSound then
		StopSound() -- stops last playing sound
		secureSoundHandler.chanellingSound = false
	end]]--

	if type(soundFile) == "table" then
		local index = soundFile.index or 1
		_PlaySound(soundFile[index])
		if dontAllowMultiple ~= true then
			secureSoundHandler:SetAttribute("increment", soundFile)
		end
	else
		_PlaySound(soundFile)
	end

	--[[if chanellingSound then
		secureSoundHandler.chanellingSound = true
	end]]--
end

_DisableAddOn = _DisableAddOn or DisableAddOn
function DisableAddOn(...)
	local id
	if InGlue() then
		id = select(2, ...)
	else
		id = ...
	end

	if C_AddonPanel:IsSecureAddon(id) then
		EnableAddOn(...)
		return
	end

	_DisableAddOn(...)
end

_DisableAllAddOns = _DisableAllAddOns or DisableAllAddOns
function DisableAllAddOns(...)
	_DisableAllAddOns()
	C_AddonPanel:EnableHiddenAddons()
end

local _GetCVarMin = _GetCVarMin or GetCVarMin
function GetCVarMin(cvarName)
	if cvarName then
		local parentCVar = cvarName:match("(.+)_raid$")
		cvarName = parentCVar or cvarName
	end
	return _GetCVarMin(cvarName)
end

local _GetCVarMax = _GetCVarMax or GetCVarMax
function GetCVarMax(cvarName)
	if cvarName then
		local parentCVar = cvarName:match("(.+)_raid$")
		cvarName = parentCVar or cvarName
	end
	return _GetCVarMax(cvarName)
end

local _xpcall = _xpcall or xpcall
if _xpcall then
	function xpcall(func, err, ...)
		if select("#", ...) > 0 then
			return _xpcall(GenerateClosureSafe(func, ...), err)
		end
		return _xpcall(func, err)
	end
end

-- dont let error handler be hijacked
do
	_seterrorhandler = seterrorhandler
	function seterrorhandler(...)
		return
	end
end


