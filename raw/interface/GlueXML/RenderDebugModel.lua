RenderDebugModelMixin = {}

function RenderDebugModelMixin:OnShow()
    self:SetSequence(0);
    self:SetCamera(0);
    self:SetPosition(0, 0, 0)
    SetCharCustomizeFrame("RenderDebugModel")
    ResetCharCustomize()
    SetCharacterGender(2)
    SetSelectedClass(10)
    SetCharacterClass(10)
    SetCharacterCreateFacing(-15)
    SetCharacterRace(1)
    SetSelectedRace(1)
    SetBackgroundModel(self, "ALLIANCE")

    if AscensionDevClientNotification then
        AscensionDevClientNotification.Text:SetText("-- DEBUG RENDERER --")
    end
end

function RenderDebugModelMixin:OnUpdate()
    if self.RotateRight:GetButtonState() == "PUSHED" then
        SetCharacterCreateFacing(GetCharacterCreateFacing() - CHARACTER_FACING_INCREMENT);
    end
    
    if self.RotateLeft:GetButtonState() == "PUSHED" then
        SetCharacterCreateFacing(GetCharacterCreateFacing() + CHARACTER_FACING_INCREMENT);
    end
end