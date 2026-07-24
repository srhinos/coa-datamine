function ExecuteFrameScript(frame, scriptName, ...)
	local script = frame:GetScript(scriptName)
	if script then
		xpcall(script, CallErrorHandler, frame, ...)
	end
end

function CallMethodOnNearestAncestor(self, methodName, ...)
	local ancestor = self:GetParent()
	while ancestor and not ancestor[methodName] do
		ancestor = ancestor:GetParent()
	end

	if ancestor then
		return true, ancestor[methodName](ancestor, ...)
	end

	return false
end

function GetValueOrCallFunction(tbl, key, ...)
	if not tbl then
		return
	end

	local value = tbl[key]
	if type(value) == "function" then
		return value(...)
	else
		return value
	end
end

local function CompositeIterator(iteratorCallbackArray)
	if #iteratorCallbackArray == 0 then
		return nop
	end

	local iteratorIndex = 1
	local currentIterator, currentTable, iteratorKey = iteratorCallbackArray[1]()
	local function AdvanceIterators()
		if currentIterator == nil then
			return nil
		end

		local nextKey = currentIterator(currentTable, iteratorKey)
		if nextKey ~= nil then
			iteratorKey = nextKey
			return nextKey
		end

		if iteratorIndex < #iteratorCallbackArray then
			iteratorIndex = iteratorIndex + 1
			currentIterator, currentTable, iteratorKey = iteratorCallbackArray[iteratorIndex]()
			return AdvanceIterators()
		end

		currentIterator = nil
		return nil
	end

	return AdvanceIterators
end

function IteratePools(...)
	local callbackArray = {}
	for i = 1, select("#", ...) do
		local pool = select(i, ...)
		table.insert(callbackArray, GenerateClosure(pool.EnumerateActive, pool))
	end

	return CompositeIterator(callbackArray)
end

function IterateTables(iteratorFunction, ...)
	local callbackArray = {}
	for i = 1, select("#", ...) do
		local tbl = select(i, ...)
		table.insert(callbackArray, GenerateClosure(iteratorFunction, tbl))
	end

	return CompositeIterator(callbackArray)
end

-- [[ Closure generation ]]

local closureGeneration = {
	function(f) return function(...) return f(...) end end,
	function(f, a) return function(...) return f(a, ...) end end,
	function(f, a, b) return function(...) return f(a, b, ...) end end,
	function(f, a, b, c) return function(...) return f(a, b, c, ...) end end,
	function(f, a, b, c, d) return function(...) return f(a, b, c, d, ...) end end,
	function(f, a, b, c, d, e) return function(...) return f(a, b, c, d, e, ...) end end,
	function(func, a, b, c, d, e, f) return function(...) return func(a, b, c, d, e, f, ...) end end,
	function(func, a, b, c, d, e, f, g) return function(...) return func(a, b, c, d, e, f, g, ...) end end,
	function(func, a, b, c, d, e, f, g, h) return function(...) return func(a, b, c, d, e, f, g, h, ...) end end,
	function(func, a, b, c, d, e, f, g, h, i) return function(...) return func(a, b, c, d, e, f, g, h, i, ...) end end,
}

function GenerateClosure(f, ...)
	local count = select("#", ...)
	local generator = closureGeneration[count + 1]
	if generator then
		return generator(f, ...)
	end
	error("Closure generation does not support more than "..(#closureGeneration - 1).." parameters")
end

function GenerateClosureSafe(f, ...)
	local count = select("#", ...)
	local generator = closureGeneration[count + 1] or closureGeneration[#closureGeneration]
	if generator then
		return generator(f, ...)
	end
end

function RunNextFrame(callback)
	Timer.NextFrame(callback)
end