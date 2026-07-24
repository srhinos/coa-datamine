-- Protected Ascension Addons
ASCENSION_PROTECTED_ADDONS = {
	["AscensionUI"] = true,
	["AscensionHelp"] = true,
}

function LoadAscensionAddOns()
	for i = 1, GetNumAddOns() do
		local addon = GetAddOnInfo(i)
		if addon and ASCENSION_PROTECTED_ADDONS[addon] then
			EnableAddOn(nil, i)
		end
	end
end
