PaperDollPanelMixin = {}

function PaperDollPanelMixin:OnLoad()
	self.FelCommutationNotice.Artwork:SetAtlas("legioninvasion-title-bg-bottom", Const.TextureKit.IgnoreAtlasSize)
	self.FelCommutationNotice:SetFrameLevel(self.Model:GetFrameLevel() + 1)
	self:SetUnit("player")
end

function PaperDollPanelMixin:OnShow()
	self:RegisterEvent("UNIT_MODEL_CHANGED")
	self:SetBackground()
	self.Model:ResetValues()
	self.Model:SetUnit(self.unit)
	self:UpdateFelCommutation()
end

function PaperDollPanelMixin:OnHide()
	self:UnregisterEvent("UNIT_MODEL_CHANGED")
end

function PaperDollPanelMixin:OnEvent(event, arg1)
	if event == "UNIT_MODEL_CHANGED" then
		if arg1 == self.unit then
			self.Model:SetUnit(arg1)
		end
	end
end

function PaperDollPanelMixin:SetUnit(unit)
	self.unit = unit
	self.Model:SetUnit(self.unit)
	for _, slot in pairs(self.ItemsFrame.ItemSlots) do
		slot:SetUnit(self.unit)
	end
end

function PaperDollPanelMixin:UpdateFelCommutation()
	if C_Player:IsHighRisk() then
		self.FelCommutationNotice:Show()
		if C_HighRisk.IsFelCommutationActive() then
			self.FelCommutationNotice.Cost:Show()
			self.FelCommutationNotice.Label:SetText(FEL_COMMUTATION_POTENTIAL_LOSS)
			self.FelCommutationNotice.Cost:SetFormattedText(FEL_COMMUTATION_DEATH_COST_S, GetMoneyString(C_HighRisk.GetInsuranceTotalCost()))
		else
			self.FelCommutationNotice.Cost:Hide()
			self.FelCommutationNotice.Label:SetText(FEL_COMMUTATION_NOT_ACTIVE)
		end
	else
		self.FelCommutationNotice:Hide()
	end
end

function PaperDollPanelMixin:SetBackground()
	local _, fileName = UnitRace(self.unit)
	local atlas = DressUpTexturePath(fileName, true)
	local model = self.Model

	model.Background:SetAtlas(atlas)
	model.Background:SetDesaturated(true)

	-- HACK - Adjust background brightness for different races
	if ( strupper(fileName) == "BLOODELF") then
		model.BackgroundOverlay:SetAlpha(0.8)
	elseif (strupper(fileName) == "NIGHTELF") then
		model.BackgroundOverlay:SetAlpha(0.6)
	elseif ( strupper(fileName) == "SCOURGE") then
		model.BackgroundOverlay:SetAlpha(0.3)
	elseif ( strupper(fileName) == "TROLL" or strupper(fileName) == "ORC") then
		model.BackgroundOverlay:SetAlpha(0.6)
	else
		model.BackgroundOverlay:SetAlpha(0.7)
	end
end

function PaperDollPanelMixin:GetItemSlot(slot)
	return self.ItemsFrame.ItemSlots[slot]
end

function PaperDollPanelMixin:GetItemSlots()
	return self.ItemsFrame.ItemSlots
end