KeystoneAffixMixin = {}

function KeystoneAffixMixin:OnLoad()
	self.Background:SetPortraitTexture("Interface\\Icons\\uico_blood_spell_03_gray_Border")
	self.Background:SetVertexColor(0.1, 0.1, 0.1)
	SetParentArray(self, "AffixButtons", self:GetID())
end

function KeystoneAffixMixin:OnEnter()
	if self.affixID then
		GameTooltip:SetOwner(self, GameTooltip_AutoAnchor(self))
		GameTooltip:SetAffix(self.affixID)
		GameTooltip:Show()
	elseif self.tooltipTitle then
		GameTooltip:SetOwner(self, GameTooltip_AutoAnchor(self))
		GameTooltip:SetText(self.tooltipTitle, 1, 1, 1, 1)
		if self.tooltipText then
			GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, true)
		end
		GameTooltip:Show()
	end
end

function KeystoneAffixMixin:OnClick()
	if self.affixID and IsModifiedClick("CHATLINK") then
		ChatEdit_InsertLink(GetSpellLink(self.affixID))
	end
end

function KeystoneAffixMixin:SetAffix(affixID)
	self.tooltipTitle = nil
	self.tooltipText = nil
	if affixID then
		self.Icon:Show()
		self.Information:Show()
		self.affixID = affixID

		local name, level, icon = GetSpellInfo(affixID)
		if not name then
			name = "Unknown Affix: "..affixID
			icon = "Interface\\Icons\\inv_misc_questionmark"
		end

		if level then
			name = format("%s\n|cffFFFFFF(%s)|r", name, level)
		end
		self.Information.Text:SetText(name)
		self.Icon:SetPortraitTexture(icon)
		self:EnableMouse(true)
	else
		self:EnableMouse(false)
		self.affixID = nil
		self.Icon:Hide()
		self.Information:Hide()
	end
end 

function KeystoneAffixMixin:SetStaticAffix(keystoneInfo, index)
	self.affixID = nil
	local affix = MYTHIC_PLUS_STATIC_AFFIXES[index]
	self.Icon:Show()
	self.Information:Show()

	local name = format(affix.name, keystoneInfo[affix.value])
	local tooltipText = format(affix.tooltipText, keystoneInfo[affix.value])

	self.tooltipTitle = affix.tooltipTitle
	self.tooltipText = tooltipText

	self.Information.Text:SetText(name)
	self.Icon:SetPortraitTexture(affix.icon)
end

KeystoneAffixSmallMixin = CreateFromMixins(KeystoneAffixMixin)

function KeystoneAffixSmallMixin:SetAffix(affixID)
	self.tooltipTitle = nil
	self.tooltipText = nil
	if affixID then
		self.Icon:Show()
		self.affixID = affixID

		local _, level, icon = GetSpellInfo(affixID)
		if not icon then
			icon = "Interface\\Icons\\inv_misc_questionmark"
		end

		self.Icon:SetPortraitTexture(icon)
		self.Level:SetText(level and level:match("%d+") or "")
		self:EnableMouse(true)
	else
		self:EnableMouse(false)
		self.affixID = nil
		self.Icon:Hide()
	end
end 