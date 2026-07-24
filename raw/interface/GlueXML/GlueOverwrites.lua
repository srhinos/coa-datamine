function InGlue()
	return true
end

function ReloadUI()
	C_Hook:SendEvent("RELOAD_UI")
	ConsoleExec("reloadui")
end

_RestartGx = _RestartGx or RestartGx
-- Overwrite RestartGx to also reloadUI.
-- Custom Textures will become completely white if this isn't done.
function RestartGx()
	_RestartGx()
	ReloadUI()
end