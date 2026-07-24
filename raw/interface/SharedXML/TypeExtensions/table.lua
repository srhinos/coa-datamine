function table.Copy(t, lookup_table)
    if type(t) ~= "table" then return end

	local copy = {}

	for i, v in pairs(t) do
		if type(v) ~= "table" then
			copy[i] = v
		else
			lookup_table = lookup_table or {}
			lookup_table[t] = copy
			if lookup_table[v] then
				copy[i] = lookup_table[v] -- we already copied this table. reuse the copy.
			else
				copy[i] = table.Copy(v, lookup_table) -- not yet copied. copy it.
			end
		end
	end
	return copy
end

tcopy = table.Copy


function table.Contains(t, value)
	for k, v in pairs(t) do
		if v == value then
			return true, k
		end
	end

	return false
end

tcontains = table.Contains

function table.RemoveItem(t, value)
	for k, v in pairs(t) do
		if v == value then
			tremove(t, k)
			return k, v
		end
	end
end

tremoveItem = table.RemoveItem

function table.length(t)
	local len = 0
	for _ in pairs(t) do
		len = len + 1
	end
	
	return len
end

tlen = table.length

function table.reverse(t)
	for i = 1, math.floor(#t / 2) do
		t[i], t[#t - i + 1] = t[#t - i + 1], t[i]
	end
	return t
end

treverse = table.reverse

function table.invert(t)
	local inverted = {}
	for k, v in pairs(t) do
		inverted[v] = k
	end
	
	return inverted
end
tinvert = table.invert
tInvert = table.invert

function table.append(t1, t2)
	if not t2[1] then
		for k, v in pairs(t2) do
			if not t1[k] then
				t1[k] = v
			end
		end
	else
		for _, v in ipairs(t2) do
			tinsert(t1, v)
		end
	end
end
tappend = table.append

function table.select(t, n, index)
	if type(n) == "number" then
		index = index or 1
		return { unpack(t, index, index+(n-1)) }
	end

	if type(n) == "function" then
		local out = {}
		for _, v in ipairs(t) do
			if n(v) then
				tinsert(out, v)
			end
		end
		
		return out
	end
end
tselect = table.select

function table.take(t, n, index)
	if n >= #t then
		local t1 = table.Copy(t)
		wipe(t)
		return t1
	end

	index = index or 1
	local t1 = {}
	
	for i = index + (n - 1), index, -1 do
		if t[i] then
			table.insert(t1, table.remove(t, i))
		end
	end
	
	
	return table.reverse(t1)
end
ttake = table.take


function table.indexOf(t, item)
	for i, v in ipairs(t) do
		if item == v then
			return i
		end
	end
end
tIndexOf = table.indexOf

function table.insertMany(t, ...)
	for i = 1, select("#", ...) do
		tinsert(t, (select(i, ...)))
	end
end
tinsertMany = table.insertMany

function table.isNilOrEmpty(t)
	return not t or next(t) == nil
end

function table.hasAnyEntries(t)
    return not table.isNilOrEmpty(t)
end
TableHasAnyEntries = table.hasAnyEntries

function table.compare(t1, t2)
    for k, v in pairs(t1) do
        if type(v) == "table" and type(t2[k]) == "table" then
            if not table.compare(v, t2[k]) then
                return false
            end
        elseif t2[k] ~= v then
            return false
        end
    end
    for k in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end
    return true
end
tCompare = table.compare

function table.merge(t1, t2, safe)
    local merged = {}
    for k, v in pairs(t1) do
        merged[k] = v
    end
    for k, v in pairs(t2) do
        if not safe or not merged[k] then
            merged[k] = v
        end
    end
    return merged
end
MergeTable = table.merge

function table.appendAll(table, array)
    for i, element in ipairs(array) do
        tinsert(table, element)
    end
end
tAppendAll = table.appendAll

function table.ipairs_reverse(t)
    local function Enumerator(t, index)
        index = index - 1;
        local value = t[index];
        if value ~= nil then
            return index, value;
        end
    end
    return Enumerator, t, #t + 1;
end
ipairs_reverse = table.ipairs_reverse

function GetKeysArray(tbl)
	local keysArray = {}
	for key in pairs(tbl) do
		tinsert(keysArray, key)
	end

	return keysArray
end

function GetValuesArray(tbl)
	local valuesArray = {}
	for key, value in pairs(tbl) do
		tinsert(valuesArray, value)
	end

	return valuesArray
end

function GetPairsArray(tbl)
	local pairsArray = {}
	for key, value in pairs(tbl) do
		tinsert(pairsArray, { key = key, value = value })
	end

	return pairsArray
end

table.empty = {}
