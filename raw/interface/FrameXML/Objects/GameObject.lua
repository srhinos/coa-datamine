GameObject = {}
GameObjectMixin = {}

function GameObject:CreateFromID(objectID)
	local object = CreateFromMixins(GameObjectMixin)
	object:SetObjectID(objectID)
	return object
end

function GameObjectMixin:SetObjectID(objectID)
	self.objectID = objectID
end

function GameObjectMixin:Clear()
	self.objectID = nil
end

function GameObjectMixin:IsEmpty()
	return not self.objectID or type(self.objectID) ~= "number" or self.objectID <= 0
end

