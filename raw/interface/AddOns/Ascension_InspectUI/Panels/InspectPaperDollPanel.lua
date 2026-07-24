InspectPaperDollPanelMixin = CreateFromMixins(PaperDollPanelMixin)

function InspectPaperDollPanelMixin:OnLoad()
	PaperDollPanelMixin.OnLoad(self)
	self:SetUnit("target")
end

function InspectPaperDollPanelMixin:OnShow()
	self:SetUnit(AscensionInspectFrame:GetUnit())
	PaperDollPanelMixin.OnShow(self)
end
