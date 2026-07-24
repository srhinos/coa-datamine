--
-- Single Line Text
--
EditableBuildTextMixin = CreateFromMixins(EditableBuildElementMixin)

function EditableBuildTextMixin:OnLoad()
    self.EditBox:SetMaxLetters(128)
end

function EditableBuildTextMixin:OnShow()
    self.EditBox:Hide()
    self.Text:Show()
end

function EditableBuildTextMixin:ShowEditMode()
    self.Text:Hide()
    self.EditBox:Show()
    self.EditBox:SetFocus()
end

function EditableBuildTextMixin:SetText(text)
    self.Text:SetText(text)
    self.EditBox:SetText(text)
    self.EditBox:Hide()
    self.Text:Show()
end

function EditableBuildTextMixin:HideEditMode()
    self.Text:SetText(self.EditBox:GetText())
end

function EditableBuildTextMixin:IsEditMode()
    return self.EditBox:IsShown()
end

function EditableBuildTextMixin:OnClick()
    self:StartEditing()
end

function EditableBuildTextMixin:ToText()
    local text = self.EditBox:GetText() or ""
    return text:trim()
end

--
-- Multiline Text
-- Multiline is a little confusing
-- self.ScrollFrame.Text is the EditBox
-- self.Text is the SimpleHTML text element
--
EditableBuildMultilineTextMixin = CreateFromMixins(EditableBuildElementMixin)

function EditableBuildMultilineTextMixin:OnLoad()
    self.ScrollFrame.Text:SetMaxLetters(2000)
    self.ScrollFrame.Text:SetScript("OnEnterPressed", function(editBox)
        if IsShiftKeyDown() then
            editBox:Insert("\n")
            return
        end

        EditBox_ClearFocus(editBox)
        self:HideEditModeIfEditing()
    end)

    self.ScrollFrame.Text:SetScript("OnEscapePressed", function(editBox)
        EditBox_ClearFocus(editBox)
        self:HideEditModeIfEditing()
    end)
end

function EditableBuildMultilineTextMixin:OnShow()
    self.ScrollFrame:Hide()
    self.Text:Show()
end

function EditableBuildMultilineTextMixin:ShowEditMode()
    self.Text:Hide()
    self.ScrollFrame:Show()
    self.ScrollFrame.Text:SetFocus()
    self.ScrollFrame:SetVerticalScroll(0)
    ChatEdit_SetInsertTarget(self.ScrollFrame.Text)
end

function EditableBuildMultilineTextMixin:SetText(text)
    self:SetHeight(2000)
    self.ScrollFrame.Text:SetText(text)
    local height = self.Text:SetDynamicText(text)
    self:GetParent():SetHeight(math.max(190, height + 62))
    self:SetHeight(math.max(128, height))
    self.ScrollFrame:Hide()
    self.Text:Show()
end

function EditableBuildMultilineTextMixin:HideEditMode()
    self:SetText(self.ScrollFrame.Text:GetText())
    ChatEdit_ClearInsertTarget(self.ScrollFrame.Text)
end

function EditableBuildMultilineTextMixin:IsEditMode()
    return self.ScrollFrame:IsShown()
end

function EditableBuildMultilineTextMixin:OnClick()
    self:StartEditing()
end

function EditableBuildMultilineTextMixin:ToText()
    local text = self.ScrollFrame.Text:GetText() or ""
    return text:trim()
end

EditableBuildProsAndConsTextMixin = CreateFromMixins(EditableBuildMultilineTextMixin)

function EditableBuildProsAndConsTextMixin:SetText(text)
    -- colors pros / cons
    text = BuildCreatorUtil.FormatProsAndCons(text)
    self:SetHeight(2000)
    self.ScrollFrame.Text:SetText(text)
    local height = self.Text:SetDynamicText(text)
    self:GetParent():SetHeight(math.max(190, height + 62))
    self:SetHeight(math.max(128, height))
    self.ScrollFrame:Hide()
    self.Text:Show()
end