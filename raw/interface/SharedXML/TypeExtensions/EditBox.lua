local EditBox = GetEditBoxMetatable().__index

function EditBox:Disable()
    self:EnableMouse(false)
    self:EnableKeyboard(false)
    self:ClearFocus()
end

function EditBox:Enable()
    self:EnableMouse(true)
    self:EnableKeyboard(true)
end 

function EditBox:IsEnabled()
    return self:IsMouseEnabled() and self:IsKeyboardEnabled() and 1
end 

function EditBox:SetEnabled(enable)
    if enable then
        self:Enable()
    else
        self:Disable()
    end
end