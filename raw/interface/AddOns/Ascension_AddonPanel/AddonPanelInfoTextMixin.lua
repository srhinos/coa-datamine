AddonPanelInfoTextMixin = {}

function AddonPanelInfoTextMixin:OnLoad()
	AttributesToKeyValues(self)
	self:SetHeaderFontObject(self.headerFont)
	self:SetFontObject(self.textFont)
	self:SetHeader(_G[self.header] or self.header)
	self:SetText(_G[self.text] or self.text)
	self:EnableDivider(self.showDivider)
end

function AddonPanelInfoTextMixin:UpdateSize()
	self.Header:SetWidth(self:GetWidth())
	self.Value:SetWidth(self:GetWidth())
	self.Divider:SetWidth(self:GetWidth())
	self:SetHeight(self.Header:GetStringHeight() + 6 + self.Value:GetStringHeight() + (self.Divider:IsShown() and 12 or 4))
end

function AddonPanelInfoTextMixin:EnableDivider(show)
	self.Divider:SetShown(show)
	self:UpdateSize()
end

function AddonPanelInfoTextMixin:SetHeaderFontObject(font)
	if not font then return end
	self.Header:SetFontObject(font)
	self:UpdateSize()
end

function AddonPanelInfoTextMixin:SetHeader(text)
	self.Header:SetText(text)
	self:UpdateSize()
end

function AddonPanelInfoTextMixin:SetFontObject(font)
	if not font then return end
	self.Value:SetFontObject(font)
	self:UpdateSize()
end

function AddonPanelInfoTextMixin:SetText(text)
	self.Value:SetText(text)
	if not text or strlen(text) == 0 then
		self.Divider:ClearAndSetPoint("TOPLEFT", self.Header, "BOTTOMLEFT", 0, -8)
	else
		self.Divider:ClearAndSetPoint("TOPLEFT", self.Value, "BOTTOMLEFT", 0, -8)
	end
	self:UpdateSize()
end