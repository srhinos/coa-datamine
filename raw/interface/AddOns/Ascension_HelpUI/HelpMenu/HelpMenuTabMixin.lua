HelpMenuTabMixin = CreateFromMixins(TabSystemTabMixin)

function HelpMenuTabMixin:OnLoad()
	self:SetNormalAtlas("helpbutton")
	self:SetPushedAtlas("helpbutton-pushed")
	self:SetHighlightAtlas("helpbutton-highlight")
	self.Selected:SetAtlas("helpbutton-selected", Const.TextureKit.IgnoreAtlasSize)

	AttributesToKeyValues(self)
	self:SetIcon(self.IconAtlas)
end

function HelpMenuTabMixin:SetIcon(icon, iconSize)
	if not icon then
		self.Icon:SetTexture(nil)
		return
	end
	
	self.Icon:SetAtlas(icon, iconSize == nil)
	if iconSize then
		self.Icon:SetSize(iconSize, iconSize)
	end
end

function HelpMenuTabMixin:OnDisable()
	if self.forceDisabled then
		return
	end
	self.Selected:Show()
end

function HelpMenuTabMixin:OnEnable()
	self.Selected:Hide()
end

function HelpMenuTabMixin:SetTabEnabled(enabled, reason)
	TabSystemTabMixin.SetTabEnabled(self, enabled, reason)
	self:GetNormalTexture():SetDesaturated(not enabled)
	self.Icon:SetDesaturated(not enabled)
end

HelpMenuTabMixin.UpdateWidth = nop

HelpMenuRecoveryTabMixin = CreateFromMixins(HelpMenuTabMixin)

function HelpMenuRecoveryTabMixin:OnLoad()
	self:SetNormalAtlas("Garr_ListButton")
	self:SetPushedAtlas("Garr_ListButton")
	self:SetHighlightAtlas("Garr_ListButton-Highlight")
	self.Selected:SetAtlas("Garr_ListButton-Selection", Const.TextureKit.IgnoreAtlasSize)

	AttributesToKeyValues(self)
	self:SetIcon(self.IconAtlas)
end 