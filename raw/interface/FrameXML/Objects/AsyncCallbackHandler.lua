local MainHandler = {}
local EmptyFunc = function() end

MainHandler.CallbackHandlers = {}

function MainHandler:CacheSuccess(queryType, asset)
	if not queryType or not self.CallbackHandlers[queryType] then return end
	if not asset or asset == 0 then return end

	for _, handler in pairs(self.CallbackHandlers[queryType]) do
		handler:FireCallbacks(asset)
	end
end

EventRegistry:RegisterFrameEventAndCallback("ITEM_CACHE_REQUEST_SUCCESS", MainHandler.CacheSuccess, MainHandler, Enum.CacheQueryGroup.Items)
EventRegistry:RegisterFrameEventAndCallback("QUEST_CACHE_REQUEST_SUCCESS", MainHandler.CacheSuccess, MainHandler, Enum.CacheQueryGroup.Quests)
EventRegistry:RegisterFrameEventAndCallback("CREATURE_CACHE_REQUEST_SUCCESS", MainHandler.CacheSuccess, MainHandler, Enum.CacheQueryGroup.Creatures)

function MainHandler:Add(handler, api)
	if not api or not handler then return end

	if not MainHandler.CallbackHandlers[api] then
		MainHandler.CallbackHandlers[api] = {}
	end

	tinsert(MainHandler.CallbackHandlers[api], handler)
end

function MainHandler:Remove(handler, api)
	if not api or not handler then return end

	if not MainHandler.CallbackHandlers[api] then return end
	
	tremoveItem(MainHandler.CallbackHandlers[api], handler)
end

function MainHandler:QueryAsset(asset, api)
	if not asset or not api then return end

    local cacheFunc
    if api == Enum.CacheQueryGroup.Items then
        cacheFunc = C_AssetQueryService.TryCacheItem
    elseif api == Enum.CacheQueryGroup.Quests then
        cacheFunc = C_AssetQueryService.TryCacheQuest
    elseif api == Enum.CacheQueryGroup.Creatures then
        cacheFunc = C_AssetQueryService.TryCacheCreature
    end

    if cacheFunc then
        if cacheFunc(asset) then
            return true
        end
    end
    
    return false
end

--
-- Callback handler mixin
--
local CallbackHandlerMixin = {}

function CallbackHandlerMixin:Init(apiType)
	if not apiType then return end
	self.callbacks = {}
	self.api = apiType

	MainHandler:Add(self, self.api)
	-- wipe this function so we can't recall this
	self.Init = nil
end

function CallbackHandlerMixin:Query(asset)
	return self:AddCallback(asset, EmptyFunc)
end

function CallbackHandlerMixin:AddCallback(asset, func, validator)
	if type(asset) == "table" then
		for i = #asset, 1, -1 do
			if validator and not validator(asset[i]) then
				func(asset[i])
				tremove(asset, i)
			else
				local callbacks = self:GetOrCreateCallbacks(asset[i])
				tinsert(callbacks, func)
			end
		end

		if #asset > 0 then
            for _, assetID in ipairs(asset) do
                MainHandler:QueryAsset(assetID, self.api)
            end
		end
		
		return #asset, asset
	else
		if validator and not validator(asset) then
			func(asset)
			return 0, 0
		end
		local callbacks = self:GetOrCreateCallbacks(asset)
		tinsert(callbacks, func)
		if #callbacks == 1 then
			MainHandler:QueryAsset(asset, self.api)
		end

		return #callbacks, callbacks
	end
end

function CallbackHandlerMixin:AddCancelableCallback(asset, func, validator)
	if type(asset) == "table" then
		local count = self:AddCallback(asset, func, validator)
		if count == 0 then return nop end

		return function()
			local cancelled = false
			for _, id in ipairs(asset) do
				if self.callbacks[id] then
					cancelled = true
					self.callbacks[id] = -1
				end
			end
			
			return cancelled
		end
	else
		local index, callbacks = self:AddCallback(asset, func, validator)
		if index == 0 then return nop end

		return function()
			if #callbacks > 0 and callbacks[index] ~= -1 then
				callbacks[index] = -1
				return true
			end

			return false
		end
	end
	
end

function CallbackHandlerMixin:FireCallbacks(asset)
	local callbacks = self:GetCallbacks(asset)
	
	if not callbacks then return end
	
	self:ClearCallbacks(asset)

	if callbacks == -1 then
		return
	end

	for _, callback in ipairs(callbacks) do
		if callback ~= -1 then
			pcall(callback, asset)
		end
	end

	-- cancel function has a ref to this table so must be manually wiped or it wont GC
	for i = #callbacks, 1, -1 do
		callbacks[i] = nil
	end
end

function CallbackHandlerMixin:ClearCallbacks(asset)
	self.callbacks[asset] = nil
end

function CallbackHandlerMixin:GetCallbacks(asset)
	return self.callbacks[asset]
end

function CallbackHandlerMixin:GetOrCreateCallbacks(asset)
	local callbacks = self:GetCallbacks(asset)

	if not callbacks or callbacks == -1 then
		callbacks = {}
		self.callbacks[asset] = callbacks
	end
	
	return callbacks
end

local function CreateListener(apiType)
	assert(type(apiType) == "number", "AsyncCallbackHandler: Number expected for CreateListener. Got apiType = " .. type(apiType))
	local listener = Mixin(CreateFrame("Frame"), CallbackHandlerMixin)
	listener:Init(apiType)
	return listener
end

CreatureQueryListener = CreateListener(Enum.CacheQueryGroup.Creatures)
ItemQueryListener = CreateListener(Enum.CacheQueryGroup.Items)
QuestQueryListener = CreateListener(Enum.CacheQueryGroup.Quests)