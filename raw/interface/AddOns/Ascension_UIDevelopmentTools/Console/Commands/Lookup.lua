local LUA_LIBRARIES

local function GetRealType(key, obj)
	local t = type(obj)
	if t == "table" then
		if obj.GetObjectType then
			local ok, objType = pcall(obj.GetObjectType, obj)
			if ok then
				if not objType then
					return "frame", "Unknown <Region>"
				else
					return "frame", objType .. " <Region>"
				end
			end
		end
	end

	if key:startswith("C_") and t == "table" then
		return t, "Function Namespace"
	end

	if key:endswith("Util") and t == "table" then
		return t, "Utility Namespace"
	end

	if key:endswith("Mixin") and t == "table" then
		return t, "Mixin"
	end

	return t, t
end

local function PrintEntry(key, tag)
	if not tag or tag == "" then
		return DevConsole:Print("|cff00CCFF" .. key .. "|r")
	end
	
	DevConsole:Print("|cff00CCFF" .. key .. "|r", "<"..tag..">")
end

local LookupTypes = {
	["event"] = {
		description = "Search for a script event containing <|cff00DDFFtext|r>",
		func = function(searchText)
			return FindScriptEvents(searchText or "")
		end
	},
	["function"] = {
		alias = "func",
		description = "Search functions with the global key name containing <|cff00DDFFname|r>",
		type = "function"
	},
	["namespace"] = {
		alias = "ns",
		description = "Search namespaces with the global key name containing <|cff00DDFFname|r>",
		type = "table",
		match = function(key, obj)
			return key:endswith("Util") or key:startswith("C_")
		end
	},
	["mixin"] = {
		description = "Search mixins with the global key name containing <|cff00DDFFname|r>",
		type = "table",
		match = function(key, obj)
			return key:endswith("Mixin")
		end
	},
	["table"] = {
		description = "Search tables with the global key name containing <|cff00DDFFname|r>",
		type = "table"
	},
	["frame"] = {
		description = "Search frame objects with the global key name containing <|cff00DDFFname|r>",
		type = "frame"
	},
	["global"] = {
		description = "Search all global values with the key name containing <|cff00DDFFname|r>",
	},
	["library"] = {
		description = "Search for loadable LibStub libraries provided by Ascension containing <|cff00DDFFname|r>",
		alias = "lib",
		func = function(searchText)
			local libs = {}
			for _, lib in ipairs(LUA_LIBRARIES) do
				if lib:lower():find(searchText) then
					table.insert(libs, lib)
				end
			end
			return libs
		end
	}
}

local function DoLookup(text)
	local command, obj, target = text:match("([^%s]+)%s+(.-)%s+in%s+(.*)")
	if not command then
		command, obj = text:match("([^%s]+)%s+(.*)")
	end

	if target and not _G[target] then
		-- try and eval target
		local getTarget = loadstring("return " .. target)
		local success, newTarget
		if getTarget then
			success, newTarget = pcall(getTarget)
		end
		
		if not success or not newTarget and not _G[newTarget] then
			return DevConsole:PrintError("Cound not find", target, "in the global table!")
		end
		
		target = newTarget
	end

	if not command or not obj then
		DevConsole:Print("Usage: Lookup <|cff00DDFFtype|r> <|cff00DDFFname or `any`|r> (optional) in <|cff00DDFFtable|r>")
		DevConsole:Print("Example: Lookup function realm |cff00DDFF--Lists all functions with realm in the name|r")
		DevConsole:Print("Example: Lookup function appearance in C_Appearance |cff00DDFF--Searches all keys inside C_Appearance with `appearance` in the name|r")
		for keyword, definition in pairs(LookupTypes) do
			if definition.alias then
				DevConsole:Print("|cff00DDFF"..keyword.."|r", "Alias: |cff00DDFF"..definition.alias.."|r", definition.description)
			else
				DevConsole:Print("|cff00DDFF"..keyword.."|r", definition.description)
			end
		end
		return
	end

	command = command:lower()
	obj = obj:lower()
	if obj == "any" then obj = "" end

	if target then
		DevConsole:Print("|cff22FF22Lookup Results for:|r", command, "->", obj, "in", target)
	else
		DevConsole:Print("|cff22FF22Lookup Results for:|r", command, "->", obj)
	end

	local definition = LookupTypes[command]

	if not definition then
		-- maybe alias?
		for keyword, lookupType in pairs(LookupTypes) do
			if lookupType.alias == command then
				definition = lookupType
				command = keyword
				break
			end
		end

		if not definition then
			return DevConsole:PrintError("No lookup type for", command, "found")
		end
	end

	if definition.func then
		for _, value in ipairs(definition.func(obj)) do
			PrintEntry(value)
		end
		return
	end

	local lookupTable = target and _G[target] or _G
	local keyPrefix = target and target .. "." or ""
	for k, v in pairs(lookupTable) do
		local realType, friendlyName = GetRealType(tostring(k), v)
		if (not definition.type or realType == definition.type) and (not definition.match or definition.match(k, v)) and tostring(k):lower():find(obj) then
			PrintEntry(keyPrefix..k, friendlyName)
		end
	end
end

DevConsole:RegisterCommand({ "lookup", "loo" }, "search for something following the command", DoLookup)

LUA_LIBRARIES = {
	"CallbackHandler-1.0",
	"LibTalentQuery-1.0",
	"LibSharedMedia-3.0",
}