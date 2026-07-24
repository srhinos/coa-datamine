ModelMixin = {}

local function OnUpdate(self, elapsed)
    if self.rotation then -- legacy thing
        Model_OnUpdate(self, elapsed)
    elseif self.RotateRightButton and self.RotateLeftButton then
        if self.RotateRightButton:GetButtonState() == "PUSHED" then
            self.facing = self:GetFacing() - 0.02
            self:SetFacing(self.facing)
        elseif self.RotateLeftButton:GetButtonState() == "PUSHED" then
            self.facing = self:GetFacing() + 0.02
            self:SetFacing(self.facing)
        end
    end

    if self.RightX and self.RightY then
        local x, y = GetScaledCursorPosition(self)
        local diffX = (x - self.RightX) * self.dragScale
        local diffY = (y - self.RightY) * self.dragScale

        self.RightX = x
        self.RightY = y

        local x, y, z = self:GetPosition()
        if self.maxPos then
            y = MClamp(y + diffX, -self.maxPos.x, self.maxPos.x)
            z = MClamp(z + diffY, -self.maxPos.y, self.maxPos.y)
        else
            y = y + diffX
            z = z + diffY
        end
        self.position = { x, y, z }
        self:SetPosition(x, y, z)

        if self.PostUpdate then
            self:PostUpdate()
        end
        return
    end

    if self.LeftX then
        local x = GetScaledCursorPosition(self)
        local diff = (x - self.LeftX) * 0.01
        self.LeftX = x
        self.facing = self:GetFacing() + diff
        self:SetFacing(self.facing)
    end

    if self.PostUpdate then
        self:PostUpdate()
    end
end

local function OnMouseDown(self, button)
    if button == "RightButton" and self.dragMove then
        self.RightX, self.RightY = GetScaledCursorPosition(self)
        return
    end

    if self.dragRotation then
        self.LeftX = GetScaledCursorPosition(self)
    end
end

local function OnMouseUp(self)
    self.RightX = nil
    self.RightY = nil
    self.LeftX = nil
end

local function OnMouseWheel(self, delta)
    local distance, y, z = self:GetPosition()

    distance = distance + (delta * 0.05)

    distance = max(distance, self.minDistance or -3)
    distance = min(distance, self.maxDistance or 0)

    self.distance = distance
    self:SetPosition(distance, y, z)
end

function ModelMixin:OnLoad()
    self.defaultDistance = self:GetPosition()
    self.defaultFacing = self:GetFacing()
    self.defaultPosition = { self:GetPosition() }
    self.dragScale = 0.01

    self:ResetValues()
    self:SetScript("OnUpdate", OnUpdate)
    self:EnableMouse(true)
    self:EnableMouseWheel()
end

function ModelMixin:SetMinMaxDistance(minDistance, maxDistance)
    self.minDistance = minDistance
    self.maxDistance = maxDistance
    self.distance = MClamp(self.distance, minDistance, maxDistance)
    local x, y, z = self:GetPosition()
    
    x = MClamp(self.distance, y, z)
    self:SetPosition(x, y, z)
end

function ModelMixin:SetDragScale(scale)
    self.dragScale = scale
end

function ModelMixin:SetMaxPosOffset(x, y)
    self.maxPos = {
        x = x,
        y = y
    }

    local x, y, z = self:GetPosition()
    if self.maxPos then
        y = MClamp(y, -self.maxPos.x, self.maxPos.x)
        z = MClamp(z, -self.maxPos.y, self.maxPos.y)
    end

    self.position = { x, y, z }
    self:SetPosition(x, y, z)
end

function ModelMixin:RefreshValues()
    self:SetFacing(self.facing)
    self:SetPosition(unpack(self.position))
end

function ModelMixin:ResetValues()
    self.facing = self.defaultFacing
    self.position = self.defaultPosition
    self.distance = self.position[1]

    self:RefreshValues()
end

function ModelMixin:SetEnableDragRotation(enable)
    self.dragRotation = enable
    if enable then
        if self.dragMove then
            return
        end
        self:SetScript("OnMouseDown", OnMouseDown)
        self:SetScript("OnMouseUp", OnMouseUp)
    else
        if self.dragMove then
            return
        end
        self:SetScript("OnMouseDown", nil)
        self:SetScript("OnMouseUp", nil)
    end
end

function ModelMixin:SetEnableDragMove(enable)
    self.dragMove = enable
    if enable then
        if self.dragRotation then
            return
        end
        self:SetScript("OnMouseDown", OnMouseDown)
        self:SetScript("OnMouseUp", OnMouseUp)
    else
        if self.dragRotation then
            return
        end
        self:SetScript("OnMouseDown", nil)
        self:SetScript("OnMouseUp", nil)
    end
end

function ModelMixin:SetEnableScrollZoom(enable)
    self.scrollZoom = enable

    if enable then
        self:SetScript("OnMouseWheel", OnMouseWheel)
    else
        self:SetScript("OnMouseWheel", nil)
    end
end