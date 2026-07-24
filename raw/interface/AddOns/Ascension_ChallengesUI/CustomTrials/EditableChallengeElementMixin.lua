EditableChallengeElementMixin = {}

function EditableChallengeElementMixin:ShowEditMode()
	dprint(self:GetName(), "ShowEditMode No Implementation")
end

function EditableChallengeElementMixin:HideEditMode()
	dprint(self:GetName(), "HideEditMode No Implementation")
end

function EditableChallengeElementMixin:HideEditModeIfEditing()
	self:GetParent():HideEditModeIfElement(self)
end

function EditableChallengeElementMixin:IsEditMode()
	return false
end

function EditableChallengeElementMixin:HideOverlay()
	self.EditOverlay:Hide()
end

EditableChallengeIconMixin = CreateFromMixins(EditableChallengeElementMixin)

function EditableChallengeIconMixin:ShowEditMode()
	self.IconSelector:Show()
end

function EditableChallengeIconMixin:HideEditMode()
	self.IconSelector:Hide()
end

function EditableChallengeIconMixin:IsEditMode()
	return self.IconSelector:IsShown()
end

EditableChallengeTextMixin = CreateFromMixins(EditableChallengeElementMixin)

function EditableChallengeTextMixin:ShowEditMode()
	self.Text:Hide()
	self.EditBox:Show()
	self.EditBox:SetFocus()
end

function EditableChallengeTextMixin:HideEditMode()
	self.EditBox:Hide()
	self.Text:SetText(self.EditBox:GetText())
	self.Text:Show()
end

function EditableChallengeTextMixin:IsEditMode()
	return self.EditBox:IsShown()
end 