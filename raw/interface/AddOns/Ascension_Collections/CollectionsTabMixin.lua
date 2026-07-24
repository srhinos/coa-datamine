CollectionsTabMixin = CreateFromMixins(TabSystemTabMixin)

function CollectionsTabMixin:OnLoad()
	self:SetTextPadding(26)
	self.Icon:SetBorderTexture("Interface\\common\\WhiteIconFrame")
	self.Icon:SetBorderColor(GRAY_FONT_COLOR:GetRGB())
end

function CollectionsTabMixin:SetIcon(icon)
	self.Icon:SetIcon(icon)
end

function CollectionsTabMixin:OnMouseDown()
	if not self:IsTabEnabled() then
		return
	end
	self.Icon:SetPointOffset(0, -1)
end 

function CollectionsTabMixin:OnMouseUp()
	if not self:IsTabEnabled() then
		self.Icon:SetPointOffset(0, 0)
		return
	end
	self.Icon:SetPointOffset(0, 0)
end

function CollectionsTabMixin:OnHide()
	self.Icon:SetPointOffset(0, 0)
end

function CollectionsTabMixin:OnSelected()
	self.Icon:SetBorderColor(YELLOW_FONT_COLOR:GetRGB())
end

function CollectionsTabMixin:OnDeselected()
	self.Icon:SetBorderColor(GRAY_FONT_COLOR:GetRGB())
end 
