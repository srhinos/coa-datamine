InspectStatsPanelMixin = CreateFromMixins(StatsPanelMixin)

function InspectStatsPanelMixin:OnShow()
	self.Background:SetAtlas(GetCharacterFrameSidePanelBackgroundAtlas(self:GetUnit()))
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

function InspectStatsPanelMixin:OnHide()
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end


function InspectStatsPanelMixin:OnEvent(event, ...)
	local unit = ...
	if (not unit or self:IsUnit(unit)) and self:IsVisible() then
		self:ScheduleUpdate()
	end
end

function InspectStatsPanelMixin:GetUnit()
	return AscensionInspectFrame:GetUnit()
end

function InspectStatsPanelMixin:IsUnit(unit)
	return AscensionInspectFrame:IsUnit(unit)
end