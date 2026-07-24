InspectMysticEnchantPanelMixin = CreateFromMixins(MysticEnchantPanelMixin)

function InspectMysticEnchantPanelMixin:OnLoad()
	self.enchants = {}
	self:SetTemplate("MysticEnchantPanelItemTemplate")
	self:SetGetNumResultsFunction(function() return #self.enchants end)
	self:SetCanSelect(false)
	self.unit = "target"
end

function InspectMysticEnchantPanelMixin:OnShow()
	self.unit = AscensionInspectFrame:GetUnit()
	MysticEnchantPanelMixin.OnShow(self)
	self:RegisterEvent("MYSTIC_ENCHANT_INSPECT_RESULT")
end

function InspectMysticEnchantPanelMixin:OnHide()
	MysticEnchantPanelMixin.OnHide(self)
	self:UnregisterEvent("MYSTIC_ENCHANT_INSPECT_RESULT")
	wipe(self.enchants)
end