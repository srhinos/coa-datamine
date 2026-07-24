--
-- https://github.com/AlexFolland/GarbageProtector
--

GarbageCollectionUtil = {}

local _collectgarbage = collectgarbage
_collectgarbage("setpause", 105)
_collectgarbage("setstepmul", 300)

function collectgarbage(option, args)
	if option == nil or option == "collect" or option == "stop" or option == "restart" or option == "step" then
		-- dont allow anything to manually collect garbage.
		-- its completely pointless, lua can do it on its own as needed.
	elseif option == "count" then
		return _collectgarbage(option, args)
	elseif option == "setpause" then
		--prevents addons from changing GC pause from 105, but still returns current value
		return _collectgarbage("setpause", 105)
	elseif option == "setstepmul" then
		--prevents addons from changing GC step multiplier from 300, but still returns current value
		return _collectgarbage("setstepmul", 300)
	else
		--if lua adds something new like isrunning to this, it should still work
		return _collectgarbage(option, args)
	end
end

function GarbageCollectionUtil.SecureCollectGarbage()
	if not issecure() then return end
	_collectgarbage()
end

function GarbageCollectionUtil.SetAllowUpdateMemoryUsage(allow)
	C_CVar.Set("allowAddonMemoryUsage", allow and "1" or "0")
end

function GarbageCollectionUtil.UpdateMemoryUsageAllowed()
	return C_CVar.GetBool("allowAddonMemoryUsage")
end

--UpdateAddOnMemoryUsage is a waste of time and some addons like Details call it periodically for no apparent reason
--this hook makes memory profiling addons that call GetAddOnMemoryUsage show 0 or the last returned value of course
local _UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage

-- allow secure code to call whenever it wants, but only if we've explicitly called it.
-- this function may be called somewhere by old code so just make a new wrapper
function GarbageCollectionUtil.UpdateAddOnMemoryUsage()
	if not issecure() then return end
	_UpdateAddOnMemoryUsage()
end

-- gm clients should always bypass since we check this often
UpdateAddOnMemoryUsage = function(...)
	if GarbageCollectionUtil.UpdateMemoryUsageAllowed() or IsGMClient then
		return _UpdateAddOnMemoryUsage(...)
	end
end