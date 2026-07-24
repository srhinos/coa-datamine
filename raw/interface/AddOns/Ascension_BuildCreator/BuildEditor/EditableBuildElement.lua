EditableBuildElementMixin = {}

function EditableBuildElementMixin:GetEditController()
    return BuildCreatorFrameEditableBuildViewPanel
end
 
function EditableBuildElementMixin:ShowEditMode()
    dprint(self:GetName(), "ShowEditMode No Implementation")
end

function EditableBuildElementMixin:HideEditMode()
    dprint(self:GetName(), "HideEditMode No Implementation")
end

function EditableBuildElementMixin:HideEditModeIfEditing()
    local parent = self:GetEditController()
    if parent.editElement == self then
        parent.editElement:HideEditMode()
        parent.editElement = nil
        if parent.OnEditModeHide then
            parent:OnEditModeHide(self)
        end
    end
end

function EditableBuildElementMixin:StartEditing()
    local parent = self:GetEditController()
    if parent.editElement then
        parent.editElement:HideEditMode()
        if parent.OnEditModeHide then
            parent:OnEditModeHide(parent.editElement)
        end
    end

    parent.editElement = self
    self:ShowEditMode()
    self:HideOverlay()

    if parent.OnEditModeShow then
        parent:OnEditModeShow(self)
    end
end

function EditableBuildElementMixin:IsEditMode()
    return false
end

function EditableBuildElementMixin:HideOverlay()
    self.EditOverlay:Hide()
end

function EditableBuildElementMixin:ToText()
    dprint(self:GetName(), "ToText No Implementation")
end

function EditableBuildElementMixin:OnEnter()
    if self:IsEditMode() then
        self.EditOverlay:Hide()
        return
    end
    self.EditOverlay:Show()
end

function EditableBuildElementMixin:OnLeave()
    self.EditOverlay:Hide()
end