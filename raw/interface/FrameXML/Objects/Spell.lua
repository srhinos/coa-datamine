Spell = {}
SpellMixin = {}

function Spell:CreateFromID(spellID)
	local spell = CreateFromMixins(SpellMixin)
	spell:SetSpellID(spellID)
	return spell
end

function SpellMixin:SetSpellID(spellID)
	self.spellID = spellID
end 

function SpellMixin:Clear()
	self.spellID = nil
end

function SpellMixin:IsEmpty()
	return not self.spellID or type(self.spellID) ~= "number" or self.spellID <= 0
end

function SpellMixin:GetInfo()
	if self:IsEmpty() then return end
	return GetSpellInfo(self.spellID)
end

function SpellMixin:IsCached()
	if self:IsEmpty() then return false end
	return GetSpellInfo(self.spellID) ~= nil
end

function SpellMixin:GetDescription()
	if self:IsEmpty() then return "" end
	
	return C_Spell:GetSpellDescription(self.spellID)
end