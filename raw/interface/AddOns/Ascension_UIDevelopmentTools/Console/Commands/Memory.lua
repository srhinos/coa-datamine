local TABLE_BASE_BYTES = 40
local TABLE_ENTRY_BYTES = 32
local REFERENCE_BYTES = 8
local STRING_BASE_BYTES = 24
local DEFAULT_PRINT_LIMIT = 100
local MAX_PATH_LENGTH = 180

local function FormatBytes(bytes)
	if bytes >= 1024 * 1024 then
		return format("%.2f MB", bytes / (1024 * 1024))
	elseif bytes >= 1024 then
		return format("%.1f KB", bytes / 1024)
	end

	return format("%d B", bytes)
end

local function EstimateValueBytes(value)
	local valueType = type(value)
	if valueType == "string" then
		return STRING_BASE_BYTES + strlen(value)
	elseif valueType == "number" then
		return 8
	elseif valueType == "boolean" then
		return 4
	elseif valueType == "table" or valueType == "function" or valueType == "userdata" or valueType == "thread" then
		return REFERENCE_BYTES
	end

	return 0
end

local function ShortenPath(path)
	if strlen(path) <= MAX_PATH_LENGTH then
		return path
	end

	local sideLength = floor((MAX_PATH_LENGTH - 3) / 2)
	return string.sub(path, 1, sideLength) .. "..." .. string.sub(path, -sideLength)
end

local function EscapePathString(value)
	value = string.gsub(value, "\\", "\\\\")
	value = string.gsub(value, "\"", "\\\"")
	value = string.gsub(value, "\n", "\\n")
	value = string.gsub(value, "\r", "\\r")

	if strlen(value) > 48 then
		value = string.sub(value, 1, 45) .. "..."
	end

	return "\"" .. value .. "\""
end

local function BuildChildPath(parentPath, key)
	local keyType = type(key)
	if keyType == "string" then
		if string.match(key, "^[_%a][_%w]*$") then
			return ShortenPath(parentPath .. "." .. key)
		end

		return ShortenPath(parentPath .. "[" .. EscapePathString(key) .. "]")
	elseif keyType == "number" or keyType == "boolean" then
		return ShortenPath(parentPath .. "[" .. tostring(key) .. "]")
	end

	return ShortenPath(parentPath .. "[" .. keyType .. ":" .. tostring(key) .. "]")
end

local function AddTableToQueue(tbl, path, queue, seen)
	if not seen[tbl] then
		seen[tbl] = true
		queue[#queue + 1] = { tbl = tbl, path = path }
	end
end

local function MeasureTable(tbl, path, queue, seen)
	local bytes = TABLE_BASE_BYTES
	local entries = 0
	local childTables = 0

	local ok, err = pcall(function()
		for key, value in pairs(tbl) do
			entries = entries + 1
			bytes = bytes + TABLE_ENTRY_BYTES + EstimateValueBytes(key) + EstimateValueBytes(value)

			if type(key) == "table" then
				childTables = childTables + 1
				AddTableToQueue(key, ShortenPath(path .. "[key:" .. tostring(key) .. "]"), queue, seen)
			end

			if type(value) == "table" then
				childTables = childTables + 1
				AddTableToQueue(value, BuildChildPath(path, key), queue, seen)
			end
		end
	end)

	local metaOk, metatable = pcall(getmetatable, tbl)
	if metaOk and type(metatable) == "table" then
		childTables = childTables + 1
		AddTableToQueue(metatable, ShortenPath(path .. ".__metatable"), queue, seen)
	end

	return {
		path = path,
		bytes = bytes,
		entries = entries,
		childTables = childTables,
		error = not ok and tostring(err) or nil,
	}
end

local function ScanTables(root, rootName)
	local queue = { { tbl = root, path = rootName } }
	local seen = { [root] = true }
	local records = {}
	local totalBytes = 0
	local index = 1

	while index <= #queue do
		local current = queue[index]
		local record = MeasureTable(current.tbl, current.path, queue, seen)
		records[#records + 1] = record
		totalBytes = totalBytes + record.bytes
		index = index + 1
	end

	table.sort(records, function(left, right)
		if left.bytes == right.bytes then
			return left.path < right.path
		end

		return left.bytes > right.bytes
	end)

	return records, totalBytes
end

local function GetRootOwner(path, rootName)
	if rootName ~= "_G" then
		return rootName
	end

	local owner = string.match(path, "^_G%.([_%a][_%w]*)")
	if owner then
		return owner
	end

	owner = string.match(path, "^_G%[\"([^\"]+)\"%]")
	return owner or "_G"
end

local function BuildOwnerSummary(records, rootName)
	local ownerByName = {}
	local owners = {}

	for _, record in ipairs(records) do
		local ownerName = GetRootOwner(record.path, rootName)
		local owner = ownerByName[ownerName]
		if not owner then
			owner = { name = ownerName, bytes = 0, tables = 0 }
			ownerByName[ownerName] = owner
			owners[#owners + 1] = owner
		end

		owner.bytes = owner.bytes + record.bytes
		owner.tables = owner.tables + 1
	end

	table.sort(owners, function(left, right)
		if left.bytes == right.bytes then
			return left.name < right.name
		end

		return left.bytes > right.bytes
	end)

	return owners
end

local function StripColors(text)
	text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
	text = string.gsub(text, "|r", "")
	return text
end

local function PrintMemoryLine(text, logResults)
	DevConsole:Print(text)

	if logResults and C_Logger and C_Logger.LUA then
		C_Logger.LUA("%s", StripColors(text))
	end
end

local function PrintMemoryHelp()
	DevConsole:Print("Usage: memtables [|cff00DDFFcount|r or |cff00DDFFall|r] [|cff00DDFFrootTable|r] [|cff00DDFFlog|r]")
	DevConsole:Print("Example: memtables")
	DevConsole:Print("Example: memtables 250")
	DevConsole:Print("Example: memtables all log")
	DevConsole:Print("Example: memtables 100 C_CharacterAdvancement")
	DevConsole:Print("Scans tables reachable from _G by default. Sizes are rough shallow estimates, not exact retained memory.")
end

local function ParseMemoryCommand(text)
	local printLimit = DEFAULT_PRINT_LIMIT
	local rootExpression
	local logResults = false

	for arg in string.gmatch(text or "", "%S+") do
		local lowerArg = string.lower(arg)
		if lowerArg == "help" then
			return nil, nil, false, true
		elseif lowerArg == "all" then
			printLimit = nil
		elseif lowerArg == "log" then
			logResults = true
		elseif tonumber(arg) then
			printLimit = max(1, floor(tonumber(arg)))
		elseif not rootExpression then
			rootExpression = arg
		end
	end

	return printLimit, rootExpression, logResults, false
end

local function ResolveRoot(rootExpression)
	if not rootExpression then
		return _G, "_G"
	end

	local chunk, err = loadstring("return " .. rootExpression)
	if not chunk then
		return nil, nil, err
	end

	local ok, root = pcall(chunk)
	if not ok then
		return nil, nil, root
	end

	if type(root) ~= "table" then
		return nil, nil, rootExpression .. " is " .. type(root) .. ", not table"
	end

	return root, rootExpression
end

local function ConsoleMemTables(text)
	local printLimit, rootExpression, logResults, showHelp = ParseMemoryCommand(text)
	if showHelp then
		PrintMemoryHelp()
		return
	end

	local root, rootName, err = ResolveRoot(rootExpression)
	if not root then
		DevConsole:PrintError("memtables:", err)
		return
	end

	local startMS = debugprofilestop and debugprofilestop()
	local records, totalBytes = ScanTables(root, rootName)
	local elapsedMS = startMS and (debugprofilestop() - startMS)
	local heapKB = collectgarbage("count")
	local heapText = heapKB and format(", Lua heap %.2f MB", heapKB / 1024) or ""
	local elapsedText = elapsedMS and format(", scan %.1fms", elapsedMS) or ""

	PrintMemoryLine(format("|cff22FF22Memory table scan:|r %d tables from |cff00DDFF%s|r%s%s, estimate %s", #records, rootName, heapText, elapsedText, FormatBytes(totalBytes)), logResults)
	PrintMemoryLine("|cff22FF22Top roots by first discovered path:|r", logResults)

	local owners = BuildOwnerSummary(records, rootName)
	for index = 1, min(10, #owners) do
		local owner = owners[index]
		PrintMemoryLine(format("%02d |cff00CCFF%s|r tables=%d %s", index, FormatBytes(owner.bytes), owner.tables, owner.name), logResults)
	end

	local outputCount = printLimit and min(printLimit, #records) or #records
	PrintMemoryLine(format("|cff22FF22Largest tables:|r showing %d of %d", outputCount, #records), logResults)

	for index = 1, outputCount do
		local record = records[index]
		local suffix = record.error and " |cffff4444partial: pairs failed|r" or ""
		PrintMemoryLine(format("%03d |cff00CCFF%s|r entries=%d tableRefs=%d %s%s", index, FormatBytes(record.bytes), record.entries, record.childTables, record.path, suffix), logResults)
	end

	if printLimit and printLimit < #records then
		DevConsole:Print("Use |cff00DDFFmemtables all|r to print every table, or |cff00DDFFmemtables all log|r to also write it to LUA.txt.")
	end

	if logResults and (not C_Logger or not C_Logger.LUA) then
		DevConsole:PrintError("memtables:", "C_Logger.LUA is not available; results were only printed to the console.")
	end
end

DevConsole:RegisterCommand({ "memtables", "tablemem", "mtables" }, "Print estimated Lua table memory usage. Use |cff00DDFFmemtables help|r for options.", ConsoleMemTables)
