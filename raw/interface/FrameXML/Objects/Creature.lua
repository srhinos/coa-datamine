Creature = {}
CreatureMixin = {}

function Creature:CreateFromID(creatureID)
	local creature = CreateFromMixins(CreatureMixin)
	creature:SetCreatureID(creatureID)
	return creature
end

function CreatureMixin:Query()
	if not self:IsCached() then
		CreatureQueryListener:Query(self.creatureID)
	end
end

function CreatureMixin:SetCreatureID(creatureID)
	self.creatureID = creatureID
end

function CreatureMixin:Clear()
	self.creatureID = nil
end

function CreatureMixin:IsEmpty()
	return not self.creatureID or type(self.creatureID) ~= "number" or self.creatureID <= 0
end

function CreatureMixin:IsCached()
	if self:IsEmpty() then return false end
	return GetCreatureTemplate(self.creatureID) ~= nil
end

function CreatureMixin:GetName()
	local template = GetCreatureTemplate(self.creatureID)
	if not template then return end
	return template.Name
end

-- adds a callback to be executed when this spell data is available, executes immediately if already loaded.
function CreatureMixin:ContinueOnLoad(func)
	if type(func) ~= "function" or self:IsEmpty() then
		error("Usage: NonEmptyCreature:ContinueOnLoad", 2)
	end

	if self:IsCached() then
		func(self.creatureID)
		return
	end

	CreatureQueryListener:AddCallback(self.creatureID, func)
end

-- returns a function that will cancel this callback when called
function CreatureMixin:CancelableContinueOnLoad(func)
	if type(func) ~= "function" or self:IsEmpty() then
		error("Usage: NonEmptyCreature:ContinueOnLoad", 2)
	end

	if self:IsCached() then
		func(self.creatureID)
		return
	end

	return CreatureQueryListener:AddCancelableCallback(self.creatureID, func)
end 

