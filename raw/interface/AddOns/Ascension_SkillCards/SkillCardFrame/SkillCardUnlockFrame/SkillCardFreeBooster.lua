-------------------------------------------------------------------------------
--                                    Menu                                   --
-------------------------------------------------------------------------------
SkillCardFreeBoosterMixin = {}

function SkillCardFreeBoosterMixin:OnLoad()
	self:EnableMouse(true)
	self:Layout()
	self.ProgressBar:PlayUpdateValueAnim(0, SkillCardUtil.GetBonusSealedCardPacksProgress())
end

function SkillCardFreeBoosterMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(FREE_BOOSTER_PROGRESS, 1, 1, 1, 1)
	GameTooltip:AddLine(FREE_BOOSTER_PROGRESS_TOOLTIP, 1, 0.82, 0, 1)
	GameTooltip:Show()
	self.IllustrationAdd:Show()
end

function SkillCardFreeBoosterMixin:OnLeave()
	GameTooltip:Hide()
	self.IllustrationAdd:Hide()
end

function SkillCardFreeBoosterMixin:GetProgress()
	if self.ProgressBar:GetScript("OnUpdate") then
		return self.ProgressBar.newValue
	end

	return self.ProgressBar:GetValue()
end

function SkillCardFreeBoosterMixin:UpdateProgressBar(progress)
	if (self.ProgressBar:IsVisible()) then
		self.ProgressBar:PlayUpdateValueAnim()
	else
		self.ProgressBar:SetValue(progress)
	end
end

function SkillCardFreeBoosterMixin:Layout()
	self:SetSize(276, 34)

	self.ProgressBar = CreateFrame("FRAME", "$parent.ProgressBar", self, "BetterStatusBarTemplate")
	self.ProgressBar:SetPoint("RIGHT", -4, 0)
	self.ProgressBar:SetWidth(208)
	MixinAndLoadScripts(self.ProgressBar, SkillCardFreeBoosterProgressBar)
	
	self.ProgressBar:SetScript("OnEnter", GenerateClosure(self.OnEnter, self))
	self.ProgressBar:SetScript("OnLeave", GenerateClosure(self.OnLeave, self))

	self.Illustration = self:CreateTexture(nil, "ARTWORK")
	self.Illustration:SetSize(64, 64)
	self.Illustration:SetPoint("RIGHT", self.ProgressBar, "LEFT", -4, 6)
	self.Illustration:SetTexture("Interface\\Darkmoon\\booster_gold")

	self.IllustrationAdd = self:CreateTexture(nil, "OVERLAY")
	self.IllustrationAdd:SetSize(64, 64)
	self.IllustrationAdd:SetPoint("CENTER", self.Illustration, 0, 0)
	self.IllustrationAdd:SetTexture("Interface\\Darkmoon\\booster_gold")
	self.IllustrationAdd:Hide()
	self.IllustrationAdd:SetBlendMode("ADD")
	self.IllustrationAdd:SetAlpha(0.5)
end
