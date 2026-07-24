DraftCardCurrencyMixin = {}

DraftCardCurrencyMixin.CurrencyType = {
	AbilityEssence = 1,
	TalentEssence = 2,
}

function DraftCardCurrencyMixin:SetCurrencyType(currencyType)
	self.currencyType = currencyType

	if currencyType == DraftCardCurrencyMixin.CurrencyType.AbilityEssence then
		self.Border:SetAtlas("draft-card-currency-ae", Const.TextureKit.UseAtlasSize)
		self.Highlight:SetAtlas("draft-card-currency-ae-highlight", Const.TextureKit.UseAtlasSize)
		self.Border:SetPoint("CENTER", -42, 26)
		self.Highlight:SetPoint("CENTER", 6, 9)
		self.Count:SetPoint("CENTER", 6, -4)
		self.tooltipTitle = DRAFT_AE_COST
		self.tooltipText = DRAFT_AE_COST_TOOLTIP
	elseif currencyType == DraftCardCurrencyMixin.CurrencyType.TalentEssence then
		self.Border:SetAtlas("draft-card-currency-te", Const.TextureKit.UseAtlasSize)
		self.Highlight:SetAtlas("draft-card-currency-te-highlight", Const.TextureKit.UseAtlasSize)
		self.Border:SetPoint("CENTER", 42, 26)
		self.Highlight:SetPoint("CENTER", -6, 9)
		self.Count:SetPoint("CENTER", -6, -4)
		self.tooltipTitle = DRAFT_TE_COST
		self.tooltipText = DRAFT_TE_COST_TOOLTIP
	end
end

function DraftCardCurrencyMixin:OnEnter()
	GameTooltip_GenericTooltip(self, "ANCHOR_RIGHT")
end

function DraftCardCurrencyMixin:OnLeave()
	GameTooltip:Hide()
end

function DraftCardCurrencyMixin:SetValue(value)
	if not value or value == 0 then
		self:Hide()
		return
	end

	self:Show()
	self.Count:SetText(value)
end