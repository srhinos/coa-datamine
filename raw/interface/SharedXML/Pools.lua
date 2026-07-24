--
-- https://github.com/Gethe/wow-ui-source/blob/53eff055dcffff98029f0438f9b0da421e4dad70/Interface/SharedXML/Pools.lua
--
ObjectPoolMixin = {};

function ObjectPoolMixin:OnLoad(creationFunc, resetterFunc)
	self.creationFunc = creationFunc;
	self.resetterFunc = resetterFunc;

	self.activeObjects = {};
	self.inactiveObjects = {};
	self.deferredRelease = {};

	self.numActiveObjects = 0;
end

function ObjectPoolMixin:Acquire()
	local numInactiveObjects = #self.inactiveObjects;
	if numInactiveObjects > 0 then
		local obj = self.inactiveObjects[numInactiveObjects];
		self.activeObjects[obj] = true;
		self.numActiveObjects = self.numActiveObjects + 1;
		self.inactiveObjects[numInactiveObjects] = nil;
		self.deferredRelease[obj] = nil
		return obj, false;
	end

	local newObj = self.creationFunc(self);
	if self.resetterFunc and not self.disallowResetIfNew then
		self.resetterFunc(self, newObj);
	end
	self.activeObjects[newObj] = true;
	self.numActiveObjects = self.numActiveObjects + 1;
	return newObj, true;
end

function ObjectPoolMixin:Release(obj)
	if self:IsActive(obj) then
		self.inactiveObjects[#self.inactiveObjects + 1] = obj;
		self.activeObjects[obj] = nil;
		self.numActiveObjects = self.numActiveObjects - 1;
		self.deferredRelease[obj] = nil
		if self.resetterFunc then
			self.resetterFunc(self, obj);
		end

		return true;
	end

	return false;
end

function ObjectPoolMixin:ReleaseAll()
	for obj in pairs(self.activeObjects) do
		self:Release(obj);
	end
end

function ObjectPoolMixin:ReleaseAllWithParent(parent)
	for obj in pairs(self.activeObjects) do
		if obj.GetParent and obj:GetParent() == parent then
			self:Release(obj);
		end
	end
end

function ObjectPoolMixin:DeferredRelease(obj)
	if self:IsActive(obj) then
		self.inactiveObjects[#self.inactiveObjects + 1] = obj;
		self.activeObjects[obj] = nil;
		self.numActiveObjects = self.numActiveObjects - 1;
		if self.resetterFunc then
			self.deferredRelease[obj] = true
		end

		return true;
	end

	return false;
end

function ObjectPoolMixin:DeferredReleaseAll()
	for obj in pairs(self.activeObjects) do
		self:DeferredRelease(obj);
	end
end

function ObjectPoolMixin:DeferredReleaseAllWithParent(parent)
	for obj in pairs(self.activeObjects) do
		if obj.GetParent and obj:GetParent() == parent then
			self:DeferredRelease(obj);
		end
	end
end

function ObjectPoolMixin:CompleteDeferredRelease()
	for obj in pairs(self.deferredRelease) do
		if self.resetterFunc then
			self.resetterFunc(self, obj);
		end
	end
	
	wipe(self.deferredRelease)
end

function ObjectPoolMixin:SetResetDisallowedIfNew(disallowed)
	self.disallowResetIfNew = disallowed;
end

function ObjectPoolMixin:EnumerateActive()
	return pairs(self.activeObjects);
end

function ObjectPoolMixin:EnumerateActiveWithParent(parent)
	local currentObject = nil;
	return function()
		if currentObject then
			currentObject = self:GetNextActive(currentObject);
		else
			currentObject = self:GetNextActive();
		end

		while currentObject do
			if currentObject.GetParent and currentObject:GetParent() == parent then
				return currentObject;
			end

			currentObject = self:GetNextActive(currentObject);
		end
	end, nil;
end

function ObjectPoolMixin:GetNextActive(current)
	return (next(self.activeObjects, current));
end

function ObjectPoolMixin:GetNextInactive(current)
	return (next(self.inactiveObjects, current));
end

function ObjectPoolMixin:IsActive(object)
	return (self.activeObjects[object] ~= nil);
end

function ObjectPoolMixin:GetNumActive()
	return self.numActiveObjects;
end

function ObjectPoolMixin:EnumerateInactive()
	return ipairs(self.inactiveObjects);
end

function CreateObjectPool(creationFunc, resetterFunc)
	local objectPool = CreateFromMixins(ObjectPoolMixin);
	objectPool:OnLoad(creationFunc, resetterFunc);
	return objectPool;
end

FramePoolMixin = CreateFromMixins(ObjectPoolMixin);

local function FramePoolFactory(framePool)
	if type(framePool.parent) == "string" then
		framePool.parent = _G[framePool.parent]
	end
	local parentName = framePool.parent and framePool.parent:GetName()
	local frameName
	if parentName then
		framePool.frameCount = framePool.frameCount + 1
		frameName = string.format("%sPoolFrame%s%d", parentName, framePool.frameTemplate, framePool.frameCount)
	else
		frameName = string.format("FramePoolFrame_%s_%s", framePool:GetNumActive(), time())
	end
	return CreateFrame(framePool.frameType, frameName, framePool.parent, framePool.frameTemplate);
end

function FramePoolMixin:OnLoad(frameType, parent, frameTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, FramePoolFactory, resetterFunc);
	self.frameType = frameType;
	self.frameCount = 0
	self.parent = parent;
	self.frameTemplate = frameTemplate;
end

function FramePoolMixin:GetTemplate()
	return self.frameTemplate;
end

function FramePool_Hide(framePool, frame)
	frame:Hide();
end

function FramePool_HideAndClearAnchors(framePool, frame)
	frame:Hide();
	frame:ClearAllPoints();
end

function CreateFramePool(frameType, parent, frameTemplate, resetterFunc)
	local framePool = CreateFromMixins(FramePoolMixin);
	framePool:OnLoad(frameType, parent, frameTemplate, resetterFunc or FramePool_HideAndClearAnchors);
	return framePool;
end

TexturePoolMixin = CreateFromMixins(ObjectPoolMixin);

local function TexturePoolFactory(texturePool)
	if type(texturePool.parent) == "string" then
		texturePool.parent = _G[texturePool.parent]
	end
	return texturePool.parent:CreateTexture(nil, texturePool.layer, texturePool.textureTemplate);
end

function TexturePoolMixin:OnLoad(parent, layer, textureTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, TexturePoolFactory, resetterFunc);
	self.parent = parent;
	self.layer = layer;
	self.textureTemplate = textureTemplate;
end

TexturePool_Hide = FramePool_Hide;
TexturePool_HideAndClearAnchors = FramePool_HideAndClearAnchors;

function CreateTexturePool(parent, layer, textureTemplate, resetterFunc)
	local texturePool = CreateFromMixins(TexturePoolMixin);
	texturePool:OnLoad(parent, layer, textureTemplate, resetterFunc or TexturePool_HideAndClearAnchors);
	return texturePool;
end

FontStringPoolMixin = CreateFromMixins(ObjectPoolMixin);

local function FontStringPoolFactory(fontStringPool)
	if type(fontStringPool.parent) == "string" then
		fontStringPool.parent = _G[fontStringPool.parent]
	end
	return fontStringPool.parent:CreateFontString(nil, fontStringPool.layer, fontStringPool.fontStringTemplate, fontStringPool.subLayer);
end

function FontStringPoolMixin:OnLoad(parent, layer, subLayer, fontStringTemplate, resetterFunc)
	ObjectPoolMixin.OnLoad(self, FontStringPoolFactory, resetterFunc);
	self.parent = parent;
	self.layer = layer;
	self.subLayer = subLayer;
	self.fontStringTemplate = fontStringTemplate;
end

FontStringPool_Hide = FramePool_Hide;
FontStringPool_HideAndClearAnchors = FramePool_HideAndClearAnchors;

function CreateFontStringPool(parent, layer, subLayer, fontStringTemplate, resetterFunc)
	local fontStringPool = CreateFromMixins(FontStringPoolMixin);
	fontStringPool:OnLoad(parent, layer, subLayer, fontStringTemplate, resetterFunc or FontStringPool_HideAndClearAnchors);
	return fontStringPool;
end

FramePoolCollectionMixin = {};

function CreateFramePoolCollection()
	local poolCollection = CreateFromMixins(FramePoolCollectionMixin);
	poolCollection:OnLoad();
	return poolCollection;
end

function FramePoolCollectionMixin:OnLoad()
	self.pools = {};
end

function FramePoolCollectionMixin:GetNumActive()
	local numTotalActive = 0;
	for _, pool in pairs(self.pools) do
		numTotalActive = numTotalActive + pool:GetNumActive();
	end
	return numTotalActive;
end

function FramePoolCollectionMixin:GetOrCreatePool(frameType, parent, template, resetterFunc)
	local pool = self:GetPool(template);
	if not pool then
		return self:CreatePool(frameType, parent, template, resetterFunc), true;
	end
	return pool, false;
end

function FramePoolCollectionMixin:CreatePool(frameType, parent, template, resetterFunc)
	assert(self:GetPool(template) == nil);
	local pool = CreateFramePool(frameType, parent, template, resetterFunc);
	pool:SetResetDisallowedIfNew(self.resetDisallowed);
	self.pools[template] = pool;
	return pool;
end

function FramePoolCollectionMixin:CreatePoolIfNeeded(frameType, parent, template, resetterFunc)
	if not self:GetPool(template) then
		self:CreatePool(frameType, parent, template, resetterFunc);
	end
end

function FramePoolCollectionMixin:GetPool(template)
	return self.pools[template];
end

function FramePoolCollectionMixin:Acquire(template)
	local pool = self:GetPool(template);
	assert(pool);
	return pool:Acquire();
end

function FramePoolCollectionMixin:Release(object)
	for _, pool in pairs(self.pools) do
		if pool:Release(object) then
			-- Found it! Just return
			return;
		end
	end

	-- Huh, we didn't find that object
end

function FramePoolCollectionMixin:ReleaseAll(template)
	if template then
		local pool = self:GetPool(template)
		if not pool then return end
		pool:ReleaseAll()
	else
		for _, pool in pairs(self.pools) do
			pool:ReleaseAll()
		end
	end

	-- Huh, we didn't find that object
end

function FramePoolCollectionMixin:SetResetDisallowedIfNew(disallowed)
	self.resetDisallowed = disallowed;
	for _, pool in pairs(self.pools) do
		pool:SetResetDisallowedIfNew(disallowed);
	end
end

function FramePoolCollectionMixin:ReleaseAllByTemplate(template)
	local pool = self:GetPool(template);
	if pool then
		pool:ReleaseAll();
	end
end

function FramePoolCollectionMixin:EnumerateActiveByTemplate(template)
	local pool = self:GetPool(template);
	if pool then
		return pool:EnumerateActive();
	end

	return nop;
end

function FramePoolCollectionMixin:EnumerateActive()
	local currentPoolKey, currentPool = next(self.pools, nil);
	local currentObject = nil;
	return function()
		if currentPool then
			currentObject = currentPool:GetNextActive(currentObject);
			while not currentObject do
				currentPoolKey, currentPool = next(self.pools, currentPoolKey);
				if currentPool then
					currentObject = currentPool:GetNextActive();
				else
					break;
				end
			end
		end

		return currentObject;
	end, nil;
end

function FramePoolCollectionMixin:EnumerateInactiveByTemplate(template)
	local pool = self:GetPool(template);
	if pool then
		return pool:EnumerateInactive();
	end

	return nop;
end

function FramePoolCollectionMixin:EnumerateInactive()
	local currentPoolKey, currentPool = next(self.pools, nil);
	local currentObject = nil;
	return function()
		if currentPool then
			currentObject = currentPool:GetNextInactive(currentObject);
			while not currentObject do
				currentPoolKey, currentPool = next(self.pools, currentPoolKey);
				if currentPool then
					currentObject = currentPool:GetNextInactive();
				else
					break;
				end
			end
		end

		return currentObject;
	end, nil;
end

FixedSizeFramePoolCollectionMixin = CreateFromMixins(FramePoolCollectionMixin);

function CreateFixedSizeFramePoolCollection()
	local poolCollection = CreateFromMixins(FixedSizeFramePoolCollectionMixin);
	poolCollection:OnLoad();
	return poolCollection;
end

function FixedSizeFramePoolCollectionMixin:OnLoad()
	FramePoolCollectionMixin.OnLoad(self);
	self.sizes = {};
end

function FixedSizeFramePoolCollectionMixin:CreatePool(frameType, parent, template, resetterFunc, maxPoolSize, preallocate)
	local pool = FramePoolCollectionMixin.CreatePool(self, frameType, parent, template, resetterFunc);

	if preallocate then
		for i = 1, maxPoolSize do
			pool:Acquire();
		end
		pool:ReleaseAll();
	end

	self.sizes[template] = maxPoolSize;

	return pool;
end

function FixedSizeFramePoolCollectionMixin:Acquire(template)	
	local pool = self:GetPool(template);
	assert(pool);

	if pool:GetNumActive() < self.sizes[template] then
		return pool:Acquire();
	end
	return nil;
end